import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/pet_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MascotasApp());
}

class MascotasApp extends StatelessWidget {
  const MascotasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patitas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF287A68),
          surface: const Color(0xFFF8F8F4),
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const _FirebaseStartup(),
    );
  }
}

class _FirebaseStartup extends StatefulWidget {
  const _FirebaseStartup();

  @override
  State<_FirebaseStartup> createState() => _FirebaseStartupState();
}

class _FirebaseStartupState extends State<_FirebaseStartup> {
  late final Future<void> _initialization = _initializeFirebase();

  Future<void> _initializeFirebase() async {
    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!DefaultFirebaseOptions.isConfigured) {
      return const _SetupMessage();
    }

    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StartupError(error: snapshot.error!);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const AuthGate();
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthScreen.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StartupError(error: snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return const AuthScreen();
        }
        return const PetListScreen();
      },
    );
  }
}

class _SetupMessage extends StatelessWidget {
  const _SetupMessage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets, size: 64, color: Color(0xFF287A68)),
                const SizedBox(height: 16),
                Text(
                  '¡Bienvenido a Patitas!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Para conectar la aplicación, configura las opciones de '
                  'Firebase indicadas en README.md y vuelve a ejecutar Flutter.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No agregues contraseñas ni el API Secret de Cloudinary al código.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No se pudo iniciar Firebase.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
