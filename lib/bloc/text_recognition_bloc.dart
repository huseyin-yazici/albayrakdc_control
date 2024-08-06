import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:albayrakdc_control/bloc/text_recognition_event.dart';
import 'package:albayrakdc_control/bloc/text_recognition_state.dart';
import '../controller/wire_rod_field_controller.dart';
import '../g_sheets_services.dart';

class TextRecognitionBloc
    extends Bloc<TextRecognitionEvent, TextRecognitionState> {
  final textRecognizer = GoogleMlKit.vision.textRecognizer();
  final imagePicker = ImagePicker();
  final controllers = WireRodControllers.controllers;

  TextRecognitionBloc() : super(TextRecognitionState()) {
    on<RecognizeTextFromCamera>(_onRecognizeTextFromCamera);
    on<RecognizeTextFromGallery>(_onRecognizeTextFromGallery);
    on<UploadToGoogleSheets>(_onUploadToGoogleSheets);
    on<UpdateSelectedNumber>(_onUpdateSelectedNumber);
    on<IncrementSelectedNumber>(_onIncrementSelectedNumber);
    on<UpdateTextFieldValue>(_onUpdateTextFieldValue);
    /* on<DownloadSpreadsheet>(_onDownloadSpreadsheet);*/
    on<SwitchToSheet2>(_onSwitchToSheet2);
    on<PrintRecognizedText>(_onPrintRecognizedText);
    on<ClearGoogleSheetsRange>(_onClearGoogleSheetsRange); // Yeni eklenen satır

  }

  Future<void> _onRecognizeTextFromCamera(
      RecognizeTextFromCamera event, Emitter<TextRecognitionState> emit) async {
    await _recognizeText(ImageSource.camera, emit);
  }

  Future<void> _onRecognizeTextFromGallery(RecognizeTextFromGallery event,
      Emitter<TextRecognitionState> emit) async {
    await _recognizeText(ImageSource.gallery, emit);
  }


  Future<void> _recognizeText(
      ImageSource source, Emitter<TextRecognitionState> emit) async {
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
      final recognizedTextString =
          extractedData.entries.map((e) => '${e.key}: ${e.value}').join('\n');

      emit(state.copyWith(
        isLoading: false,
        recognizedText: recognizedTextString.isNotEmpty
            ? recognizedTextString
            : 'Metin bulunamadı',
        extractedData: extractedData,
        isDataRecognized: true,
      ));
    } catch (e) {
      emit(state.copyWith(
          isLoading: false,
          error: 'Görüntü tanınamadı. Lütfen tekrar deneyin.',
          isDataRecognized: false));
    }
  }
  Future<void> _onClearGoogleSheetsRange(
      ClearGoogleSheetsRange event, Emitter<TextRecognitionState> emit) async {
    emit(state.copyWith(isClearingSheets: true));
    try {
      await GoogleSheetsService.clearRange();
      emit(state.copyWith(
        isClearingSheets: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isClearingSheets: false,
      ));
    }
  }

// Bu fonksiyon, tanınmış metinleri analiz eder ve belirli anahtar kelimeleri içeren bir harita döndürür.
  Map<String, String> _filterRecognizedText(RecognizedText recognizedText) {
    final extractedData = <String, String>{
      'EBAT': '',
      'KALITE': '',
      'DOKUM': '',
      'AGIRLIK': '',
      'PAKET': '',
    };

    final List<String> allTexts = [];
    String previousText = '';

    // EBAT için regex: 1-3 haneli sayı veya ondalık sayı (örn. 7.5)
    final ebatRegex = RegExp(r'^\d{1,3}(\.\d+)?$');

    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        var text = line.text.trim();

        if (text.contains(':')) {
          text = text.split(':').last.trim();
        }

        if (text.contains('SAE')) {
          extractedData['KALITE'] = text;
          // SAE'den önceki uygun formattaki sayıyı EBAT olarak al
          if (ebatRegex.hasMatch(previousText)) {
            extractedData['EBAT'] = previousText;
          }
        }

        allTexts.add(text);
        previousText = text;
      }
    }

    // Öncelikle 'Ø' içeren metni ara
    if (extractedData['EBAT']!.isEmpty) {
      var ebatText = allTexts.firstWhere(
            (text) => text.contains('Ø'),
        orElse: () => '',
      );
      if (ebatText.isNotEmpty) {
        // 'Ø' işaretinden sonraki sayıyı al
        var match = RegExp(r'Ø\s*(\d{1,3}(\.\d+)?)').firstMatch(ebatText);
        if (match != null) {
          extractedData['EBAT'] = match.group(1)!;
        } else {
          extractedData['EBAT'] = ebatText;
        }
      }
    }

    // Eğer hala EBAT bulunamadıysa, uygun formattaki ilk sayıyı al
    if (extractedData['EBAT']!.isEmpty) {
      for (var text in allTexts) {
        if (ebatRegex.hasMatch(text)) {
          extractedData['EBAT'] = text;
          break;
        }
      }
    }

    // Sadece 6 haneli sayıyı ara (DOKUM için)
    for (var text in allTexts) {
      if (RegExp(r'^\d{6}$').hasMatch(text)) {
        extractedData['DOKUM'] = text;
        break;
      }
    }

    if (extractedData['AGIRLIK']!.isEmpty || extractedData['PAKET']!.isEmpty) {
      for (int i = 0; i < allTexts.length; i++) {
        var text = allTexts[i];
        if (extractedData['AGIRLIK']!.isEmpty && i + 1 < allTexts.length) {
          extractedData['AGIRLIK'] = allTexts[i + 1];
        }
        if (extractedData['PAKET']!.isEmpty && RegExp(r'\d{8}').hasMatch(text)) {
          extractedData['PAKET'] = RegExp(r'\d{8}').firstMatch(text)!.group(0)!;
        }
      }
    }

    // Ağırlık değerini temizle ve 'kg' ifadesini kaldır
    if (extractedData['AGIRLIK']!.isNotEmpty) {
      extractedData['AGIRLIK'] = extractedData['AGIRLIK']!
          .replaceAll(RegExp(r'kg', caseSensitive: false), '')
          .trim();
    }

    // Eğer ağırlık hala boşsa veya 4 haneli rakam değilse, 4 haneli rakam ara
    if (extractedData['AGIRLIK']!.isEmpty ||
        !RegExp(r'^\d{4}$').hasMatch(extractedData['AGIRLIK']!)) {
      for (var text in allTexts) {
        var cleanText = text.replaceAll(RegExp(r'kg', caseSensitive: false), '').trim();
        if (RegExp(r'^\d{4}$').hasMatch(cleanText)) {
          extractedData['AGIRLIK'] = cleanText;
          break;
        }
      }
    }

    print('--- All Recognized Texts ---');
    allTexts.forEach((text) => print(text));
    print('----------------------------');

    return extractedData;
  }
  void _onPrintRecognizedText(
      PrintRecognizedText event, Emitter<TextRecognitionState> emit) {
    print('--- Recognized Text ---');
    state.extractedData.forEach((key, value) {
      print('$key: $value');
    });
    print('----------------------');
  }

  void _onUpdateTextFieldValue(
      UpdateTextFieldValue event, Emitter<TextRecognitionState> emit) {
    controllers[event.field]?.text = event.value;
    emit(state.copyWith(
      extractedData: Map.from(state.extractedData)
        ..update(event.field, (_) => event.value),
    ));
  }

  Future<void> _onUploadToGoogleSheets(
      UploadToGoogleSheets event, Emitter<TextRecognitionState> emit) async {
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
      emit(state.copyWith(
          isLoading: false, error: 'Veri yüklenirken bir hata oluştu: $e'));
    }
  }

  void _onUpdateSelectedNumber(
      UpdateSelectedNumber event, Emitter<TextRecognitionState> emit) {
    emit(state.copyWith(
      selectedNumber: event.number,
      isDataRecognized: false,
      extractedData: {},
    ));
  }

  void _onSwitchToSheet2(
      SwitchToSheet2 event, Emitter<TextRecognitionState> emit) {
    GoogleSheetsService.switchToSheet2();
    emit(state.copyWith(isSheet2: true));
  }

  void _onIncrementSelectedNumber(
      IncrementSelectedNumber event, Emitter<TextRecognitionState> emit) {
    final newNumber = state.selectedNumber < 25 ? state.selectedNumber + 1 : 1;
    emit(state.copyWith(selectedNumber: newNumber));
  }

  /*Future<void> _onDownloadSpreadsheet(DownloadSpreadsheet event, Emitter<TextRecognitionState> emit) async {
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
  }*/

  @override
  Future<void> close() {
    textRecognizer.close();
    controllers.values.forEach((controller) => controller.dispose());
    return super.close();
  }
}
