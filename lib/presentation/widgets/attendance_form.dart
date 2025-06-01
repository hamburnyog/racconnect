// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:racconnect/data/models/attendance_model.dart';

// import 'package:racconnect/logic/cubit/attendance_cubit.dart';

// class AttendanceForm extends StatefulWidget {
//   final AttendanceModel? attendanceModel;
//   const AttendanceForm({this.attendanceModel, super.key});

//   @override
//   State<AttendanceForm> createState() => _AttendanceFormState();
// }

// class _AttendanceFormState extends State<AttendanceForm> {
//   TextEditingController dateController = TextEditingController();
//   final formKey = GlobalKey<FormState>();

//   void addAttendance() {
//     if (formKey.currentState!.validate()) {
//       context.read<AttendanceCubit>().addAttendance(
//         employeeNumber: employeeNumberController.text.trim(),
//         timestamp: DateTime.parse(dateController.text),
//       );
//       Navigator.of(context).pop();
//     }
//   }

//   // void saveAttendance() {
//   //   if (formKey.currentState!.validate()) {
//   //     final attendanceId = widget.attendanceModel?.id ?? '';
//   //     context.read<AttendanceCubit>().updateAttendance(
//   //       id: attendanceId,
//   //       employeeNumber: employeeNumberController.text.trim(),
//   //       date: DateTime.parse(dateController.text),
//   //     );
//   //     Navigator.of(context).pop();
//   //   }
//   }

//   @override
//   void initState() {
//     super.initState();
//     if (widget.attendanceModel != null) {
//       employeeNumberController.text = widget.attendanceModel!.employeeNumber;
//       dateController.text =
//           widget.attendanceModel!.date.toString().split(
//             ' ',
//           )[0]; // Format date to 'YYYY-MM-DD'
//     }
//   }

//   @override
//   void dispose() {
//     employeeNumberController.dispose();
//     dateController.dispose();
//     formKey.currentState?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: MediaQuery.of(context).viewInsets,
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: formKey,
//           child: Column(
//             children: [
//               Stack(
//                 children: [
//                   Container(
//                     height: 120,
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).primaryColor,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20.0,
//                       vertical: 10,
//                     ),
//                     child: Row(
//                       children: [
//                         Text(
//                           'Attendance',
//                           style: TextStyle(
//                             fontSize: 30,
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Spacer(),
//                         Center(
//                           child: SvgPicture.asset(
//                             'assets/images/calendar.svg',
//                             height: 100,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 30),
//               TextFormField(
//                 maxLength: 50,
//                 controller: employeeNumberController,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'This field is required';
//                   }
//                   return null;
//                 },
//                 onFieldSubmitted:
//                     (_) =>
//                         (widget.attendanceModel == null)
//                             ? addAttendance
//                             : saveAttendance,
//                 decoration: const InputDecoration(
//                   labelText: 'employeeNumber',
//                   hintText: 'Enter a employeeNumber',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 20),
//               TextFormField(
//                 controller: dateController,
//                 readOnly: true,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'This field is required';
//                   }
//                   return null;
//                 },
//                 onTap: () async {
//                   FocusScope.of(context).requestFocus(FocusNode());
//                   DateTime? pickedDate = await showDatePicker(
//                     context: context,
//                     initialDate:
//                         dateController.text.isNotEmpty
//                             ? DateTime.tryParse(dateController.text) ??
//                                 DateTime.now()
//                             : DateTime.now(),
//                     firstDate: DateTime(2000),
//                     lastDate: DateTime(2100),
//                   );
//                   if (pickedDate != null) {
//                     dateController.text =
//                         pickedDate.toIso8601String().split('T').first;
//                     setState(() {});
//                   }
//                 },
//                 decoration: const InputDecoration(
//                   labelText: 'Date',
//                   hintText: 'Select a date',
//                   border: OutlineInputBorder(),
//                   suffixIcon: Icon(Icons.calendar_today),
//                 ),
//               ),
//               SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Theme.of(context).primaryColor,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                   onPressed:
//                       (widget.attendanceModel == null)
//                           ? addAttendance
//                           : saveAttendance,
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.save, color: Colors.white),
//                         SizedBox(width: 10),
//                         Text(
//                           'Save',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
