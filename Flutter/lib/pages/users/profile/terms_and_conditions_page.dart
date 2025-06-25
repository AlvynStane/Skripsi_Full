import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms and Conditions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text(
                      '1. Introduction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Welcome to our app. By accessing or using the app, you agree to comply with and be bound by the following terms and conditions.',
                    ),
                    SizedBox(height: 16),
                    Text(
                      '2. User Obligations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You agree to use the app in compliance with all applicable laws and regulations. Any unauthorized use of the app is prohibited.',
                    ),
                    SizedBox(height: 16),
                    Text(
                      '3. Limitation of Liability',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We are not responsible for any damages that may occur from using the app. Your use of the app is at your own risk.',
                    ),
                    SizedBox(height: 16),
                    Text(
                      '4. Amendments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We reserve the right to update or modify these terms at any time. Please review these terms regularly for updates.',
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Agree & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
