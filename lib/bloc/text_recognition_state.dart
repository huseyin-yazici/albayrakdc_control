import 'dart:convert';

class TextRecognitionState {
  final String recognizedText;
  final Map<String, String> extractedData;
  final bool isLoading;
  final String? error;
  final int selectedNumber;
  final bool isDataRecognized;
  final bool useSheet2;
  final bool isSheet2;
  final bool isSuccess;

  final bool isClearingSheets;

  TextRecognitionState({
    this.recognizedText = '',
    this.extractedData = const {
      'EBAT': '',
      'KALITE': '',
      'DOKUM': '',
      'AGIRLIK': '',
      'PAKET': '',
    },
    this.isLoading = false,
    this.error,
    this.selectedNumber = 1,
    this.isDataRecognized = false,
    this.useSheet2 = false,
    this.isSheet2 = false,
    this.isSuccess = false,
    this.isClearingSheets = false,
  });

  TextRecognitionState copyWith({
    bool? isClearingSheets,
    String? recognizedText,
    Map<String, String>? extractedData,
    bool? isLoading,
    String? error,
    int? selectedNumber,
    bool? isDataRecognized,
    bool? useSheet2,
    bool? isSheet2,
    bool? isSuccess,
  }) {
    return TextRecognitionState(
      isClearingSheets: isClearingSheets ?? this.isClearingSheets,
      selectedNumber: selectedNumber ?? this.selectedNumber,
      recognizedText: recognizedText ?? this.recognizedText,
      extractedData: extractedData ?? this.extractedData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isDataRecognized: isDataRecognized ?? this.isDataRecognized,
      useSheet2: useSheet2 ?? this.useSheet2,
      isSheet2: isSheet2 ?? this.isSheet2,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
