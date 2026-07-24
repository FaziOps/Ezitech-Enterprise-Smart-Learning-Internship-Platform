import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../features/ai_assistant/presentation/screens/study_planner_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/assignments/presentation/screens/assignment_detail_screen.dart';
import '../../features/assignments/presentation/screens/assignment_list_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/community/presentation/screens/community_post_detail_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/courses/presentation/screens/course_detail_screen.dart';
import '../../features/courses/presentation/screens/course_list_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/downloads/presentation/screens/downloads_screen.dart';
import '../../features/internship/presentation/screens/internship_screen.dart';
import '../../features/live/presentation/screens/live_learning_screen.dart';
import '../../features/live/presentation/screens/live_session_chat_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/portfolio/presentation/screens/portfolio_screen.dart';
import '../widgets/app_shell.dart';

/// Route names centralized as constants so `context.goNamed(...)` calls
/// throughout the app never rely on hand-typed path strings.
class AppRoutes {
  AppRoutes._();
  static const login = 'login';
  static const dashboard = 'dashboard';
  static const courses = 'courses';
  static const courseDetail = 'course-detail';
  static const internship = 'internship';
  static const assignments = 'assignments';
  static const assignmentDetail = 'assignment-detail';
  static const live = 'live';
  static const liveChat = 'live-chat';
  static const portfolio = 'portfolio';
  static const aiAssistant = 'ai-assistant';
  static const studyPlanner = 'study-planner';
  static const notifications = 'notifications';
  static const community = 'community';
  static const communityPost = 'community-post';
  static const analytics = 'analytics';
  static const downloads = 'downloads';
}

/// Wraps GoRouter in a provider so its `redirect` callback can watch
/// [authControllerProvider] and react to login/logout without the app
/// needing a separate manual navigation call after every auth change.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/courses',
            name: AppRoutes.courses,
            builder: (context, state) => const CourseListScreen(),
            routes: [
              GoRoute(
                path: ':courseId',
                name: AppRoutes.courseDetail,
                builder: (context, state) =>
                    CourseDetailScreen(courseId: state.pathParameters['courseId']!),
              ),
            ],
          ),
          GoRoute(
            path: '/internship',
            name: AppRoutes.internship,
            builder: (context, state) => const InternshipScreen(),
          ),
          GoRoute(
            path: '/assignments',
            name: AppRoutes.assignments,
            builder: (context, state) => const AssignmentListScreen(),
            routes: [
              GoRoute(
                path: ':assignmentId',
                name: AppRoutes.assignmentDetail,
                builder: (context, state) =>
                    AssignmentDetailScreen(assignmentId: state.pathParameters['assignmentId']!),
              ),
            ],
          ),
          GoRoute(
            path: '/ai-assistant',
            name: AppRoutes.aiAssistant,
            builder: (context, state) => const AiAssistantScreen(),
            routes: [
              GoRoute(
                path: 'study-planner',
                name: AppRoutes.studyPlanner,
                builder: (context, state) => const StudyPlannerScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/live',
            name: AppRoutes.live,
            builder: (context, state) => const LiveLearningScreen(),
          ),
          // Live chat is pushed as an extra (not a shell child, since it needs
          // its own AppBar without the bottom nav shell).
          GoRoute(
            path: '/live/:sessionId/chat',
            name: AppRoutes.liveChat,
            builder: (context, state) {
              final session = state.extra;
              if (session == null) return const LiveLearningScreen();
              return LiveSessionChatScreen(session: session as dynamic);
            },
          ),
          GoRoute(
            path: '/portfolio',
            name: AppRoutes.portfolio,
            builder: (context, state) => const PortfolioScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: AppRoutes.notifications,
            builder: (context, state) => const NotificationCenterScreen(),
          ),
          GoRoute(
            path: '/community',
            name: AppRoutes.community,
            builder: (context, state) => const CommunityScreen(),
            routes: [
              GoRoute(
                path: ':postId',
                name: AppRoutes.communityPost,
                builder: (context, state) =>
                    CommunityPostDetailScreen(postId: state.pathParameters['postId']!),
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            name: AppRoutes.analytics,
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/downloads',
            name: AppRoutes.downloads,
            builder: (context, state) => const DownloadsScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod's state changes into a Listenable GoRouter can watch,
/// so `redirect` re-evaluates the instant auth status flips.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
