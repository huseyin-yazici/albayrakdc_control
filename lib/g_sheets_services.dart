import 'package:gsheets/gsheets.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GoogleSheetsService {
  static const _credentials = r''' { "type": "service_account", "project_id": "firmasin-ocr", "private_key_id": "a99c4bf3b853610669a1cd5795bf0785b9ab6950", "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCP+KTNVSiHpI3y\n/L5QYoshIWIeymR8n5VaBDu+/nSK+ul57cW7F2QF3StZFM+4jvmOpJsTP1R/suwq\nVxCihups69RWWbhPFDhG04mK9DqeqixNVKGk+gaIe3C2Z4/6JAvjUG6NfDZfMo0h\nnR1NpjOUXHQ7DUbUeZfmF7JlmwakAxvDa+uQjNjBAXpgQCDL/D8HLXhqsFtUdgDA\nYkVOjYEUpo+QosAlIiCrDkT3WqFmQX/AcokXrIPfk7zVZWoBTkvyJ+Ysw0zGGJb1\nxVTD+XI/ucykxnmX0RhUsjbrit7O7QLcIGWfHEDI5pA/+DRI9wkbSXeRYnQDacFA\nhaA/3pZZAgMBAAECggEABSAH1dtrNvDvsK+4oqnvY/2JPalczGbt7SdrbRAn2+60\nswd424EoqWDHM0OfZWWJkr9fWd8ORgF7kMJKsE53N+tpQq2s9vu0SSkso0qwb4eF\nTjduDa5s3xzt1UB4iqIP3ka1uMmsMdVd2s16BpKdEXH9HUEKvXOaqbE8Q4uyP9Ji\n1npojAcVHNOPjXJnpp5l77SmoC7sYJl++/FkYxft5zhNe15MyHduz4aO8/Bie2JF\nxlEJY6nspvRriutZO7tamNd7mc3RVmhpiGEz0MzKwW+gK3sV7x1H1ecfmuV9hm1W\nzHu6jx5TncM/apbXo9oGh3UoigYtZZcGF4SuiBpmAQKBgQDAD1YcgiXusE42s/Sj\n5Wq3wl7TZIUdMqIp75abdHYjYh4OiyP7ac8UGXExctm7mGEH536mQ2kzw+22wZhe\nAhZzJgZPty/swiJ3wHoVkW0nKxDQ9g3y0Yb4zIUFyQ1DkGmJBY1FlVoBktPN8FdF\n+SiRlAi2WHr5BvvuBrYgCnB5QQKBgQC/5tz3R4CTY3j0xr6VekJ2P84PQsoR9puX\n5GVb4+6oE/Np55AW1dr5XuC6JI/+hNLYIDAo+r5lMH1CZD612aBGESSAe1hvPkFn\nNr/eTj423Yin8mVqVSJoCxbAVIRdCU84PTlchB7HRD5NW1di/P9BRMp3Wp9XdYZU\nbaDAGFv/GQKBgQCVBZFYT3flS3F0qo8g+KqkaLGxLqbGr/n5tghTGLtt2vzdZgMG\nWeQugUs+BhKBp8tqGapAkb+4RcdV7cMu9km7EP8GrWoHN98MshFIWO2r3ZOPv8u0\n4/Tpaa+xfH3JNe1dPyyNmEQdQnMLsPfWuGxNAOL9sYvBXDTwTM7V76OzwQKBgBTQ\n8SUtr2fNgYBj0qaaRX1YPHzxTMQYERav4sLN/cRjraLOSJYBiqhEP3JRpwD/3XMu\nQqsfT+ngEaZTA25sdfNDxsbdGmGuyh9tE/EEYcFH1JwLMi8PnxTUJxqj0FvbN6mt\nEnzTpBcPcwanItqNAQ9Oa/v4a5JsIC8mWSqdOdV5AoGARkczCptFxLbWqyBS9OiF\n6l2dF/L3RcYTFscIXQQVoltPSfXGE5mljt2VKJNeQK+JUNtesEg0DOsVSeqO1L0s\nNt7IF3MABuUcZ6pITkA3zzB6p7tQktdXZhfC9pXFcjMl5WFgrVYC95HWIP/XPdPZ\ncImuw2BK/xllRYBB6rhcgfI=\n-----END PRIVATE KEY-----\n", "client_email": "flutter-ocr-firmasin@firmasin-ocr.iam.gserviceaccount.com", "client_id": "107950404657529745541", "auth_uri": "https://accounts.google.com/o/oauth2/auth", "token_uri": "https://oauth2.googleapis.com/token", "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs", "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/flutter-ocr-firmasin%40firmasin-ocr.iam.gserviceaccount.com", "universe_domain": "googleapis.com" } ''';

  static const _spreadsheetId = '1bkjX6WaC2an3VSc3PeZ3T9EgPxcWeaZfmfhqd9VMqn8';
  static final _gsheets = GSheets(_credentials);
  static Worksheet? _worksheet1;
  static Worksheet? _worksheet2;
  static Worksheet? _currentWorksheet;

  static Future<void> init() async {
    final ss = await _gsheets.spreadsheet(_spreadsheetId);
    _worksheet1 = ss.worksheetByTitle('Sheet1');
    _worksheet2 = ss.worksheetByTitle('Sheet2');
    _currentWorksheet = _worksheet1; // Varsayılan olarak Sheet1'i kullan
  }

  static void switchToSheet2() {
    _currentWorksheet = _worksheet2;
  }

  static void switchToSheet1() {
    _currentWorksheet = _worksheet1;
  }

  static Future<Uint8List?> downloadSpreadsheet() async {
    try {
      final url = 'https://docs.google.com/spreadsheets/d/$_spreadsheetId/export?format=xlsx';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Error downloading spreadsheet: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading spreadsheet: $e');
      return null;
    }
  }

  static Future<void> insertData(Map<String, String> data, int selectedNumber) async {
    if (_currentWorksheet == null) return;

    int rowToInsert = 8 + selectedNumber; // 1 seçildiğinde 9. satır, 2 seçildiğinde 10. satır, vb.

    await Future.wait([
      _currentWorksheet!.values.insertValue(data['ETIKET'] ?? '', column: 2, row: rowToInsert),  // B
      _currentWorksheet!.values.insertValue(data['EBAT'] ?? '', column: 6, row: rowToInsert),    // F
      _currentWorksheet!.values.insertValue(data['KALITE'] ?? '', column: 9, row: rowToInsert),  // I
      _currentWorksheet!.values.insertValue(data['DOKUM'] ?? '', column: 15, row: rowToInsert),  // O
      _currentWorksheet!.values.insertValue(data['AGIRLIK'] ?? '', column: 16, row: rowToInsert),// P
      _currentWorksheet!.values.insertValue(data['PAKET'] ?? '', column: 13, row: rowToInsert),  // M
    ]);
  }
}