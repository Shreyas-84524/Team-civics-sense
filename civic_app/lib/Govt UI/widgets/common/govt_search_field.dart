import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../theme/govt_theme_tokens.dart';
import '../../theme/govt_typography.dart';
import 'govt_loading_states.dart';

/// Compact, accessible search field with debounce and loading indicator.
class GovtSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final String hintText;
  final double? width;
  final bool isLoading;
  final Duration debounceDuration;
  final FocusNode? focusNode;
  final bool autofocus;

  const GovtSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hintText = 'Search complaints, IDs, keywords...',
    this.width,
    this.isLoading = false,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<GovtSearchField> createState() => _GovtSearchFieldState();
}

class _GovtSearchFieldState extends State<GovtSearchField> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _isInternalController = true;
    } else {
      _controller = widget.controller!;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleChanged(String value) {
    if (widget.onChanged == null) return;

    if (widget.debounceDuration == Duration.zero) {
      widget.onChanged!(value);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (mounted) {
        widget.onChanged!(value);
      }
    });
  }

  void _handleClear() {
    _controller.clear();
    _debounceTimer?.cancel();
    if (widget.onClear != null) widget.onClear!();
    if (widget.onChanged != null) widget.onChanged!('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return SizedBox(
      width: widget.width ?? 320,
      height: 40,
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onChanged: (val) {
          _handleChanged(val);
          setState(() {});
        },
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.search,
        style: GovtTypography.bodySmall.copyWith(
          color: GovtThemeTokens.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: GovtTypography.caption.copyWith(
            color: GovtThemeTokens.textDisabled,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: GovtThemeTokens.textSecondary,
          ),
          suffixIcon: widget.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(11.0),
                  child: GovtInlineLoader(size: 14),
                )
              : hasText
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: _handleClear,
                      tooltip: 'Clear search',
                    )
                  : null,
          filled: true,
          fillColor: GovtThemeTokens.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CivicFixSpacing.md,
            vertical: CivicFixSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: GovtThemeTokens.chipRadius,
            borderSide: const BorderSide(color: GovtThemeTokens.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: GovtThemeTokens.chipRadius,
            borderSide: const BorderSide(color: GovtThemeTokens.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: GovtThemeTokens.chipRadius,
            borderSide: const BorderSide(color: GovtThemeTokens.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
