import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.pending;
        break;
      case 'verifikasi':
        color = Colors.blue;
        label = 'Verifikasi';
        icon = Icons.verified;
        break;
      case 'lulus':
        color = Colors.green;
        label = 'Lulus';
        icon = Icons.check_circle;
        break;
      case 'tidak_lulus':
        color = Colors.red;
        label = 'Tidak Lulus';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}