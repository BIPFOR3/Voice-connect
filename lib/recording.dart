import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:record/record.dart';

import 'theme/theme.dart';
import 'audio_storage.dart';

enum EstadoGrabacion { lista, grabando, pausada, finalizada }

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final CollectionReference<Map<String, dynamic>> _grabaciones =
      FirebaseFirestore.instance.collection('grabaciones');

  Timer? _timer;
  EstadoGrabacion _estado = EstadoGrabacion.lista;
  Duration _duracion = Duration.zero;
  String? _archivoLocal;
  bool _ocupado = false;

  late AnimationController _waveAnimController;

  @override
  void initState() {
    super.initState();
    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Iniciar la grabación automáticamente al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _iniciarGrabacion();
    });
  }

  @override
  void dispose() {
    _waveAnimController.dispose();
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String _formatear(Duration duracion) {
    final minutos = duracion.inMinutes.toString().padLeft(2, '0');
    final segundos =
        duracion.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.fixed,
      ));
  }

  void _iniciarContador() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _duracion += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _iniciarGrabacion() async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      if (!await _recorder.hasPermission()) {
        _mensaje('Debes permitir el acceso al micrófono para grabar.');
        if (mounted) {
          setState(() {
            _estado = EstadoGrabacion.lista;
            _ocupado = false;
          });
        }
        return;
      }

      final rutaDestino = await getRecordingPath();

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: rutaDestino,
      );

      if (!mounted) return;
      setState(() {
        _archivoLocal = rutaDestino;
        _duracion = Duration.zero;
        _estado = EstadoGrabacion.grabando;
      });
      _iniciarContador();
    } catch (e) {
      _mensaje('Error al iniciar la grabación: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _controlarGrabacion() async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      switch (_estado) {
        case EstadoGrabacion.lista:
          await _iniciarGrabacion();
          break;
        case EstadoGrabacion.grabando:
          await _recorder.pause();
          _timer?.cancel();
          if (mounted) {
            setState(() => _estado = EstadoGrabacion.pausada);
          }
          break;
        case EstadoGrabacion.pausada:
          await _recorder.resume();
          if (mounted) {
            setState(() => _estado = EstadoGrabacion.grabando);
          }
          _iniciarContador();
          break;
        case EstadoGrabacion.finalizada:
          _abrirGuardar();
          break;
      }
    } catch (e) {
      _mensaje('Error al cambiar estado de grabación: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _descartar({bool salir = true}) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      if (_estado == EstadoGrabacion.grabando ||
          _estado == EstadoGrabacion.pausada) {
        await _recorder.stop();
      }
      _timer?.cancel();

      final ruta = _archivoLocal;
      if (ruta != null && ruta.isNotEmpty) {
        await deleteAudioFile(ruta);
      }

      if (!mounted) return;
      setState(() {
        _archivoLocal = null;
        _duracion = Duration.zero;
        _estado = EstadoGrabacion.lista;
      });

      if (salir) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      _mensaje('No se pudo descartar la grabación: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _detenerYGuardar() async {
    if (_ocupado) return;
    if (_estado == EstadoGrabacion.lista && _duracion == Duration.zero) {
      _mensaje('No hay ninguna grabación activa.');
      return;
    }

    setState(() => _ocupado = true);
    try {
      if (_estado == EstadoGrabacion.grabando ||
          _estado == EstadoGrabacion.pausada) {
        final rutaFinal = await _recorder.stop();
        _timer?.cancel();
        if (rutaFinal != null && rutaFinal.isNotEmpty) {
          _archivoLocal = rutaFinal;
        }
        if (mounted) {
          setState(() => _estado = EstadoGrabacion.finalizada);
        }
      }
      _abrirGuardar();
    } catch (e) {
      _mensaje('Error al pausar/detener la grabación: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _abrirGuardar() async {
    final now = DateTime.now();
    final hora = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minutos = now.minute.toString().padLeft(2, '0');
    final periodo = now.hour >= 12 ? 'p.m.' : 'a.m.';
    final tituloSugerido = 'Grabación ${now.day}/${now.month} ($hora:$minutos $periodo)';

    final tituloController = TextEditingController(text: tituloSugerido);
    final formKey = GlobalKey<FormState>();
    bool guardando = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppSemanticColors.surfaceMain,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.m)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => PopScope(
          canPop: !guardando,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.spacing400,
              AppSpacing.spacing300,
              AppSpacing.spacing400,
              MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.spacing400,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Guardar grabación',
                          style: AppTypography.subtitle1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.gs1000,
                          ),
                        ),
                        IconButton(
                          onPressed: guardando
                              ? null
                              : () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close, color: AppColors.gs1000),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacing200),
                    Text(
                      'Duración: ${_formatear(_duracion)}',
                      style: AppTypography.body2.copyWith(
                        color: AppCardTokens.subtLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing300),
                    TextFormField(
                      controller: tituloController,
                      autofocus: true,
                      style: AppTypography.body1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la grabación',
                        hintText: 'Ej. Nota importante',
                        filled: true,
                        fillColor: AppTextInputTokens.defaultBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.s),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (valor) =>
                          valor == null || valor.trim().isEmpty
                              ? 'Ingresa un nombre para la grabación'
                              : null,
                    ),
                    const SizedBox(height: AppSpacing.spacing400),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppButtonTokens.filledBg,
                          foregroundColor: AppButtonTokens.filledLabel,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.s),
                          ),
                        ),
                        onPressed: guardando
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => guardando = true);
                                setState(() => _ocupado = true);

                                final exito = await _subirGrabacion(
                                  tituloController.text.trim(),
                                );

                                if (mounted) setState(() => _ocupado = false);
                                if (!sheetContext.mounted) return;

                                if (exito) {
                                  Navigator.of(sheetContext).pop();
                                  _mensaje('Grabación guardada correctamente');
                                  if (mounted) {
                                    Navigator.of(context).maybePop();
                                  }
                                } else {
                                  setSheetState(() => guardando = false);
                                }
                              },
                        icon: guardando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppButtonTokens.filledLabel,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          guardando ? 'Guardando…' : 'Guardar en la nube',
                          style: AppTypography.subtitle2.copyWith(
                            color: AppButtonTokens.filledLabel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    tituloController.dispose();
  }

  Future<bool> _subirGrabacion(String titulo) async {
    final ruta = _archivoLocal;
    if (ruta == null || ruta.isEmpty) {
      _mensaje('No hay archivo de audio para subir.');
      return false;
    }

    Reference? referencia;
    bool subido = false;
    try {
      final bytes = await getAudioBytes(ruta);
      if (bytes.isEmpty) {
        throw Exception('El audio grabado está vacío.');
      }

      final id = _grabaciones.doc().id;
      const extension = 'm4a';
      const contentType = 'audio/mp4';

      referencia =
          FirebaseStorage.instance.ref('grabaciones/$id.$extension');

      await referencia.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      subido = true;

      final urlDescarga = await referencia.getDownloadURL();

      await _grabaciones.doc(id).set({
        'titulo': titulo,
        'archivo': referencia.fullPath,
        'url': urlDescarga,
        'duracionSegundos': _duracion.inSeconds,
        'creadoEn': FieldValue.serverTimestamp(),
      });

      await deleteAudioFile(ruta);

      if (mounted) {
        setState(() {
          _archivoLocal = null;
          _duracion = Duration.zero;
          _estado = EstadoGrabacion.lista;
        });
      }
      return true;
    } catch (e) {
      if (subido && referencia != null) {
        try {
          await referencia.delete();
        } catch (_) {}
      }
      _mensaje('Error al guardar la grabación: $e');
      return false;
    }
  }

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
        onTap: () {
          if (_duracion.inSeconds > 0) {
            _mostrarConfirmacionSalir();
          } else {
            Navigator.maybePop(context);
          }
        },
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

  void _mostrarConfirmacionSalir() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Descartar grabación?'),
        content: const Text(
          'Tienes una grabación en curso. Si sales ahora se descartará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continuar grabando'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _descartar(salir: true);
            },
            child: const Text(
              'Descartar y salir',
              style: TextStyle(color: AppSemanticColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAndTimer() {
    final estadoTexto = switch (_estado) {
      EstadoGrabacion.lista => 'Listo para grabar',
      EstadoGrabacion.grabando => 'Grabando',
      EstadoGrabacion.pausada => 'Pausa',
      EstadoGrabacion.finalizada => 'Grabación detenida',
    };

    return Column(
      children: [
        Text(
          estadoTexto,
          style: AppTypography.h5.copyWith(
            color: AppColors.gs1000,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing600),
        Text(
          _formatear(_duracion),
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
    final grabando = _estado == EstadoGrabacion.grabando;

    return Center(
      child: AnimatedBuilder(
        animation: _waveAnimController,
        builder: (context, child) {
          final valor = grabando ? _waveAnimController.value : 0.2;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWaveBar(height: 18 + valor * 14),
              const SizedBox(width: 6),
              _buildWaveBar(height: 28 + (1 - valor) * 20),
              const SizedBox(width: 6),
              _buildWaveBar(height: 40 + valor * 24, isCenter: true),
              const SizedBox(width: 6),
              _buildWaveBar(height: 26 + (1 - valor) * 18),
              const SizedBox(width: 6),
              _buildWaveBar(height: 16 + valor * 12),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWaveBar({required double height, bool isCenter = false}) {
    return Container(
      width: 6,
      height: height.clamp(12.0, 70.0),
      decoration: BoxDecoration(
        color: isCenter
            ? AppSemanticColors.primary
            : AppSemanticColors.primary.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
    );
  }

  Widget _buildProgressBarSection() {
    return Column(
      children: [
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.gs400,
            borderRadius: BorderRadius.circular(AppRadius.l),
          ),
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Progreso visual basado en el primer minuto o ciclo de 60s
              final progress = (_duracion.inSeconds % 60) / 60.0;
              return Container(
                width: constraints.maxWidth * progress.clamp(0.02, 1.0),
                decoration: BoxDecoration(
                  color: AppSemanticColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.l),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.spacing100),
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
              _formatear(_duracion),
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
    final grabando = _estado == EstadoGrabacion.grabando;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón Cancelar / Eliminar (Rojo)
        GestureDetector(
          onTap: _ocupado ? null : () => _descartar(salir: true),
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

        // Botón Principal Pausar/Reanudar (Azul con sombra)
        GestureDetector(
          onTap: _ocupado ? null : _controlarGrabacion,
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
            child: Icon(
              grabando ? Icons.pause : Icons.mic,
              color: AppButtonTokens.filledLabel,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing400),

        // Botón Detener / Guardar (Amarillo)
        GestureDetector(
          onTap: _ocupado ? null : _detenerYGuardar,
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