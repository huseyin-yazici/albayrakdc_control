import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerView extends StatefulWidget {
  final Function(String) onQRCodeScanned;

  const QRScannerView({Key? key, required this.onQRCodeScanned}) : super(key: key);

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanned = false;
  String debugMessage = 'QR kodu taramak için kamerayı doğrultun';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Kod Tarayıcı')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(debugMessage),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
      debugMessage = 'Kamera başlatıldı, QR kodu bekleniyor...';
    });
    controller.scannedDataStream.listen((scanData) {
      if (!isScanned && scanData.code != null) {
        setState(() {
          isScanned = true;
          debugMessage = 'QR Kod okundu: ${scanData.code}';
        });
        widget.onQRCodeScanned(scanData.code!);
        // QR kodu okunduktan hemen sonra sayfayı kapat
        Navigator.of(context).pop(scanData.code);
      }
    });
  }


  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      setState(() {
        debugMessage = 'Kamera yeniden başlatılıyor...';
      });
      controller!.resumeCamera();
    }
  }
}