import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/school_service.dart';
import '../../models/user_model.dart';
import '../../models/school_model.dart';
import '../../theme/app_theme.dart';
import 'school_dashboard_screen.dart';
import 'school_selection_screen.dart';

class SchoolScreen extends StatefulWidget {
  const SchoolScreen({super.key});

  @override
  State<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> {
  final AuthService _authService = AuthService();
  final SchoolService _schoolService = SchoolService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
        body: Center(
          child: Text(
            'Please sign in to view your school',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
        ),
      );
    }

    return FutureBuilder<UserModel?>(
      future: _authService.getUserData(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor:
                isDark ? AppTheme.darkBackground : AppTheme.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor:
                isDark ? AppTheme.darkBackground : AppTheme.background,
            body: Center(
              child: Text(
                'Error loading school information',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.black,
                ),
              ),
            ),
          );
        }

        final userData = snapshot.data!;
        final schoolIds = userData.schoolIds;

        if (schoolIds.isEmpty) {
          return Scaffold(
            backgroundColor:
                isDark ? AppTheme.darkBackground : AppTheme.background,
            appBar: AppBar(
              title: const Text('My School'),
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 80,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.grey,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No School Joined',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Join a school to access school information, events, and resources.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SchoolSelectionScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Join a School'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppTheme.darkPrimary
                            : AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // If user has multiple schools, show selection
        if (schoolIds.length > 1) {
          return Scaffold(
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
            appBar: AppBar(
              title: const Text('My Schools'),
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            ),
            body: FutureBuilder<List<SchoolModel>>(
              future: Future.wait(
                schoolIds.map((id) async {
                  final school = await _schoolService.getSchool(id);
                  return school;
                }).toList(),
              ).then((results) => results.whereType<SchoolModel>().toList()),
              builder: (context, schoolsSnapshot) {
                if (schoolsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final schools = schoolsSnapshot.data ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schools.length,
                  itemBuilder: (context, index) {
                    final school = schools[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDark
                              ? AppTheme.darkPrimary
                              : AppTheme.primaryBlue,
                          child: Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          school.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.black,
                          ),
                        ),
                        subtitle: Text(
                          '${school.city}, ${school.state}',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppTheme.darkGray,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppTheme.mediumGray,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SchoolDashboardScreen(
                                schoolId: school.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          );
        }

        // Single school - show dashboard directly
        return SchoolDashboardScreen(schoolId: schoolIds.first);
      },
    );
  }
}

