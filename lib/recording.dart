import 'package:flutter/material.dart';
import 'theme/theme.dart';

class RecordingScreen extends StatelessWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSemanticColors.surfaceMain,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing400,
            vertical: AppSpacing.spacing300,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(context),
              const SizedBox(height: AppSpacing.spacing600),
              _buildHeaderAndTimer(),
              const Spacer(),
              _buildWaveformIndicator(),
              const Spacer(),
              _buildProgressBarSection(),
              const SizedBox(height: AppSpacing.spacing400),
              _buildControlsSection(context),
              const SizedBox(height: AppSpacing.spacing400),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGETS DE SECCIÓN
  // ==========================================

  Widget _buildTopBar(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.gs1000,
              width: 1.8,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.arrow_left,
              color: AppColors.gs1000,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAndTimer() {
    return Column(
      children: [
        Text(
          'Grabando',
          style: AppTypography.h5.copyWith(
            color: AppColors.gs1000,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing600),
        Text(
          '00:01',
          style: AppTypography.h1.copyWith(
            color: AppColors.gs1000,
            fontSize: 64,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveformIndicator() {
    return Center(
      child: Container(
        width: 6,
        height: 48,
        decoration: BoxDecoration(
          color: AppSemanticColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
      ),
    );
  }

  Widget _buildProgressBarSection() {
    return Column(
      children: [
        // Barra de progreso
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.gs400,
            borderRadius: BorderRadius.circular(AppRadius.l),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing100),
        // Tiempos inferior izquierdo y derecho
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '00:00',
              style: AppTypography.caption.copyWith(
                color: AppCardTokens.subtLabel,
              ),
            ),
            Text(
              '00:01',
              style: AppTypography.caption.copyWith(
                color: AppCardTokens.subtLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlsSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón Cancelar / Eliminar (Rojo)
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppSemanticColors.error,
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.close,
              color: AppSemanticColors.error,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing400),

        // Botón Principal Pausar (Azul con sombra)
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppButtonTokens.filledBg,
              shape: BoxShape.circle,
              boxShadow: [
                AppElevations.level2,
                BoxShadow(
                  color: AppColors.gs1000.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.pause,
              color: AppButtonTokens.filledLabel,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing400),

        // Botón Detener / Guardar (Amarillo)
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppSemanticColors.warning,
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.stop_rounded,
              color: AppSemanticColors.warning,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}