import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/event_service.dart';
import 'event_detail_screen.dart';

class EventQRScannerScreen extends StatefulWidget {
  const EventQRScannerScreen({super.key});

  @override
  State<EventQRScannerScreen> createState() => _EventQRScannerScreenState();
}

class _EventQRScannerScreenState extends State<EventQRScannerScreen> {
  final EventService _eventService = EventService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Event QR Code'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  setState(() => _isProcessing = true);
                  await _processQRCode(code);
                  setState(() => _isProcessing = false);
                  break;
                }
              }
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Point your camera at an event QR code',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _processQRCode(String qrCode) async {
    try {
      final event = await _eventService.getEventByQRCode(qrCode);

      if (!mounted) return;

      if (event != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event not found')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
