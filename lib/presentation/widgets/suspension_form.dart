import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:racconnect/data/models/suspension_model.dart';
import 'package:racconnect/logic/cubit/suspension_cubit.dart';

class SuspensionForm extends StatefulWidget {
  final SuspensionModel? suspensionModel;
  const SuspensionForm({this.suspensionModel, super.key});

  @override
  State<SuspensionForm> createState() => _SuspensionFormState();
}

class _SuspensionFormState extends State<SuspensionForm> {
  TextEditingController nameController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isHalfday = false;
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.suspensionModel != null) {
      nameController.text = widget.suspensionModel!.name;
      dateController.text =
          widget.suspensionModel!.datetime.toIso8601String().split('T').first;
      isHalfday = widget.suspensionModel!.isHalfday;
      if (isHalfday) {
        selectedTime = TimeOfDay.fromDateTime(widget.suspensionModel!.datetime);
      }
    }
  }

  void addSuspension() {
    if (formKey.currentState!.validate()) {
      DateTime finalDateTime;
      final date = DateTime.parse(dateController.text);
      if (isHalfday) {
        finalDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      } else {
        finalDateTime = date;
      }
      context.read<SuspensionCubit>().addSuspension(
        name: nameController.text,
        datetime: finalDateTime,
        isHalfday: isHalfday,
      );
      Navigator.of(context).pop();
    }
  }

  void saveSuspension() {
    if (formKey.currentState!.validate()) {
      DateTime finalDateTime;
      final date = DateTime.parse(dateController.text);
      if (isHalfday) {
        finalDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      } else {
        finalDateTime = date;
      }
      context.read<SuspensionCubit>().updateSuspension(
        id: widget.suspensionModel!.id!,
        name: nameController.text,
        datetime: finalDateTime,
        isHalfday: isHalfday,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    timeController.dispose();
    formKey.currentState?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.suspensionModel != null && isHalfday) {
      timeController.text = selectedTime.format(context);
    }
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
                          'Suspension',
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/rain.svg',
                            height: 100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              TextFormField(
                maxLength: 50,
                controller: nameController,
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
                onFieldSubmitted:
                    (_) =>
                        (widget.suspensionModel == null)
                            ? addSuspension
                            : saveSuspension,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter a name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: dateController,
                readOnly: true,
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate:
                        dateController.text.isNotEmpty
                            ? DateTime.tryParse(dateController.text) ??
                                DateTime.now()
                            : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    dateController.text =
                        pickedDate.toIso8601String().split('T').first;
                    setState(() {});
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Date',
                  hintText: 'Select a date',
                  border: OutlineInputBorder(),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(right: 26.0),
                    child: Icon(Icons.calendar_today),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: isHalfday,
                    onChanged: (value) {
                      setState(() {
                        isHalfday = value ?? false;
                        if (!isHalfday) {
                          timeController.clear();
                        }
                      });
                    },
                  ),
                  Text('Halfday Suspension?'),
                ],
              ),
              if (isHalfday)
                TextFormField(
                  controller: timeController,
                  readOnly: true,
                  validator: (value) {
                    if (isHalfday) {
                      if (value == null || value.isEmpty) {
                        return 'Time is required for half-day suspension';
                      }
                      final hour = selectedTime.hour;
                      final minute = selectedTime.minute;
                      if (hour < 7 || (hour >= 18 && minute > 30)) {
                        return 'Time must be between 7:00 AM and 6:30 PM';
                      }
                    }
                    return null;
                  },
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (pickedTime != null) {
                      setState(() {
                        selectedTime = pickedTime;
                        timeController.text = pickedTime.format(context);
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Suspension Time',
                    hintText: 'Select a time',
                    border: OutlineInputBorder(),
                    suffixIcon: Padding(
                      padding: EdgeInsets.only(right: 26.0),
                      child: Icon(Icons.access_time),
                    ),
                  ),
                ),
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
                  onPressed:
                      (widget.suspensionModel == null)
                          ? addSuspension
                          : saveSuspension,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Save',
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
