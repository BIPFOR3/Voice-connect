import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'recording.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mis Grabaciones',
      theme: AppTheme.light,
      home: const RecordingsHomeScreen(),
    );
  }
}

class RecordingsHomeScreen extends StatelessWidget {
  const RecordingsHomeScreen({super.key});

  static const List<Map<String, String>> _recordings = [
    {'title': 'Grabación 10', 'date': 'Hoy, 4:15 p.m.', 'duration': '00:39'},
    {'title': 'Grabación 9', 'date': 'Hoy, 4:14 p.m.', 'duration': '20:19'},
    {'title': 'Grabación 8', 'date': 'Hoy, 4:13 p.m.', 'duration': '05:32'},
    {'title': 'Grabación 7', 'date': 'Hoy, 4:12 p.m.', 'duration': '02:01'},
    {'title': 'Grabación 6', 'date': 'Hoy, 4:11 p.m.', 'duration': '05:39'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSemanticColors.surfaceMain,
      body: SafeArea(
        child: Stack(
          children: [
            // Contenido principal scrolleable
            ListView(
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing400,
                vertical: AppSpacing.spacing200,
              ),
              children: [
                _buildTopMenu(),
                const SizedBox(height: AppSpacing.spacing300),
                _buildHeaderTitle(),
                const SizedBox(height: AppSpacing.spacing300),
                _buildSearchBar(),
                const SizedBox(height: AppSpacing.spacing400),
                _buildTabsSection(),
                const SizedBox(height: AppSpacing.spacing400),
                _buildRecordingsList(),
                // Espacio inferior para que el FAB y el BottomBar no tapen la lista
                const SizedBox(height: 140),
              ],
            ),

            // Botón flotante de micrófono (FAB)
            Positioned(
              right: AppSpacing.spacing400,
              bottom: 96,
              child: _buildMicFab(),
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

  // ==========================================
  // WIDGETS DE SECCIÓN
  // ==========================================

  Widget _buildTopMenu() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(
          Icons.menu,
          color: AppColors.gs1000,
          size: 28,
        ),
        onPressed: () {},
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Text(
      'Mis Grabaciones',
      style: AppTypography.h4.copyWith(
        color: AppColors.gs1000,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.md,
        vertical: AppPadding.sm,
      ),
      decoration: BoxDecoration(
        color: AppTextInputTokens.defaultBg,
        borderRadius: BorderRadius.circular(AppTextInputTokens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppColors.gs1000,
            size: AppTextInputTokens.iconMd,
          ),
          const SizedBox(width: AppSpacing.spacing200),
          Expanded(
            child: TextField(
              style: AppTypography.body1,
              decoration: InputDecoration(
                hintText: '',
                hintStyle: AppTypography.body2.copyWith(
                  color: AppTextInputTokens.holder,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSection() {
    return Row(
      children: [
        // Tab Activa: Todas
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Todas',
                style: AppTypography.subtitle1.copyWith(
                  color: AppColors.gs1000,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing100),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppSemanticColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.spacing400),
        // Tab Inactiva: Favoritos
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favoritos',
                style: AppTypography.subtitle1.copyWith(
                  color: AppColors.gs1000,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing100),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.gs300,
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingsList() {
    return Column(
      children: _recordings.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.spacing300),
          child: _RecordingCard(
            title: item['title']!,
            date: item['date']!,
            duration: item['duration']!,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMicFab() {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordingScreen(),
              ),
            );
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppButtonTokens.filledBg,
              shape: BoxShape.circle,
              boxShadow: [AppElevations.level2],
            ),
            child: const Icon(
              Icons.mic,
              color: AppButtonTokens.filledLabel,
              size: 34,
            ),
          ),
        );
      },
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
          // Ítem activo (Home)
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
              Icons.home,
              color: AppColors.gs1000,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing400),
          // Ítem Comunidad / Grupos
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppPadding.md),
            child: Icon(
              Icons.groups_outlined,
              color: AppColors.gs1000,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing400),
          // Ítem Perfil
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.md,
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.gs1000,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET AUXILIAR: CARD DE GRABACIÓN
// ==========================================

class _RecordingCard extends StatelessWidget {
  final String title;
  final String date;
  final String duration;

  const _RecordingCard({
    required this.title,
    required this.date,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.md,
        vertical: AppPadding.md,
      ),
      decoration: BoxDecoration(
        color: AppCardTokens.defaultBg,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(
          color: AppColors.gs300.withValues(alpha: 0.5),
          width: 0.5,
        ),
        // Elevación mediante BoxShadow + Token de elevación
        boxShadow: [
          AppElevations.level2,
          BoxShadow(
            color: AppColors.gs1000.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón circular de Play
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppSemanticColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: AppSemanticColors.onPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing300),

          // Textos: Título y Fecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.subtitle1.copyWith(
                    color: AppCardTokens.defaultLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: AppTypography.body2.copyWith(
                    color: AppCardTokens.subtLabel,
                  ),
                ),
              ],
            ),
          ),

          // Duración y menú de 3 puntos
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.spacing200),
                child: Text(
                  duration,
                  style: AppTypography.body2.copyWith(
                    color: AppCardTokens.subtLabel,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing100),
              Icon(
                Icons.more_vert,
                color: AppCardTokens.subtLabel,
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }
}