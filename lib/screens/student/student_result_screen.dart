import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';

class StudentResultScreen extends StatelessWidget {
  final String testName;
  final String studentName;
  final int score;
  final int total; // Number of questions
  final int? maxScore; // Maximum possible points
  final List<dynamic> questions;
  final Map<int, String> selectedAnswers;
  final bool wasCheating;
  final bool wasTimeout;

  const StudentResultScreen({
    super.key,
    required this.testName,
    required this.studentName,
    required this.score,
    required this.total,
    this.maxScore,
    required this.questions,
    required this.selectedAnswers,
    this.wasCheating = false,
    this.wasTimeout = false,
  });

  double get percentage {
    int maxPts = maxScore ?? total;
    return maxPts > 0 ? (score / maxPts) * 100 : 0;
  }

  String get grade {
    if (wasCheating) return 'DQ';
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  Color get gradeColor {
    if (wasCheating) return AppTheme.error;
    if (percentage >= 80) return AppTheme.emerald;
    if (percentage >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: GlassBackground(
          child: SafeArea(
            child: Column(
              children: [
                GlassAppBar(
                  title: 'Exam Results',
                  showBack: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 16),
                      // Score Hero Card
                      _buildScoreCard(),
                      const SizedBox(height: 24),
                      // Stats Row
                      _buildStatsRow(),
                      const SizedBox(height: 32),
                      // Answer Review Header
                      if (!wasCheating) ...[
                        Row(
                          children: [
                            const Icon(Icons.fact_check_outlined, color: AppTheme.emerald),
                            const SizedBox(width: 8),
                            Text('Answer Review', style: AppTheme.headlineSM),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Question Review List
                        ...List.generate(questions.length, (index) => _buildQuestionReview(index)),
                        const SizedBox(height: 16),
                      ],
                      // Done Button
                      EmeraldButton(
                        label: 'Go Back Home',
                        icon: Icons.home_rounded,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return GlassCard(
      emeraldBorder: true,
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Status Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gradeColor.withValues(alpha: 0.15),
              border: Border.all(color: gradeColor.withValues(alpha: 0.4), width: 3),
              boxShadow: [
                BoxShadow(
                  color: gradeColor.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: wasCheating
                  ? const Icon(Icons.gpp_bad_rounded, color: AppTheme.error, size: 42)
                  : Text(
                      grade,
                      style: AppTheme.headlineXL.copyWith(
                        color: gradeColor,
                        fontSize: 28,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            wasCheating
                ? 'Test Terminated'
                : wasTimeout
                    ? 'Time\'s Up!'
                    : percentage >= 60
                        ? 'Well Done! 🎉'
                        : 'Keep Trying! 💪',
            style: AppTheme.headlineLG,
          ),
          const SizedBox(height: 8),
          Text(
            wasCheating
                ? 'You were disqualified for leaving the app.'
                : '$studentName, you scored $score out of $total',
            style: AppTheme.bodyLG,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Score Bar
          if (!wasCheating) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: LinearProgressIndicator(
                value: score / (total > 0 ? total : 1),
                backgroundColor: AppTheme.glassBorder,
                color: gradeColor,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTheme.headlineMD.copyWith(color: gradeColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    int correctCount = 0;
    int wrongCount = 0;
    int skippedCount = 0;

    for (int i = 0; i < questions.length; i++) {
      if (!selectedAnswers.containsKey(i)) {
        skippedCount++;
      } else if (selectedAnswers[i] == questions[i]['correctAnswer']) {
        correctCount++;
      } else {
        wrongCount++;
      }
    }

    return Row(
      children: [
        _buildStatItem('$correctCount', 'Correct', AppTheme.emerald, Icons.check_circle_rounded),
        const SizedBox(width: 12),
        _buildStatItem('$wrongCount', 'Wrong', AppTheme.error, Icons.cancel_rounded),
        const SizedBox(width: 12),
        _buildStatItem('$skippedCount', 'Skipped', AppTheme.textMuted, Icons.remove_circle_rounded),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: AppTheme.headlineMD.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(label, style: AppTheme.labelSM.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionReview(int index) {
    final q = questions[index];
    final correctAnswer = q['correctAnswer'];
    final selectedAnswer = selectedAnswers[index];
    final isCorrect = selectedAnswer == correctAnswer;
    final isSkipped = selectedAnswer == null;
    final options = q['options'] as List<dynamic>;

    final statusColor = isSkipped
        ? AppTheme.textMuted
        : isCorrect
            ? AppTheme.emerald
            : AppTheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: AppTheme.labelMD.copyWith(color: statusColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q['question'],
                      style: AppTheme.bodyLG.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    isSkipped
                        ? Icons.remove_circle_outline_rounded
                        : isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                    color: statusColor,
                    size: 24,
                  ),
                ],
              ),
            ),
            // Options
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: options.map<Widget>((option) {
                  final optionStr = option.toString();
                  final isThisCorrect = optionStr == correctAnswer;
                  final isThisSelected = optionStr == selectedAnswer;

                  Color optionBg = Colors.transparent;
                  Color optionBorder = AppTheme.glassBorder;
                  Color optionText = AppTheme.textSecondary;
                  IconData? optionIcon;

                  if (isThisCorrect) {
                    optionBg = AppTheme.emerald.withValues(alpha: 0.1);
                    optionBorder = AppTheme.emerald.withValues(alpha: 0.5);
                    optionText = AppTheme.emerald;
                    optionIcon = Icons.check_circle_rounded;
                  } else if (isThisSelected && !isThisCorrect) {
                    optionBg = AppTheme.error.withValues(alpha: 0.1);
                    optionBorder = AppTheme.error.withValues(alpha: 0.5);
                    optionText = AppTheme.error;
                    optionIcon = Icons.cancel_rounded;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: optionBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: optionBorder),
                    ),
                    child: Row(
                      children: [
                        if (optionIcon != null) ...[
                          Icon(optionIcon, color: optionText, size: 18),
                          const SizedBox(width: 10),
                        ] else ...[
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.textMuted, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            optionStr,
                            style: AppTheme.bodyMD.copyWith(color: optionText),
                          ),
                        ),
                        if (isThisCorrect)
                          Text('Correct', style: AppTheme.labelSM.copyWith(color: AppTheme.emerald, fontWeight: FontWeight.w700)),
                        if (isThisSelected && !isThisCorrect)
                          Text('Your Answer', style: AppTheme.labelSM.copyWith(color: AppTheme.error, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
