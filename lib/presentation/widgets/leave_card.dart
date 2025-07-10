import 'package:flutter/material.dart';

class LeaveCard extends StatelessWidget {
  final Map<String, dynamic> leaveCredits;

  const LeaveCard({super.key, required this.leaveCredits});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLeaveColumn(
              icon: Icons.healing,
              label: 'SL',
              count: leaveCredits['SL'],
              color: Colors.orange,
            ),
            _buildLeaveColumn(
              icon: Icons.beach_access,
              label: 'VL',
              count: leaveCredits['VL'],
              color: Colors.blue,
            ),
            _buildLeaveColumn(
              icon: Icons.star_border,
              label: 'SPL',
              count: leaveCredits['SPL'],
              color: Colors.purple,
            ),
            _buildLeaveColumn(
              icon: Icons.timelapse,
              label: 'CTO',
              count: leaveCredits['CTO'],
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeaveColumn({
    required IconData icon,
    required String label,
    required dynamic count,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
