import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';

class TestResultsScreen extends ConsumerWidget {
  final String testId;
  final String testName;

  const TestResultsScreen({
    super.key,
    required this.testId,
    required this.testName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Custom Glass App Bar
              GlassAppBar(
                titleWidget: Text(
                  '$testName - Results',
                  style: AppTheme.headlineSM,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error.withValues(alpha: 0.8)),
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
              
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: ref.read(databaseServiceProvider).getTestResults(testId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: AppTheme.bodyLG));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.emerald));
                    }

                    var docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.emerald.withValues(alpha: 0.06),
                                border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.15), width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline_rounded, size: 40, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                                  const SizedBox(height: 4),
                                  Icon(Icons.hourglass_empty_rounded, size: 20, color: AppTheme.emerald.withValues(alpha: 0.5)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text('No results yet', style: AppTheme.headlineSM.copyWith(color: AppTheme.textMuted)),
                            const SizedBox(height: 8),
                            Text('Waiting for students to take the test...', style: AppTheme.bodySM),
                          ],
                        ),
                      );
                    }
                    
                    // Sort locally by score descending
                    docs = docs.toList()..sort((a, b) {
                      final aScore = (a.data() as Map)['score'] as int? ?? 0;
                      final bScore = (b.data() as Map)['score'] as int? ?? 0;
                      return bScore.compareTo(aScore);
                    });
                    
                    // Calculate stats
                    int totalStudents = docs.length;
                    int totalQuestions = docs.isNotEmpty ? ((docs.first.data() as Map)['total'] as int? ?? 0) : 0;
                    double avgScore = docs.fold(0.0, (sum, doc) => sum + ((doc.data() as Map)['score'] as int? ?? 0)) / (totalStudents > 0 ? totalStudents : 1);

                    return Column(
                      children: [
                        // Summary Card
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(testName, style: AppTheme.headlineLG, overflow: TextOverflow.ellipsis, maxLines: 1)),
                                    const SizedBox(width: 8),
                                    EmeraldChip(label: testId, backgroundColor: AppTheme.emerald.withValues(alpha: 0.1)),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    _buildStatCard('${totalQuestions > 0 ? totalQuestions : "-"}', 'Questions', Icons.assignment_outlined),
                                    const SizedBox(width: 12),
                                    _buildStatCard('$totalStudents', 'Students', Icons.people_outline_rounded),
                                    const SizedBox(width: 12),
                                    _buildStatCard(avgScore.toStringAsFixed(1), 'Avg Score', Icons.analytics_outlined),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Leaderboard Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events_outlined, color: AppTheme.emerald),
                              const SizedBox(width: 8),
                              Text('Student Rankings', style: AppTheme.headlineSM),
                            ],
                          ),
                        ),
                        
                        // Results List
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                            itemCount: docs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final score = data['score'] as int? ?? 0;
                              final total = data['total'] as int? ?? 0;
                              final maxScore = data['maxScore'] as int? ?? total;
                              final isCheating = score == 0; // Simplified cheating detection mapping for demo
                              
                              Color cardBorderColor = index == 0 ? AppTheme.warning.withValues(alpha: 0.5) // Gold for 1st
                                  : isCheating ? AppTheme.error.withValues(alpha: 0.5) 
                                  : AppTheme.glassBorder;

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: cardBorderColor),
                                  boxShadow: index == 0 
                                      ? [BoxShadow(color: AppTheme.warning.withValues(alpha: 0.1), blurRadius: 10)]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // Rank Badge
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isCheating 
                                            ? AppTheme.error.withValues(alpha: 0.1)
                                            : AppTheme.emerald.withValues(alpha: index == 0 ? 0.2 : 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        isCheating ? '-' : '${index + 1}',
                                        style: AppTheme.headlineSM.copyWith(
                                          color: isCheating ? AppTheme.error : AppTheme.emerald,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Student Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['studentName'] ?? 'Unknown Student',
                                            style: AppTheme.labelMD,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          if (isCheating)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.error,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text('CHEATING DETECTED', style: AppTheme.labelSM.copyWith(color: Colors.white, fontSize: 9)),
                                            )
                                          else
                                            Text(
                                              'Submitted: ${data['submittedAt'] != null ? _formatTime(data['submittedAt'] as Timestamp) : 'N/A'}',
                                              style: AppTheme.bodySM,
                                            ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Score
                                    Row(
                                      children: [
                                        Text(
                                          '$score/$maxScore',
                                          style: AppTheme.headlineSM.copyWith(
                                            color: isCheating ? AppTheme.error : AppTheme.emerald,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Bottom Actions — Export Results
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: EmeraldButton(
                            label: 'Export & Copy Results',
                            icon: Icons.content_copy_rounded,
                            onPressed: () {
                              _exportResults(context, docs, testName, testId, totalStudents, totalQuestions, avgScore);
                            },
                          ),
                        ),
                      ],
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

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.emerald, size: 24),
            const SizedBox(height: 8),
            Text(value, style: AppTheme.headlineSM),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: AppTheme.bodySM, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(Timestamp ts) {
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        title: Text('Delete Test?', style: AppTheme.headlineSM),
        content: Text('Are you sure you want to delete this test and all its results? This cannot be undone.', style: AppTheme.bodyLG),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('Cancel', style: AppTheme.labelMD)
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(databaseServiceProvider).deleteTest(testId);
                if (context.mounted) {
                  Navigator.pop(context); // Go back to dashboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test deleted.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: Text('Delete', style: AppTheme.labelMD.copyWith(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _exportResults(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
    String name,
    String id,
    int totalStudents,
    int totalQuestions,
    double avgScore,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 ExamGuard — Test Results');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📝 Test: $name');
    buffer.writeln('🔑 Code: $id');
    buffer.writeln('👥 Students: $totalStudents');
    buffer.writeln('❓ Questions: $totalQuestions');
    buffer.writeln('📊 Average: ${avgScore.toStringAsFixed(1)}/$totalQuestions');
    buffer.writeln('');
    buffer.writeln('┌──────────────────────────────');
    buffer.writeln('│ Rank │ Student │ Score');
    buffer.writeln('├──────────────────────────────');

    for (int i = 0; i < docs.length; i++) {
      final data = docs[i].data() as Map<String, dynamic>;
      final studentName = data['studentName'] ?? 'Unknown';
      final score = data['score'] ?? 0;
      final total = data['total'] ?? 0;
      final maxScore = data['maxScore'] ?? total;
      final pct = maxScore > 0 ? ((score / maxScore) * 100).toStringAsFixed(0) : '0';
      buffer.writeln('│ ${(i + 1).toString().padLeft(2)}   │ $studentName │ $score/$maxScore ($pct%)');
    }
    
    buffer.writeln('└──────────────────────────────');
    buffer.writeln('');
    buffer.writeln('Generated by ExamGuard App');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Results copied to clipboard! Paste in WhatsApp, Email, etc.'),
        backgroundColor: AppTheme.emerald,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
