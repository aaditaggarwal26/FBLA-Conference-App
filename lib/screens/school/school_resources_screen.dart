import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/school_resource_model.dart';
import '../../services/school_service.dart';

class SchoolResourcesScreen extends StatefulWidget {
  final String schoolId;

  const SchoolResourcesScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<SchoolResourcesScreen> createState() => _SchoolResourcesScreenState();
}

class _SchoolResourcesScreenState extends State<SchoolResourcesScreen> {
  final _schoolService = SchoolService();

  Future<void> _createResource() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    String resourceType = 'link';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Resource'),
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
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: resourceType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'link', child: Text('Web Link')),
                    const DropdownMenuItem(value: 'document', child: Text('Document')),
                    const DropdownMenuItem(value: 'video', child: Text('Video')),
                    const DropdownMenuItem(value: 'social', child: Text('Social Media')),
                    const DropdownMenuItem(value: 'calendar', child: Text('Calendar')),
                  ],
                  onChanged: (value) {
                    setState(() => resourceType = value ?? 'link');
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
                if (titleController.text.isEmpty || 
                    descriptionController.text.isEmpty || 
                    urlController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  await _schoolService.createSchoolResource(
                    schoolId: widget.schoolId,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    url: urlController.text.trim(),
                    type: resourceType,
                    createdBy: FirebaseAuth.instance.currentUser!.uid,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Resource added successfully'),
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'document':
        return Icons.description;
      case 'video':
        return Icons.videocam;
      case 'social':
        return Icons.share;
      case 'calendar':
        return Icons.calendar_today;
      default:
        return Icons.link;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'document':
        return Colors.blue;
      case 'video':
        return Colors.red;
      case 'social':
        return Colors.purple;
      case 'calendar':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('School Resources'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createResource,
        icon: const Icon(Icons.add),
        label: const Text('Add Resource'),
      ),
      body: StreamBuilder<List<SchoolResourceModel>>(
        stream: _schoolService.getSchoolResources(widget.schoolId),
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
                    Icons.link_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No resources yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your first resource',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final resources = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: resources.length,
            itemBuilder: (context, index) {
              final resource = resources[index];
              final icon = _getIconForType(resource.type);
              final color = _getColorForType(resource.type);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () => _launchUrl(resource.url),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(
                    resource.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    resource.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
