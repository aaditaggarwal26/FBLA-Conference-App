import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../backend/pin_trading/pin_model.dart';
import '../../backend/pin_trading/pin_service.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../messages/chat_page.dart';

class PinDetailPage extends StatefulWidget {
  final PinModel pin;

  const PinDetailPage({super.key, required this.pin});

  @override
  State<PinDetailPage> createState() => _PinDetailPageState();
}

class _PinDetailPageState extends State<PinDetailPage> {
  final PinService _pinService = PinService();
  int _currentImageIndex = 0;

  void _contactOwner() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId == widget.pin.userId) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          otherUserId: widget.pin.userId,
          otherUserName: widget.pin.userName,
        ),
      ),
    );
  }

  Future<void> _markAsTraded() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Traded'),
        content: const Text('Are you sure you want to mark this pin as traded?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark as Traded'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _pinService.markAsTraded(widget.pin.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pin marked as traded!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == widget.pin.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: FlutterFlowTheme.of(context).primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'pin_${widget.pin.id}',
                child: widget.pin.imageUrls.isNotEmpty
                    ? PageView.builder(
                        itemCount: widget.pin.imageUrls.length,
                        onPageChanged: (index) => setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          return Image.network(
                            widget.pin.imageUrls[index],
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              FlutterFlowTheme.of(context).primary,
                              FlutterFlowTheme.of(context).secondary,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.push_pin_rounded, size: 120, color: Colors.white),
                        ),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.pin.pinName,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.pin.isAvailable
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.pin.isAvailable ? 'Available' : 'Traded',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.bold,
                            color: widget.pin.isAvailable ? const Color(0xFF10B981) : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFD8DEFE),
                        backgroundImage: widget.pin.userPhotoUrl != null
                            ? NetworkImage(widget.pin.userPhotoUrl!)
                            : null,
                        child: widget.pin.userPhotoUrl == null
                            ? const Icon(Icons.person, color: Color(0xFF3B58F4))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pin.userName,
                            style: const TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Pin Owner',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.pin.description,
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD8DEFE), Color(0xFFB8C9FE)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wants in Return',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B58F4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.pin.wantInReturn,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.pin.isOpenToOffers) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Open to other offers',
                                style: TextStyle(
                                  fontFamily: 'Google Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  if (!isOwner && widget.pin.isAvailable)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _contactOwner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.chat, color: Colors.white),
                        label: const Text(
                          'Contact Owner',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  
                  if (isOwner && widget.pin.isAvailable) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _markAsTraded,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF10B981), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                        label: const Text(
                          'Mark as Traded',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
