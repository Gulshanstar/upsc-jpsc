import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../utils/supabase_service.dart';
import '../../providers/user_provider.dart';
import '../../models/user_profile.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _selectedExam = 0; // 0=UPSC, 1=JPSC, 2=Both
  bool _isLoading = false;
  bool _signedIn = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _signedIn = SupabaseService.instance.isAuthenticated;
    if (_signedIn) {
      _userEmail = SupabaseService.instance.client.auth.currentUser?.email;
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await SupabaseService.instance.signInWithGoogle();
      if (user != null) {
        setState(() {
          _signedIn = true;
          _userEmail = user.email;
        });

        // Fetch profile from Supabase for returning user
        final profile = await SupabaseService.instance.fetchProfile();
        if (profile != null) {
          await ref.read(userProfileProvider.notifier).update(profile);
          if (profile.onboardingComplete && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome back, ${profile.name}!'),
                backgroundColor: AppColors.green,
              ),
            );
            context.go('/dashboard');
            return;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully authenticated as ${user.email}!'),
              backgroundColor: AppColors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Authentication failed: Please try again or continue as guest.'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Beautiful Logo & Brand
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'StudyPath',
                        style: GoogleFonts.instrumentSerif(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'UPSC & JPSC Companion',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),

              const SizedBox(height: 48),

              Text(
                'Your exam.\nYour journey.',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 42,
                  color: AppColors.textPrimary,
                  height: 1.1,
                  fontWeight: FontWeight.w400,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2),

              const SizedBox(height: 12),

              Text(
                'Track syllabus systematically, revise with active recall, and visualize your daily consistency to crack civil services.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

              const SizedBox(height: 36),

              // Authentication Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _signedIn ? 'Cloud Sync Enabled' : 'Secure Cloud Backup',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _signedIn ? AppColors.green : AppColors.gold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _signedIn
                          ? 'Synchronizing study hours, syllabus milestones, and recall history with $_userEmail.'
                          : 'Sign in with Google to synchronize progress across multiple devices and ensure you never lose your data.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!_signedIn)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: AppColors.surfaceElevated,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.login_rounded, size: 18, color: AppColors.gold),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Connect with Google',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.greenSurface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: AppColors.green, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _userEmail ?? 'Authenticated',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await SupabaseService.instance.signOut();
                              await ref.read(userProfileProvider.notifier).update(UserProfile.defaultProfile());
                              setState(() {
                                _signedIn = false;
                                _userEmail = null;
                              });
                            },
                            child: Text(
                              'Sign Out',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.red),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

              const SizedBox(height: 32),

              Text(
                'Which exam are you preparing for?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 14),

              ...[
                ('UPSC', 'Civil Services Examination', Icons.account_balance_rounded, 0),
                ('JPSC', 'Jharkhand Combined Civil Services', Icons.spa_rounded, 1),
                ('UPSC + JPSC', 'Preparing for both exams', Icons.auto_awesome_rounded, 2),
              ].asMap().entries.map((entry) {
                final i = entry.key;
                final (title, sub, icon, idx) = entry.value;
                final isSelected = _selectedExam == idx;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedExam = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.goldSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold.withValues(alpha: 0.12)
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? AppColors.gold : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.inter(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? AppColors.goldDark : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sub,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.gold : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppColors.gold : AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 700 + i * 80), duration: 400.ms).slideX(begin: 0.05);
              }),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push('/profile-setup', extra: _selectedExam),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _signedIn ? 'Continue' : 'Continue as Guest',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
