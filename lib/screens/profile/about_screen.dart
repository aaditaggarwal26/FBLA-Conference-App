import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: const Color(0xFF001231),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FBLA Conference App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Version: 1.0.0',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Appropriate use of classes, modules, and/or components:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Our app uses a modular architecture with clear separation between data models, services, and UI components. For example, the ParsedEventModel defines the structure of an event, while the EventService handles business logic, and the ProfileScreen displays user information.',
              ),
              const SizedBox(height: 24),
              const Text(
                'Appropriate use of mobile app architectural patterns:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We follow the Service-Repository pattern to ensure the UI does not directly interact with the database. For example, the LocationPinService encapsulates complex operations like uploading images and saving data.',
              ),
              const SizedBox(height: 24),
              const Text(
                'Data Handling and Storage:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Our app securely handles data by using Firebase Firestore and Storage. For example, images are uploaded with unique filenames to prevent overwrites, and download URLs are stored securely.',
              ),
              const SizedBox(height: 24),
              const Text(
                'Documentation and copyright compliance:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Our codebase is well-documented with clear comments explaining the purpose and functionality of each method. For example, the ARNavigationService includes detailed comments on how bearings are calculated.',
              ),
              const SizedBox(height: 24),
              const Text(
                'Compelling evidence from professionally legitimate sources & resources:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Our app integrates Firebase for backend services, providing secure and scalable solutions for authentication, database management, and file storage. Firebase is trusted by developers worldwide and backed by Google, ensuring reliability and continuous updates.',
              ),
              const SizedBox(height: 8),
              const Text(
                'We use Flutter, an open-source UI toolkit developed by Google, to create a seamless cross-platform experience. Flutter is widely adopted in the industry, with a strong community and extensive documentation.',
              ),
              const SizedBox(height: 8),
              const Text(
                'For location-based features, we utilize the Geolocator package, which is a well-maintained library for accessing GPS data. This package is supported by the Flutter community and ensures accurate and efficient location tracking.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}