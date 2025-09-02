import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/models/accomplishment_model.dart';

class WfhInfoDisplay extends StatelessWidget {
  final List<AttendanceModel> attendance;
  final AccomplishmentModel? accomplishment;
  final DateTime date;

  const WfhInfoDisplay({
    required this.attendance,
    required this.accomplishment,
    required this.date,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
                        const Icon(Icons.home, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'WFH Information',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      DateFormat('MMMM dd, y').format(date),
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.login, color: Colors.deepPurple),
                                    SizedBox(width: 6),
                                    Text(
                                      'Time In',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _getTimeIn(),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      color: Colors.deepPurple,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Time Out',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _getTimeOut(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: SvgPicture.asset(
                    'assets/images/creative.svg',
                    height: 150,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.2),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          if (attendance.isEmpty)
            Column(
              children: [
                const SizedBox(height: 50),
                SvgPicture.asset('assets/images/dog.svg', height: 100),
                const Center(
                  child: Text(
                    'No WFH details for this day.',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (accomplishment == null)
                  Column(
                    children: [
                      const SizedBox(height: 50),
                      SvgPicture.asset('assets/images/dog.svg', height: 100),
                      const Center(
                        child: Text(
                          'No work details available.',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: accomplishment!.target,
                        maxLines: 5,
                        minLines: 1,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Accomplishment:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: accomplishment!.accomplishment,
                        maxLines: 5,
                        minLines: 1,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _getTimeIn() {
    // First attendance record is Time In
    if (attendance.isEmpty) {
      return '--:--';
    }

    return DateFormat('hh:mm a').format(attendance.first.timestamp);
  }

  String _getTimeOut() {
    // Second attendance record is Time Out (if it exists)
    if (attendance.length < 2) {
      return '--:--';
    }

    return DateFormat('hh:mm a').format(attendance.last.timestamp);
  }
}
