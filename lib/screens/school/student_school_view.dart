import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/school_model.dart';
import '../../models/announcement_model.dart';
import '../../models/school_event_model.dart';
import '../../models/school_resource_model.dart';
import '../../services/school_service.dart';

class StudentSchoolView extends StatefulWidget {
  final String schoolId;

  const StudentSchoolView({
    super.key,
    required this.schoolId,
  });

  @override
  State<StudentSchoolView> createState() => _StudentSchoolViewState();
}

class _StudentSchoolViewState extends State<StudentSchoolView> with SingleTickerProviderStateMixin {
  final _schoolService = SchoolService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<SchoolModel?>(
      stream: _schoolService.getSchoolStream(widget.schoolId),
      builder: (context, schoolSnapshot) {
        if (!schoolSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final school = schoolSnapshot.data!;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.offWhite,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    school.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Color.fromARGB(128, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.deepPurple,
                          Colors.purple[700]!,
                        ],
                      ),
                    ),
                    child: school.bannerUrl != null
                        ? Image.network(school.bannerUrl!, fit: BoxFit.cover)
                        : null,
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.home), text: 'Home'),
                    Tab(icon: Icon(Icons.campaign), text: 'News'),
                    Tab(icon: Icon(Icons.event), text: 'Events'),
                    Tab(icon: Icon(Icons.link), text: 'Resources'),
                  ],
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHomeTab(school),
                    _buildAnnouncementsTab(),
                    _buildEventsTab(),
                    _buildResourcesTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeTab(SchoolModel school) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          school.fullAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (school.socialMediaLinks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect With Us',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...school.socialMediaLinks.entries.map((entry) {
                      IconData icon;
                      Color color;
                      
                      switch (entry.key) {
                        case 'facebook':
                          icon = Icons.facebook;
                          color = const Color(0xFF1877F2);
                          break;
                        case 'twitter':
                          icon = Icons.close;
                          color = const Color(0xFF1DA1F2);
                          break;
                        case 'instagram':
                          icon = Icons.camera_alt;
                          color = const Color(0xFFE4405F);
                          break;
                        default:
                          icon = Icons.language;
                          color = AppTheme.primaryBlue;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(icon, color: color),
                          title: Text(entry.key.toUpperCase()),
                          trailing: const Icon(Icons.open_in_new, size: 16),
                          onTap: () => _launchUrl(entry.value),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 32,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${school.memberIds.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Members',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<AnnouncementModel>>(
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
                Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No announcements yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                          if (announcement.isPinned) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.push_pin, size: 16, color: Colors.amber),
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
                      Text(
                        DateFormat('MMM d, yyyy').format(announcement.postedAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<SchoolEventModel>>(
      stream: _schoolService.getSchoolEvents(widget.schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No events scheduled',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final isUpcoming = event.startTime.isAfter(DateTime.now());
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUpcoming 
                                ? Colors.purple.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.event,
                            color: isUpcoming ? Colors.purple : Colors.grey,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (event.location != null)
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      event.location!,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(event.startTime),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResourcesTab() {
    return StreamBuilder<List<SchoolResourceModel>>(
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
                Icon(Icons.link_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No resources available',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.link, color: Colors.green),
                ),
                title: Text(
                  resource.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
