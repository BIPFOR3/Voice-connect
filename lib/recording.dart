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
              _buildHeaderAndTimer(context),
              const Spacer(),
              _buildWaveformIndicator(),
              const Spacer(),
              _buildProgressBarSection(context),
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
          width: AppSizes.backButton,
          height: AppSizes.backButton,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.gs1000,
              width: AppStroke.medium,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.arrow_left,
              color: AppColors.gs1000,
              size: AppIconSizes.xs,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAndTimer(BuildContext context) {
    return Column(
      children: [
        Text(
          'Grabando',
          style: Theme.of(context).textTheme.headlineMedium!
              .copyWith(color: AppColors.gs1000, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.spacing600),
        Text(
          '00:01',
          style: Theme.of(context).textTheme.displayLarge!.copyWith(
            color: AppColors.gs1000,
            fontSize: AppSizes.timerFontSize,
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
        width: AppSizes.waveformWidth,
        height: AppSizes.waveformHeight,
        decoration: BoxDecoration(
          color: AppSemanticColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
      ),
    );
  }

  Widget _buildProgressBarSection(BuildContext context) {
    return Column(
      children: [
        // Barra de progreso
        Container(
          height: AppSizes.indicatorHeight,
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
              style: Theme.of(context).textTheme.bodySmall!
                  .copyWith(color: AppCardTokens.subtLabel),
            ),
            Text(
              '00:01',
              style: Theme.of(context).textTheme.bodySmall!
                  .copyWith(color: AppCardTokens.subtLabel),
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
            width: AppSizes.controlButton,
            height: AppSizes.controlButton,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppSemanticColors.error,
                width: AppStroke.thin,
              ),
            ),
            child: const Icon(
              Icons.close,
              color: AppSemanticColors.error,
              size: AppIconSizes.md,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing400),

        // Botón Principal Pausar (Azul con sombra)
        GestureDetector(
          onTap: () {},
          child: Container(
            width: AppSizes.primaryControlButton,
            height: AppSizes.primaryControlButton,
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
              size: AppIconSizes.xxl,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing400),

        // Botón Detener / Guardar (Amarillo)
        GestureDetector(
          onTap: () {},
          child: Container(
            width: AppSizes.controlButton,
            height: AppSizes.controlButton,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppSemanticColors.warning,
                width: AppStroke.thin,
              ),
            ),
            child: const Icon(
              Icons.stop_rounded,
              color: AppSemanticColors.warning,
              size: AppIconSizes.lg,
            ),
          ),
        ),
      ],
    );
  }
}
