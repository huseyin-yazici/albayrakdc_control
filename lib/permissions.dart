<<<<<<< HEAD
=======
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

Future<void> requestStoragePermission(BuildContext context) async {
  var status = await Permission.storage.status;

  if (!status.isGranted) {
    if (await Permission.storage.request().isGranted) {
      print('Depolama izni verildi.');
    } else if (await Permission.storage.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Depolama İzni Gerekli'),
          content: Text('Depolama iznini uygulama ayarlarından manuel olarak vermeniz gerekiyor.'),
          actions: <Widget>[
            TextButton(
              child: Text('Ayarlar'),
              onPressed: () {
                openAppSettings();
              },
            ),
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } else {
      // Kullanıcı izni reddetti
      print('Depolama izni reddedildi.');
    }
  } else {
    print('Depolama izni zaten verilmiş.');
  }
}
>>>>>>> b5962d1ba88232bdd366b8c5768e2d30f7f7a26b
