import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onPlay;

  const HomeScreen({super.key, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Adventurer Mario',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              ),
              child: const Text('Play', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
