import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:racconnect/data/models/section_model.dart';

import 'package:racconnect/logic/cubit/section_cubit.dart';

class SectionForm extends StatefulWidget {
  final SectionModel? sectionModel;
  const SectionForm({this.sectionModel, super.key});

  @override
  State<SectionForm> createState() => _SectionFormState();
}

class _SectionFormState extends State<SectionForm> {
  TextEditingController nameController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  void addSection() {
    if (formKey.currentState!.validate()) {
      context.read<SectionCubit>().addSection(
        name: nameController.text.trim(),
        code: codeController.text.trim(),
      );
      Navigator.of(context).pop();
    }
  }

  void saveSection() {
    if (formKey.currentState!.validate()) {
      final sectionId = widget.sectionModel?.id ?? '';
      context.read<SectionCubit>().updateSection(
        id: sectionId,
        name: nameController.text.trim(),
        code: codeController.text.trim(),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.sectionModel != null) {
      nameController.text = widget.sectionModel!.name;
      codeController.text = widget.sectionModel!.code;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
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
                          'Section',
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/group_selfie.svg',
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

                  bool textValid = RegExp(r'^[a-zA-Z -]+$').hasMatch(value);
                  if (!textValid) {
                    return 'No numbers and special characters.';
                  }

                  return null;
                },
                onFieldSubmitted:
                    (_) =>
                        (widget.sectionModel == null)
                            ? addSection()
                            : saveSection(),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter a name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                maxLength: 20,
                controller: codeController,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }

                  bool textValid = RegExp(r'^[a-zA-Z]+$').hasMatch(value);
                  if (!textValid) {
                    return 'No numbers, special characters and spaces.';
                  }

                  return null;
                },
                onFieldSubmitted:
                    (_) =>
                        (widget.sectionModel == null)
                            ? addSection()
                            : saveSection(),
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'Enter an acronym or code',
                  border: OutlineInputBorder(),
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
                      (widget.sectionModel == null) ? addSection : saveSection,
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
