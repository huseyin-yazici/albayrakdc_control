import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final int value;
  final Function(int?) onChanged;

  const CustomDropdown({Key? key, required this.value, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        underline: SizedBox(),
        items: List.generate(25, (index) => index + 1).map((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text('$value. Mal'),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}