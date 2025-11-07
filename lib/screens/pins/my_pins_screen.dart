import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/pin_service.dart';
import '../../models/pin_model.dart';
import '../../theme/app_theme.dart';
import 'pin_detail_screen.dart';

class MyPinsScreen extends StatelessWidget {
  const MyPinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(child: Text('Please sign in to view your pins'));
    }

    return StreamBuilder<List<PinModel>>(
      stream: PinService().getUserPins(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final pins = snapshot.data ?? [];

        if (pins.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 60,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No pins yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first pin listing!',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pins.length,
          itemBuilder: (context, index) {
            return _buildMyPinCard(context, pins[index]);
          },
        );
      },
    );
  }

  Widget _buildMyPinCard(BuildContext context, PinModel pin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PinDetailScreen(pin: pin),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Pin Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(16),
                    image: pin.imageUrls.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(pin.imageUrls.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: pin.imageUrls.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.push_pin_rounded,
                            size: 32,
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Pin Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pin.pinName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: pin.isAvailable
                                  ? AppTheme.success.withOpacity(0.1)
                                  : AppTheme.mediumGray.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pin.isAvailable ? 'Available' : 'Traded',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: pin.isAvailable
                                    ? AppTheme.success
                                    : AppTheme.mediumGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Want: ${pin.wantInReturn}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.mediumGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pin.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.mediumGray,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
