import 'package:go_router/go_router.dart';
import 'package:krishi_link/features/admin/screens/admin_home_page.dart';
import 'package:krishi_link/features/auth/screens/login_screen.dart';
import 'package:krishi_link/features/auth/screens/register_screen.dart';
import 'package:krishi_link/features/onboarding/screens/splash_screen.dart';
import 'package:krishi_link/features/onboarding/screens/welcome_page.dart';

class AppRoute {
  static final router = _router;
  static final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminHomePage(),
      ),
    ],
  );
}
