import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/presentation/widgets/copy_feedback_icon_button.dart';

void showRemarksDialog({
  required BuildContext context,
  required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  required DateTime day,
  required String timeInRemarks,
  required String timeOutRemarks,
}) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            'WFH Remarks - ${DateFormat('MMM dd, yyyy').format(day)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.teal.shade700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Targets (Time In):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    CopyFeedbackIconButton(
                      textToCopy: timeInRemarks,
                      tooltip: 'Copy Targets',
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  timeInRemarks,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Accomplishments (Time Out):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    CopyFeedbackIconButton(
                      textToCopy: timeOutRemarks,
                      tooltip: 'Copy Accomplishments',
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  timeOutRemarks,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.teal.shade700),
              ),
            ),
          ],
        ),
  );
}
