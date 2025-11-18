import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/announcement_model.dart';
import '../../services/school_service.dart';

class SchoolAnnouncementsScreen extends StatefulWidget {
  final String schoolId;

  const SchoolAnnouncementsScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<SchoolAnnouncementsScreen> createState() => _SchoolAnnouncementsScreenState();
}

class _SchoolAnnouncementsScreenState extends State<SchoolAnnouncementsScreen> {
  final _schoolService = SchoolService();

  Future<void> _createAnnouncement() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'School News';
    bool isPinned = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'School News',
                    'Events',
                    'Academic',
                    'Sports',
                    'Important',
                  ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) {
                    setState(() => category = value ?? 'School News');
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Pin this announcement'),
                  value: isPinned,
                  onChanged: (value) {
                    setState(() => isPinned = value ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  await _schoolService.createSchoolAnnouncement(
                    schoolId: widget.schoolId,
                    title: titleController.text.trim(),
                    content: contentController.text.trim(),
                    postedBy: FirebaseAuth.instance.currentUser!.uid,
                    category: category,
                    isPinned: isPinned,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Announcement created'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('School Announcements'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAnnouncement,
        icon: const Icon(Icons.add),
        label: const Text('New Announcement'),
      ),
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: _schoolService.getSchoolAnnouncements(widget.schoolId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No announcements yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create one to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final announcements = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.deepPurple.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepPurple.withOpacity(0.05),
                        Colors.purple.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 14,
                                    color: Colors.deepPurple[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SCHOOL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? AppTheme.darkCard 
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                announcement.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (announcement.isPinned) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.push_pin,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          announcement.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          announcement.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, yyyy').format(announcement.postedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
