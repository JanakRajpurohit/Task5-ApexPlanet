import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/catalog_repository.dart';
import 'data/cod_order_repository.dart';
import 'firebase_options.dart';
import 'firebase_setup.dart';
import 'services/firebase_auth_service.dart';
import 'state/crave_store.dart';
import 'ui/crave_screens.dart';
import 'ui/crave_widgets.dart';
import 'ui/seller_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!isFirebaseConfigured) {
    runApp(FirebaseSetupApp(message: firebaseSetupMessage));
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    runApp(FirebaseStartupErrorApp(message: error.message ?? error.code));
    return;
  }

  final authService = FirebaseAuthService();
  final store = CraveStore(
    const [],
    catalogRepository: CatalogRepository(),
    codOrderRepository: CodOrderRepository(),
    authService: authService,
  )..startCatalog();
  runApp(CraveApp(store: store, authService: authService));
}

class CraveApp extends StatelessWidget {
  const CraveApp({required this.store, this.authService, super.key});

  final CraveStore store;
  final FirebaseAuthService? authService;

  ThemeData _theme({required bool dark}) {
    const coral = Color(0xFFFF7043);
    const darkTeal = Color(0xFF20645F);
    const cream = Color(0xFFFFF8F3);
    const ink = Color(0xFF302A28);

    final scheme = ColorScheme.fromSeed(
      seedColor: coral,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: coral,
      secondary: darkTeal,
      surface: dark ? const Color(0xFF211F1E) : Colors.white,
      error: const Color(0xFFD94B45),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF151413) : cream,
      cardColor: scheme.surface,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: dark ? scheme.onSurface : ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: dark ? scheme.onSurface : ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: dark ? scheme.onSurface : ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: dark ? scheme.onSurface : ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: dark ? const Color(0xFFBDB6B1) : const Color(0xFF817873),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: coral, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => MaterialApp(
      title: 'Crave',
      debugShowCheckedModeBanner: false,
      theme: _theme(dark: false),
      darkTheme: _theme(dark: true),
      themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: authService == null
          ? SplashScreen(store: store)
          : AuthGate(store: store, authService: authService!),
    ),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({required this.store, required this.authService, super.key});

  final CraveStore store;
  final FirebaseAuthService authService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _loadedUid;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;
  String? _storeSyncKey;

  void _scheduleStoreSync({
    required String? uid,
    required String? role,
    String name = '',
    String email = '',
    String phone = '',
  }) {
    final syncKey = [uid, role, name, email, phone].join('\u0000');
    if (_storeSyncKey == syncKey) return;
    _storeSyncKey = syncKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _storeSyncKey != syncKey) return;
      if (widget.authService.currentUser?.uid != uid ||
          (uid != null && _loadedUid != uid)) {
        _storeSyncKey = null;
        return;
      }

      if (role == 'customer' && uid != null) {
        widget.store.startCustomerOrders(uid);
        widget.store.setProfile(name: name, email: email, phone: phone);
      } else if (role == 'seller' || uid == null) {
        widget.store.stopCustomerOrders();
        if (uid == null) {
          widget.store.setProfile(name: '', email: '', phone: '');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: widget.authService.authStateChanges,
    initialData: widget.authService.currentUser,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _StartupMessage(
          title: 'Unable to check your sign-in status',
          message: snapshot.error.toString(),
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
        return const _StartupProgress();
      }
      final user = snapshot.data;
      if (user == null) {
        _loadedUid = null;
        _profileStream = null;
        _scheduleStoreSync(uid: null, role: null);
        return SplashScreen(store: widget.store);
      }
      if (_loadedUid != user.uid) {
        _loadedUid = user.uid;
        _profileStream = widget.authService.watchProfile(user);
      }
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profileStream,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.hasError) {
            return _StartupMessage(
              title: 'Unable to load your profile',
              message: profileSnapshot.error.toString(),
              onRetry: () => setState(() {
                _loadedUid = null;
                _profileStream = null;
              }),
            );
          }
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const _StartupProgress();
          }

          final profile = profileSnapshot.data?.data();
          if (profile == null) {
            return const _StartupMessage(
              title: 'Profile not found',
              message:
                  'Your signed-in account does not have a Firestore profile. Check your Firebase rules and try again.',
            );
          }

          final role = profile['role'];
          if (role == 'seller') {
            _scheduleStoreSync(uid: user.uid, role: 'seller');
            return SellerPortal(
              uid: user.uid,
              onSignOut: widget.authService.signOut,
            );
          }
          if (role != 'customer') {
            return const _StartupMessage(
              title: 'Account access unavailable',
              message: 'This account does not have a supported Crave role.',
            );
          }
          _scheduleStoreSync(
            uid: user.uid,
            role: 'customer',
            name: profile['name'] as String? ?? '',
            email: profile['email'] as String? ?? user.email ?? '',
            phone: profile['phone'] as String? ?? user.phoneNumber ?? '',
          );
          return MainShell(store: widget.store);
        },
      );
    },
  );
}

class FirebaseSetupApp extends StatelessWidget {
  const FirebaseSetupApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: _StartupMessage(
      title: 'Connect Firebase to continue',
      message: message,
    ),
  );
}

class FirebaseStartupErrorApp extends StatelessWidget {
  const FirebaseStartupErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: _StartupMessage(title: 'Firebase could not start', message: message),
  );
}

class _StartupMessage extends StatelessWidget {
  const _StartupMessage({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            SelectableText(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    ),
  );
}

class _StartupProgress extends StatelessWidget {
  const _StartupProgress();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.store, super.key});

  final CraveStore store;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _showWelcome = false;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
    lowerBound: 0.88,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _showWelcome = true);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) return WelcomeScreen(store: widget.store);
    return Scaffold(
      backgroundColor: const Color(0xFF20645F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043),
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'C',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const CraveWordmark(light: true),
            const SizedBox(height: 8),
            const Text(
              'Your favourite meals are just a tap away.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
