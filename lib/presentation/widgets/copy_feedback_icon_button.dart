import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyFeedbackIconButton extends StatefulWidget {
  final String textToCopy;
  final String tooltip;

  const CopyFeedbackIconButton({
    super.key,
    required this.textToCopy,
    required this.tooltip,
  });

  @override
  State<CopyFeedbackIconButton> createState() => _CopyFeedbackIconButtonState();
}

class _CopyFeedbackIconButtonState extends State<CopyFeedbackIconButton> {
  bool copied = false;

  void _copyText() {
    Clipboard.setData(ClipboardData(text: widget.textToCopy));
    setState(() => copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        copied ? Icons.check_circle : Icons.copy,
        size: 20,
        color: copied ? Colors.green : Colors.teal,
      ),
      tooltip: widget.tooltip,
      onPressed: _copyText,
    );
  }
}
