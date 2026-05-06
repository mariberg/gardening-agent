import 'package:flutter/material.dart';

/// A grouped settings section with a bold heading and a list of child widgets.
///
/// Used to organize settings rows into logical groups such as
/// "Account", "Preferences", and "Support".
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.heading,
    required this.children,
  });

  final String heading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              heading,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
