import 'package:flutter/material.dart';

Widget buildTimeCell(String? timeString, {required bool isSmallScreen}) {
  if (timeString == null || timeString.trim() == '—') {
    return Text(
      '—',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
    );
  }

  final match = RegExp(
    r'^(\d{1,2}:\d{2})\s?(AM|PM)$',
  ).firstMatch(timeString.trim().toUpperCase());

  if (match != null && isSmallScreen) {
    final time = match.group(1)!;
    final period = match.group(2)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          time,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        Text(
          period,
          style: const TextStyle(fontSize: 10, height: 1.1, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  return Text(
    timeString,
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
  );
}

Widget buildBadge(String type, {bool smallScreen = false}) {
  final normalized = type.toLowerCase();
  final isWFH = normalized.contains('wfh');
  final isSuspension = normalized.contains('suspension');

  Color color;
  String text;

  if (isSuspension) {
    color = Colors.orange;
    text = 'SUSP.';
  } else if (isWFH) {
    color = Colors.purple;
    text = 'WFH';
  } else {
    color = Colors.teal;
    text = 'BIO';
  }

  return Container(
    margin: EdgeInsets.only(left: 5),
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: smallScreen ? 8 : 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ),
  );
}
