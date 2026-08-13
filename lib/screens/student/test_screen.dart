import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/security/security_manager.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import 'student_result_screen.dart';

class StudentTestScreen extends ConsumerStatefulWidget {
  final String testId;
  final String studentName;
  const StudentTestScreen({super.key, required this.testId, required this.studentName});

  @override
  ConsumerState<StudentTestScreen> createState() => _StudentTestScreenState();
}

class _StudentTestScreenState extends ConsumerState<StudentTestScreen> with WidgetsBindingObserver {
  
  bool _isTestActive = true;
  bool _isLoading = true;
  Map<String, dynamic>? _testData;
  final Map<int, String> _selectedAnswers = {};
  
  Timer? _timer;
  int _remainingSeconds = 0;
  
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSecurity();
    _loadTest();
  }

  Future<void> _loadTest() async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      final test = await dbService.getTest(widget.testId);
      if (mounted) {
        setState(() {
          // Shuffle logic
          if (test != null && test['questions'] != null) {
            List<dynamic> questionsList = List<dynamic>.from(test['questions']);
            questionsList.shuffle();
            
            for (var q in questionsList) {
              if (q is Map && q['options'] != null) {
                List<dynamic> options = List<dynamic>.from(q['options']);
                options.shuffle();
                q['options'] = options;
              }
            }
            test['questions'] = questionsList;
          }
          
          _testData = test;
          _isLoading = false;
          int minutes = test?['durationMinutes'] ?? 10;
          _remainingSeconds = minutes * 60;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading test: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.error));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeSecurity() async {
    await SecurityManager.enableExamSecurity();
    WakelockPlus.enable();
    BrowserContextMenu.disableContextMenu();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0 && _isTestActive) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        if (_isTestActive) {
          _submitTest(isCheating: false, isTimeout: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    SecurityManager.disableExamSecurity();
    WakelockPlus.disable();
    BrowserContextMenu.enableContextMenu();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isTestActive) return;

    // inactive = switching apps, paused = app in background, hidden = tab switch on web
    if (state == AppLifecycleState.inactive || 
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _autoSubmitAndEndTest();
    }
  }

  void _autoSubmitAndEndTest() {
    setState(() {
      _isTestActive = false;
    });
    
    _submitTest(isCheating: true);
  }

  void _submitTest({bool isCheating = false, bool isTimeout = false}) async {
    if (_testData == null || !_isTestActive) return;
    
    setState(() => _isTestActive = false);
    _timer?.cancel();
    
    final questions = _testData!['questions'] as List<dynamic>;
    bool hasNegativeMarking = _testData!['hasNegativeMarking'] ?? false;
    int score = 0;
    int maxScore = questions.length * (hasNegativeMarking ? 4 : 1);

    if (!isCheating) {
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        if (_selectedAnswers[i] == q['correctAnswer']) {
          score += hasNegativeMarking ? 4 : 1;
        } else if (hasNegativeMarking && _selectedAnswers.containsKey(i)) {
          score -= 1;
        }
      }
    } else {
      score = 0;
    }

    try {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.submitResult(widget.testId, widget.studentName, score, questions.length, maxScore: maxScore);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StudentResultScreen(
              testName: _testData!['testName'] ?? 'Exam',
              studentName: widget.studentName,
              score: score,
              total: questions.length,
              maxScore: maxScore,
              questions: questions,
              selectedAnswers: Map<int, String>.from(_selectedAnswers),
              wasCheating: isCheating,
              wasTimeout: isTimeout,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Submit error: $e');
    }
  }

  void _nextPage() {
    if (_currentPage < (_testData!['questions'] as List).length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.emerald)),
      );
    }
    
    if (_testData == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: const GlassAppBar(title: 'Error'),
        body: Center(child: Text('Test not found!', style: AppTheme.headlineSM)),
      );
    }

    final questions = _testData!['questions'] as List<dynamic>;
    final totalQ = questions.length;

    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You cannot go back during an active test!'),
            backgroundColor: AppTheme.error,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: GlassBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, color: AppTheme.emerald),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testData!['testName'] ?? 'Active Exam',
                          style: AppTheme.headlineSM,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Timer Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _remainingSeconds <= 60
                              ? AppTheme.error.withValues(alpha: 0.15)
                              : AppTheme.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: _remainingSeconds <= 60
                                ? AppTheme.error.withValues(alpha: 0.5)
                                : AppTheme.emerald.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: _remainingSeconds <= 60 ? AppTheme.error : AppTheme.emerald,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                              style: AppTheme.labelMD.copyWith(
                                color: _remainingSeconds <= 60 ? AppTheme.error : AppTheme.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Progress', style: AppTheme.labelSM),
                          Text('Q${_currentPage + 1} of $totalQ', style: AppTheme.labelSM.copyWith(color: AppTheme.emerald)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (_currentPage + 1) / totalQ,
                        backgroundColor: AppTheme.glassBorder,
                        color: AppTheme.emerald,
                        borderRadius: BorderRadius.circular(50),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
                
                // Question Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    itemCount: totalQ,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      final options = q['options'] as List<dynamic>;
                      
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            GlassCard(
                              emeraldBorder: true,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  EmeraldChip(
                                    label: 'Question ${index + 1}',
                                    backgroundColor: AppTheme.emerald.withValues(alpha: 0.1),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    q['question'],
                                    style: AppTheme.bodyLG.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: options.length,
                              separatorBuilder: (context, i) => const SizedBox(height: 12),
                              itemBuilder: (context, optIdx) {
                                final option = options[optIdx].toString();
                                final isSelected = _selectedAnswers[index] == option;
                                
                                return GestureDetector(
                                  onTap: _isTestActive ? () {
                                    setState(() {
                                      // Toggle: tap again to deselect
                                      if (_selectedAnswers[index] == option) {
                                        _selectedAnswers.remove(index);
                                      } else {
                                        _selectedAnswers[index] = option;
                                      }
                                    });
                                  } : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.emerald.withValues(alpha: 0.1) : AppTheme.glassBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? AppTheme.emerald : AppTheme.glassBorder,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? AppTheme.emerald : AppTheme.textMuted,
                                              width: 2,
                                            ),
                                            color: isSelected ? AppTheme.emerald : Colors.transparent,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            option,
                                            style: AppTheme.bodyMD.copyWith(
                                              color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Bottom Navigation
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    border: Border(top: BorderSide(color: AppTheme.glassBorder)),
                  ),
                  child: Column(
                    children: [
                      // Question Navigator Button + Dots
                      GestureDetector(
                        onTap: () => _showQuestionNavigator(totalQ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.grid_view_rounded, color: AppTheme.emerald, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedAnswers.length}/$totalQ Answered',
                                style: AppTheme.labelSM.copyWith(color: AppTheme.emerald),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_up_rounded, color: AppTheme.emerald, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: GlassButton(
                              label: 'Previous',
                              icon: Icons.arrow_back_rounded,
                              onPressed: _currentPage > 0 ? _prevPage : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _currentPage == totalQ - 1
                                ? EmeraldButton(
                                    label: 'Submit Exam',
                                    icon: Icons.check_circle_outline_rounded,
                                    onPressed: _isTestActive ? () => _showSubmitConfirmation(totalQ) : null,
                                  )
                                : EmeraldButton(
                                    label: 'Next',
                                    icon: Icons.arrow_forward_rounded,
                                    onPressed: _nextPage,
                                  ),
                          ),
                        ],
                      ),
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

  void _showSubmitConfirmation(int totalQ) {
    final answeredCount = _selectedAnswers.length;
    final unansweredCount = totalQ - answeredCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.glassBorder),
        ),
        title: Row(
          children: [
            Icon(
              unansweredCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: unansweredCount > 0 ? AppTheme.warning : AppTheme.emerald,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                unansweredCount > 0 ? 'Unanswered Questions!' : 'Submit Exam?',
                style: AppTheme.headlineSM,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unansweredCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      '$unansweredCount',
                      style: AppTheme.headlineLG.copyWith(color: AppTheme.warning),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'questions are still unanswered. They will be marked as wrong.',
                        style: AppTheme.bodyMD,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                _buildConfirmStat('$answeredCount', 'Answered', AppTheme.emerald),
                const SizedBox(width: 12),
                _buildConfirmStat('$unansweredCount', 'Skipped', unansweredCount > 0 ? AppTheme.warning : AppTheme.textMuted),
                const SizedBox(width: 12),
                _buildConfirmStat('$totalQ', 'Total', AppTheme.mint),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to submit?',
              style: AppTheme.bodyLG,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Go Back', style: AppTheme.labelMD.copyWith(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitTest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: unansweredCount > 0 ? AppTheme.warning : AppTheme.emerald,
            ),
            child: Text(
              'Submit',
              style: AppTheme.labelMD.copyWith(color: const Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: AppTheme.headlineSM.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.labelSM.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  void _showQuestionNavigator(int totalQ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.grid_view_rounded, color: AppTheme.emerald),
                  const SizedBox(width: 8),
                  Text('Jump to Question', style: AppTheme.headlineSM),
                ],
              ),
              const SizedBox(height: 8),
              // Legend
              Row(
                children: [
                  _buildLegendDot(AppTheme.emerald, 'Current'),
                  const SizedBox(width: 16),
                  _buildLegendDot(AppTheme.mint, 'Answered'),
                  const SizedBox(width: 16),
                  _buildLegendDot(AppTheme.textMuted, 'Unanswered'),
                ],
              ),
              const SizedBox(height: 20),
              // Grid
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                itemCount: totalQ,
                itemBuilder: (context, index) {
                  final isCurrent = _currentPage == index;
                  final isAnswered = _selectedAnswers.containsKey(index);

                  Color bgColor = AppTheme.glassBackground;
                  Color borderColor = AppTheme.glassBorder;
                  Color textColor = AppTheme.textMuted;

                  if (isCurrent) {
                    bgColor = AppTheme.emerald.withValues(alpha: 0.2);
                    borderColor = AppTheme.emerald;
                    textColor = AppTheme.emerald;
                  } else if (isAnswered) {
                    bgColor = AppTheme.mint.withValues(alpha: 0.1);
                    borderColor = AppTheme.mint.withValues(alpha: 0.4);
                    textColor = AppTheme.mint;
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: AppTheme.labelMD.copyWith(color: textColor),
                      ),
                    ),
                  );
                },
              ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.labelSM.copyWith(color: color)),
      ],
    );
  }
}
