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
  List<TextEditingController> emailControllers = [TextEditingController()];
  TextEditingController forumDateController = TextEditingController();
  String selectedType = 'Pre-adoption';
  final formKey = GlobalKey<FormState>();

  void addEmailField() {
    setState(() {
      emailControllers.add(TextEditingController());
    });
  }

  void removeEmailField(int index) {
    if (emailControllers.length > 1) {
      setState(() {
        emailControllers[index].dispose();
        emailControllers.removeAt(index);
      });
    }
  }

  String get joinedEmails => emailControllers
      .map((c) => c.text.trim())
      .where((text) => text.isNotEmpty)
      .join(' / ');

  void addAttendee() {
    if (formKey.currentState!.validate()) {
      context.read<ForumCubit>().addAttendee(
            ForumAttendee(
              name: nameController.text.trim(),
              address: addressController.text.trim(),
              email: joinedEmails,
              type: selectedType,
              forumDate: DateTime.parse(forumDateController.text),
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
              email: joinedEmails,
              type: selectedType,
              forumDate: DateTime.parse(forumDateController.text),
              emailSentDate: widget.forumAttendee?.emailSentDate,
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

      final emails = widget.forumAttendee!.emails;
      if (emails.isNotEmpty) {
        emailControllers =
            emails.map((e) => TextEditingController(text: e)).toList();
      }

      selectedType = widget.forumAttendee!.type.isNotEmpty
          ? widget.forumAttendee!.type
          : 'Pre-adoption';
      forumDateController.text =
          widget.forumAttendee!.forumDate.toString().split(' ')[0];
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    for (var controller in emailControllers) {
      controller.dispose();
    }
    forumDateController.dispose();
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          'Certificate',
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
                maxLength: 200,
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
              const Text(
                'Email Address(es)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...List.generate(emailControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: emailControllers[index],
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (index == 0 && (value == null || value.isEmpty)) {
                              return 'At least one email is required';
                            }
                            if (value != null &&
                                value.isNotEmpty &&
                                !value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Email ${index + 1}',
                            hintText: 'Enter email address',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      if (emailControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => removeEmailField(index),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: addEmailField,
                icon: const Icon(Icons.add),
                label: const Text('Add another email'),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Pre-adoption', 'Foster Care'].map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedType = newValue;
                    });
                  }
                },
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
                    initialDate:
                        forumDateController.text.isNotEmpty
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
                      (widget.forumAttendee == null)
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
