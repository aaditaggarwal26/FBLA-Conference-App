import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

class QRService {
  /// Generate QR code data for different features
  
  // School invite code QR
  static String getSchoolInviteQR(String inviteCode) {
    return 'fbla-app://join-school?code=$inviteCode';
  }

  // User profile QR
  static String getUserProfileQR(String userId) {
    return 'fbla-app://profile/$userId';
  }

  // Event QR for check-in
  static String getEventQR(String eventId) {
    return 'fbla-app://event/$eventId';
  }

  // Pin trading QR
  static String getPinTradingQR(String userId) {
    return 'fbla-app://trade-pin/$userId';
  }

  // Chat room QR
  static String getChatRoomQR(String roomId) {
    return 'fbla-app://chat/$roomId';
  }

  // Generic deep link QR
  static String getDeepLinkQR(String path) {
    return 'fbla-app://$path';
  }

  /// Show QR code in a dialog
  static void showQRDialog({
    required BuildContext context,
    required String data,
    required String title,
    String? subtitle,
    Color? color,
  }) {
    showDialog(
      context: context,
      builder: (context) => QRCodeDialog(
        data: data,
        title: title,
        subtitle: subtitle,
        color: color,
      ),
    );
  }

  /// Capture QR code as image and share
  static Future<void> shareQRCode({
    required GlobalKey qrKey,
    required String text,
  }) async {
    try {
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();
        await Share.shareXFiles(
          [XFile.fromData(pngBytes, name: 'qr_code.png', mimeType: 'image/png')],
          text: text,
        );
      }
    } catch (e) {
      print('Error sharing QR code: $e');
    }
  }
}

class QRCodeDialog extends StatefulWidget {
  final String data;
  final String title;
  final String? subtitle;
  final Color? color;

  const QRCodeDialog({
    super.key,
    required this.data,
    required this.title,
    this.subtitle,
    this.color,
  });

  @override
  State<QRCodeDialog> createState() => _QRCodeDialogState();
}

class _QRCodeDialogState extends State<QRCodeDialog> {
  final GlobalKey _qrKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrColor = widget.color ?? Theme.of(context).primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            
            // Pretty QR Code with branding
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: PrettyQrView.data(
                  data: widget.data,
                  decoration: PrettyQrDecoration(
                    shape: PrettyQrSmoothSymbol(
                      color: qrColor,
                      roundFactor: 1,
                    ),
                    image: const PrettyQrDecorationImage(
                      image: AssetImage('assets/icon.png'),
                      scale: 0.2,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      QRService.shareQRCode(
                        qrKey: _qrKey,
                        text: widget.title,
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable QR Code Widget
class CustomQRCode extends StatelessWidget {
  final String data;
  final double size;
  final Color? color;
  final bool showLogo;

  const CustomQRCode({
    super.key,
    required this.data,
    this.size = 200,
    this.color,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final qrColor = color ?? Theme.of(context).primaryColor;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: showLogo
          ? PrettyQrView.data(
              data: data,
              decoration: PrettyQrDecoration(
                shape: PrettyQrSmoothSymbol(
                  color: qrColor,
                  roundFactor: 1,
                ),
                image: const PrettyQrDecorationImage(
                  image: AssetImage('assets/icon.png'),
                  scale: 0.2,
                ),
              ),
            )
          : QrImageView(
              data: data,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              foregroundColor: qrColor,
            ),
    );
  }
}
