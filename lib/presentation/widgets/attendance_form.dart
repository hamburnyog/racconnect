import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/models/accomplishment_model.dart';
import 'package:racconnect/logic/cubit/attendance_cubit.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';

class AttendanceForm extends StatefulWidget {
  final AttendanceModel? attendanceModel;
  const AttendanceForm({this.attendanceModel, super.key});

  @override
  State<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends State<AttendanceForm> {
  final _accomplishmentRepository = AccomplishmentRepository();
  TextEditingController accomplishmentController = TextEditingController();
  TextEditingController targetController = TextEditingController();
  final now = DateTime.now();
  final formKey = GlobalKey<FormState>();
  List<AttendanceModel> attendanceToday = [];
  AccomplishmentModel? accomplishmentToday;

  Future<void> loadAttendanceToday() async {
    var cubit = context.read<AttendanceCubit>();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
      var employeeNumber = authState.user.profile?.employeeNumber ?? '';
      if (employeeNumber.isNotEmpty) {
        await cubit.getEmployeeAttendanceToday(employeeNumber: employeeNumber);
        final state = cubit.state;
        if (state is GetTodayAttendanceSuccess) {
          setState(() {
            attendanceToday = state.attendanceModels;
          });
        }
      }
    }
  }

  Future<void> _loadAccomplishmentForToday() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
      final employeeNumber = authState.user.profile?.employeeNumber;
      if (employeeNumber == null) return;
      final accomplishment = await _accomplishmentRepository
          .getAccomplishmentByDate(now, employeeNumber);
      if (accomplishment != null) {
        setState(() {
          accomplishmentToday = accomplishment;
          targetController.text = accomplishment.target;
          accomplishmentController.text = accomplishment.accomplishment;
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
                  onPressed: () async {
                    final authState = context.read<AuthCubit>().state;
                    final attendanceCubit = context.read<AttendanceCubit>();
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    if (authState is AuthenticatedState) {
                      final employeeNumber =
                          authState.user.profile?.employeeNumber;
                      if (employeeNumber == null) return;

                      if (attendanceToday.isEmpty) {
                        final accomplishment = await _accomplishmentRepository
                            .addAccomplishment(
                              date: now,
                              target: targetController.text.trim(),
                              accomplishment: '',
                              employeeNumber: employeeNumber,
                            );
                        if (!mounted) return;
                        attendanceCubit.addAttendance(
                          employeeNumber:
                              authState.user.profile?.employeeNumber ?? '',
                          remarks: targetController.text.trim(),
                          accomplishmentId: accomplishment.id,
                        );
                      } else {
                        final accomplishment = await _accomplishmentRepository
                            .getAccomplishmentByDate(now, employeeNumber);
                        if (accomplishment != null) {
                          await _accomplishmentRepository.updateAccomplishment(
                            id: accomplishment.id!,
                            date: accomplishment.date,
                            target: targetController.text.trim(),
                            accomplishment:
                                accomplishmentController.text.trim(),
                            employeeNumber: employeeNumber,
                          );
                        }
                        if (!mounted) return;
                        attendanceCubit.addAttendance(
                          employeeNumber:
                              authState.user.profile?.employeeNumber ?? '',
                          remarks: accomplishmentController.text.trim(),
                          accomplishmentId: accomplishment?.id,
                        );
                      }
                    }
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
    _loadAccomplishmentForToday();
  }

  @override
  void dispose() {
    accomplishmentController.dispose();
    targetController.dispose();
    formKey.currentState?.dispose();
    attendanceToday.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceCubit, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceAddSuccess) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          loadAttendanceToday();
          if (!context.mounted) return;
          Navigator.of(context).pop();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                attendanceToday.isEmpty
                    ? 'Successfully timed in!'
                    : 'Successfully timed out!',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_home_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'WFH Attendance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            DateFormat('MMMM dd, y').format(now),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          StreamBuilder(
                            stream: Stream.periodic(const Duration(seconds: 1)),
                            builder: (context, snapshot) {
                              return Column(
                                children: [
                                  Text(
                                    DateFormat(
                                      'h:mm:ss a',
                                    ).format(DateTime.now()),
                                    style: TextStyle(
                                      fontSize: 50,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.yellow,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: const [
                                                    Icon(
                                                      Icons.login,
                                                      color: Colors.deepPurple,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Time In',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.deepPurple,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  attendanceToday.isNotEmpty
                                                      ? DateFormat(
                                                        'hh:mm a',
                                                      ).format(
                                                        attendanceToday
                                                            .first
                                                            .timestamp,
                                                      )
                                                      : '--:--',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(
                                              left: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: const [
                                                    Icon(
                                                      Icons.logout,
                                                      color: Colors.deepPurple,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Time Out',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.deepPurple,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  attendanceToday.length > 1
                                                      ? DateFormat(
                                                        'hh:mm a',
                                                      ).format(
                                                        attendanceToday
                                                            .last
                                                            .timestamp,
                                                      )
                                                      : '--:--',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: SvgPicture.asset(
                          'assets/images/creative.svg',
                          height: 200,
                          colorFilter: ColorFilter.mode(
                            Colors.white.withValues(alpha: 0.2),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                if (attendanceToday.isEmpty)
                  TextFormField(
                    maxLength: 1000,
                    controller: targetController,
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
                    decoration: InputDecoration(
                      labelText: 'Target',
                      hintText: 'Enter your tasks for the day',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  Column(
                    children: [
                      TextFormField(
                        maxLength: 1000,
                        controller: targetController,
                        readOnly: false,
                        maxLines: 5,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          labelText: 'Target',
                          hintText: 'Enter your tasks for the day',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        maxLength: 1000,
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
                        decoration: InputDecoration(
                          labelText: 'Accomplishment',
                          hintText: 'Enter your accomplished tasks for the day',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
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
                    onPressed:
                        attendanceToday.length >= 2 ? null : addAttendance,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            attendanceToday.length >= 2
                                ? Icons.check
                                : Icons.timer,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            attendanceToday.length >= 2
                                ? 'WFH Recorded'
                                : (attendanceToday.isEmpty)
                                ? 'Time In'
                                : 'Time Out',
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
      ),
    );
  }
}
