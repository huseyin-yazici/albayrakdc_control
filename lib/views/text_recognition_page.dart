import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../bloc/text_recognition_bloc.dart';
import '../bloc/text_recognition_event.dart';
import '../bloc/text_recognition_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_action_button.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_textfields.dart';

class TextRecognitionScreen extends StatefulWidget {
  @override
  _TextRecognitionScreenState createState() => _TextRecognitionScreenState();
}

class _TextRecognitionScreenState extends State<TextRecognitionScreen> {
  final TextRecognizer _textRecognizer = TextRecognizer();
  String _recognizedText = '';
  final Map<String, TextEditingController> _controllers = {
    'ETIKET': TextEditingController(),
    'EBAT': TextEditingController(),
    'KALITE': TextEditingController(),
    'DOKUM': TextEditingController(),
    'AGIRLIK': TextEditingController(),
    'PAKET': TextEditingController(),
  };

  void _printRecognizedText() {
    print('--- Recognized Text ---');
    _controllers.forEach((key, controller) {
      print('$key: ${controller.text}');
    });
    print('----------------------');
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          BlocBuilder<TextRecognitionBloc, TextRecognitionState>(
            builder: (context, state) {
              return IconButton(
                icon: state.isClearingSheets
                    ? CircularProgressIndicator(color: Colors.white)
                    : Icon(Icons.refresh, color: Colors.white),
                onPressed: state.isClearingSheets
                    ? null
                    : () {
                  context.read<TextRecognitionBloc>().add(ClearGoogleSheetsRange());
                },
              ); /*IconButton(
            icon: Icon(
              state.isSheet2 ? Icons.filter_2 : Icons.filter_1,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              context.read<TextRecognitionBloc>().add(
                  state.isSheet2 ? SwitchToSheet2() : SwitchToSheet2()
              );
            },
            tooltip: state.isSheet2 ? 'Sheet 1\'e Geç' : 'Sheet 2\'ye Geç',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(12),
            ),
          );*/
            },
          ),
        ],
        centerTitle: true,
        title: Text('Albayrak DC Firmaşin Kabul Kontrol'),
      ),
      body: BlocConsumer<TextRecognitionBloc, TextRecognitionState>(
        listener: (context, state) {
          if (state.isDataRecognized) {
            state.extractedData.forEach((key, value) {
              _controllers[key]?.text = value;
            });
            // Tanıma işlemi tamamlandığında PrintRecognizedText event'ini tetikle
            context.read<TextRecognitionBloc>().add(PrintRecognizedText());
          } else {
            _controllers.forEach((key, controller) => controller.clear());
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomDropdown(
                  value: state.selectedNumber,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      context
                          .read<TextRecognitionBloc>()
                          .add(UpdateSelectedNumber(newValue));
                    }
                  },
                ),
                SizedBox(height: 16),
                _buildActionButtons(context),
                SizedBox(height: 24),
                if (state.isLoading)
                  Center(child: CircularProgressIndicator())
                else if (state.error != null)
                  Text(state.error!, style: TextStyle(color: Colors.red))
                else if (state.error != null)
                  Text(state.error!, style: TextStyle(color: Colors.green)),
                ..._buildTextFields(),
                SizedBox(height: 16),
                if (state.isDataRecognized)
                  ElevatedButton(
                    onPressed: () => _uploadData(context),
                    child: Text(
                      'Google Sheets\'e Kaydet',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomActionButton(
            icon: Icons.photo_library,
            onPressed: () => context
                .read<TextRecognitionBloc>()
                .add(RecognizeTextFromGallery()),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: CustomActionButton(
            icon: Icons.camera_alt,
            onPressed: () => context
                .read<TextRecognitionBloc>()
                .add(RecognizeTextFromCamera()),
          ),
        ),

      ],
    );
  }

  List<Widget> _buildTextFields() {
    return _controllers.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: CustomTextField(
          label: entry.key,
          controller: entry.value,
          keyboardtype: entry.key == 'KALITE'
              ? TextInputType.text
              : TextInputType.numberWithOptions(decimal: true),
        ),
      );
    }).toList();
  }

  void _uploadData(BuildContext context) {
    final updatedData =
        _controllers.map((key, controller) => MapEntry(key, controller.text));
    context.read<TextRecognitionBloc>().add(UploadToGoogleSheets(updatedData));
  }
}
