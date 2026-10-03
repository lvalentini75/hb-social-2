import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Filled, borderless text field with a label above it, used across all
/// auth forms.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: context.textStyles.labelLarge?.withColor(LightModeColors.lightOnSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: context.textStyles.bodyLarge?.withColor(LightModeColors.lightOnSurface),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: context.textStyles.bodyLarge?.withColor(LightModeColors.lightOnSurfaceVariant),
            filled: true,
            fillColor: LightModeColors.lightSurfaceVariant,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: LightModeColors.lightOnSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: LightModeColors.lightPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
          ),
        ),
      ],
    );
  }
}
