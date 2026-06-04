import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/blocs/cubit/attendance_cubit.dart';

class TimeLogBottomSheet extends StatefulWidget {
  final AttendanceModel? log;
  final DateTime? initialDate;
  final String employeeNumber;

  const TimeLogBottomSheet({
    super.key,
    this.log,
    this.initialDate,
    required this.employeeNumber,
  });

  @override
  State<TimeLogBottomSheet> createState() => _TimeLogBottomSheetState();
}

class _TimeLogBottomSheetState extends State<TimeLogBottomSheet> {
  late DateTime _selectedDate;
  late TextEditingController _timeController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.log?.timestamp ?? widget.initialDate ?? DateTime.now();
    _timeController = TextEditingController(
      text: widget.log != null ? DateFormat('HH:mm').format(widget.log!.timestamp) : '',
    );
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this attendance record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final cubit = context.read<AttendanceCubit>();
      final navigator = Navigator.of(context);
      
      try {
        await cubit.deleteAttendance(widget.log!.id!);
        if (mounted) navigator.pop(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting log: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;

    final timeParts = _timeController.text.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final newTimestamp = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    final cubit = context.read<AttendanceCubit>();
    if (widget.log == null) {
      await cubit.uploadAttendance(
        employeeNumber: widget.employeeNumber,
        timestamp: newTimestamp,
      );
    } else {
      await cubit.updateAttendance(
        id: widget.log!.id!,
        timestamp: newTimestamp,
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.log == null ? 'Add Time Log' : 'Edit Time Log',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (widget.log != null)
                  IconButton(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
              title: const Text('Date', style: TextStyle(fontSize: 14, color: Colors.grey)),
              subtitle: Text(
                DateFormat('MMMM dd, yyyy').format(_selectedDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
            ),
            const Divider(),
            const SizedBox(height: 10),
            TextFormField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Time (HH:mm)',
                hintText: 'e.g., 08:30 or 17:00',
                prefixIcon: Icon(Icons.access_time),
              ),
              keyboardType: TextInputType.datetime,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Time is required';
                final regExp = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
                if (!regExp.hasMatch(value)) return 'Use HH:mm format (24h)';
                return null;
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
