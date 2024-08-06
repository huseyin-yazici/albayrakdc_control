import 'package:albayrakdc_control/views/text_recognition_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bloc/text_bloc/text_recognition_bloc.dart';
import 'theme/app_theme.dart';
import 'g_sheets_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleSheetsService.init();
  await checkPermissions();
  runApp(MyApp());
}

Future<void> checkPermissions() async {
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: BlocProvider(
        create: (context) => TextRecognitionBloc(),
        child: TextRecognitionScreen(),
      ),
    );
  }
}