import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/accomplishment_model.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';

class AccomplishmentDialog extends StatefulWidget {
  final DateTime day;

  const AccomplishmentDialog({required this.day, super.key});

  @override
  State<AccomplishmentDialog> createState() => _AccomplishmentDialogState();
}

class _AccomplishmentDialogState extends State<AccomplishmentDialog> {
  final _accomplishmentRepository = AccomplishmentRepository();
  final _targetController = TextEditingController();
  final _accomplishmentController = TextEditingController();
  AccomplishmentModel? _accomplishment;

  @override
  void initState() {
    super.initState();
    _loadAccomplishment();
  }

  Future<void> _loadAccomplishment() async {
    final accomplishment =
        await _accomplishmentRepository.getAccomplishmentByDate(widget.day);
    if (!mounted) return;
    if (accomplishment != null) {
      setState(() {
        _accomplishment = accomplishment;
        _targetController.text = accomplishment.target;
        _accomplishmentController.text = accomplishment.accomplishment;
      });
    }
  }

  Future<void> _copyFromYesterday() async {
    final yesterday = widget.day.subtract(const Duration(days: 1));
    final accomplishment =
        await _accomplishmentRepository.getAccomplishmentByDate(yesterday);
    if (!mounted) return;
    if (accomplishment != null) {
      setState(() {
        _targetController.text = accomplishment.target;
        _accomplishmentController.text = accomplishment.accomplishment;
      });
    }
  }

  Future<void> _saveAccomplishment() async {
    final navigator = Navigator.of(context);
    if (_accomplishment != null) {
      await _accomplishmentRepository.updateAccomplishment(
        id: _accomplishment!.id!,
        date: widget.day,
        target: _targetController.text,
        accomplishment: _accomplishmentController.text,
      );
    } else {
      await _accomplishmentRepository.addAccomplishment(
        date: widget.day,
        target: _targetController.text,
        accomplishment: _accomplishmentController.text,
      );
    }
    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          'Accomplishments for ${DateFormat('MMMM dd, yyyy').format(widget.day)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _targetController,
              maxLines: 5,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Target/s',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accomplishmentController,
              maxLines: 5,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Accomplishment/s',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _copyFromYesterday,
          child: const Text('Copy from yesterday'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAccomplishment,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
