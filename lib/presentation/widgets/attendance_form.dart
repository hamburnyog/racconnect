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
  List<AttendanceModel> attendanceToday = [];

  Future<void> loadAttendanceToday() async {
    var cubit = context.read<AttendanceCubit>();
    AuthSignedIn signedIn = context.read<AuthCubit>().state as AuthSignedIn;
    var employeeeNumber = signedIn.user.profile?.employeeNumber ?? '';
    if (employeeeNumber.isNotEmpty) {
      await cubit.getEmployeeAttendanceToday(employeeNumber: employeeeNumber);
      final state = cubit.state;
      if (state is GetTodayAttendanceSuccess) {
        setState(() {
          attendanceToday = state.attendanceModels;
        });
      }
    }
  }

  void addAttendance() {
    if (formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Confirm Attendance'),
              content: const Text(
                'Are you sure you want to submit your attendance?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size(100, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    AuthSignedIn signedIn =
                        context.read<AuthCubit>().state as AuthSignedIn;
                    context.read<AttendanceCubit>().addAttendance(
                      employeeNumber:
                          signedIn.user.profile?.employeeNumber ?? '',
                      remarks: accomplishmentController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadAttendanceToday();
  }

  @override
  void dispose() {
    accomplishmentController.dispose();
    formKey.currentState?.dispose();
    attendanceToday.clear();
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
                  DateFormat('MMMM dd, y').format(now),
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
                  return Column(
                    children: [
                      Text(
                        DateFormat('h:mm:ss a').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (attendanceToday.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(
                                            Icons.login,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Time In',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        DateFormat('hh:mm a').format(
                                          attendanceToday.first.timestamp,
                                        ),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.logout, color: Colors.red),
                                          SizedBox(width: 6),
                                          Text(
                                            'Time Out',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        attendanceToday.length > 1
                                            ? DateFormat('hh:mm a').format(
                                              attendanceToday.last.timestamp,
                                            )
                                            : '--:--',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // SizedBox(height: 10),
                      // if (attendanceToday.length >= 2)
                      //   Padding(
                      //     padding: const EdgeInsets.symmetric(vertical: 10.0),
                      //     child: Container(
                      //       padding: const EdgeInsets.all(12),
                      //       decoration: BoxDecoration(
                      //         borderRadius: BorderRadius.circular(8),
                      //         border: Border.all(color: Colors.red.shade400),
                      //       ),
                      //       child: Row(
                      //         children: const [
                      //           Icon(Icons.info_outline, color: Colors.red),
                      //           SizedBox(width: 10),
                      //           Expanded(
                      //             child: Text(
                      //               'You have already recorded at least two (2) attendance logs for today.',
                      //               style: TextStyle(
                      //                 fontSize: 10,
                      //                 color: Colors.red,
                      //                 fontWeight: FontWeight.w600,
                      //               ),
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                    ],
                  );
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                maxLength: 1000,
                controller: accomplishmentController,
                maxLines: 5,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => addAttendance,
                decoration: InputDecoration(
                  labelText:
                      (attendanceToday.isEmpty)
                          ? 'Target/s'
                          : 'Accomplishment/s',
                  hintText:
                      (attendanceToday.isEmpty)
                          ? 'Enter today\'s target/s'
                          : 'Enter today\'s Accomplishment/s',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
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
                          (attendanceToday.isEmpty) ? 'Time In' : 'Time Out',
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
