import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
<<<<<<< HEAD:lib/bloc/text_recognition_bloc.dart
import 'package:albayrakdc_control/bloc/text_recognition_event.dart';
import 'package:albayrakdc_control/bloc/text_recognition_state.dart';
import '../controller/wire_rod_field_controller.dart';
import '../g_sheets_services.dart';

class TextRecognitionBloc
    extends Bloc<TextRecognitionEvent, TextRecognitionState> {
=======
import 'package:albayrakdc_control/bloc/text_bloc/text_recognition_state.dart';
import '../../g_sheets_services.dart';
import 'text_recognition_event.dart';

class TextRecognitionBloc extends Bloc<TextRecognitionEvent, TextRecognitionState> {
  String? _field;
  String? _value;
>>>>>>> b5962d1ba88232bdd366b8c5768e2d30f7f7a26b:lib/bloc/text_bloc/text_recognition_bloc.dart
  final textRecognizer = GoogleMlKit.vision.textRecognizer();
  final imagePicker = ImagePicker();
  final controllers = WireRodControllers.controllers;

  TextRecognitionBloc() : super(TextRecognitionState()) {
    on<RecognizeTextFromCamera>(_onRecognizeTextFromCamera);
    on<RecognizeTextFromGallery>(_onRecognizeTextFromGallery);
    on<UpdateSelectedNumber>(_onUpdateSelectedNumber);
    on<IncrementSelectedNumber>(_onIncrementSelectedNumber);
    on<UpdateTextFieldValue>(_onUpdateTextFieldValue);
    /* on<DownloadSpreadsheet>(_onDownloadSpreadsheet);*/
    on<SwitchToSheet2>(_onSwitchToSheet2);
<<<<<<< HEAD:lib/bloc/text_recognition_bloc.dart
    on<PrintRecognizedText>(_onPrintRecognizedText);
    on<ClearGoogleSheetsRange>(_onClearGoogleSheetsRange); // Yeni eklenen satır
=======
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

>>>>>>> b5962d1ba88232bdd366b8c5768e2d30f7f7a26b:lib/bloc/text_bloc/text_recognition_bloc.dart

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
  void setFieldAndValue(String field, String value) {
    this._field = field;
    this._value = value;
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

<<<<<<< HEAD:lib/bloc/text_recognition_bloc.dart
  Future<void> _onUploadToGoogleSheets(
      UploadToGoogleSheets event, Emitter<TextRecognitionState> emit) async {
=======

  Future<void> _onUploadToGoogleSheets(UploadToGoogleSheets event, Emitter<TextRecognitionState> emit) async {
>>>>>>> b5962d1ba88232bdd366b8c5768e2d30f7f7a26b:lib/bloc/text_bloc/text_recognition_bloc.dart
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
<<<<<<< HEAD:lib/bloc/text_recognition_bloc.dart

  void _onSwitchToSheet2(
      SwitchToSheet2 event, Emitter<TextRecognitionState> emit) {
=======
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
>>>>>>> b5962d1ba88232bdd366b8c5768e2d30f7f7a26b:lib/bloc/text_bloc/text_recognition_bloc.dart
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
