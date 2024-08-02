import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart' as permission;

import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:gsheets/gsheets.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:path_provider/path_provider.dart';

class GoogleSheetsService {
  static const _credentials = r'''
    { "type": "service_account", "project_id": "firmasin-ocr", "private_key_id": "a99c4bf3b853610669a1cd5795bf0785b9ab6950", "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCP+KTNVSiHpI3y\n/L5QYoshIWIeymR8n5VaBDu+/nSK+ul57cW7F2QF3StZFM+4jvmOpJsTP1R/suwq\nVxCihups69RWWbhPFDhG04mK9DqeqixNVKGk+gaIe3C2Z4/6JAvjUG6NfDZfMo0h\nnR1NpjOUXHQ7DUbUeZfmF7JlmwakAxvDa+uQjNjBAXpgQCDL/D8HLXhqsFtUdgDA\nYkVOjYEUpo+QosAlIiCrDkT3WqFmQX/AcokXrIPfk7zVZWoBTkvyJ+Ysw0zGGJb1\nxVTD+XI/ucykxnmX0RhUsjbrit7O7QLcIGWfHEDI5pA/+DRI9wkbSXeRYnQDacFA\nhaA/3pZZAgMBAAECggEABSAH1dtrNvDvsK+4oqnvY/2JPalczGbt7SdrbRAn2+60\nswd424EoqWDHM0OfZWWJkr9fWd8ORgF7kMJKsE53N+tpQq2s9vu0SSkso0qwb4eF\nTjduDa5s3xzt1UB4iqIP3ka1uMmsMdVd2s16BpKdEXH9HUEKvXOaqbE8Q4uyP9Ji\n1npojAcVHNOPjXJnpp5l77SmoC7sYJl++/FkYxft5zhNe15MyHduz4aO8/Bie2JF\nxlEJY6nspvRriutZO7tamNd7mc3RVmhpiGEz0MzKwW+gK3sV7x1H1ecfmuV9hm1W\nzHu6jx5TncM/apbXo9oGh3UoigYtZZcGF4SuiBpmAQKBgQDAD1YcgiXusE42s/Sj\n5Wq3wl7TZIUdMqIp75abdHYjYh4OiyP7ac8UGXExctm7mGEH536mQ2kzw+22wZhe\nAhZzJgZPty/swiJ3wHoVkW0nKxDQ9g3y0Yb4zIUFyQ1DkGmJBY1FlVoBktPN8FdF\n+SiRlAi2WHr5BvvuBrYgCnB5QQKBgQC/5tz3R4CTY3j0xr6VekJ2P84PQsoR9puX\n5GVb4+6oE/Np55AW1dr5XuC6JI/+hNLYIDAo+r5lMH1CZD612aBGESSAe1hvPkFn\nNr/eTj423Yin8mVqVSJoCxbAVIRdCU84PTlchB7HRD5NW1di/P9BRMp3Wp9XdYZU\nbaDAGFv/GQKBgQCVBZFYT3flS3F0qo8g+KqkaLGxLqbGr/n5tghTGLtt2vzdZgMG\nWeQugUs+BhKBp8tqGapAkb+4RcdV7cMu9km7EP8GrWoHN98MshFIWO2r3ZOPv8u0\n4/Tpaa+xfH3JNe1dPyyNmEQdQnMLsPfWuGxNAOL9sYvBXDTwTM7V76OzwQKBgBTQ\n8SUtr2fNgYBj0qaaRX1YPHzxTMQYERav4sLN/cRjraLOSJYBiqhEP3JRpwD/3XMu\nQqsfT+ngEaZTA25sdfNDxsbdGmGuyh9tE/EEYcFH1JwLMi8PnxTUJxqj0FvbN6mt\nEnzTpBcPcwanItqNAQ9Oa/v4a5JsIC8mWSqdOdV5AoGARkczCptFxLbWqyBS9OiF\n6l2dF/L3RcYTFscIXQQVoltPSfXGE5mljt2VKJNeQK+JUNtesEg0DOsVSeqO1L0s\nNt7IF3MABuUcZ6pITkA3zzB6p7tQktdXZhfC9pXFcjMl5WFgrVYC95HWIP/XPdPZ\ncImuw2BK/xllRYBB6rhcgfI=\n-----END PRIVATE KEY-----\n", "client_email": "flutter-ocr-firmasin@firmasin-ocr.iam.gserviceaccount.com", "client_id": "107950404657529745541", "auth_uri": "https://accounts.google.com/o/oauth2/auth", "token_uri": "https://oauth2.googleapis.com/token", "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs", "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/flutter-ocr-firmasin%40firmasin-ocr.iam.gserviceaccount.com", "universe_domain": "googleapis.com" }
  ''';

  static const _spreadsheetId = '1bkjX6WaC2an3VSc3PeZ3T9EgPxcWeaZfmfhqd9VMqn8';
  static final _gsheets = GSheets(_credentials);
  static Worksheet? _worksheet1;
  static Worksheet? _worksheet2;
  static Worksheet? _currentWorksheet;

  static Future<void> init() async {
    try {
      final ss = await _gsheets.spreadsheet(_spreadsheetId);
      _worksheet1 = ss.worksheetByTitle('Sheet1');
      _worksheet2 = ss.worksheetByTitle('Sheet2');
      _currentWorksheet = _worksheet1; // Varsayılan olarak Sheet1'i kullan
      print('Sheets initialized successfully');
    } catch (e) {
      print('Error initializing sheets: $e');
    }
  }

  static void switchToSheet2() {
    _currentWorksheet = _worksheet2;
    print('Switched to Sheet2');
  }

  static void switchToSheet1() {
    _currentWorksheet = _worksheet1;
    print('Switched to Sheet1');
  }

  static Future<String?> downloadSpreadsheet() async {
    try {
      final accountCredentials = ServiceAccountCredentials.fromJson(_credentials);
      final scopes = [
        sheets.SheetsApi.driveScope,
        sheets.SheetsApi.spreadsheetsReadonlyScope,
      ];

      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final api = sheets.SheetsApi(client);

      final response = await api.spreadsheets.get(_spreadsheetId);
      final downloadUrl = 'https://docs.google.com/spreadsheets/d/$_spreadsheetId/export?format=xlsx';

      final downloadResponse = await client.get(Uri.parse(downloadUrl));

      if (downloadResponse.statusCode == 200) {
        // İzin kontrolü
        if (Platform.isAndroid) {
          var status = await permission.Permission.storage.status;
          if (!status.isGranted) {
            status = await permission.Permission.storage.request();
            if (!status.isGranted) {
              throw Exception('Storage permission not granted');
            }
          }
        }

        // İndirilenler klasörünü al
        Directory? directory;
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            // Android'de Downloads klasörüne git
            String newPath = "";
            List<String> folders = directory.path.split("/");
            for (int x = 1; x < folders.length; x++) {
              String folder = folders[x];
              if (folder != "Android") {
                newPath += "/" + folder;
              } else {
                break;
              }
            }
            newPath = newPath + "/Download";
            directory = Directory(newPath);
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory == null) {
          throw Exception('Could not access storage directory');
        }

        // Klasörün var olduğundan emin olun
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        // Dosya yolunu oluştur
        final filePath = '${directory.path}/spreadsheet.xlsx';

        // Dosyayı yaz
        final file = File(filePath);
        await file.writeAsBytes(downloadResponse.bodyBytes);

        print('Spreadsheet downloaded successfully to: $filePath');
        return filePath;
      } else {
        print('Error downloading spreadsheet: ${downloadResponse.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading spreadsheet: $e');
      return null;
    }

  }
  static Future<void> insertData(Map<String, String> data, int selectedNumber) async {
    if (_currentWorksheet == null) {
      print('No worksheet selected');
      return;
    }

    int rowToInsert = 8 + selectedNumber; // 1 seçildiğinde 9. satır, 2 seçildiğinde 10. satır, vb.

    try {
      await Future.wait([
        _currentWorksheet!.values.insertValue(data['ETIKET'] ?? '', column: 2, row: rowToInsert),  // B
        _currentWorksheet!.values.insertValue(data['EBAT'] ?? '', column: 6, row: rowToInsert),    // F
        _currentWorksheet!.values.insertValue(data['KALITE'] ?? '', column: 9, row: rowToInsert),  // I
        _currentWorksheet!.values.insertValue(data['DOKUM'] ?? '', column: 15, row: rowToInsert),  // O
        _currentWorksheet!.values.insertValue(data['AGIRLIK'] ?? '', column: 16, row: rowToInsert),// P
        _currentWorksheet!.values.insertValue(data['PAKET'] ?? '', column: 13, row: rowToInsert),  // M
      ]);
      print('Data inserted successfully to row $rowToInsert');
    } catch (e) {
      print('Error inserting data: $e');
    }
  }
}