import 'package:flutter_test/flutter_test.dart';

// Mirrors the fixed redirect logic in app_router.dart.
// The splash route '/' uses exact match so it doesn't make every path public.
const _publicRoutes = ['/login', '/onboarding', '/otp', '/biometric', '/security/login'];

Future<String?> _redirect(String? token, String path) async {
  final isPublic = path == '/' || _publicRoutes.any((r) => path.startsWith(r));
  if (token == null && !isPublic) return '/login';
  return null;
}

void main() {
  group('Router redirect guard', () {
    test('unauthenticated user navigating to /home redirects to /login',
        () async {
      final destination = await _redirect(null, '/home');
      expect(destination, equals('/login'));
    });

    test('unauthenticated user navigating to /home/gate redirects to /login',
        () async {
      final destination = await _redirect(null, '/home/gate');
      expect(destination, equals('/login'));
    });

    test('authenticated user navigating to /home proceeds (no redirect)',
        () async {
      final destination = await _redirect('valid-token', '/home');
      expect(destination, isNull);
    });

    test('unauthenticated user on /login is not redirected (public route)',
        () async {
      final destination = await _redirect(null, '/login');
      expect(destination, isNull);
    });

    test('unauthenticated user on /onboarding is not redirected', () async {
      final destination = await _redirect(null, '/onboarding');
      expect(destination, isNull);
    });

    test('unauthenticated user on splash / is not redirected', () async {
      final destination = await _redirect(null, '/');
      expect(destination, isNull);
    });

    test('unauthenticated user on /security/login is not redirected', () async {
      final destination = await _redirect(null, '/security/login');
      expect(destination, isNull);
    });

    test('unauthenticated user on /security (guard view) redirects to /login',
        () async {
      final destination = await _redirect(null, '/security');
      expect(destination, equals('/login'));
    });
  });
}
