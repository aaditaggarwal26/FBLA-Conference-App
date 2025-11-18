import 'package:flutter/material.dart';
import '../../models/pin_model.dart';

class PinDetailScreen extends StatelessWidget {
  final PinModel pin;

  const PinDetailScreen({super.key, required this.pin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pin.pinName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pin.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  pin.imageUrls.first,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              pin.pinName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: pin.userPhotoUrl != null
                      ? NetworkImage(pin.userPhotoUrl!)
                      : null,
                  child: pin.userPhotoUrl == null
                      ? Text(pin.userName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 8),
                Text(pin.userName),
              ],
            ),
            const SizedBox(height: 16),
            if (pin.wantInReturn != null) ...[
              Text(
                'Want in Return',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(pin.wantInReturn!),
              const SizedBox(height: 16),
            ],
            if (pin.isAvailableForTrade)
              Chip(
                label: const Text('Available for Trade'),
                backgroundColor: Colors.green.shade100,
              ),
            if (pin.isOpenToOffers)
              Chip(
                label: const Text('Open to Offers'),
                backgroundColor: Colors.blue.shade100,
              ),
          ],
        ),
      ),
    );
  }
}
