import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import 'create_test_screen.dart';
import 'test_results_screen.dart';
import 'teacher_profile_screen.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Glass App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ExamGuard', style: AppTheme.headlineSM.copyWith(color: AppTheme.emerald)),
                    GestureDetector(
                      onTap: () async {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area with AnimatedSwitcher
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _currentIndex == 0
                      ? _buildDashboardContent()
                      : const TeacherProfileScreen(key: ValueKey('profile')),
                ),
              ),
              
              // Bottom Nav
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.glassBackground,
                  border: Border(top: BorderSide(color: AppTheme.glassBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home_rounded, 'Home', 0),
                    _buildNavItem(Icons.add_circle_outline_rounded, 'Create', -1),
                    _buildNavItem(Icons.person_outline_rounded, 'Profile', 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      key: const ValueKey('dashboard'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Teacher'}! 👋', 
                      style: AppTheme.headlineLG, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 4),
                    Text('Manage your exams', style: AppTheme.bodyLG),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.emerald, width: 2),
                  color: AppTheme.emerald.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emerald.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.person_rounded, color: AppTheme.emerald, size: 32),
              ),
            ],
          ),
        ),

        // Create Test Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: EmeraldButton(
            label: 'Create New Test',
            icon: Icons.add_rounded,
            onPressed: () {
              Navigator.push(
                context,
                _buildPageRoute(const CreateTestScreen()),
              );
            },
          ),
        ),

        // Tests List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Tests', style: AppTheme.headlineMD),
            ],
          ),
        ),

        // Tests List with Pull-to-Refresh
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ref.read(databaseServiceProvider).getTeacherTests(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: AppTheme.bodyLG));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.emerald),
                );
              }

              var docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Empty state illustration
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.emerald.withValues(alpha: 0.06),
                          border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.15), width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 44, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 4),
                            Icon(Icons.add_circle_outline_rounded, size: 20, color: AppTheme.emerald.withValues(alpha: 0.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('No tests created yet', style: AppTheme.headlineSM.copyWith(color: AppTheme.textMuted)),
                      const SizedBox(height: 8),
                      Text('Tap "Create New Test" to get started!', style: AppTheme.bodySM),
                    ],
                  ),
                );
              }
              
              // Sort locally
              docs = docs.toList()..sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['createdAt'] as Timestamp?;
                final bTime = bData['createdAt'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime); // descending
              });

              return RefreshIndicator(
                color: AppTheme.emerald,
                backgroundColor: AppTheme.surfaceContainer,
                onRefresh: () async {
                  // StreamBuilder will automatically refresh, just add a small delay for UX
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final questions = data['questions'] as List<dynamic>? ?? [];
                    final testName = data['testName'] ?? 'Untitled Test';
                    final testId = data['testId'];
                    final isActive = data['isActive'] ?? true;
                    final durationMinutes = data['durationMinutes'] ?? 10;
                    
                    return GlassCard(
                      padding: const EdgeInsets.all(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          _buildPageRoute(
                            TestResultsScreen(testId: testId, testName: testName),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  testName,
                                  style: AppTheme.headlineSM,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Active/Closed Toggle
                              GestureDetector(
                                onTap: () async {
                                  final dbService = ref.read(databaseServiceProvider);
                                  await dbService.toggleTestStatus(testId, !isActive);
                                },
                                child: EmeraldChip(
                                  label: isActive ? 'Active' : 'Closed',
                                  backgroundColor: isActive
                                      ? AppTheme.emerald.withValues(alpha: 0.15)
                                      : AppTheme.error.withValues(alpha: 0.15),
                                  textColor: isActive ? AppTheme.emerald : AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Flexible(child: EmeraldChip(label: testId)),
                              const SizedBox(width: 10),
                              Text(
                                '${questions.length} Qs',
                                style: AppTheme.bodySM,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${durationMinutes}m',
                                style: AppTheme.bodySM,
                              ),
                              const Spacer(),
                              // Edit Button
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    _buildPageRoute(
                                      CreateTestScreen(
                                        existingTestId: testId,
                                        existingTestName: testName,
                                        existingDuration: durationMinutes,
                                        existingHasNegativeMarking: data['hasNegativeMarking'] ?? false,
                                        existingQuestions: questions.map<Map<String, dynamic>>((q) => Map<String, dynamic>.from(q as Map)).toList(),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emerald.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: AppTheme.emerald, size: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.emerald),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Animated page route
  Route _buildPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOutCubic));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == -1) {
          Navigator.push(
            context,
            _buildPageRoute(const CreateTestScreen()),
          );
        } else {
          setState(() => _currentIndex = index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.emerald.withValues(alpha: 0.15) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? AppTheme.emerald : AppTheme.textMuted,
              size: 24,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppTheme.emerald,
                shape: BoxShape.circle,
              ),
            )
          ]
        ],
      ),
    );
  }
}
