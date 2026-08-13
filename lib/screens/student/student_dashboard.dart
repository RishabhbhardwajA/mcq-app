import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import 'student_join_screen.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'Student';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hi, $name',
                        style: AppTheme.headlineSM.copyWith(
                          color: AppTheme.emerald,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(authServiceProvider).signOut(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppTheme.error,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: EmeraldButton(
                  label: 'Join New Test',
                  icon: Icons.play_circle_outline_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentJoinScreen()),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, color: AppTheme.emerald),
                    const SizedBox(width: 8),
                    Text('Past Results', style: AppTheme.headlineSM),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: ref.read(databaseServiceProvider).getCurrentStudentResults(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: AppTheme.bodyLG,
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.emerald),
                      );
                    }

                    var docs = snapshot.data?.docs ?? [];
                    docs = docs.toList()
                      ..sort((a, b) {
                        final aTime = (a.data() as Map)['submittedAt'] as Timestamp?;
                        final bTime = (b.data() as Map)['submittedAt'] as Timestamp?;
                        if (aTime == null || bTime == null) return 0;
                        return bTime.compareTo(aTime);
                      });

                    if (docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: GlassCard(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fact_check_outlined,
                                  color: AppTheme.textMuted.withValues(alpha: 0.7),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No past results yet',
                                  style: AppTheme.headlineSM.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your submitted tests will appear here.',
                                  style: AppTheme.bodySM,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final testName = data['testName'] ?? 'Exam';
                        final testId = data['testId'] ?? '';
                        final score = data['score'] as int? ?? 0;
                        final total = data['total'] as int? ?? 0;
                        final maxScore = data['maxScore'] as int? ?? total;
                        final double pct =
                            maxScore > 0 ? (score / maxScore) * 100 : 0.0;

                        return GlassCard(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _scoreColor(pct).withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: _scoreColor(pct).withValues(alpha: 0.35),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${pct.toStringAsFixed(0)}%',
                                  style: AppTheme.labelMD.copyWith(
                                    color: _scoreColor(pct),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      testName.toString(),
                                      style: AppTheme.labelMD,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Code: $testId',
                                      style: AppTheme.bodySM,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$score/$maxScore',
                                style: AppTheme.headlineSM.copyWith(
                                  color: _scoreColor(pct),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(num pct) {
    if (pct >= 80) return AppTheme.emerald;
    if (pct >= 50) return AppTheme.warning;
    return AppTheme.error;
  }
}
