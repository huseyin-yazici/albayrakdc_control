import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:albayrakdc_control/bloc/text_bloc/text_recognition_state.dart';
import '../../g_sheets_services.dart';
import 'text_recognition_event.dart';

class TextRecognitionBloc extends Bloc<TextRecognitionEvent, TextRecognitionState> {
  String? _field;
  String? _value;
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
    on<UpdateSelectedNumber>(_onUpdateSelectedNumber);
    on<IncrementSelectedNumber>(_onIncrementSelectedNumber);
    on<UpdateTextFieldValue>(_onUpdateTextFieldValue);
    on<DownloadSpreadsheet>(_onDownloadSpreadsheet);
    on<SwitchToSheet2>(_onSwitchToSheet2);
    on<UpdateTextFieldQrValue>(_onUpdateTextFieldQrValue);
    on<RecognizeQRFromImage>(_onRecognizeQRFromImage);
    on<UploadToGoogleSheets>((event, emit) async {
      emit(state.copyWith(isLoading: true, error: null));

      try {
        await GoogleSheetsService.insertData(event.data, state.selectedNumber);
        emit(state.copyWith(
          isLoading: false,
          error: null,
          isDataRecognized: false,
          extractedData: {},
        ));
        add(UploadSuccessful());
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Veri yüklenirken bir hata oluştu: $e',
        ));
      }
    });

    on<UploadSuccessful>((event, emit) {
      emit(state.copyWith(
        isDataRecognized: false,
        extractedData: {},
      ));
    });


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
  void setFieldAndValue(String field, String value) {
    this._field = field;
    this._value = value;
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
void _onUpdateTextFieldQrValue(UpdateTextFieldQrValue event, Emitter<TextRecognitionState> emit) {
  event.qrData.forEach((key, value) {
    controllers[key]?.text = value;
  });
  emit(state.copyWith(
    extractedData: Map.from(state.extractedData)..addAll(event.qrData),
    isDataRecognized: true,
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

  Future<void> _onRecognizeQRFromImage(RecognizeQRFromImage event, Emitter<TextRecognitionState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      print('Resim seçme işlemi başlatılıyor...');
      final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        print('Resim seçilmedi');
        emit(state.copyWith(isLoading: false, error: 'Resim seçilmedi'));
        return;
      }
      print('Resim seçildi: ${pickedFile.path}');

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      print('InputImage oluşturuldu');

      final qrCodeDetector = GoogleMlKit.vision.barcodeScanner();
      print('QR kod tarayıcı başlatıldı');

      print('QR kod tarama işlemi başlıyor...');
      final List<Barcode> barcodes = await qrCodeDetector.processImage(inputImage);
      print('Taranan barkod sayısı: ${barcodes.length}');

      if (barcodes.isNotEmpty) {
        final qrData = barcodes.first.displayValue ?? '';
        print('Okunan QR kod verisi: $qrData');
        final parsedData = _parseQRData(qrData);
        print('Ayrıştırılmış veri: $parsedData');
        emit(state.copyWith(
          isLoading: false,
          extractedData: parsedData,
          isDataRecognized: true,
        ));
      } else {
        print('QR kod bulunamadı');
        emit(state.copyWith(isLoading: false, error: 'QR kod bulunamadı'));
      }

      await qrCodeDetector.close();
    } catch (e) {
      print('QR kod okuma hatası: $e');
      emit(state.copyWith(isLoading: false, error: 'QR kod okuma hatası: $e'));
    }
  }

  Map<String, String> _parseQRData(String data) {
    final extractedData = <String, String>{
      'EBAT': '',
      'KALITE': '',
      'DOKUM': '',
      'AGIRLIK': '',
      'PAKET': '',
    };

    final parts = data.split(';');
    for (var part in parts) {
      part = part.trim();
      if (part.startsWith('Ø')) {
        extractedData['EBAT'] = part;
      } else if (part.startsWith('SAE')) {
        extractedData['KALITE'] = part;
      } else if (RegExp(r'^\d{6}$').hasMatch(part)) {
        extractedData['DOKUM'] = part;
      } else if (RegExp(r'^\d{4}$').hasMatch(part)) {
        extractedData['AGIRLIK'] = part;
      } else if (RegExp(r'^\d{8}$').hasMatch(part)) {
        extractedData['PAKET'] = part;
      }
    }

    print('Ayrıştırılmış veri: $extractedData'); // Hata ayıklama için

    return extractedData;
  }
  @override
  Future<void> close() {
    textRecognizer.close();
    controllers.values.forEach((controller) => controller.dispose());
    return super.close();
  }
}