import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Soft, borderless text field with an optional label above it and an
/// optional error line below it. Focus state shows a 1.5px primaryOutline
/// border plus a soft 3px primarySoft ring, no plain Material underline.
class HBInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final bool autofocus;
  final bool search;

  const HBInput({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.search = false,
  });

  @override
  State<HBInput> createState() => _HBInputState();
}

class _HBInputState extends State<HBInput> {
  late bool _obscure = widget.obscureText;
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: context.textStyles.labelLarge?.withColor(LightModeColors.lightOnSurface)),
          const SizedBox(height: AppSpacing.xs),
        ],
        AnimatedContainer(
          duration: AppMotion.of(context).base,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.search ? AppRadius.pill : AppRadius.xs),
            border: Border.all(
              color: hasError ? LightModeColors.lightError : (_isFocused ? LightModeColors.lightPrimary : LightModeColors.lightBorder),
              width: _isFocused ? 1.5 : 1,
            ),
            boxShadow: null,
          ),
          child: TextFormField(
            enabled: widget.enabled,
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscure,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.obscureText ? 1 : widget.minLines,
            autofocus: widget.autofocus,
            style: context.textStyles.bodyLarge?.withColor(LightModeColors.lightOnSurface),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: context.textStyles.bodyLarge?.withColor(LightModeColors.lightTextTertiary),
              filled: true,
              fillColor: widget.search ? LightModeColors.lightBackground : LightModeColors.lightSurface,
              prefixIcon: widget.search ? (widget.prefixIcon ?? const Icon(Icons.search_rounded)) : widget.prefixIcon,
              counterText: '',
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: LightModeColors.lightOnSurfaceVariant,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : widget.suffixIcon,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(widget.search ? AppRadius.pill : AppRadius.xs), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(widget.search ? AppRadius.pill : AppRadius.xs), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(widget.search ? AppRadius.pill : AppRadius.xs), borderSide: BorderSide.none),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(widget.search ? AppRadius.pill : AppRadius.xs), borderSide: BorderSide.none),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(widget.search ? AppRadius.pill : AppRadius.xs), borderSide: BorderSide.none),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 11),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(widget.errorText!, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError)),
        ],
      ],
    );
  }
}
