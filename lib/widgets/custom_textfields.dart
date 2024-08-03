import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
final TextInputType keyboardtype;
  const CustomTextField({Key? key, required this.label, required this.controller, required this.keyboardtype}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return TextField(keyboardType: keyboardtype,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,

      ),
    );
  }
}