import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/pin_model.dart';
import '../../services/pin_service.dart';
import '../../theme/app_theme.dart';
import 'pin_detail_screen.dart';
import 'create_pin_screen.dart';

class MyPinsScreen extends StatefulWidget {
  const MyPinsScreen({super.key});

  @override
  State<MyPinsScreen> createState() => _MyPinsScreenState();
}

class _MyPinsScreenState extends State<MyPinsScreen> {
  final PinService _pinService = PinService();

  Future<void> _deletePin(String pinId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pin'),
        content: const Text('Are you sure you want to delete this pin listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _pinService.deletePin(pinId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pin deleted successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
          setState(() {}); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting pin: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(
        child: Text(
          'Please sign in to view your pins',
          style: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.6) : AppTheme.mediumGray,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.offWhite,
      body: StreamBuilder<List<PinModel>>(
        stream: _pinService.getUserPins(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.error),
              ),
            );
          }

          final pins = snapshot.data ?? [];

          if (pins.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.push_pin_outlined,
                    size: 80,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppTheme.lightGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pins yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first pin listing',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.mediumGray,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreatePinScreen(),
                        ),
                      );
                      setState(() {}); // Refresh after returning
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Pin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
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
              final pin = pins[index];
              return _buildPinCard(pin, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildPinCard(PinModel pin, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PinDetailScreen(pin: pin),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Pin image or placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: pin.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              pin.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.push_pin_rounded,
                                  size: 40,
                                  color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.push_pin_rounded,
                            size: 40,
                            color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                          ),
                  ),

                  const SizedBox(width: 16),

                  // Pin info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pin.pinName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pin.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : AppTheme.mediumGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (pin.isOpenToOffers)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.success.withValues(alpha: 0.2)
                                  : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Open to offers',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.success : const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Delete button
                  IconButton(
                    onPressed: () => _deletePin(pin.id),
                    icon: const Icon(Icons.delete_outline),
                    color: AppTheme.error,
                    tooltip: 'Delete pin',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Want in return
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkCard.withValues(alpha: 0.5)
                      : AppTheme.lightGray.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Looking for: ${pin.wantInReturn}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : AppTheme.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
