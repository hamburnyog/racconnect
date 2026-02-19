import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:racconnect/data/models/forum_attendee.dart';
import 'package:racconnect/logic/cubit/forum_cubit.dart';

class ForumAttendeeForm extends StatefulWidget {
  final ForumAttendee? forumAttendee;
  const ForumAttendeeForm({this.forumAttendee, super.key});

  @override
  State<ForumAttendeeForm> createState() => _ForumAttendeeFormState();
}

class _ForumAttendeeFormState extends State<ForumAttendeeForm> {
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController forumDateController = TextEditingController();
  TextEditingController certificateDateController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  void addAttendee() {
    if (formKey.currentState!.validate()) {
      context.read<ForumCubit>().addAttendee(
            ForumAttendee(
              name: nameController.text.trim(),
              address: addressController.text.trim(),
              forumDate: DateTime.parse(forumDateController.text),
              certificateDate: DateTime.parse(certificateDateController.text),
            ),
          );
      Navigator.of(context).pop();
    }
  }

  void saveAttendee() {
    if (formKey.currentState!.validate()) {
      final attendeeId = widget.forumAttendee?.id ?? '';
      context.read<ForumCubit>().updateAttendee(
            attendeeId,
            ForumAttendee(
              name: nameController.text.trim(),
              address: addressController.text.trim(),
              forumDate: DateTime.parse(forumDateController.text),
              certificateDate: DateTime.parse(certificateDateController.text),
            ),
          );
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.forumAttendee != null) {
      nameController.text = widget.forumAttendee!.name;
      addressController.text = widget.forumAttendee!.address;
      forumDateController.text =
          widget.forumAttendee!.forumDate.toString().split(' ')[0];
      certificateDateController.text =
          widget.forumAttendee!.certificateDate.toString().split(' ')[0];
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    forumDateController.dispose();
    certificateDateController.dispose();
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
                          'Forum Attendee',
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/group_fun.svg',
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
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter a name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                maxLength: 100,
                controller: addressController,
                keyboardType: TextInputType.streetAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter an address',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: forumDateController,
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
                    initialDate: forumDateController.text.isNotEmpty
                        ? DateTime.tryParse(forumDateController.text) ??
                            DateTime.now()
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    forumDateController.text =
                        pickedDate.toIso8601String().split('T').first;
                    setState(() {});
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Forum Date',
                  hintText: 'Select a date',
                  border: OutlineInputBorder(),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(right: 26.0),
                    child: Icon(Icons.calendar_today),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: certificateDateController,
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
                    initialDate: certificateDateController.text.isNotEmpty
                        ? DateTime.tryParse(certificateDateController.text) ??
                            DateTime.now()
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    certificateDateController.text =
                        pickedDate.toIso8601String().split('T').first;
                    setState(() {});
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Certificate Date',
                  hintText: 'Select a date',
                  border: OutlineInputBorder(),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(right: 26.0),
                    child: Icon(Icons.calendar_today),
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
                  onPressed: (widget.forumAttendee == null)
                      ? addAttendee
                      : saveAttendee,
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
