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
class DownloadSpreadsheet extends TextRecognitionEvent {}
class IncrementSelectedNumber extends TextRecognitionEvent {}