import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import '../teacher/teacher_dashboard.dart';

class TeacherAuthScreen extends ConsumerStatefulWidget {
  const TeacherAuthScreen({super.key});

  @override
  ConsumerState<TeacherAuthScreen> createState() => _TeacherAuthScreenState();
}

class _TeacherAuthScreenState extends ConsumerState<TeacherAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _superPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureSuperPassword = true;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    
    if (email.isEmpty || password.isEmpty) return;
    if (!_isLogin && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your Full Name.'),
          backgroundColor: AppTheme.warning.withValues(alpha: 0.9),
        ),
      );
      return;
    }

    // Super password validation for registration
    if (!_isLogin) {
      final superPassword = _superPasswordController.text.trim();
      final expectedSuperPassword = dotenv.env['SUPER_PASSWORD'] ?? '';
      
      if (superPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter the Super Password to register.'),
            backgroundColor: AppTheme.warning.withValues(alpha: 0.9),
          ),
        );
        return;
      }
      
      if (superPassword != expectedSuperPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid Super Password. Contact your admin to get the password.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      if (_isLogin) {
        await authService.signInWithEmail(email, password);
      } else {
        await authService.registerWithEmail(email, password, name);
      }
      
      // Navigate to Teacher Dashboard on success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully authenticated!')),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherDashboard()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email first.'),
          backgroundColor: AppTheme.warning.withValues(alpha: 0.9),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              const GlassAppBar(title: "ExamGuard"),
              
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: GlassCard(
                      emeraldBorder: true,
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Avatar Icon
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
                            child: const Icon(Icons.school_rounded, color: AppTheme.emerald, size: 36),
                          ),
                          const SizedBox(height: 20),
                          
                          // Headings
                          Text(
                            _isLogin ? 'Welcome Back' : 'Create Account',
                            style: AppTheme.headlineLG,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin ? 'Sign in to continue' : 'Register to get started',
                            style: AppTheme.bodyLG,
                          ),
                          const SizedBox(height: 32),

                          // Tab Switcher
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF), // slightly lighter
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isLogin = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _isLogin ? AppTheme.emerald : Colors.transparent,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Login',
                                        style: AppTheme.labelMD.copyWith(
                                          color: _isLogin ? const Color(0xFF003120) : AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isLogin = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_isLogin ? AppTheme.emerald : Colors.transparent,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Register',
                                        style: AppTheme.labelMD.copyWith(
                                          color: !_isLogin ? const Color(0xFF003120) : AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Inputs
                          if (!_isLogin) ...[
                            GlassTextField(
                              controller: _nameController,
                              hintText: 'Full Name',
                              prefixIcon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                            ),
                            const SizedBox(height: 16),
                          ],
                          GlassTextField(
                            controller: _emailController,
                            hintText: 'Email address',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          GlassTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          
                          // Super Password field — only visible in Register mode
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            // Info banner
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.shield_rounded, color: AppTheme.warning, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Contact your admin for the Super Password',
                                      style: AppTheme.bodySM.copyWith(color: AppTheme.warning),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassTextField(
                              controller: _superPasswordController,
                              hintText: 'Super Password',
                              prefixIcon: Icons.admin_panel_settings_rounded,
                              obscureText: _obscureSuperPassword,
                              suffixIcon: _obscureSuperPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              onSuffixTap: () => setState(() => _obscureSuperPassword = !_obscureSuperPassword),
                            ),
                          ],
                          
                          if (_isLogin) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _resetPassword,
                                child: Text(
                                  'Forgot Password?',
                                  style: AppTheme.labelMD.copyWith(color: AppTheme.emerald),
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 32),

                          // CTA Button
                          EmeraldButton(
                            label: _isLogin ? 'Sign In' : 'Register',
                            icon: Icons.arrow_forward_rounded,
                            isLoading: _isLoading,
                            onPressed: _submit,
                          ),
                          
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 24),

                          // Toggle — fixed overflow with Flexible
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _isLogin ? "Don't have an account? " : "Already have an account? ",
                                  style: AppTheme.bodyMD,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _isLogin = !_isLogin),
                                child: Text(
                                  _isLogin ? 'Register' : 'Login',
                                  style: AppTheme.labelMD.copyWith(color: AppTheme.emerald),
                                ),
                              ),
                            ],
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
}
