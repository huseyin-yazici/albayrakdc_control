import 'package:equatable/equatable.dart';

abstract class QRScanEvent extends Equatable {
  const QRScanEvent();

  @override
  List<Object> get props => [];
}

class StartScan extends QRScanEvent {}

class StopScan extends QRScanEvent {}

class QRCodeScanned extends QRScanEvent {
  final String data;

  const QRCodeScanned(this.data);

  @override
  List<Object> get props => [data];
}