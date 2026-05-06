import 'package:flutter/material.dart';

/// An individual tappable settings row displaying a label, optional value,
/// and a trailing chevron icon.
///
/// Used within [SettingsSection] to represent individual settings items
/// such as "Name", "Email", "Notifications", etc.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.value,
    this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Text(label, style: const TextStyle(fontSize: 16)),
                const Spacer(),
                if (value != null)
                  Text(
                    value!,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5),
      ],
    );
  }
}
