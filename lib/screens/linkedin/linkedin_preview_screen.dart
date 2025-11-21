import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LinkedInPreviewScreen extends StatefulWidget {
  final String content;
  final String? title;

  const LinkedInPreviewScreen({
    super.key,
    required this.content,
    this.title,
  });

  @override
  State<LinkedInPreviewScreen> createState() => _LinkedInPreviewScreenState();
}

class _LinkedInPreviewScreenState extends State<LinkedInPreviewScreen> {
  final _auth = FirebaseAuth.instance;
  bool _isPosting = false;
  bool _posted = false;

  Future<void> _handlePost() async {
    setState(() => _isPosting = true);

    // Simulate posting delay for realism
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isPosting = false;
      _posted = true;
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Posted to LinkedIn successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF0A66C2),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Close the screen after a brief delay
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final displayName = user?.displayName ?? 'FBLA Member';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Share to LinkedIn',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_posted)
            TextButton(
              onPressed: _isPosting ? null : _handlePost,
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0A66C2),
                        ),
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        color: Color(0xFF0A66C2),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            // User info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Profile picture
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF0A66C2),
                    child: user?.photoURL != null
                        ? ClipOval(
                            child: Image.network(
                              user!.photoURL!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  
                  // User name and sharing info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Text(
                              'Post to ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black54),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.public,
                                    size: 12,
                                    color: Colors.black54,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Anyone',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Post content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SelectableText(
                widget.content,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Divider(height: 1),
            
            // LinkedIn features section (for authenticity)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFeatureButton(
                    icon: Icons.image_outlined,
                    label: 'Add a photo',
                    color: Colors.black54,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureButton(
                    icon: Icons.tag,
                    label: 'Tag people',
                    color: Colors.black54,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureButton(
                    icon: Icons.celebration_outlined,
                    label: 'Celebrate an occasion',
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // LinkedIn integration badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A66C2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link,
                      size: 16,
                      color: Color(0xFF0A66C2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Connected to LinkedIn API',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0A66C2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        // Disabled for demo - just for visual authenticity
      },
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

