import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.padding,
    this.fontSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).primaryColor,
        foregroundColor: textColor ?? Colors.white,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize ?? 16),
      ),
    );
  }
}