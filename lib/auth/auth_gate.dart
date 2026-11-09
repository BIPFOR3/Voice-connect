
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      initialData: FirebaseAuth.instance.currentUser,
      // Escuchar los cambios de autenticación
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {
        // Esperar mientras Firebase comprueba la sesión (solo si aún no hay datos y está esperando)
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Mostrar la pantalla de audios si existe una sesión activa
        if (snapshot.hasData && snapshot.data != null) {
          return const RecordingsHomeScreen();
        }

        // Mostrar el login si no existe una sesión
        return const LoginScreen();
      },
    );
  }
}

