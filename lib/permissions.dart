import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
    if (status.isGranted) {
      print('Storage permission granted');
    } else {
      print('Storage permission denied');
    }
  } else {
    print('Storage permission already granted');
  }
}