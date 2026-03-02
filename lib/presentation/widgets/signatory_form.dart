import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:racconnect/data/models/signatory_model.dart';
import 'package:racconnect/logic/cubit/section_cubit.dart';
import 'package:racconnect/logic/cubit/signatory_cubit.dart';

class SignatoryForm extends StatefulWidget {
  final SignatoryModel? signatoryModel;
  const SignatoryForm({this.signatoryModel, super.key});

  @override
  State<SignatoryForm> createState() => _SignatoryFormState();
}

class _SignatoryFormState extends State<SignatoryForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController supervisorController = TextEditingController();
  final TextEditingController supervisorDesignationController = TextEditingController();
  String? selectedSectionId;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context.read<SectionCubit>().getAllSections();
    context.read<SignatoryCubit>().getSignatories();
    if (widget.signatoryModel != null) {
      nameController.text = widget.signatoryModel!.name;
      designationController.text = widget.signatoryModel!.designation;
      supervisorController.text = widget.signatoryModel!.supervisor ?? '';
      supervisorDesignationController.text =
          widget.signatoryModel!.supervisorDesignation ?? '';
      selectedSectionId = widget.signatoryModel!.section;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    designationController.dispose();
    supervisorController.dispose();
    supervisorDesignationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (formKey.currentState!.validate()) {
      final signatory = SignatoryModel(
        id: widget.signatoryModel?.id,
        name: nameController.text.trim(),
        designation: designationController.text.trim(),
        supervisor: supervisorController.text.trim().isEmpty
            ? null
            : supervisorController.text.trim(),
        supervisorDesignation: supervisorDesignationController.text.trim().isEmpty
            ? null
            : supervisorDesignationController.text.trim(),
        section: selectedSectionId,
      );

      if (widget.signatoryModel == null) {
        context.read<SignatoryCubit>().addSignatory(signatory);
      } else {
        context.read<SignatoryCubit>().updateSignatory(signatory);
      }
      Navigator.of(context).pop();
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
            mainAxisSize: MainAxisSize.min,
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
                        const Text(
                          'Signatory',
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
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
              const SizedBox(height: 30),
              BlocBuilder<SectionCubit, SectionState>(
                builder: (context, sectionState) {
                  return BlocBuilder<SignatoryCubit, SignatoryState>(
                    builder: (context, signatoryState) {
                      List<DropdownMenuItem<String>> items = [];

                      if (sectionState is GetAllSectionSuccess &&
                          signatoryState is SignatoryLoadSuccess) {
                        final existingSignatorySectionIds =
                            signatoryState.signatories
                                .map((s) => s.section)
                                .where((id) => id != null)
                                .toSet();

                        items =
                            sectionState.sectionModels.where((section) {
                              // Allow the section if it's the one currently being edited
                              if (widget.signatoryModel?.section ==
                                  section.id) {
                                return true;
                              }
                              // Otherwise, only show if it doesn't have a signatory yet
                              return !existingSignatorySectionIds.contains(
                                section.id,
                              );
                            }).map((section) {
                              return DropdownMenuItem(
                                value: section.id,
                                child: Text(section.name),
                              );
                            }).toList();
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: selectedSectionId,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(),
                        ),
                        items: items,
                        onChanged: (value) {
                          setState(() {
                            selectedSectionId = value;
                          });
                        },
                        validator:
                            (value) =>
                                value == null
                                    ? 'Please select a section'
                                    : null,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: designationController,
                decoration: const InputDecoration(
                  labelText: 'Designation',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a designation'
                    : null,
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Unit Head Supervisor (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: supervisorController,
                decoration: const InputDecoration(
                  labelText: 'Supervisor Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: supervisorDesignationController,
                decoration: const InputDecoration(
                  labelText: 'Supervisor Designation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _submit,
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
