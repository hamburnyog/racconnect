import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:racconnect/data/models/leave_model.dart';
import 'package:racconnect/logic/cubit/leave_cubit.dart';
import 'package:table_calendar/table_calendar.dart';

class LeaveForm extends StatefulWidget {
  final LeaveModel? leaveModel;
  final String employeeNumber;
  const LeaveForm({this.leaveModel, required this.employeeNumber, super.key});

  @override
  State<LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends State<LeaveForm> {
  TextEditingController leaveTypeController = TextEditingController();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Set<DateTime> _selectedDates = <DateTime>{};
  final formKey = GlobalKey<FormState>();

  // Common leave types for Philippine government employees
  final List<String> leaveTypes = [
    'Vacation Leave',
    'Sick Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Special Leave Benefits for Women',
    'Study Leave',
    'Bereavement Leave',
    'Compensatory Time-Off (CTO)',
    'Other',
  ];

  void addLeaves() {
    if (formKey.currentState!.validate() && _selectedDates.isNotEmpty) {
      context.read<LeaveCubit>().addMultipleLeaves(
            employeeNumber: widget.employeeNumber,
            type: leaveTypeController.text.trim(),
            dates: _selectedDates.toList(),
          );
      Navigator.of(context).pop();
    } else if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one date'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void saveLeave() {
    if (formKey.currentState!.validate() && _selectedDay != null) {
      final leaveId = widget.leaveModel?.id ?? '';
      context.read<LeaveCubit>().updateLeave(
            id: leaveId,
            type: leaveTypeController.text.trim(),
            date: _selectedDay!,
          );
      Navigator.of(context).pop();
    } else if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.leaveModel != null) {
      leaveTypeController.text = widget.leaveModel!.type;
      _selectedDay = widget.leaveModel!.date;
      _focusedDay = widget.leaveModel!.date;
    }
  }

  @override
  void dispose() {
    leaveTypeController.dispose();
    formKey.currentState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Text(
                          widget.leaveModel == null ? 'Add Leaves' : 'Edit Leave',
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/calendar.svg',
                            height: 100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              DropdownButtonFormField<String>(
                initialValue: leaveTypeController.text.isEmpty ? null : leaveTypeController.text,
                items: leaveTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a leave type';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      leaveTypeController.text = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Leave Type',
                  hintText: 'Select leave type',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              if (widget.leaveModel == null) ...[
                // For adding multiple leaves
                const Text(
                  'Select dates for your leave:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TableCalendar(
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    if (widget.leaveModel != null) {
                      // For editing a single leave, highlight that date
                      return isSameDay(_selectedDay, day);
                    } else {
                      // For adding multiple leaves, highlight selected dates
                      return _selectedDates.any((selectedDay) => isSameDay(selectedDay, day));
                    }
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (widget.leaveModel == null) {
                      // For adding multiple leaves
                      setState(() {
                        _focusedDay = focusedDay;
                        if (_selectedDates.any((date) => isSameDay(date, selectedDay))) {
                          // If already selected, remove it
                          _selectedDates.removeWhere((date) => isSameDay(date, selectedDay));
                        } else {
                          // If not selected, add it
                          _selectedDates.add(selectedDay);
                        }
                      });
                    } else {
                      // For editing a single leave
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  calendarFormat: _calendarFormat,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarBuilders: CalendarBuilders(
                    selectedBuilder: (context, date, _) {
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${date.day}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                    todayBuilder: (context, date, _) {
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(color: Colors.black),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                if (_selectedDates.isNotEmpty)
                  Text(
                    '${_selectedDates.length} date(s) selected',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ] else ...[
                // For editing a single leave, show a simple date picker
                const Text(
                  'Select leave date:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Leave Date',
                    hintText: 'Select date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: _selectedDay != null
                        ? '${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}'
                        : '',
                  ),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDay ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDay = pickedDate;
                      });
                    }
                  },
                ),
              ],
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: widget.leaveModel == null ? addLeaves : saveLeave,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          widget.leaveModel == null ? 'Add Leaves' : 'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}