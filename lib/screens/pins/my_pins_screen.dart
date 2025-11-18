import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/pin_model.dart';
import '../../services/pin_service.dart';
import 'pin_detail_screen.dart';

class MyPinsScreen extends StatelessWidget {
  const MyPinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your pins'));
    }

    final pinService = PinService();

    return StreamBuilder<List<PinModel>>(
      stream: pinService.getUserPinsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final pins = snapshot.data ?? [];

        if (pins.isEmpty) {
          return const Center(
            child: Text('No pins yet. Create your first pin!'),
          );
        }

        return ListView.builder(
          itemCount: pins.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final pin = pins[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: pin.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          pin.imageUrls.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.push_pin, size: 40),
                title: Text(pin.pinName),
                subtitle: pin.wantInReturn != null
                    ? Text('Want: ${pin.wantInReturn}')
                    : null,
                trailing: Icon(
                  pin.isAvailableForTrade
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: pin.isAvailableForTrade
                      ? Colors.green
                      : Colors.grey,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PinDetailScreen(pin: pin),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
