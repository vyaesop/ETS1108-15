import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onStart;

  const OnboardingScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text('Chrono', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'A timezone-aware planning app for meetings, calls, and reminders. Inspired by your Dribbble references.',
              style: TextStyle(fontSize: 16, height: 1.45),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: const Color(0xFFEEECE4),
              ),
              child: const Text(
                'Use Today, Calendar, and Month views. Your profile and events are saved locally on this device.',
                style: TextStyle(fontSize: 15),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Enter App'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
