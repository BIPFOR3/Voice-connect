import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';

import 'theme/theme.dart';
import 'community_audio_detail.dart';

class NewCommunityPostScreen extends StatefulWidget {
  const NewCommunityPostScreen({super.key});

  @override
  State<NewCommunityPostScreen> createState() => _NewCommunityPostScreenState();
}

class _NewCommunityPostScreenState extends State<NewCommunityPostScreen> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final AudioPlayer _player = AudioPlayer();

  String _grupoSeleccionado = 'Estudio';
  final List<String> _grupos = ['Estudio', 'Trabajo', 'Ideas'];

  String? _selectedAudioUrl;
  String _selectedAudioTitle = 'Mi Audio';
  String _selectedAudioDuration = '00:06';
  String _selectedAudioTime = 'Hoy 12:00 p.m.';
  bool _isPlaying = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarUltimoAudioUsuario();
    _player.playerStateStream.listen((state) {
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
    _tituloController.dispose();
    _descController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _cargarUltimoAudioUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('grabaciones')
          .where('userId', isEqualTo: user.uid)
          .limit(10)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first.data();
        setState(() {
          _selectedAudioUrl = doc['audioUrl'];
          _selectedAudioTitle = doc['titulo'] ?? doc['title'] ?? 'Mi Audio';
          _selectedAudioDuration = doc['duracion'] ?? '00:06';
          _selectedAudioTime = doc['fecha'] ?? 'Hoy 12:00 p.m.';
          if (_tituloController.text.isEmpty) {
            _tituloController.text = _selectedAudioTitle;
          }
        });
        if (_selectedAudioUrl != null) {
          await _player.setUrl(_selectedAudioUrl!);
        }
      }
    } catch (e) {
      debugPrint('Aviso cargando grabaciones para adjuntar: $e');
    }
  }

  void _togglePlayAudio() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_selectedAudioUrl != null) {
        await _player.play();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reproduciendo vista previa simulada')),
        );
        setState(() => _isPlaying = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isPlaying = false);
        });
      }
    }
  }

  Future<void> _publicar() async {
    final titulo = _tituloController.text.trim();
    final desc = _descController.text.trim();

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe un título para la publicación')),
      );
      return;
    }

    setState(() => _guardando = true);

    final user = FirebaseAuth.instance.currentUser;
    final nombreAutor = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email != null ? user!.email!.split('@').first : 'Ana Torres');

    try {
      final newDoc = await FirebaseFirestore.instance
          .collection('publicaciones_comunidad')
          .add({
        'title': titulo,
        'description': desc,
        'authorName': nombreAutor,
        'authorId': user?.uid ?? '',
        'group': _grupoSeleccionado,
        'audioUrl': _selectedAudioUrl,
        'durationText': _selectedAudioDuration,
        'timeText': 'Hoy, ${_formatHoraActual()}',
        'isPinned': false,
        'likesCount': 0,
        'commentsCount': 0,
        'comments': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Publicación creada exitosamente en la comunidad!')),
        );
        Navigator.of(context).pop(
          CommunityPost(
            id: newDoc.id,
            title: titulo,
            description: desc,
            authorName: nombreAutor,
            authorId: user?.uid ?? '',
            group: _grupoSeleccionado,
            audioUrl: _selectedAudioUrl,
            durationText: _selectedAudioDuration,
            timeText: 'Hoy, ${_formatHoraActual()}',
            likesCount: 0,
            commentsCount: 0,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error publicando en Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _formatHoraActual() {
    final now = DateTime.now();
    final hora = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final min = now.minute.toString().padLeft(2, '0');
    final per = now.hour >= 12 ? 'p.m.' : 'a.m.';
    return '$hora:$min $per';
  }

  Widget _buildWaveformBars() {
    const barHeights = [
      8.0, 14.0, 22.0, 10.0, 16.0, 28.0, 16.0, 22.0, 32.0, 14.0,
      10.0, 24.0, 18.0, 12.0, 18.0, 30.0, 22.0, 14.0, 28.0, 20.0,
      14.0, 10.0, 24.0, 18.0, 12.0, 26.0, 18.0, 12.0, 16.0, 24.0,
      16.0, 10.0
    ];

    return SizedBox(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: barHeights.map((h) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.2),
            width: 2.8,
            height: h,
            decoration: BoxDecoration(
              color: const Color(0xFF6B7280),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSemanticColors.surfaceMain,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón Atrás
              GestureDetector(
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

              const SizedBox(height: 20),

              // Título
              const Text(
                'Nueva publicación',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Montserrat',
                ),
              ),

              const SizedBox(height: 28),

              // 1. Audio adjunto
              const Text(
                'Audio adjunto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // Tarjeta de Audio Adjunto (Imagen 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Botón Reproducir
                        GestureDetector(
                          onTap: _togglePlayAudio,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1D5BF7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Ondas
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildWaveformBars(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 3 puntos
                        const Icon(
                          Icons.more_vert,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedAudioTime,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          Text(
                            _selectedAudioDuration,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Título
              const Text(
                'Título',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un título',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Descripción
              const Text(
                'Descripción',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _descController,
                  minLines: 5,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Agrega una descripción',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 4. Grupo
              const Text(
                'Grupo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _grupos.map((grupo) {
                  final isSelected = _grupoSeleccionado == grupo;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _grupoSeleccionado = grupo),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1D5BF7) : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1D5BF7) : const Color(0xFF2B2B2B),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          grupo,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF2B2B2B),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 48),

              // Botón Publicar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _publicar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5BF7),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Publicar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
