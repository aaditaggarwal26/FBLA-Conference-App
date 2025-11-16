import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I trade pins?',
      answer:
          'Go to the Pins tab to view available pins. You can create your own pins or browse pins from other users. Tap on a pin to view details and initiate a trade. Both parties must confirm the trade for it to be completed.',
    ),
    FAQItem(
      question: 'How do I send messages to other attendees?',
      answer:
          'Navigate to the Messages tab to see your conversations. Tap the compose button to start a new conversation, or tap on an existing conversation to continue chatting with other conference attendees.',
    ),
    FAQItem(
      question: 'How do I update my profile?',
      answer:
          'Go to your Profile tab and tap "Edit Profile". You can update your name, profile picture, and other information. Changes are saved automatically when you tap "Save".',
    ),
    FAQItem(
      question: 'I forgot my password. How do I reset it?',
      answer:
          'On the login screen, tap "Forgot Password" and enter your email address. You\'ll receive an email with instructions to reset your password. Alternatively, you can reset your password from the Edit Profile screen.',
    ),
    FAQItem(
      question: 'How do I scan a QR code for event check-in?',
      answer:
          'At events you attend there will be a QR code for you to scan to check in. You may also use QR codes to join school groups.',
    ),
    FAQItem(
      question: 'Can I delete my account?',
      answer:
          'Yes, you can delete your account from the Edit Profile screen. Tap "Delete Account" and confirm your decision. This action is permanent and cannot be undone. All your data will be permanently deleted.',
    ),
    FAQItem(
      question: 'How do I report inappropriate content?',
      answer:
          'If you encounter inappropriate content, please contact support immediately using the "Contact Support" option below. Include details about the content and we\'ll address it promptly.',
    ),
  ];

  Future<void> _launchEmail(
    String email, {
    String? subject,
    String? body,
  }) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open email client'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _contactSupport() async {
    await _launchEmail(
      'support@fblaconference.com',
      subject: 'FBLA Conference App - Support Request',
      body: 'Please describe your issue or question:\n\n',
    );
  }

  Future<void> _reportBug() async {
    await _launchEmail(
      'support@fblaconference.com',
      subject: 'FBLA Conference App - Bug Report',
      body:
          'Please describe the bug you encountered:\n\n1. What were you doing when the bug occurred?\n2. What did you expect to happen?\n3. What actually happened?\n4. Steps to reproduce (if applicable):\n\n',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 70,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppTheme.darkPrimary.withValues(alpha: 0.2),
                            AppTheme.darkSecondary.withValues(alpha: 0.1),
                          ]
                        : [
                            AppTheme.lightBlue,
                            AppTheme.lightBlue.withValues(alpha: 0.5),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 64,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We\'re here to help!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find answers to common questions or contact our support team',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.black,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.email_outlined,
                      title: 'Contact Support',
                      subtitle: 'Get help from our team',
                      onTap: _contactSupport,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.bug_report_outlined,
                      title: 'Report a Bug',
                      subtitle: 'Help us improve',
                      onTap: _reportBug,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // FAQ Section
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.black,
                ),
              ),
              const SizedBox(height: 12),
              ..._faqs.map((faq) => _buildFAQItem(faq, isDark)),

              const SizedBox(height: 24),

              // Additional Resources
              Text(
                'Additional Resources',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildResourceCard(
                icon: Icons.info_outline,
                title: 'About the App',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'FBLA Conference App',
                    applicationVersion: '1.0.0',
                    applicationIcon: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/logo.png',
                        height: 48,
                        width: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    children: [
                      Text(
                        'The official app for FBLA Conference attendees. '
                        'Connect with other members, manage your schedule, '
                        'trade pins, and stay updated with conference events.',
                      ),
                    ],
                  );
                },
                isDark: isDark,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkCard.withValues(alpha: 0.3)
              : AppTheme.lightGray,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: AppTheme.primaryBlue, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppTheme.mediumGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkCard.withValues(alpha: 0.3)
              : AppTheme.lightGray,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          title: Text(
            faq.question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          iconColor: AppTheme.primaryBlue,
          collapsedIconColor: AppTheme.primaryBlue,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq.answer,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.mediumGray,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkCard.withValues(alpha: 0.3)
              : AppTheme.lightGray,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlue),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : AppTheme.mediumGray,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.mediumGray),
        onTap: onTap,
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
