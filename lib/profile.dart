import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'theme/theme.dart';
import 'auth/auth_gate.dart';

final _googleSignIn = GoogleSignIn(
  serverClientId:
      '574839829287-th1j9g7ulr50erp617g0vjvruup4r0df.apps.googleusercontent.com',
);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _cerrarSesion() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Aviso google signOut: $e');
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error firebase signOut: $e');
    }
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  Future<void> _enviarRecuperacionContrasena() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Se envió un enlace para cambiar tu contraseña a ${user.email}'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _mostrarDialogoEditarCampo(
      String campo, String actual, Function(String) onGuardar) async {
    final controller = TextEditingController(
        text: actual == 'Nombre' || actual == 'Apellido' ? '' : actual);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Editar $campo',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ingresa tu $campo',
            filled: true,
            fillColor: const Color(0xFFF0F1F3),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D5BF7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onGuardar(text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1F3),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF8E8E93),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildFloatingBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.xs,
        vertical: AppPadding.xs,
      ),
      decoration: BoxDecoration(
        color: AppTextInputTokens.defaultBg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ítem Home
          GestureDetector(
            onTap: () {
              Navigator.of(context).maybePop();
            },
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppPadding.md),
              child: Icon(
                Icons.home_outlined,
                color: AppColors.gs1000,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing400),
          // Ítem Comunidad / Grupos
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Grupos disponible próximamente')),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppPadding.md),
              child: Icon(
                Icons.groups_outlined,
                color: AppColors.gs1000,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing400),
          // Ítem Perfil (Activo con píldora blanca)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.lg,
              vertical: AppPadding.sm,
            ),
            decoration: BoxDecoration(
              color: AppSemanticColors.surfaceMain,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.gs1000,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final parts = (displayName != null && displayName.isNotEmpty)
        ? displayName.split(' ')
        : <String>[];
    final nombre = parts.isNotEmpty ? parts.first : 'Nombre';
    final apellido = parts.length > 1 ? parts.sublist(1).join(' ') : 'Apellido';

    return Scaffold(
      backgroundColor: AppSemanticColors.surfaceMain,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Botón superior izquierdo: Regresar
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).maybePop();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.only(left: 3),
                            child: Icon(
                              Icons.arrow_back_ios,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Título "Mi Perfil"
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mi Perfil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Avatar circular con botón de cámara
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 125,
                          height: 125,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F1F3),
                            shape: BoxShape.circle,
                            image: user?.photoURL != null
                                ? DecorationImage(
                                    image: NetworkImage(user!.photoURL!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD6E2FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                              color: Color(0xFF1D5BF7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Nombre y Apellido
                  Text(
                    displayName?.isNotEmpty == true
                        ? displayName!
                        : (user?.email?.split('@').first ?? 'Nombre Apellido'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Correo del usuario
                  Text(
                    user?.email ?? 'usuario@email.com',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Sección: Información usuario
                  _buildProfileSectionHeader('Información usuario'),
                  const SizedBox(height: 10),
                  _buildProfileItem(
                    title: 'Nombre',
                    onTap: () =>
                        _mostrarDialogoEditarCampo('Nombre', nombre, (val) async {
                      final nuevo = '$val $apellido'.trim();
                      await user?.updateDisplayName(nuevo);
                      if (mounted) setState(() {});
                    }),
                  ),
                  const SizedBox(height: 10),
                  _buildProfileItem(
                    title: 'Apellido(s)',
                    onTap: () =>
                        _mostrarDialogoEditarCampo('Apellido(s)', apellido, (val) async {
                      final nuevo = '$nombre $val'.trim();
                      await user?.updateDisplayName(nuevo);
                      if (mounted) setState(() {});
                    }),
                  ),
                  const SizedBox(height: 10),
                  _buildProfileItem(
                    title: 'Email',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tu correo es: ${user?.email}')),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Sección: Cuenta
                  _buildProfileSectionHeader('Cuenta'),
                  const SizedBox(height: 10),
                  _buildProfileItem(
                    title: 'Cambiar contraseña',
                    onTap: _enviarRecuperacionContrasena,
                  ),

                  const SizedBox(height: 24),

                  // Sección: Preferencias
                  _buildProfileSectionHeader('Preferencias'),
                  const SizedBox(height: 10),
                  _buildProfileItem(
                    title: 'Notificaciones',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notificaciones activadas')),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Botón de texto: Cerrar sesión
                  GestureDetector(
                    onTap: _cerrarSesion,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          color: Color(0xFFFF5C5C),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Espacio para la barra flotante inferior
                  const SizedBox(height: 140),
                ],
              ),
            ),

            // Barra de navegación inferior tipo píldora
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.spacing400,
              child: Center(
                child: _buildFloatingBottomBar(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

