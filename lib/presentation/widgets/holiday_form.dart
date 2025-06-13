import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:racconnect/data/models/holiday_model.dart';

import 'package:racconnect/logic/cubit/holiday_cubit.dart';

class HolidayForm extends StatefulWidget {
  final HolidayModel? holidayModel;
  const HolidayForm({this.holidayModel, super.key});

  @override
  State<HolidayForm> createState() => _HolidayFormState();
}

class _HolidayFormState extends State<HolidayForm> {
  TextEditingController nameController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  void addHoliday() {
    if (formKey.currentState!.validate()) {
      context.read<HolidayCubit>().addHoliday(
        name: nameController.text.trim(),
        date: DateTime.parse(dateController.text),
      );
      Navigator.of(context).pop();
    }
  }

  void saveHoliday() {
    if (formKey.currentState!.validate()) {
      final holidayId = widget.holidayModel?.id ?? '';
      context.read<HolidayCubit>().updateHoliday(
        id: holidayId,
        name: nameController.text.trim(),
        date: DateTime.parse(dateController.text),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.holidayModel != null) {
      nameController.text = widget.holidayModel!.name;
      dateController.text =
          widget.holidayModel!.date.toString().split(
            ' ',
          )[0]; // Format date to 'YYYY-MM-DD'
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
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
                          'Holiday',
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
                        (widget.holidayModel == null)
                            ? addHoliday
                            : saveHoliday,
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
                  suffixIcon: Icon(Icons.calendar_today),
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
                      (widget.holidayModel == null) ? addHoliday : saveHoliday,
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
