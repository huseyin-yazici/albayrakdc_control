import 'package:flutter/material.dart';

class CustomActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const CustomActionButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
            Icon(icon, size: 70, color: AppTheme.primaryRed),
            SizedBox(height: 8),

          ],
=======
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
>>>>>>> b5962d1ba88232bdd366b8c5768e2d30f7f7a26b
        ),
        padding: EdgeInsets.all(16),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}