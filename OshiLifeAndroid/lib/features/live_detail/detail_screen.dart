import 'package:flutter/material.dart';

/// M0/M1 placeholder for `LiveDetailView`; the real screen ships in M3.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(eventId)),
    );
  }
}
