import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/onboarding/syllabus_selection_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard_screen.dart';
import '../screens/syllabus_screen.dart';
import '../screens/revision_screen.dart';
import '../screens/journey_screen.dart';
import '../screens/analytics_screen.dart';
import '../providers/user_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final profile = ref.watch(userProfileProvider);
  return GoRouter(
    initialLocation: profile.onboardingComplete ? '/dashboard' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/syllabus-selection',
        builder: (context, state) => const SyllabusSelectionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/syllabus',
            builder: (context, state) => const SyllabusScreen(),
          ),
          GoRoute(
            path: '/revision',
            builder: (context, state) => const RevisionScreen(),
          ),
          GoRoute(
            path: '/journey',
            builder: (context, state) => const JourneyScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
        ],
      ),
    ],
  );
});
