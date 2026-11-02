
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Escuchar los cambios de autenticación
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {

        // Esperar mientras Firebase comprueba la sesión
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Mostrar la pantalla de audios si existe una sesión
        if (snapshot.hasData) {
          return const RecordingsHomeScreen();
        }

        // Mostrar el login si no existe una sesión
        return const LoginScreen();
      },
    );
  }
}

