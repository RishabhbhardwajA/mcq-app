import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'core/auth/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/glass_widgets.dart';
import 'screens/auth/teacher_auth_screen.dart';
import 'screens/auth/student_auth_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Environment Variables
  await dotenv.load(fileName: ".env", isOptional: true);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MCQExamApp()));
}

class MCQExamApp extends StatelessWidget {
  const MCQExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExamGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.emerald)),
      ),
      error: (_, __) => const RoleSelectionScreen(),
      data: (user) {
        if (user == null) return const RoleSelectionScreen();

        return FutureBuilder<String>(
          future: ref.read(authServiceProvider).getCurrentUserRole(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                backgroundColor: AppTheme.background,
                body: Center(
                  child: CircularProgressIndicator(color: AppTheme.emerald),
                ),
              );
            }

            return snapshot.data == 'student'
                ? const StudentDashboard()
                : const TeacherDashboard();
          },
        );
      },
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo with glow
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.emerald.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.emerald.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 44,
                    color: AppTheme.emerald,
                  ),
                ),

                const SizedBox(height: 20),

                // App Name
                Text(
                  'ExamGuard',
                  style: AppTheme.headlineXL.copyWith(
                    shadows: [
                      Shadow(
                        color: AppTheme.emerald.withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Secure Online Exams',
                  style: AppTheme.bodyLG.copyWith(color: AppTheme.mint),
                ),

                const Spacer(),

                // Teacher Card
                GlassCard(
                  emeraldBorder: true,
                  padding: const EdgeInsets.all(24),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeacherAuthScreen()),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.emerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.school_rounded, color: AppTheme.emerald, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('I am a Teacher', style: AppTheme.headlineSM),
                            const SizedBox(height: 4),
                            Text('Create & manage MCQ tests', style: AppTheme.bodySM),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.emerald, size: 18),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (!kIsWeb)
                  GlassCard(
                    emeraldBorder: true,
                    padding: const EdgeInsets.all(24),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentAuthScreen()),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.mint.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: AppTheme.mint, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('I am a Student', style: AppTheme.headlineSM),
                              const SizedBox(height: 4),
                              Text('Login, join tests, view results', style: AppTheme.bodySM),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.mint, size: 18),
                      ],
                    ),
                  ),
                if (kIsWeb)
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppTheme.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Student exam mode is disabled on the website. Use the mobile or desktop app for student attempts.',
                            style: AppTheme.bodySM,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.textMuted, size: 14),
                    const SizedBox(width: 6),
                    Text('Powered by AI', style: AppTheme.labelSM),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
