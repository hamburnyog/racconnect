import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/accomplishment_model.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';

class AccomplishmentBottomSheet extends StatefulWidget {
  final DateTime day;

  const AccomplishmentBottomSheet({required this.day, super.key});

  @override
  State<AccomplishmentBottomSheet> createState() =>
      _AccomplishmentBottomSheetState();
}

class _AccomplishmentBottomSheetState extends State<AccomplishmentBottomSheet> {
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
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
      final employeeNumber = authState.user.profile?.employeeNumber;
      if (employeeNumber == null) return;
      final accomplishment = await _accomplishmentRepository
          .getAccomplishmentByDate(widget.day, employeeNumber);
      if (!mounted) return;
      if (accomplishment != null) {
        setState(() {
          _accomplishment = accomplishment;
          _targetController.text = accomplishment.target;
          _accomplishmentController.text = accomplishment.accomplishment;
        });
      }
    }
  }

  Future<void> _saveAccomplishment() async {
    final navigator = Navigator.of(context);
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
      final employeeNumber = authState.user.profile?.employeeNumber;
      if (employeeNumber == null) return;

      if (_accomplishment != null) {
        await _accomplishmentRepository.updateAccomplishment(
          id: _accomplishment!.id!,
          date: widget.day,
          target: _targetController.text,
          accomplishment: _accomplishmentController.text,
          employeeNumber: employeeNumber,
        );
      }
      if (!mounted) return;
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Accomplishments for ${DateFormat('MMMM dd, yyyy').format(widget.day)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _targetController,
              readOnly: true,
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Target/s',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _targetController.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Target copied to clipboard')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accomplishmentController,
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Accomplishment/s',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _accomplishmentController.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Accomplishment copied to clipboard')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAccomplishment,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
