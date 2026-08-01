import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';

/// Human-crafted 6-digit PIN input where each box strictly holds max 1 digit.
class OtpInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? otpCode;

  const OtpInputField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.errorText,
    this.otpCode,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  List<TextEditingController> _controllers = [];
  List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _initFields();

    if (widget.otpCode != null && widget.otpCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyOtpCode(widget.otpCode!, notify: true);
        }
      });
    }
  }

  void _initFields() {
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    for (int i = 0; i < widget.length; i++) {
      _focusNodes[i].addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(OtpInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focusNodes.length != widget.length) {
      _initFields();
    }
    if (widget.otpCode != null &&
        widget.otpCode!.isNotEmpty &&
        widget.otpCode != oldWidget.otpCode) {
      final currentCombined = _controllers.map((c) => c.text).join();
      if (currentCombined != widget.otpCode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _applyOtpCode(widget.otpCode!, notify: false);
          }
        });
      }
    }
  }

  void _applyOtpCode(String code, {bool notify = true}) {
    final clean = code.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < widget.length; i++) {
      if (i < clean.length) {
        _controllers[i].text = clean[i];
      } else {
        _controllers[i].clear();
      }
    }
    if (clean.isNotEmpty) {
      final targetIndex = clean.length >= widget.length ? widget.length - 1 : clean.length;
      if (targetIndex < _focusNodes.length) {
        _focusNodes[targetIndex].requestFocus();
      }
    }
    if (notify) {
      _notifyChange();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(int index, String value) {
    final clean = value.replaceAll(RegExp(r'\D'), '');

    // Handle full 6-digit OTP code paste (e.g., from SMS or clipboard)
    if (clean.length > 2) {
      for (int i = 0; i < widget.length; i++) {
        if (i < clean.length) {
          _controllers[i].text = clean[i];
        } else {
          _controllers[i].clear();
        }
      }
      final targetIndex = (clean.length >= widget.length)
          ? widget.length - 1
          : clean.length;
      if (targetIndex < _focusNodes.length) {
        _focusNodes[targetIndex].requestFocus();
      }
      _notifyChange();
      return;
    }

    if (clean.length == 2) {
      // User typed a new digit into a box that already contained a digit
      final newDigit = clean[1];
      _controllers[index].value = TextEditingValue(
        text: newDigit,
        selection: const TextSelection.collapsed(offset: 1),
      );
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    } else if (clean.length == 1) {
      // Single digit entered into box
      _controllers[index].value = TextEditingValue(
        text: clean,
        selection: const TextSelection.collapsed(offset: 1),
      );
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    } else {
      // Cleared / Backspace
      _controllers[index].clear();
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    _notifyChange();
  }

  void _notifyChange() {
    final otp = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(otp);
    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controllers.length != widget.length || _focusNodes.length != widget.length) {
      _initFields();
    }

    return AutofillGroup(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              final bool isFocused = index < _focusNodes.length && _focusNodes[index].hasFocus;
              final bool hasValue = index < _controllers.length && _controllers[index].text.isNotEmpty;
              final bool hasError = widget.errorText != null;

              Color borderColor = AppColors.cardBorder;
              if (hasError) {
                borderColor = AppColors.error;
              } else if (isFocused) {
                borderColor = AppColors.primary;
              } else if (hasValue) {
                borderColor = AppColors.primary.withValues(alpha: 0.4);
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48,
                height: 58,
                decoration: BoxDecoration(
                  color: isFocused ? AppColors.surface : AppColors.inputFill,
                  borderRadius: AppStyles.borderRadiusMedium,
                  border: Border.all(
                    color: borderColor,
                    width: isFocused || hasError ? 2.0 : 1.2,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (value) => _onTextChanged(index, value),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                    ),
                  ),
                ),
              );
            }),
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  widget.errorText!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
