import 'package:equatable/equatable.dart';

class QRScanState extends Equatable {
  final bool isScanning;
  final String? scannedData;
  final String? error;

  const QRScanState({
    this.isScanning = false,
    this.scannedData,
    this.error,
  });

  QRScanState copyWith({
    bool? isScanning,
    String? scannedData,
    String? error,
  }) {
    return QRScanState(
      isScanning: isScanning ?? this.isScanning,
      scannedData: scannedData ?? this.scannedData,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isScanning, scannedData, error];
}