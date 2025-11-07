import 'package:flutter/material.dart';
import '../../models/pin_model.dart';
import '../../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PinDetailScreen extends StatefulWidget {
  final PinModel pin;

  const PinDetailScreen({super.key, required this.pin});

  @override
  State<PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends State<PinDetailScreen> {
  int _currentImageIndex = 0;
  bool _isLoading = false;

  Future<void> _requestTrade() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Implement trade request functionality
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trade request sent!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user?.uid == widget.pin.userId;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('Pin Details'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image carousel
            if (widget.pin.imageUrls.isNotEmpty)
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: widget.pin.imageUrls.length,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      widget.pin.imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                          child: const Icon(Icons.broken_image, size: 64),
                        );
                      },
                    );
                  },
                ),
              )
            else
              Container(
                height: 300,
                color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                child: Icon(
                  Icons.push_pin_rounded,
                  size: 100,
                  color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                ),
              ),

            // Image indicator
            if (widget.pin.imageUrls.length > 1)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.pin.imageUrls.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? (isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue)
                            : (isDark ? AppTheme.darkCard : AppTheme.lightGray),
                      ),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pin name
                  Text(
                    widget.pin.pinName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.black,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: widget.pin.userPhotoUrl != null
                            ? NetworkImage(widget.pin.userPhotoUrl!)
                            : null,
                        backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                        child: widget.pin.userPhotoUrl == null
                            ? Text(
                                widget.pin.userName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.pin.userName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppTheme.black,
                              ),
                            ),
                            Text(
                              'Posted ${_formatDate(widget.pin.createdAt)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  _buildSection(
                    'Description',
                    widget.pin.description,
                    Icons.description_rounded,
                    isDark,
                  ),

                  const SizedBox(height: 20),

                  // Want in return
                  _buildSection(
                    'Looking for',
                    widget.pin.wantInReturn,
                    Icons.swap_horiz_rounded,
                    isDark,
                  ),

                  const SizedBox(height: 20),

                  // Open to offers badge
                  if (widget.pin.isOpenToOffers)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.success.withValues(alpha: 0.2)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.success,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Open to any offers',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppTheme.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Action button
                  if (!isOwner)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestTrade,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.swap_horiz_rounded, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text(
                                    'Request Trade',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.mediumGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
