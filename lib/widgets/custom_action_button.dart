import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const CustomActionButton({
    Key? key,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppTheme.primaryRed, backgroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: AppTheme.primaryRed),
            SizedBox(height: 8),

          ],
        ),
      ),
    );
  }
}