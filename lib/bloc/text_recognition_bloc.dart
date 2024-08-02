import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:albayrakdc_control/bloc/text_recognition_event.dart';
import 'package:albayrakdc_control/bloc/text_recognition_state.dart';
import '../g_sheets_services.dart';

class TextRecognitionBloc extends Bloc<TextRecognitionEvent, TextRecognitionState> {
  final textRecognizer = GoogleMlKit.vision.textRecognizer();
  final imagePicker = ImagePicker();
  final Map<String, TextEditingController> controllers = {
    'ETIKET': TextEditingController(),
    'EBAT': TextEditingController(),
    'KALITE': TextEditingController(),
    'DOKUM': TextEditingController(),
    'AGIRLIK': TextEditingController(),
    'PAKET': TextEditingController(),
  };

  TextRecognitionBloc() : super(TextRecognitionState()) {
    on<RecognizeTextFromCamera>(_onRecognizeTextFromCamera);
    on<RecognizeTextFromGallery>(_onRecognizeTextFromGallery);
    on<UploadToGoogleSheets>(_onUploadToGoogleSheets);
    on<UpdateSelectedNumber>(_onUpdateSelectedNumber);
    on<IncrementSelectedNumber>(_onIncrementSelectedNumber);
    on<UpdateTextFieldValue>(_onUpdateTextFieldValue);
    on<DownloadSpreadsheet>(_onDownloadSpreadsheet);
    on<SwitchToSheet2>(_onSwitchToSheet2);
  }

  Future<void> _onRecognizeTextFromCamera(RecognizeTextFromCamera event, Emitter<TextRecognitionState> emit) async {
    await _recognizeText(ImageSource.camera, emit);
  }

  Future<void> _onRecognizeTextFromGallery(RecognizeTextFromGallery event, Emitter<TextRecognitionState> emit) async {
    await _recognizeText(ImageSource.gallery, emit);
  }

  Future<void> _recognizeText(ImageSource source, Emitter<TextRecognitionState> emit) async {
    emit(state.copyWith(isLoading: true, error: null, isDataRecognized: false));

    try {
      final pickedFile = await imagePicker.pickImage(source: source);
      if (pickedFile == null) {
        emit(state.copyWith(isLoading: false, error: 'Belge Seçilmedi'));
        return;
      }

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final recognizedText = await textRecognizer.processImage(inputImage);

      final extractedData = _filterRecognizedText(recognizedText);
      final recognizedTextString = extractedData.entries.map((e) => '${e.key}: ${e.value}').join('\n');

      emit(state.copyWith(
        isLoading: false,
        recognizedText: recognizedTextString.isNotEmpty ? recognizedTextString : 'Metin bulunamadı',
        extractedData: extractedData,
        isDataRecognized: true,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Görüntü tanınamadı. Lütfen tekrar deneyin.', isDataRecognized: false));
    }
  }

  Map<String, String> _filterRecognizedText(RecognizedText recognizedText) {
    final extractedData = <String, String>{
      'EBAT': '',
      'KALITE': '',
      'DOKUM': '',
      'AGIRLIK': '',
      'PAKET': '',
    };

    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        final text = line.text;
        if (text.contains('Ø')) {
          extractedData['EBAT'] = text;
        } else if (text.contains('SAE')) {
          extractedData['KALITE'] = text;
        } else if (RegExp(r'^\d{6}$').hasMatch(text)) {
          extractedData['DOKUM'] = text;
        } else if (RegExp(r'^\d+$').hasMatch(text) && text.length == 4) {
          extractedData['AGIRLIK'] = text;
        } else if (RegExp(r'^\d{8}$').hasMatch(text)) {
          extractedData['PAKET'] = text;
        }
      }
    }

    return extractedData;
  }

  void _onUpdateTextFieldValue(UpdateTextFieldValue event, Emitter<TextRecognitionState> emit) {
    controllers[event.field]?.text = event.value;
    emit(state.copyWith(
      extractedData: Map.from(state.extractedData)..update(event.field, (_) => event.value),
    ));
  }

  Future<void> _onUploadToGoogleSheets(UploadToGoogleSheets event, Emitter<TextRecognitionState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await GoogleSheetsService.insertData(event.data, state.selectedNumber);
      emit(state.copyWith(
        isLoading: false,
        error: 'Veriler başarıyla Google Sheets\'e yüklendi.',
        isDataRecognized: false,
        extractedData: {},
      ));
      add(IncrementSelectedNumber());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Veri yüklenirken bir hata oluştu: $e'));
    }
  }

  void _onUpdateSelectedNumber(UpdateSelectedNumber event, Emitter<TextRecognitionState> emit) {
    emit(state.copyWith(
      selectedNumber: event.number,
      isDataRecognized: false,
      extractedData: {},
    ));
  }

  void _onSwitchToSheet2(SwitchToSheet2 event, Emitter<TextRecognitionState> emit) {
    GoogleSheetsService.switchToSheet2();
    emit(state.copyWith(isSheet2: true));
  }

  void _onIncrementSelectedNumber(IncrementSelectedNumber event, Emitter<TextRecognitionState> emit) {
    final newNumber = state.selectedNumber < 25 ? state.selectedNumber + 1 : 1;
    emit(state.copyWith(selectedNumber: newNumber));
  }

  Future<void> _onDownloadSpreadsheet(DownloadSpreadsheet event, Emitter<TextRecognitionState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final filePath = await GoogleSheetsService.downloadSpreadsheet();
      if (filePath != null) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Tablo başarıyla indirildi: $filePath',
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Tablo indirilemedi.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Tablo indirilirken bir hata oluştu: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    textRecognizer.close();
    controllers.values.forEach((controller) => controller.dispose());
    return super.close();
  }
}