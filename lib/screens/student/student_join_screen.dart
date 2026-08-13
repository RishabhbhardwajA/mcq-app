import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import 'test_screen.dart';

class StudentJoinScreen extends ConsumerStatefulWidget {
  const StudentJoinScreen({super.key});

  @override
  ConsumerState<StudentJoinScreen> createState() => _StudentJoinScreenState();
}

class _StudentJoinScreenState extends ConsumerState<StudentJoinScreen> {
  final _testCodeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authServiceProvider).currentUser;
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      _nameController.text = displayName;
    }
  }

  void _joinTest() async {
    final code = _testCodeController.text.trim();
    final name = _nameController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 6-digit code'),
          backgroundColor: AppTheme.warning.withValues(alpha: 0.9),
        ),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your full name'),
          backgroundColor: AppTheme.warning.withValues(alpha: 0.9),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dbService = ref.read(databaseServiceProvider);
      final test = await dbService.getTest(code);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (test != null) {
          // Check if test is active
          final isActive = test['isActive'] ?? true;
          if (!isActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('This test has been closed by the teacher.'),
                backgroundColor: AppTheme.error,
              ),
            );
            return;
          }

          // Check for duplicate attempt
          final alreadyAttempted = await dbService.hasStudentAlreadyAttempted(code, name);
          if (alreadyAttempted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name has already taken this test. You cannot retake it.'),
                  backgroundColor: AppTheme.error,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return;
          }
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudentTestScreen(testId: code, studentName: name),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Test not found! Please check the code.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining test: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    
    if (kIsWeb || !isMobile) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: GlassBackground(
          child: SafeArea(
            child: Column(
              children: [
                const GlassAppBar(title: 'ExamGuard', showBack: true),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: GlassCard(
                        emeraldBorder: true,
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: AppTheme.warning, size: 48),
                            const SizedBox(height: 20),
                            Text('Exams Blocked on this Device', style: AppTheme.headlineLG, textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text(
                              'To ensure a secure environment, exams can ONLY be taken from the Mobile App (Android/iOS).',
                              style: AppTheme.bodyLG,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              const GlassAppBar(title: 'ExamGuard'),
              
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        GlassCard(
                          emeraldBorder: true,
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.emerald.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.emerald.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.person_rounded, color: AppTheme.emerald, size: 36),
                              ),
                              const SizedBox(height: 24),
                              
                              // Heading
                              Text('Join Exam', style: AppTheme.headlineLG),
                              const SizedBox(height: 8),
                              Text('Enter your details to start', style: AppTheme.bodyLG),
                              const SizedBox(height: 32),

                              // Inputs
                              GlassTextField(
                                controller: _nameController,
                                hintText: 'Your Full Name',
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 16),
                              GlassTextField(
                                controller: _testCodeController,
                                hintText: 'Test Code (6 digits)',
                                prefixIcon: Icons.key_rounded,
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 6,
                              ),
                              const SizedBox(height: 32),

                              // CTA
                              EmeraldButton(
                                label: 'Start Exam →',
                                isLoading: _isLoading,
                                onPressed: _joinTest,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Text(
                          'Ask your teacher for the test code',
                          style: AppTheme.bodySM,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
