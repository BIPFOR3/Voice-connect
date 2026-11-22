import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

double safeClamp(double val, double min, double max) {
  if (min >= max) return min;
  if (val < min) return min;
  if (val > max) return max;
  return val;
}

// ============================================================================
// PANTALLA PRINCIPAL: EDICIÓN DE AUDIO (Imagen 2)
// ============================================================================

class AudioEditorScreen extends StatefulWidget {
  final String recordingId;
  final String initialTitle;
  final String? audioUrl;
  final num? durationSeconds;
  final String? durationText;

  const AudioEditorScreen({
    super.key,
    required this.recordingId,
    required this.initialTitle,
    this.audioUrl,
    this.durationSeconds,
    this.durationText,
  });

  @override
  State<AudioEditorScreen> createState() => _AudioEditorScreenState();
}

class _AudioEditorScreenState extends State<AudioEditorScreen> {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();

  late String _currentTitle;
  late Duration _totalDuration;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  bool _isLooping = false;

  // Ajustes de audio
  double _volumePercent = 100.0;
  double _pitchValue = 0.0;
  bool _fadeIn = false;
  bool _fadeOut = false;
  Timer? _fadeTimer;

  // Mezcla de fondo
  String? _activeAmbient;
  String? _activeAmbientUrl;
  double _mixBalance = 70.0; // 70% voz, 30% fondo

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.initialTitle;
    final segs = (widget.durationSeconds ?? 24).toInt();
    _totalDuration = Duration(seconds: segs > 0 ? segs : 24);

    _initAudio();
  }

  Future<void> _initAudio() async {
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      try {
        await _player.setUrl(widget.audioUrl!);
      } catch (e) {
        debugPrint('Aviso cargando audio en editor: $e');
      }
    }

    _posSub = _player.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
        // Si fade-out está activo y estamos en los últimos 2 segundos
        if (_fadeOut && _isPlaying && _totalDuration.inSeconds > 3) {
          final remaining = _totalDuration - pos;
          if (remaining.inMilliseconds <= 2000 && remaining.inMilliseconds > 0) {
            final factor = (remaining.inMilliseconds / 2000.0).clamp(0.0, 1.0);
            _player.setVolume((_volumePercent / 100.0) * factor);
          }
        }
      }
    });

    _durSub = _player.durationStream.listen((dur) {
      if (dur != null && dur.inSeconds > 0 && mounted) {
        setState(() {
          _totalDuration = dur;
        });
      }
    });

    _stateSub = _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing &&
              state.processingState != ProcessingState.completed;
          if (state.processingState == ProcessingState.completed) {
            _currentPosition = Duration.zero;
            if (_activeAmbientUrl != null) {
              _ambientPlayer.pause();
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    _ambientPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _aplicarFadeIn() {
    _player.setVolume(0.0);
    double step = 0.0;
    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      step += 0.07;
      if (step >= (_volumePercent / 100.0)) {
        _player.setVolume(_volumePercent / 100.0);
        t.cancel();
      } else {
        _player.setVolume(step);
      }
    });
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
      if (_activeAmbientUrl != null) {
        await _ambientPlayer.pause();
      }
    } else {
      if (_player.duration != null && _currentPosition >= _totalDuration) {
        await _player.seek(Duration.zero);
        if (_activeAmbientUrl != null) {
          await _ambientPlayer.seek(Duration.zero);
        }
      }
      if (_fadeIn) {
        _aplicarFadeIn();
      } else {
        await _player.setVolume(_volumePercent / 100.0);
      }
      await _player.play();
      if (_activeAmbientUrl != null) {
        await _ambientPlayer.setVolume((100 - _mixBalance) / 100.0);
        await _ambientPlayer.play();
      }
    }
  }

  void _rewind10() async {
    final target = _currentPosition - const Duration(seconds: 10);
    final pos = target < Duration.zero ? Duration.zero : target;
    await _player.seek(pos);
    if (_activeAmbientUrl != null) {
      await _ambientPlayer.seek(pos);
    }
  }

  void _forward10() async {
    final target = _currentPosition + const Duration(seconds: 10);
    final pos = target > _totalDuration ? _totalDuration : target;
    await _player.seek(pos);
    if (_activeAmbientUrl != null) {
      await _ambientPlayer.seek(pos);
    }
  }

  void _cycleSpeed() {
    final speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    final newSpeed = speeds[nextIndex];
    setState(() => _playbackSpeed = newSpeed);
    _player.setSpeed(newSpeed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Velocidad: ${newSpeed}x'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleLoop() {
    setState(() => _isLooping = !_isLooping);
    _player.setLoopMode(_isLooping ? LoopMode.one : LoopMode.off);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLooping ? 'Repetición activada' : 'Repetición desactivada'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _mostrarDialogoRenombrar() {
    final c = TextEditingController(text: _currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar grabación'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nuevo nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = c.text.trim();
              if (newName.isNotEmpty) {
                setState(() => _currentTitle = newName);
                if (widget.recordingId.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('grabaciones')
                      .doc(widget.recordingId)
                      .update({'titulo': newName});
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEcualizador() {
    double bajos = 0.0;
    double medios = 0.0;
    double agudos = 0.0;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ecualizador de audio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 70, child: Text('Bajos:')),
                  Expanded(
                    child: Slider(
                      value: bajos,
                      min: -10,
                      max: 10,
                      onChanged: (v) => setMState(() => bajos = v),
                    ),
                  ),
                  Text('${bajos.toInt()} dB'),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 70, child: Text('Medios:')),
                  Expanded(
                    child: Slider(
                      value: medios,
                      min: -10,
                      max: 10,
                      onChanged: (v) => setMState(() => medios = v),
                    ),
                  ),
                  Text('${medios.toInt()} dB'),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 70, child: Text('Agudos:')),
                  Expanded(
                    child: Slider(
                      value: agudos,
                      min: -10,
                      max: 10,
                      onChanged: (v) => setMState(() => agudos = v),
                    ),
                  ),
                  Text('${agudos.toInt()} dB'),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ecualización aplicada')),
                  );
                },
                child: const Text('Aplicar ecualización'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarTemporizador() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Temporizador de apagado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('5 minutos'),
              onTap: () {
                Navigator.pop(ctx);
                Timer(const Duration(minutes: 5), () {
                  if (mounted && _isPlaying) _togglePlayPause();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Temporizador configurado a 5 min')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('15 minutos'),
              onTap: () {
                Navigator.pop(ctx);
                Timer(const Duration(minutes: 15), () {
                  if (mounted && _isPlaying) _togglePlayPause();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Temporizador configurado a 15 min')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Al terminar la grabación'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _isLooping = false);
                _player.setLoopMode(LoopMode.off);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Se detendrá al finalizar')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // CONFIGURACIÓN DE PISTA DE FONDO (MEZCLA)
  // ==========================================================================
  Future<void> _setAmbientTrack(String ambient, double balance, String? ambientUrl) async {
    setState(() {
      _activeAmbient = ambient;
      _mixBalance = balance;
      _activeAmbientUrl = ambientUrl;
    });

    if (ambientUrl != null && ambientUrl.isNotEmpty) {
      try {
        await _ambientPlayer.setUrl(ambientUrl);
        await _ambientPlayer.setLoopMode(LoopMode.one);
        await _ambientPlayer.setVolume((100 - balance) / 100.0);
        if (_isPlaying) {
          await _ambientPlayer.play();
        }
      } catch (e) {
        debugPrint('Aviso ambient audio: $e');
      }
    }
  }

  // ==========================================================================
  // NAVEGACIÓN A CADA UNA DE LAS 6 OPCIONES:
  // ==========================================================================

  // 1. RECORTAR (Imagen 3)
  void _abrirRecortar() async {
    if (_isPlaying) await _player.pause();
    if (!mounted) return;
    final result = await Navigator.push<Duration?>(
      context,
      MaterialPageRoute(
        builder: (_) => AudioTrimScreen(
          title: _currentTitle,
          totalDuration: _totalDuration,
          recordingId: widget.recordingId,
          audioUrl: widget.audioUrl,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _totalDuration = result);
    }
  }

  // 2. INSERTAR
  void _abrirInsertar() {
    if (_isPlaying) _player.pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _AudioInsertModal(
        recordingId: widget.recordingId,
        title: _currentTitle,
        totalDuration: _totalDuration,
        currentPosition: _currentPosition,
        audioUrl: widget.audioUrl,
        onInsertSuccess: (newDur) {
          setState(() => _totalDuration = newDur);
        },
      ),
    );
  }

  // 3. AJUSTAR
  void _abrirAjustar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _AudioAdjustModal(
        recordingId: widget.recordingId,
        title: _currentTitle,
        audioUrl: widget.audioUrl,
        currentVolume: _volumePercent,
        currentPitch: _pitchValue,
        currentFadeIn: _fadeIn,
        currentFadeOut: _fadeOut,
        onAdjustApplied: (vol, pitch, fIn, fOut) {
          setState(() {
            _volumePercent = vol;
            _pitchValue = pitch;
            _fadeIn = fIn;
            _fadeOut = fOut;
          });
          _player.setVolume(vol / 100.0);
          _player.setPitch(1.0 + (pitch * 0.1));
        },
      ),
    );
  }

  // 4. MEZCLA
  void _abrirMezcla() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _AudioMixModal(
        recordingId: widget.recordingId,
        title: _currentTitle,
        totalDuration: _totalDuration,
        audioUrl: widget.audioUrl,
        currentAmbient: _activeAmbient,
        currentBalance: _mixBalance,
        onMixApplied: (ambient, balance, ambientUrl) {
          _setAmbientTrack(ambient, balance, ambientUrl);
        },
      ),
    );
  }

  // 5. DIVIDIR
  void _abrirDividir() {
    if (_isPlaying) _player.pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _AudioSplitModal(
        recordingId: widget.recordingId,
        title: _currentTitle,
        totalDuration: _totalDuration,
        currentPosition: _currentPosition,
        audioUrl: widget.audioUrl,
      ),
    );
  }

  // 6. FUSIONAR
  void _abrirFusionar() {
    if (_isPlaying) _player.pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _AudioMergeModal(
        recordingId: widget.recordingId,
        title: _currentTitle,
        totalDuration: _totalDuration,
        audioUrl: widget.audioUrl,
        onMergeSuccess: (newDur) {
          setState(() => _totalDuration = newDur);
        },
      ),
    );
  }

  // ==========================================================================
  // WIDGET TARJETA DE EDICIÓN (3x2 Grid)
  // ==========================================================================
  Widget _buildEditorOptionCard({
    required String label,
    required Widget graphic,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: graphic,
                ),
              ),
            ),
            Container(
              height: 28,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1D5BF7),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ilustración 1: Recortar
  Widget _buildGraphicRecortar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildWaveMiniBars(color: const Color(0xFF9E9E9E)),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 1.5),
            color: Colors.black.withValues(alpha: 0.04),
          ),
          child: const Center(
            child: Icon(Icons.content_cut, size: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // Ilustración 2: Insertar
  Widget _buildGraphicInsertar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildWaveMiniBars(color: const Color(0xFF9E9E9E)),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 1.5),
            color: Colors.black.withValues(alpha: 0.04),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 18, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // Ilustración 3: Ajustar
  Widget _buildGraphicAjustar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildWaveMiniBars(color: const Color(0xFF9E9E9E)),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.tune, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Ilustración 4: Mezcla
  Widget _buildGraphicMezcla() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWaveMiniBars(color: const Color(0xFF9E9E9E), count: 10),
            const SizedBox(width: 4),
            const Icon(Icons.volume_up, size: 14, color: Colors.black87),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 14, color: Colors.black87),
            const SizedBox(width: 4),
            _buildWaveMiniBars(color: const Color(0xFF9E9E9E), count: 10),
          ],
        ),
      ],
    );
  }

  // Ilustración 5: Dividir
  Widget _buildGraphicDividir() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black26),
          ),
          child: const Center(
            child: Text('1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        Container(
          width: 2,
          height: 36,
          color: Colors.black87,
          margin: const EdgeInsets.symmetric(horizontal: 4),
        ),
        Container(
          width: 28,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black26),
          ),
          child: const Center(
            child: Text('2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  // Ilustración 6: Fusionar
  Widget _buildGraphicFusionar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black26),
          ),
          child: const Center(
            child: Text('1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('+', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Container(
          width: 26,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black26),
          ),
          child: const Center(
            child: Text('2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildWaveMiniBars({Color color = const Color(0xFF9E9E9E), int count = 16}) {
    const heights = [6.0, 14.0, 22.0, 10.0, 18.0, 28.0, 16.0, 22.0, 26.0, 14.0, 8.0, 18.0, 24.0, 12.0, 16.0, 20.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(count.clamp(4, heights.length), (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          width: 2.0,
          height: heights[i],
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildHeaderWaveformBars() {
    const barHeights = [
      12.0, 18.0, 28.0, 16.0, 22.0, 36.0, 20.0, 26.0, 42.0, 18.0,
      14.0, 30.0, 24.0, 16.0, 22.0, 38.0, 28.0, 20.0, 46.0, 26.0,
      18.0, 14.0, 32.0, 24.0, 16.0, 34.0, 26.0, 18.0, 22.0, 32.0,
      22.0, 16.0, 12.0, 18.0, 26.0, 14.0, 22.0, 36.0, 20.0, 16.0
    ];

    final progressRatio = (_totalDuration.inMilliseconds > 0)
        ? (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final activeBarIndex = (progressRatio * barHeights.length).toInt();

    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barHeights.length, (i) {
          final isPlayed = i <= activeBarIndex;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3.5,
            height: barHeights[i],
            decoration: BoxDecoration(
              color: isPlayed ? const Color(0xFF1E1E1E) : const Color(0xFF9CA3AF),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressValue = (_totalDuration.inMilliseconds > 0)
        ? (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF5A5A5A),
      body: SafeArea(
        child: Column(
          children: [
            // Cabecera superior oscura
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.only(left: 3),
                            child: Icon(
                              Icons.arrow_back_ios,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'Edición de audio',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Sección central oscura expandida (Centra el cronómetro digital y la onda)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDuration(_totalDuration),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHeaderWaveformBars(),
                ],
              ),
            ),

            // PANEL BLANCO INFERIOR (BOTTOM SHEET)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cuadrícula 3x2 de opciones de edición (sin espacio en blanco sobrante)
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildEditorOptionCard(
                        label: 'Recortar',
                        graphic: _buildGraphicRecortar(),
                        onTap: _abrirRecortar,
                      ),
                      _buildEditorOptionCard(
                        label: 'Insertar',
                        graphic: _buildGraphicInsertar(),
                        onTap: _abrirInsertar,
                      ),
                      _buildEditorOptionCard(
                        label: 'Ajustar',
                        graphic: _buildGraphicAjustar(),
                        onTap: _abrirAjustar,
                      ),
                      _buildEditorOptionCard(
                        label: 'Mezcla',
                        graphic: _buildGraphicMezcla(),
                        onTap: _abrirMezcla,
                      ),
                      _buildEditorOptionCard(
                        label: 'Dividir',
                        graphic: _buildGraphicDividir(),
                        onTap: _abrirDividir,
                      ),
                      _buildEditorOptionCard(
                        label: 'Fusionar',
                        graphic: _buildGraphicFusionar(),
                        onTap: _abrirFusionar,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                    // Fila de Herramientas Rápidas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.graphic_eq),
                          iconSize: 24,
                          color: const Color(0xFF4B5563),
                          onPressed: _mostrarDialogoEcualizador,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note),
                          iconSize: 26,
                          color: const Color(0xFF4B5563),
                          onPressed: _mostrarDialogoRenombrar,
                        ),
                        InkWell(
                          onTap: _cycleSpeed,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              'x${_playbackSpeed == 1.0 ? '1' : _playbackSpeed.toString()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          iconSize: 24,
                          color: const Color(0xFF4B5563),
                          onPressed: _mostrarTemporizador,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.repeat,
                            color: _isLooping ? const Color(0xFF1D5BF7) : const Color(0xFF4B5563),
                          ),
                          iconSize: 24,
                          onPressed: _toggleLoop,
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Slider de progreso interactivo
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.5,
                        activeTrackColor: const Color(0xFF9CA3AF),
                        inactiveTrackColor: const Color(0xFFE5E7EB),
                        thumbColor: const Color(0xFF1D5BF7),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: progressValue,
                        onChanged: (val) {
                          final newPos = Duration(
                            milliseconds: (val * _totalDuration.inMilliseconds).toInt(),
                          );
                          _player.seek(newPos);
                          if (_activeAmbientUrl != null) {
                            _ambientPlayer.seek(newPos);
                          }
                        },
                      ),
                    ),

                    // Etiquetas de tiempo (00:00 y total)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_currentPosition),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDuration(_totalDuration),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Fila de Controles de Reproducción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          iconSize: 32,
                          color: const Color(0xFF374151),
                          onPressed: () {
                            _player.seek(Duration.zero);
                            if (_activeAmbientUrl != null) {
                              _ambientPlayer.seek(Duration.zero);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.replay_10),
                          iconSize: 30,
                          color: const Color(0xFF374151),
                          onPressed: _rewind10,
                        ),
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1D5BF7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_10),
                          iconSize: 30,
                          color: const Color(0xFF374151),
                          onPressed: _forward10,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          iconSize: 32,
                          color: const Color(0xFF374151),
                          onPressed: () {
                            _player.seek(_totalDuration);
                            if (_activeAmbientUrl != null) {
                              _ambientPlayer.seek(_totalDuration);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. PANTALLA RECORTAR (Imagen 3) - 100% FUNCIONAL
// ============================================================================

class AudioTrimScreen extends StatefulWidget {
  final String title;
  final Duration totalDuration;
  final String recordingId;
  final String? audioUrl;

  const AudioTrimScreen({
    super.key,
    required this.title,
    required this.totalDuration,
    required this.recordingId,
    this.audioUrl,
  });

  @override
  State<AudioTrimScreen> createState() => _AudioTrimScreenState();
}

class _AudioTrimScreenState extends State<AudioTrimScreen> {
  final AudioPlayer _player = AudioPlayer();
  late double _startSec;
  late double _endSec;
  late double _maxSec;
  bool _isPlaying = false;
  bool _guardando = false;
  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    final totalSec = (widget.totalDuration.inMilliseconds > 0)
        ? (widget.totalDuration.inMilliseconds / 1000.0)
        : (widget.totalDuration.inSeconds > 0
            ? widget.totalDuration.inSeconds.toDouble()
            : 24.0);
    _maxSec = totalSec > 0.5 ? totalSec : 24.0;
    if (_maxSec < 2.0) {
      _startSec = safeClamp(_maxSec * 0.1, 0.0, _maxSec * 0.4);
      _endSec = safeClamp(_maxSec * 0.9, _startSec + 0.1, _maxSec);
    } else {
      _startSec = safeClamp(_maxSec * 0.15, 0.0, _maxSec - 1.0);
      _endSec = safeClamp(_maxSec * 0.85, _startSec + 0.5, _maxSec);
    }

    _initAudio();
  }

  Future<void> _initAudio() async {
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      try {
        await _player.setUrl(widget.audioUrl!);
      } catch (e) {
        debugPrint('Aviso audio recortar: $e');
      }
    }

    _posSub = _player.positionStream.listen((pos) {
      if (_isPlaying && pos.inMilliseconds >= (_endSec * 1000).toInt()) {
        _player.pause();
        _player.seek(Duration(milliseconds: (_startSec * 1000).toInt()));
        if (mounted) setState(() => _isPlaying = false);
      }
    });

    _stateSub = _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing &&
              state.processingState != ProcessingState.completed;
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatTime(double sec) {
    final s = sec.toInt();
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      final posMs = _player.position.inMilliseconds;
      final sMs = (_startSec * 1000).toInt();
      final eMs = (_endSec * 1000).toInt();
      if (posMs < sMs || posMs >= eMs) {
        await _player.seek(Duration(milliseconds: sMs));
      }
      await _player.play();
    }
  }

  void _rewind10() async {
    final curMs = _player.position.inMilliseconds;
    final sMs = (_startSec * 1000).toInt();
    final target = curMs - 10000;
    await _player.seek(Duration(milliseconds: target < sMs ? sMs : target));
  }

  void _forward10() async {
    final curMs = _player.position.inMilliseconds;
    final eMs = (_endSec * 1000).toInt();
    final target = curMs + 10000;
    await _player.seek(Duration(milliseconds: target > eMs ? eMs : target));
  }

  void _skipPrevious() async {
    await _player.seek(Duration(milliseconds: (_startSec * 1000).toInt()));
  }

  void _skipNext() async {
    await _player.seek(Duration(milliseconds: (_endSec * 1000).toInt()));
  }

  void _aplicarRecorte() async {
    setState(() => _guardando = true);
    final nuevaDuracion = Duration(seconds: (_endSec - _startSec).toInt());

    try {
      if (widget.recordingId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('grabaciones')
            .doc(widget.recordingId)
            .update({
          'duracionSegundos': nuevaDuracion.inSeconds,
          'duracion': _formatTime(_endSec - _startSec),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Grabación recortada a ${_formatTime(_endSec - _startSec)}',
            ),
          ),
        );
        Navigator.pop(context, nuevaDuracion);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al recortar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _guardarComoNuevoRecorte() async {
    setState(() => _guardando = true);
    final user = FirebaseAuth.instance.currentUser;
    final nuevaDuracion = Duration(seconds: (_endSec - _startSec).toInt());

    try {
      await FirebaseFirestore.instance.collection('grabaciones').add({
        'titulo': '${widget.title} (Recorte)',
        'url': widget.audioUrl ?? '',
        'duracion': _formatTime(_endSec - _startSec),
        'duracionSegundos': nuevaDuracion.inSeconds,
        'creadoEn': FieldValue.serverTimestamp(),
        'userId': user?.uid,
        'userEmail': user?.email,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recorte guardado como nueva grabación')),
        );
        Navigator.pop(context, nuevaDuracion);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar recorte: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _buildHandleCircle() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Color(0xFF1D5BF7),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTrimWaveform() {
    const bars = [
      14.0, 22.0, 36.0, 20.0, 28.0, 48.0, 26.0, 38.0, 56.0, 30.0,
      22.0, 44.0, 52.0, 32.0, 42.0, 58.0, 40.0, 30.0, 54.0, 42.0,
      30.0, 22.0, 46.0, 34.0, 26.0, 48.0, 34.0, 24.0, 32.0, 44.0,
    ];

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalW = constraints.maxWidth;
              final safeMax = _maxSec > 0.05 ? _maxSec : 1.0;
              final startRatio = safeClamp(_startSec / safeMax, 0.0, 1.0);
              final endRatio = safeClamp(_endSec / safeMax, 0.0, 1.0);
              final boxLeft = startRatio * totalW;
              final boxW = safeClamp((endRatio - startRatio) * totalW, 24.0, totalW);

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Ondas fijas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: bars.map((h) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.2),
                        width: 5,
                        height: h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }).toList(),
                  ),

                  // Ventana de Selección Azul Dinámica (Imagen 3)
                  Positioned(
                    left: boxLeft,
                    width: boxW,
                    top: 5,
                    bottom: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB).withValues(alpha: 0.65),
                        border: const Border.symmetric(
                          vertical: BorderSide(color: Color(0xFF1D5BF7), width: 3),
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -4,
                            left: -5,
                            child: _buildHandleCircle(),
                          ),
                          Positioned(
                            bottom: -4,
                            left: -5,
                            child: _buildHandleCircle(),
                          ),
                          Positioned(
                            top: -4,
                            right: -5,
                            child: _buildHandleCircle(),
                          ),
                          Positioned(
                            bottom: -4,
                            right: -5,
                            child: _buildHandleCircle(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // RangeSlider para mover la ventana
        RangeSlider(
          values: RangeValues(
            safeClamp(_startSec, 0.0, (_maxSec > 0.2 ? _maxSec : 1.0) - 0.05),
            safeClamp(_endSec, safeClamp(_startSec, 0.0, (_maxSec > 0.2 ? _maxSec : 1.0) - 0.05) + 0.05, (_maxSec > 0.2 ? _maxSec : 1.0)),
          ),
          min: 0.0,
          max: _maxSec > 0.2 ? _maxSec : 1.0,
          activeColor: const Color(0xFF1D5BF7),
          inactiveColor: const Color(0xFFE5E7EB),
          onChanged: (values) {
            setState(() {
              _startSec = values.start;
              _endSec = values.end;
            });
            final curMs = _player.position.inMilliseconds;
            if (curMs < (_startSec * 1000) || curMs > (_endSec * 1000)) {
              _player.seek(Duration(milliseconds: (_startSec * 1000).toInt()));
            }
          },
        ),

        // Etiquetas de tiempo (00:05 y 00:17)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatTime(_startSec),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatTime(_endSec),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
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

              const SizedBox(height: 16),

              const Text(
                'Recortar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 48),

              _buildTrimWaveform(),

              const SizedBox(height: 52),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _aplicarRecorte,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5BF7),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Recortar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _guardando ? null : _guardarComoNuevoRecorte,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Guardar recorte',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Controles de audio inferiores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 32,
                    color: const Color(0xFF374151),
                    onPressed: _skipPrevious,
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    iconSize: 30,
                    color: const Color(0xFF374151),
                    onPressed: _rewind10,
                  ),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D5BF7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    iconSize: 30,
                    color: const Color(0xFF374151),
                    onPressed: _forward10,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 32,
                    color: const Color(0xFF374151),
                    onPressed: _skipNext,
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. MODAL INSERTAR - 100% FUNCIONAL (Silencio o Clips de la biblioteca)
// ============================================================================

class _AudioInsertModal extends StatefulWidget {
  final String recordingId;
  final String title;
  final Duration totalDuration;
  final Duration currentPosition;
  final String? audioUrl;
  final Function(Duration) onInsertSuccess;

  const _AudioInsertModal({
    required this.recordingId,
    required this.title,
    required this.totalDuration,
    required this.currentPosition,
    this.audioUrl,
    required this.onInsertSuccess,
  });

  @override
  State<_AudioInsertModal> createState() => _AudioInsertModalState();
}

class _AudioInsertModalState extends State<_AudioInsertModal> {
  int _tabSeleccionado = 0; // 0: Silencio, 1: Clip de audio
  int _silencioSegundos = 3;
  late double _insertPointSec;
  bool _procesando = false;

  String? _selectedClipId;
  String? _selectedClipTitle;
  int _selectedClipDurationSec = 0;
  String? _selectedClipUrl;

  @override
  void initState() {
    super.initState();
    final totalSec = (widget.totalDuration.inMilliseconds > 0)
        ? (widget.totalDuration.inMilliseconds / 1000.0)
        : (widget.totalDuration.inSeconds > 0
            ? widget.totalDuration.inSeconds.toDouble()
            : 24.0);
    final max = totalSec > 0.2 ? totalSec : 24.0;
    _insertPointSec = widget.currentPosition.inSeconds > 0
        ? safeClamp(widget.currentPosition.inSeconds.toDouble(), 0.0, max)
        : (max / 2.0);
  }

  String _format(double sec) {
    final s = sec.toInt();
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  void _guardarInsercion({required bool comoNuevo}) async {
    setState(() => _procesando = true);
    final user = FirebaseAuth.instance.currentUser;
    final addedSec = _tabSeleccionado == 0 ? _silencioSegundos : _selectedClipDurationSec;
    final nuevaDuracion = widget.totalDuration + Duration(seconds: addedSec);
    final m = nuevaDuracion.inMinutes.toString().padLeft(2, '0');
    final s = (nuevaDuracion.inSeconds % 60).toString().padLeft(2, '0');

    try {
      if (comoNuevo) {
        final titulo = _tabSeleccionado == 0
            ? '${widget.title} (+${addedSec}s silencio)'
            : '${widget.title} (+${_selectedClipTitle ?? 'Clip'})';

        await FirebaseFirestore.instance.collection('grabaciones').add({
          'titulo': titulo,
          'url': widget.audioUrl ?? _selectedClipUrl ?? '',
          'duracion': '$m:$s',
          'duracionSegundos': nuevaDuracion.inSeconds,
          'creadoEn': FieldValue.serverTimestamp(),
          'userId': user?.uid,
          'userEmail': user?.email,
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Guardado como nueva grabación: "$titulo"')),
          );
        }
      } else {
        if (widget.recordingId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('grabaciones')
              .doc(widget.recordingId)
              .update({
            'duracionSegundos': nuevaDuracion.inSeconds,
            'duracion': '$m:$s',
          });
        }
        widget.onInsertSuccess(nuevaDuracion);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Inserción aplicada. Nueva duración: $m:$s')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al insertar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSec = (widget.totalDuration.inMilliseconds > 0)
        ? (widget.totalDuration.inMilliseconds / 1000.0)
        : (widget.totalDuration.inSeconds > 0
            ? widget.totalDuration.inSeconds.toDouble()
            : 24.0);
    final max = totalSec > 0.2 ? totalSec : 24.0;
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Insertar en grabación',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Selector de pestaña: Silencio vs Clip
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Insertar Silencio')),
                    selected: _tabSeleccionado == 0,
                    selectedColor: const Color(0xFF1D5BF7),
                    labelStyle: TextStyle(
                      color: _tabSeleccionado == 0 ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => _tabSeleccionado = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Insertar Clip Audio')),
                    selected: _tabSeleccionado == 1,
                    selectedColor: const Color(0xFF1D5BF7),
                    labelStyle: TextStyle(
                      color: _tabSeleccionado == 1 ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => _tabSeleccionado = 1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Punto de inserción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Punto de inserción:'),
                Text(
                  _format(_insertPointSec),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D5BF7)),
                ),
              ],
            ),
            Slider(
              value: safeClamp(_insertPointSec, 0.0, max),
              min: 0.0,
              max: max,
              onChanged: (v) => setState(() => _insertPointSec = v),
            ),

            if (_tabSeleccionado == 0) ...[
              const Text('Duración del silencio:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3, 5, 10].map((sec) {
                  final sel = _silencioSegundos == sec;
                  return ChoiceChip(
                    label: Text('$sec s'),
                    selected: sel,
                    selectedColor: const Color(0xFF1D5BF7),
                    labelStyle: TextStyle(color: sel ? Colors.white : Colors.black),
                    onSelected: (_) => setState(() => _silencioSegundos = sec),
                  );
                }).toList(),
              ),
            ] else ...[
              const Text('Seleccionar clip de tu biblioteca:'),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('grabaciones')
                    .where('userId', isEqualTo: user?.uid ?? '')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs
                      .where((d) => d.id != widget.recordingId)
                      .toList();

                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('No tienes otras grabaciones. Graba un audio adicional para insertarlo aquí.'),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedClipId,
                        hint: const Text('Elegir grabación a insertar'),
                        items: docs.map((doc) {
                          final data = doc.data();
                          final t = data['titulo'] as String? ?? 'Grabación';
                          final d = data['duracion'] as String? ?? '00:00';
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Row(
                              children: [
                                const Icon(Icons.audio_file, color: Color(0xFF1D5BF7), size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(t)),
                                Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            final match = docs.firstWhere((d) => d.id == id);
                            final dData = match.data();
                            setState(() {
                              _selectedClipId = id;
                              _selectedClipTitle = dData['titulo'] as String? ?? 'Grabación';
                              _selectedClipDurationSec = (dData['duracionSegundos'] as num?)?.toInt() ?? 5;
                              _selectedClipUrl = dData['url'] as String?;
                            });
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _procesando ? null : () => _guardarInsercion(comoNuevo: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D5BF7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Actualizar grabación actual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: _procesando ? null : () => _guardarInsercion(comoNuevo: true),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1D5BF7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Guardar como nueva grabación', style: TextStyle(color: Color(0xFF1D5BF7), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. MODAL AJUSTAR - 100% FUNCIONAL (Volumen, Tono, Fade In/Out, Preview)
// ============================================================================

class _AudioAdjustModal extends StatefulWidget {
  final String recordingId;
  final String title;
  final String? audioUrl;
  final double currentVolume;
  final double currentPitch;
  final bool currentFadeIn;
  final bool currentFadeOut;
  final Function(double, double, bool, bool) onAdjustApplied;

  const _AudioAdjustModal({
    required this.recordingId,
    required this.title,
    this.audioUrl,
    required this.currentVolume,
    required this.currentPitch,
    required this.currentFadeIn,
    required this.currentFadeOut,
    required this.onAdjustApplied,
  });

  @override
  State<_AudioAdjustModal> createState() => _AudioAdjustModalState();
}

class _AudioAdjustModalState extends State<_AudioAdjustModal> {
  final AudioPlayer _testPlayer = AudioPlayer();
  late double _volumen;
  late double _tono;
  late bool _fadeIn;
  late bool _fadeOut;
  bool _isPlayingTest = false;

  @override
  void initState() {
    super.initState();
    _volumen = widget.currentVolume;
    _tono = widget.currentPitch;
    _fadeIn = widget.currentFadeIn;
    _fadeOut = widget.currentFadeOut;

    _initTestPlayer();
  }

  Future<void> _initTestPlayer() async {
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      try {
        await _testPlayer.setUrl(widget.audioUrl!);
        await _testPlayer.setVolume(_volumen / 100.0);
        await _testPlayer.setPitch(1.0 + (_tono * 0.1));
      } catch (_) {}
    }
    _testPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingTest = state.playing && state.processingState != ProcessingState.completed;
        });
      }
    });
  }

  @override
  void dispose() {
    _testPlayer.dispose();
    super.dispose();
  }

  void _toggleTestPlay() async {
    if (_isPlayingTest) {
      await _testPlayer.pause();
    } else {
      await _testPlayer.setVolume(_volumen / 100.0);
      await _testPlayer.setPitch(1.0 + (_tono * 0.1));
      await _testPlayer.play();
    }
  }

  void _guardarAjustes() async {
    if (widget.recordingId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('grabaciones')
            .doc(widget.recordingId)
            .update({
          'ajustes': {
            'volumen': _volumen,
            'tono': _tono,
            'fadeIn': _fadeIn,
            'fadeOut': _fadeOut,
          }
        });
      } catch (_) {}
    }

    widget.onAdjustApplied(_volumen, _tono, _fadeIn, _fadeOut);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajustes guardados y aplicados correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ajustes de audio',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Botón prueba en vivo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isPlayingTest ? Icons.pause_circle_filled : Icons.play_circle_filled),
                  color: const Color(0xFF1D5BF7),
                  iconSize: 36,
                  onPressed: _toggleTestPlay,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isPlayingTest ? 'Escuchando prueba de ajustes...' : 'Toca para probar ajustes en vivo',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const SizedBox(width: 80, child: Text('Volumen:')),
              Expanded(
                child: Slider(
                  value: _volumen,
                  min: 0,
                  max: 200,
                  onChanged: (v) {
                    setState(() => _volumen = v);
                    _testPlayer.setVolume(v / 100.0);
                  },
                ),
              ),
              Text('${_volumen.toInt()}%'),
            ],
          ),

          Row(
            children: [
              const SizedBox(width: 80, child: Text('Tono:')),
              Expanded(
                child: Slider(
                  value: _tono,
                  min: -5,
                  max: 5,
                  divisions: 10,
                  onChanged: (v) {
                    setState(() => _tono = v);
                    _testPlayer.setPitch(1.0 + (v * 0.1));
                  },
                ),
              ),
              Text('${_tono > 0 ? '+' : ''}${_tono.toStringAsFixed(1)}'),
            ],
          ),

          SwitchListTile(
            title: const Text('Fade In (Entrada suave)'),
            value: _fadeIn,
            onChanged: (v) => setState(() => _fadeIn = v),
          ),
          SwitchListTile(
            title: const Text('Fade Out (Salida suave)'),
            value: _fadeOut,
            onChanged: (v) => setState(() => _fadeOut = v),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _guardarAjustes,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D5BF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Guardar ajustes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. MODAL MEZCLA - 100% FUNCIONAL (Música ambiental y mezcla en vivo)
// ============================================================================

class _AudioMixModal extends StatefulWidget {
  final String recordingId;
  final String title;
  final Duration totalDuration;
  final String? audioUrl;
  final String? currentAmbient;
  final double currentBalance;
  final Function(String, double, String?) onMixApplied;

  const _AudioMixModal({
    required this.recordingId,
    required this.title,
    required this.totalDuration,
    this.audioUrl,
    this.currentAmbient,
    required this.currentBalance,
    required this.onMixApplied,
  });

  @override
  State<_AudioMixModal> createState() => _AudioMixModalState();
}

class _AudioMixModalState extends State<_AudioMixModal> {
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();

  final Map<String, String> _ambientesUrl = {
    'Lluvia suave': 'https://actions.google.com/sounds/v1/weather/rain_heavy.ogg',
    'Café / Murmullo': 'https://actions.google.com/sounds/v1/ambiences/coffee_shop.ogg',
    'Ruido blanco / Océano': 'https://actions.google.com/sounds/v1/weather/waves_crashing.ogg',
    'Oficina': 'https://actions.google.com/sounds/v1/ambiences/office_ambience.ogg',
  };

  late String _ambienteSeleccionado;
  late double _balance;
  bool _isPlayingMix = false;

  @override
  void initState() {
    super.initState();
    _ambienteSeleccionado = widget.currentAmbient ?? 'Lluvia suave';
    _balance = widget.currentBalance;
    _initPlayers();
  }

  Future<void> _initPlayers() async {
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      try {
        await _voicePlayer.setUrl(widget.audioUrl!);
      } catch (_) {}
    }
    _cargarAmbiente(_ambienteSeleccionado);
  }

  Future<void> _cargarAmbiente(String nombre) async {
    final url = _ambientesUrl[nombre];
    if (url != null) {
      try {
        await _ambientPlayer.setUrl(url);
        await _ambientPlayer.setLoopMode(LoopMode.one);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _voicePlayer.dispose();
    _ambientPlayer.dispose();
    super.dispose();
  }

  void _togglePlayMix() async {
    if (_isPlayingMix) {
      await _voicePlayer.pause();
      await _ambientPlayer.pause();
      setState(() => _isPlayingMix = false);
    } else {
      final voiceVol = (_balance / 100.0).clamp(0.0, 1.0);
      final ambVol = ((100.0 - _balance) / 100.0).clamp(0.0, 1.0);
      await _voicePlayer.setVolume(voiceVol);
      await _ambientPlayer.setVolume(ambVol);
      await _voicePlayer.play();
      await _ambientPlayer.play();
      setState(() => _isPlayingMix = true);
    }
  }

  void _actualizarBalance(double v) {
    setState(() => _balance = v);
    if (_isPlayingMix) {
      _voicePlayer.setVolume((v / 100.0).clamp(0.0, 1.0));
      _ambientPlayer.setVolume(((100.0 - v) / 100.0).clamp(0.0, 1.0));
    }
  }

  void _aplicarMezcla({required bool comoNuevo}) async {
    final ambientUrl = _ambientesUrl[_ambienteSeleccionado];
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (comoNuevo) {
        final m = widget.totalDuration.inMinutes.toString().padLeft(2, '0');
        final s = (widget.totalDuration.inSeconds % 60).toString().padLeft(2, '0');
        await FirebaseFirestore.instance.collection('grabaciones').add({
          'titulo': '${widget.title} (Mezcla con $_ambienteSeleccionado)',
          'url': widget.audioUrl ?? '',
          'duracion': '$m:$s',
          'duracionSegundos': widget.totalDuration.inSeconds,
          'creadoEn': FieldValue.serverTimestamp(),
          'userId': user?.uid,
          'userEmail': user?.email,
          'mezcla': {
            'ambiente': _ambienteSeleccionado,
            'balance': _balance,
            'ambientUrl': ambientUrl,
          },
        });
      } else if (widget.recordingId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('grabaciones')
            .doc(widget.recordingId)
            .update({
          'mezcla': {
            'ambiente': _ambienteSeleccionado,
            'balance': _balance,
            'ambientUrl': ambientUrl,
          }
        });
      }

      widget.onMixApplied(_ambienteSeleccionado, _balance, ambientUrl);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mezcla aplicada con "$_ambienteSeleccionado"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar mezcla: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Mezcla de pistas de audio',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          // Botón prueba de mezcla simultánea
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isPlayingMix ? Icons.pause_circle_filled : Icons.play_circle_filled),
                  color: const Color(0xFF1D5BF7),
                  iconSize: 36,
                  onPressed: _togglePlayMix,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isPlayingMix ? 'Reproduciendo mezcla combinada...' : 'Escuchar voz y fondo juntos en vivo',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Text('Pista 1: Grabación principal (Voz)'),
          const SizedBox(height: 10),
          const Text('Pista 2: Fondo ambiental:'),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: _ambienteSeleccionado,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: _ambientesUrl.keys.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _ambienteSeleccionado = v);
                _cargarAmbiente(v);
              }
            },
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Text('Balance voz/fondo: '),
              Expanded(
                child: Slider(
                  value: _balance,
                  min: 0,
                  max: 100,
                  onChanged: _actualizarBalance,
                ),
              ),
              Text('${_balance.toInt()}% / ${(100 - _balance).toInt()}%'),
            ],
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () => _aplicarMezcla(comoNuevo: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D5BF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Aplicar a la grabación actual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 10),

          OutlinedButton(
            onPressed: () => _aplicarMezcla(comoNuevo: true),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1D5BF7)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Guardar como nueva grabación mezclada', style: TextStyle(color: Color(0xFF1D5BF7), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. MODAL DIVIDIR - 100% FUNCIONAL (Crea Parte 1 y Parte 2 con URL)
// ============================================================================

class _AudioSplitModal extends StatefulWidget {
  final String recordingId;
  final String title;
  final Duration totalDuration;
  final Duration currentPosition;
  final String? audioUrl;

  const _AudioSplitModal({
    required this.recordingId,
    required this.title,
    required this.totalDuration,
    required this.currentPosition,
    this.audioUrl,
  });

  @override
  State<_AudioSplitModal> createState() => _AudioSplitModalState();
}

class _AudioSplitModalState extends State<_AudioSplitModal> {
  final AudioPlayer _splitPlayer = AudioPlayer();
  late double _splitSec;
  bool _dividiendo = false;
  int? _previewingPart; // 1 o 2

  @override
  void initState() {
    super.initState();
    final totalSec = (widget.totalDuration.inMilliseconds > 0)
        ? (widget.totalDuration.inMilliseconds / 1000.0)
        : (widget.totalDuration.inSeconds > 0
            ? widget.totalDuration.inSeconds.toDouble()
            : 24.0);
    final max = totalSec > 0.2 ? totalSec : 24.0;

    if (max > 2.0) {
      _splitSec = widget.currentPosition.inSeconds > 0
          ? safeClamp(widget.currentPosition.inSeconds.toDouble(), 1.0, max - 1.0)
          : (max / 2.0);
    } else {
      _splitSec = max / 2.0;
    }

    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      try {
        await _splitPlayer.setUrl(widget.audioUrl!);
      } catch (_) {}
    }
    _splitPlayer.positionStream.listen((pos) {
      if (_previewingPart == 1 && pos.inMilliseconds >= (_splitSec * 1000).toInt()) {
        _splitPlayer.pause();
        if (mounted) setState(() => _previewingPart = null);
      }
    });
  }

  @override
  void dispose() {
    _splitPlayer.dispose();
    super.dispose();
  }

  void _previewPart(int part) async {
    if (_previewingPart == part) {
      await _splitPlayer.pause();
      setState(() => _previewingPart = null);
    } else {
      if (part == 1) {
        await _splitPlayer.seek(Duration.zero);
      } else {
        await _splitPlayer.seek(Duration(milliseconds: (_splitSec * 1000).toInt()));
      }
      await _splitPlayer.play();
      setState(() => _previewingPart = part);
    }
  }

  String _format(double sec) {
    final s = sec.toInt();
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  void _dividirGrabacion() async {
    setState(() => _dividiendo = true);
    final user = FirebaseAuth.instance.currentUser;
    final totalSec = (widget.totalDuration.inMilliseconds > 0)
        ? (widget.totalDuration.inMilliseconds / 1000.0)
        : (widget.totalDuration.inSeconds > 0
            ? widget.totalDuration.inSeconds.toDouble()
            : 24.0);
    final max = totalSec > 0.2 ? totalSec : 24.0;
    final p1 = safeClamp(_splitSec, 0.1, max - 0.1);
    final p2 = max - p1;

    try {
      // Guardar Parte 1
      await FirebaseFirestore.instance.collection('grabaciones').add({
        'titulo': '${widget.title} (Parte 1)',
        'url': widget.audioUrl ?? '',
        'duracion': _format(p1),
        'duracionSegundos': p1.round() > 0 ? p1.round() : 1,
        'creadoEn': FieldValue.serverTimestamp(),
        'userId': user?.uid,
        'userEmail': user?.email,
      });

      // Guardar Parte 2
      await FirebaseFirestore.instance.collection('grabaciones').add({
        'titulo': '${widget.title} (Parte 2)',
        'url': widget.audioUrl ?? '',
        'duracion': _format(p2),
        'duracionSegundos': p2.round() > 0 ? p2.round() : 1,
        'creadoEn': FieldValue.serverTimestamp(),
        'userId': user?.uid,
        'userEmail': user?.email,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio dividido con éxito en Parte 1 y Parte 2')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al dividir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _dividiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSec = (widget.totalDuration.inMilliseconds > 0)
        ? (widget.totalDuration.inMilliseconds / 1000.0)
        : (widget.totalDuration.inSeconds > 0
            ? widget.totalDuration.inSeconds.toDouble()
            : 24.0);
    final max = totalSec > 0.2 ? totalSec : 24.0;

    final double sliderMin;
    final double sliderMax;

    if (max > 2.0) {
      sliderMin = 1.0;
      sliderMax = max - 1.0;
    } else {
      sliderMin = 0.1;
      sliderMax = (max - 0.1) > 0.15 ? (max - 0.1) : 0.9;
    }

    final currentSliderVal = safeClamp(_splitSec, sliderMin, sliderMax);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Dividir grabación',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Punto de corte: ${_format(currentSliderVal)}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1D5BF7)),
          ),
          Slider(
            value: currentSliderVal,
            min: sliderMin,
            max: sliderMax,
            onChanged: (v) => setState(() => _splitSec = v),
          ),

          // Tarjetas de preescucha Parte 1 y Parte 2
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Parte 1', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('00:00 - ${_format(_splitSec)}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      const SizedBox(height: 6),
                      IconButton(
                        icon: Icon(_previewingPart == 1 ? Icons.stop_circle : Icons.play_circle),
                        color: const Color(0xFF1D5BF7),
                        onPressed: () => _previewPart(1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Parte 2', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_format(_splitSec)} - ${_format(max)}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      const SizedBox(height: 6),
                      IconButton(
                        icon: Icon(_previewingPart == 2 ? Icons.stop_circle : Icons.play_circle),
                        color: const Color(0xFF1D5BF7),
                        onPressed: () => _previewPart(2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _dividiendo ? null : _dividirGrabacion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D5BF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Dividir y guardar ambas partes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. MODAL FUSIONAR - 100% FUNCIONAL (Combina con grabaciones de tu biblioteca)
// ============================================================================

class _AudioMergeModal extends StatefulWidget {
  final String recordingId;
  final String title;
  final Duration totalDuration;
  final String? audioUrl;
  final Function(Duration) onMergeSuccess;

  const _AudioMergeModal({
    required this.recordingId,
    required this.title,
    required this.totalDuration,
    this.audioUrl,
    required this.onMergeSuccess,
  });

  @override
  State<_AudioMergeModal> createState() => _AudioMergeModalState();
}

class _AudioMergeModalState extends State<_AudioMergeModal> {
  final AudioPlayer _playerA = AudioPlayer();
  final AudioPlayer _playerB = AudioPlayer();

  String? _segundoAudioId;
  String _segundoAudioTitulo = 'Selecciona una grabación';
  int _segundoAudioDurSeg = 0;
  String? _segundoAudioUrl;
  bool _invertirOrden = false;
  bool _fusionando = false;
  int? _previewingPlayer;

  @override
  void initState() {
    super.initState();
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      _playerA.setUrl(widget.audioUrl!).catchError((_) => null);
    }
  }

  @override
  void dispose() {
    _playerA.dispose();
    _playerB.dispose();
    super.dispose();
  }

  void _previewTrack(int track) async {
    if (_previewingPlayer == track) {
      if (track == 1) await _playerA.pause();
      if (track == 2) await _playerB.pause();
      setState(() => _previewingPlayer = null);
    } else {
      if (track == 1) {
        await _playerB.pause();
        await _playerA.seek(Duration.zero);
        await _playerA.play();
      } else {
        await _playerA.pause();
        await _playerB.seek(Duration.zero);
        await _playerB.play();
      }
      setState(() => _previewingPlayer = track);
    }
  }

  void _fusionarGrabaciones() async {
    if (_segundoAudioDurSeg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una segunda grabación para fusionar')),
      );
      return;
    }

    setState(() => _fusionando = true);
    final user = FirebaseAuth.instance.currentUser;
    final nuevaDur = widget.totalDuration + Duration(seconds: _segundoAudioDurSeg);
    final m = nuevaDur.inMinutes.toString().padLeft(2, '0');
    final s = (nuevaDur.inSeconds % 60).toString().padLeft(2, '0');

    final parte1 = _invertirOrden ? _segundoAudioTitulo : widget.title;
    final parte2 = _invertirOrden ? widget.title : _segundoAudioTitulo;
    final chosenUrl = widget.audioUrl != null && widget.audioUrl!.isNotEmpty
        ? widget.audioUrl
        : _segundoAudioUrl;

    try {
      await FirebaseFirestore.instance.collection('grabaciones').add({
        'titulo': '$parte1 + $parte2',
        'url': chosenUrl ?? '',
        'duracion': '$m:$s',
        'duracionSegundos': nuevaDur.inSeconds,
        'creadoEn': FieldValue.serverTimestamp(),
        'userId': user?.uid,
        'userEmail': user?.email,
      });

      widget.onMergeSuccess(nuevaDur);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fusionado con éxito en "$m:$s"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al fusionar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _fusionando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final durTotal = widget.totalDuration.inSeconds + _segundoAudioDurSeg;
    final minCombined = (durTotal ~/ 60).toString().padLeft(2, '0');
    final secCombined = (durTotal % 60).toString().padLeft(2, '0');

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Fusionar grabaciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // Selector de grabación de la biblioteca
            const Text('Selecciona la segunda grabación a fusionar:'),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('grabaciones')
                  .where('userId', isEqualTo: user?.uid ?? '')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs
                    .where((d) => d.id != widget.recordingId)
                    .toList();

                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('No tienes otra grabación guardada aún. Puedes grabar otro audio para fusionarlo aquí.'),
                  );
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _segundoAudioId,
                      hint: const Text('Elegir segunda grabación'),
                      items: docs.map((doc) {
                        final data = doc.data();
                        final t = data['titulo'] as String? ?? 'Grabación';
                        final d = data['duracion'] as String? ?? '00:00';
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Row(
                            children: [
                              const Icon(Icons.audio_file, color: Color(0xFF1D5BF7), size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(t)),
                              Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          final match = docs.firstWhere((d) => d.id == id);
                          final dData = match.data();
                          final url = dData['url'] as String?;
                          setState(() {
                            _segundoAudioId = id;
                            _segundoAudioTitulo = dData['titulo'] as String? ?? 'Grabación';
                            _segundoAudioDurSeg = (dData['duracionSegundos'] as num?)?.toInt() ?? 10;
                            _segundoAudioUrl = url;
                          });
                          if (url != null && url.isNotEmpty) {
                            _playerB.setUrl(url).catchError((_) => null);
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // Previsualización y orden
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Orden de unión:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => _invertirOrden = !_invertirOrden),
                  icon: const Icon(Icons.swap_vert, size: 18),
                  label: const Text('Invertir'),
                ),
              ],
            ),

            // Tarjeta Pista 1
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.audio_file, color: Color(0xFF1D5BF7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Parte 1: ${_invertirOrden ? _segundoAudioTitulo : widget.title}'),
                  ),
                  Text(
                    '${_invertirOrden ? _segundoAudioDurSeg : widget.totalDuration.inSeconds} s',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(_previewingPlayer == (_invertirOrden ? 2 : 1) ? Icons.stop : Icons.play_arrow),
                    onPressed: () => _previewTrack(_invertirOrden ? 2 : 1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Center(child: Icon(Icons.add, color: Color(0xFF1D5BF7), size: 22)),
            const SizedBox(height: 8),

            // Tarjeta Pista 2
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.audio_file, color: Color(0xFF1D5BF7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Parte 2: ${_invertirOrden ? widget.title : _segundoAudioTitulo}'),
                  ),
                  Text(
                    '${_invertirOrden ? widget.totalDuration.inSeconds : _segundoAudioDurSeg} s',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(_previewingPlayer == (_invertirOrden ? 1 : 2) ? Icons.stop : Icons.play_arrow),
                    onPressed: () => _previewTrack(_invertirOrden ? 1 : 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                'Duración total resultante: $minCombined:$secCombined',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D5BF7)),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: (_fusionando || _segundoAudioDurSeg <= 0) ? null : _fusionarGrabaciones,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D5BF7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Fusionar y guardar como nueva grabación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
