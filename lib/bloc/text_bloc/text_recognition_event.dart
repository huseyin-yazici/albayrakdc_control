abstract class TextRecognitionEvent {}
class UpdateSelectedNumber extends TextRecognitionEvent {
  final int number;
  UpdateSelectedNumber(this.number);
}
class ToggleSheet extends TextRecognitionEvent {}


class UpdateTextFieldValue extends TextRecognitionEvent {
  final String field;
  final String value;

  UpdateTextFieldValue(this.field, this.value);
}class SwitchToSheet2 extends TextRecognitionEvent {}


class RecognizeTextFromCamera extends TextRecognitionEvent {}
class RecognizeTextFromGallery extends TextRecognitionEvent {}
class UploadToGoogleSheets extends TextRecognitionEvent {
  final Map<String, String> data;
  UploadToGoogleSheets(this.data);
}
class PrintRecognizedText extends TextRecognitionEvent {}
class ClearGoogleSheetsRange extends TextRecognitionEvent {}



class DownloadSpreadsheet extends TextRecognitionEvent {}
class IncrementSelectedNumber extends TextRecognitionEvent {}
class UpdateTextFieldQrValue extends TextRecognitionEvent {
  final Map<String, String> qrData;

  UpdateTextFieldQrValue(this.qrData);
}
class RecognizeQRFromImage extends TextRecognitionEvent {}

class ScanQRCode extends TextRecognitionEvent {}
class UpdateQRData extends TextRecognitionEvent {
  final Map<String, String> data;

  UpdateQRData(this.data);
}
class UploadSuccessful extends TextRecognitionEvent {}