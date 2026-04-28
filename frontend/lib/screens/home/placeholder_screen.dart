import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String tabName;

  const PlaceholderScreen({super.key, required this.tabName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(tabName),
    );
  }
}
