import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'theme/theme.dart';
import 'home.dart';
import 'profile.dart';

class CommunityComment {
  final String id;
  final String authorName;
  final String text;
  final String timeText;
  int likes;
  bool isLiked;

  CommunityComment({
    required this.id,
    required this.authorName,
    required this.text,
    required this.timeText,
    this.likes = 0,
    this.isLiked = false,
  });

  factory CommunityComment.fromMap(Map<String, dynamic> map, String id) {
    return CommunityComment(
      id: id,
      authorName: map['authorName'] ?? 'Usuario',
      text: map['text'] ?? '',
      timeText: map['timeText'] ?? 'Hoy',
      likes: map['likes'] ?? 0,
      isLiked: map['isLiked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorName': authorName,
      'text': text,
      'timeText': timeText,
      'likes': likes,
      'isLiked': isLiked,
    };
  }
}

class CommunityPost {
  final String id;
  final String title;
  final String description;
  final String authorName;
  final String authorId;
  final String group;
  final String? audioUrl;
  final String durationText;
  final String timeText;
  final bool isPinned;
  int likesCount;
  bool isLiked;
  int commentsCount;
  List<CommunityComment> comments;

  CommunityPost({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    this.authorId = '',
    required this.group,
    this.audioUrl,
    this.durationText = '00:06',
    this.timeText = 'Hoy, 4:15 p.m.',
    this.isPinned = false,
    this.likesCount = 5,
    this.isLiked = false,
    this.commentsCount = 2,
    List<CommunityComment>? comments,
  }) : comments = comments ?? [];

  factory CommunityPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawComments = (data['comments'] as List<dynamic>?) ?? [];
    return CommunityPost(
      id: doc.id,
      title: data['title'] ?? 'Grabación',
      description: data['description'] ?? '',
      authorName: data['authorName'] ?? 'Usuario',
      authorId: data['authorId'] ?? '',
      group: data['group'] ?? 'Estudio',
      audioUrl: data['audioUrl'],
      durationText: data['durationText'] ?? '00:06',
      timeText: data['timeText'] ?? 'Hoy',
      isPinned: data['isPinned'] ?? false,
      likesCount: data['likesCount'] ?? 0,
      isLiked: data['isLiked'] ?? false,
      commentsCount: rawComments.isNotEmpty ? rawComments.length : (data['commentsCount'] ?? 0),
      comments: rawComments
          .map((c) => CommunityComment.fromMap(Map<String, dynamic>.from(c), ''))
          .toList(),
    );
  }
}

class CommunityAudioDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const CommunityAudioDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<CommunityAudioDetailScreen> createState() =>
      _CommunityAudioDetailScreenState();
}

class _CommunityAudioDetailScreenState
    extends State<CommunityAudioDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _commentController = TextEditingController();

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 6);
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  late List<CommunityComment> _comments;

  @override
  void initState() {
    super.initState();
    _comments = widget.post.comments.isNotEmpty
        ? List.from(widget.post.comments)
        : [
            CommunityComment(
              id: 'c1',
              authorName: 'Carmen Flores',
              text: '¡Gracias por compartir!, todo muy claro.',
              timeText: 'Hoy, 4:15 p.m.',
              likes: 5,
            ),
            CommunityComment(
              id: 'c2',
              authorName: 'Manuel Duarte',
              text: 'Excelente, agregaré esos puntos.',
              timeText: 'Ayer, 4:15 p.m.',
              likes: 5,
            ),
          ];

    _initAudio();
  }

  Future<void> _initAudio() async {
    if (widget.post.audioUrl != null && widget.post.audioUrl!.isNotEmpty) {
      try {
        await _player.setUrl(widget.post.audioUrl!);
      } catch (e) {
        debugPrint('Error cargando audio url: $e');
      }
    }

    _posSub = _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _durSub = _player.durationStream.listen((dur) {
      if (dur != null && mounted) setState(() => _duration = dur);
    });

    _stateSub = _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing &&
              state.processingState != ProcessingState.completed;
          if (state.processingState == ProcessingState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_player.duration != null && _position >= _duration) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  void _rewind10() async {
    final target = _position - const Duration(seconds: 10);
    await _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  void _forward10() async {
    final target = _position + const Duration(seconds: 10);
    await _player.seek(target > _duration ? _duration : target);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _agregarComentario() {
    final texto = _commentController.text.trim();
    if (texto.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final nombre = user?.displayName ??
        (user?.email != null ? user!.email!.split('@').first : 'Mi Usuario');

    setState(() {
      _comments.insert(
        0,
        CommunityComment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          authorName: nombre,
          text: texto,
          timeText: 'Ahora',
          likes: 0,
        ),
      );
      widget.post.commentsCount = _comments.length;
      _commentController.clear();
    });

    // Actualizar en Firestore si el doc existe
    if (widget.post.id.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('publicaciones_comunidad')
          .doc(widget.post.id)
          .update({
        'comments': _comments.map((c) => c.toMap()).toList(),
        'commentsCount': _comments.length,
      }).catchError((e) {
        debugPrint('Error actualizando comentarios en firestore: $e');
      });
    }
  }

  void _toggleLikeComment(CommunityComment comment) {
    setState(() {
      if (comment.isLiked) {
        comment.likes--;
        comment.isLiked = false;
      } else {
        comment.likes++;
        comment.isLiked = true;
      }
    });
  }

  Widget _buildWaveformBars() {
    const barHeights = [
      12.0, 18.0, 28.0, 16.0, 22.0, 36.0, 20.0, 26.0, 40.0, 18.0,
      14.0, 30.0, 24.0, 16.0, 22.0, 38.0, 28.0, 20.0, 36.0, 26.0,
      18.0, 14.0, 32.0, 24.0, 16.0, 34.0, 26.0, 18.0, 22.0, 32.0,
      22.0, 16.0, 12.0
    ];

    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: barHeights.map((h) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3.5,
            height: h,
            decoration: BoxDecoration(
              color: const Color(0xFF757575),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }).toList(),
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
          // Home
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                NoFadePageRoute(child: const RecordingsHomeScreen()),
                (route) => false,
              );
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
          // Comunidades (Activo)
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
              Icons.groups,
              color: AppColors.gs1000,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing400),
          // Perfil
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                NoFadePageRoute(child: const ProfileScreen()),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppPadding.md),
              child: Icon(
                Icons.person_outline,
                color: AppColors.gs1000,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressValue = (_duration.inMilliseconds > 0)
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppSemanticColors.surfaceMain,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
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

                  // Título principal
                  const Text(
                    'Detalle de audio',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Datos del Audio: Título y Autor
                  Text(
                    widget.post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.post.authorName} | ${widget.post.timeText}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tarjeta Reproductor Completo (Imagen 3)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Ondas
                        _buildWaveformBars(),

                        const SizedBox(height: 12),

                        // Barra de progreso interactiva
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.5,
                            activeTrackColor: const Color(0xFFB0B7C3),
                            inactiveTrackColor: const Color(0xFFE5E7EB),
                            thumbColor: const Color(0xFF1D5BF7),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: progressValue,
                            onChanged: (val) {
                              final newPos = Duration(
                                milliseconds: (val * _duration.inMilliseconds).toInt(),
                              );
                              _player.seek(newPos);
                            },
                          ),
                        ),

                        // Tiempo
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _formatDuration(_position),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Fila de Controles: Rebobinar 10s, Play/Pause, Avanzar 10s, Eliminar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.replay_10),
                              iconSize: 32,
                              color: const Color(0xFF4B5563),
                              onPressed: _rewind10,
                            ),
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1D5BF7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.forward_10),
                              iconSize: 32,
                              color: const Color(0xFF4B5563),
                              onPressed: _forward10,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              iconSize: 28,
                              color: const Color(0xFF9CA3AF),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Acción no permitida en audios públicos'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sección: Descripción
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.post.description.isNotEmpty
                        ? widget.post.description
                        : 'Resumen con los principales temas y puntos que se tocaron en clase.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sección: Comentarios
                  Text(
                    'Comentarios (${_comments.length})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Caja para escribir comentario
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Escribe un comentario...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9E9E9E),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _agregarComentario,
                        icon: const Icon(Icons.send_rounded),
                        color: const Color(0xFF1D5BF7),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Lista de comentarios
                  ..._comments.map((comment) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFE5E7EB),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF9CA3AF),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment.authorName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      comment.timeText,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.more_vert,
                                color: Color(0xFF9CA3AF),
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 46),
                            child: Text(
                              comment.text,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF374151),
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => _toggleLikeComment(comment),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    comment.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 16,
                                    color: comment.isLiked
                                        ? Colors.red
                                        : const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${comment.likes}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 120),
                ],
              ),
            ),

            // Barra flotante inferior
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
