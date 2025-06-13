import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/logic/cubit/attendance_cubit.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';

class AttendanceForm extends StatefulWidget {
  final AttendanceModel? attendanceModel;
  const AttendanceForm({this.attendanceModel, super.key});

  @override
  State<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends State<AttendanceForm> {
  TextEditingController accomplishmentController = TextEditingController();
  final now = DateTime.now();
  final formKey = GlobalKey<FormState>();

  void addAttendance() {
    if (formKey.currentState!.validate()) {
      AuthSignedIn signedIn = context.read<AuthCubit>().state as AuthSignedIn;
      context.read<AttendanceCubit>().addAttendance(
        employeeNumber: signedIn.user.employeeNumber ?? '',
        remarks: accomplishmentController.text.trim(),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    accomplishmentController.dispose();
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
                          'WFH Clock In',
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
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  DateFormat('MMM dd, y').format(now),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Text(
                    DateFormat('h:mm:ss a').format(DateTime.now()),
                    style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                  );
                },
              ),
              SizedBox(height: 30),
              TextFormField(
                maxLength: 50,
                controller: accomplishmentController,
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => addAttendance,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  hintText: 'Enter today\'s target(s) / accomplishment(s)',
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
                  onPressed: addAttendance,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Clock In',
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
