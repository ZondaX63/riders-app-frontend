import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable Primary Button
/// 
/// Turuncu tema renginde, tutarlı stil ile buton.
/// DRY prensibi: Tüm projede aynı stil kullanılır.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Icon(icon),
            label: Text(text),
            style: _buttonStyle,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: _buttonStyle,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(text),
          );

    return isFullWidth
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }

  static final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryOrange,
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  );
}

/// Reusable Secondary Button
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return icon != null
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(text),
            style: _buttonStyle,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: _buttonStyle,
            child: Text(text),
          );
  }

  static final ButtonStyle _buttonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppTheme.primaryOrange,
    side: const BorderSide(color: AppTheme.primaryOrange, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
