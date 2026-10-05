import 'package:flutter/material.dart';

import 'theme/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing800),
      children: [
        const SizedBox(height: AppSpacing.spacing900),
        Text(
          'Mi Perfil',
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: AppColors.gs1000,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.spacing700),
        Center(
          child: Column(
            children: [
              Container(
                width: 152,
                height: 152,
                decoration: const BoxDecoration(
                  color: AppColors.gs300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing400),
              Text(
                'Nombre Apellido',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: AppColors.gs1000,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                'usuario@email.com',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppCardTokens.subtLabel,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.spacing600),
        _ProfileSection(
          title: 'Información usuario',
          items: ['Nombre', 'Apellido(s)', 'Email'],
        ),
        const SizedBox(height: AppSpacing.spacing600),
        _ProfileSection(
          title: 'Cuenta',
          items: ['Cambiar contraseña'],
        ),
        const SizedBox(height: AppSpacing.spacing600),
        _ProfileSection(
          title: 'Preferencias',
          items: ['Notificaciones'],
        ),
        const SizedBox(height: AppSpacing.spacing700),
        Center(
          child: Text(
            'Cerrar sesión',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppSemanticColors.error,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(height: AppSizes.bottomNavigationReservedSpace),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ProfileSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: AppColors.gs1000,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: AppSpacing.spacing300),
        ...items.map((item) => _ProfileRow(label: item)),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;

  const _ProfileRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing300),
      child: Container(
        height: 61,
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
        decoration: BoxDecoration(
          color: AppColors.gs300,
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColors.gs1000,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.gs700,
              size: AppIconSizes.lg,
            ),
          ],
        ),
      ),
    );
  }
}