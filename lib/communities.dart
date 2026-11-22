import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'theme/theme.dart';
import 'home.dart';
import 'profile.dart';
import 'community_audio_detail.dart';
import 'community_new_post.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();

  String? _activeAudioUrl;
  bool _isPlaying = false;
  int _selectedTabIndex = 0; // 0: Todas, 1: Estudio, 2: Oficina
  final List<String> _tabs = ['Todas', 'Estudio', 'Oficina'];
  String _searchQuery = '';

  // Lista local para datos demo e interactivos
  late List<CommunityPost> _defaultPosts;

  @override
  void initState() {
    super.initState();
    _defaultPosts = [
      CommunityPost(
        id: 'demo_1',
        title: 'Clase 10',
        description: 'Resumen con los principales temas y puntos que se tocaron en clase.',
        authorName: 'Ana Torres',
        group: 'Estudio',
        durationText: '00:06',
        timeText: 'Lun 29, 10:00 p.m.',
        isPinned: true,
        likesCount: 5,
        commentsCount: 3,
        comments: [
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
        ],
      ),
      CommunityPost(
        id: 'demo_2',
        title: 'Grabación 10',
        description: 'Puntos clave de la sesión de estudio y resolución de dudas.',
        authorName: 'Ana Torres',
        group: 'Estudio',
        durationText: '00:06',
        timeText: 'Hoy, 4:15 p.m.',
        likesCount: 5,
        commentsCount: 3,
      ),
      CommunityPost(
        id: 'demo_3',
        title: 'Grabación 10',
        description: 'Minuta de la reunión de trabajo y objetivos del mes.',
        authorName: 'Ana Torres',
        group: 'Oficina',
        durationText: '00:06',
        timeText: 'Hoy, 4:15 p.m.',
        likesCount: 5,
        commentsCount: 3,
      ),
      CommunityPost(
        id: 'demo_4',
        title: 'Grabación 10',
        description: 'Notas de voz y seguimiento de proyectos colaborativos.',
        authorName: 'Ana Torres',
        group: 'Estudio',
        durationText: '00:06',
        timeText: 'Hoy, 4:15 p.m.',
        likesCount: 5,
        commentsCount: 3,
      ),
    ];

    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing &&
              state.processingState != ProcessingState.completed;
          if (state.processingState == ProcessingState.completed) {
            _activeAudioUrl = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _reproducirAudio(CommunityPost post) async {
    if (post.audioUrl != null && post.audioUrl!.isNotEmpty) {
      if (_activeAudioUrl == post.audioUrl && _isPlaying) {
        await _player.pause();
      } else {
        _activeAudioUrl = post.audioUrl;
        await _player.setUrl(post.audioUrl!);
        await _player.play();
      }
    } else {
      // Audio simulado
      if (_activeAudioUrl == post.id && _isPlaying) {
        setState(() {
          _isPlaying = false;
          _activeAudioUrl = null;
        });
      } else {
        setState(() {
          _activeAudioUrl = post.id;
          _isPlaying = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reproduciendo "${post.title}"'),
            duration: const Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 6), () {
          if (mounted && _activeAudioUrl == post.id) {
            setState(() {
              _isPlaying = false;
              _activeAudioUrl = null;
            });
          }
        });
      }
    }
  }

  void _abrirNuevaPublicacion() async {
    final result = await Navigator.push<CommunityPost?>(
      context,
      MaterialPageRoute(builder: (_) => const NewCommunityPostScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _defaultPosts.insert(0, result);
      });
    }
  }

  void _abrirDetalle(CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityAudioDetailScreen(post: post),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _toggleLike(CommunityPost post) {
    setState(() {
      if (post.isLiked) {
        post.likesCount--;
        post.isLiked = false;
      } else {
        post.likesCount++;
        post.isLiked = true;
      }
    });
  }

  Widget _buildHeaderTitle() {
    return const Text(
      'Comunidades',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Color(0xFF6B7280),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: 'Buscar grabaciones...',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9E9E9E),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(
                Icons.close,
                color: Color(0xFF9E9E9E),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        for (int index = 0; index < _tabs.length; index++) ...[
          if (index > 0) const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _selectedTabIndex == index
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: _selectedTabIndex == index
                            ? Colors.black
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  Container(
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == index
                          ? const Color(0xFF1D5BF7)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWaveformBars({Color color = const Color(0xFF757575), int count = 28}) {
    const heights = [
      8.0, 14.0, 22.0, 12.0, 18.0, 28.0, 16.0, 22.0, 34.0, 16.0,
      12.0, 26.0, 18.0, 14.0, 20.0, 32.0, 24.0, 16.0, 30.0, 22.0,
      14.0, 12.0, 26.0, 18.0, 14.0, 28.0, 18.0, 12.0,
    ];

    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(count.clamp(10, heights.length), (i) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.2),
            width: 2.6,
            height: heights[i],
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAudioCard(CommunityPost post, {bool isPinned = false}) {
    final isThisPlaying = _isPlaying &&
        (_activeAudioUrl == (post.audioUrl ?? post.id));

    return GestureDetector(
      onTap: () => _abrirDetalle(post),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Botón Play
                GestureDetector(
                  onTap: () => _reproducirAudio(post),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1D5BF7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isThisPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Datos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isPinned
                                  ? post.authorName
                                  : '${post.authorName} | ${post.timeText}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Icono Fijado o Menú 3 puntos
                if (isPinned)
                  Transform.rotate(
                    angle: 0.5,
                    child: const Icon(
                      Icons.push_pin_outlined,
                      color: Colors.black87,
                      size: 20,
                    ),
                  )
                else
                  const Icon(
                    Icons.more_vert,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
              ],
            ),

            // Si es fijado, mostrar ondas doradas grandes (Imagen 4)
            if (isPinned) ...[
              const SizedBox(height: 10),
              Center(
                child: _buildWaveformBars(
                  color: const Color(0xFFF59E0B),
                  count: 26,
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Pie de tarjeta: Comentarios, Corazón y Duración
            Row(
              children: [
                // Comentarios
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${post.commentsCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                // Likes
                GestureDetector(
                  onTap: () => _toggleLike(post),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: post.isLiked ? Colors.red : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${post.likesCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Duración
                Text(
                  post.durationText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
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
          // Home
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                NoFadePageRoute(child: const RecordingsHomeScreen()),
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
          // Comunidades (Activo con píldora blanca)
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
              Navigator.pushReplacement(
                context,
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
    final currentTabName = _tabs[_selectedTabIndex];

    return Scaffold(
      backgroundColor: AppSemanticColors.surfaceMain,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera FIJA: Menú, Título, Buscador y Pestañas
                Container(
                  color: AppSemanticColors.surfaceMain,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTitle(),
                      const SizedBox(height: 14),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildTabs(),
                    ],
                  ),
                ),

                // Lista scrolleable conectada a Firestore + demo
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('publicaciones_comunidad')
                        .snapshots(),
                    builder: (context, snapshot) {
                      List<CommunityPost> allPosts = List.from(_defaultPosts);

                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        final firestorePosts = snapshot.data!.docs
                            .map((doc) => CommunityPost.fromFirestore(doc))
                            .toList();

                        // Unificar sin duplicados
                        final ids = firestorePosts.map((p) => p.id).toSet();
                        allPosts = [
                          ...firestorePosts,
                          ..._defaultPosts.where((p) => !ids.contains(p.id)),
                        ];
                      }

                      // Filtrar por tab ("Todas", "Estudio", "Oficina")
                      if (_selectedTabIndex > 0) {
                        allPosts = allPosts
                            .where((p) =>
                                p.group.toLowerCase() ==
                                currentTabName.toLowerCase())
                            .toList();
                      }

                      // Filtrar por búsqueda
                      if (_searchQuery.isNotEmpty) {
                        allPosts = allPosts
                            .where((p) =>
                                p.title.toLowerCase().contains(_searchQuery) ||
                                p.description.toLowerCase().contains(_searchQuery) ||
                                p.authorName.toLowerCase().contains(_searchQuery))
                            .toList();
                      }

                      final isGrupoView = _selectedTabIndex > 0;
                      final pinnedPost = allPosts.where((p) => p.isPinned).toList();
                      final recentPosts = allPosts.where((p) => !p.isPinned).toList();

                      return ListView(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: 140,
                        ),
                        children: [
                          // Si estamos en un grupo (Imagen 4): Mostrar Miembros
                          if (isGrupoView) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Miembros (3)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: List.generate(3, (index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE5E7EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF6B7280),
                                    size: 22,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 20),

                            // Sección Fijado
                            if (pinnedPost.isNotEmpty) ...[
                              const Text(
                                'Fijado',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...pinnedPost.map(
                                (p) => _buildAudioCard(p, isPinned: true),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Sección Recientes
                            const Text(
                              'Recientes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...recentPosts.map((p) => _buildAudioCard(p)),

                            const SizedBox(height: 16),

                            // Botón "Publicar grabación" al pie de grupo (Imagen 4)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _abrirNuevaPublicacion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D5BF7),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Publicar grabación',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Vista "Todas" (Imagen 1)
                            if (allPosts.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text(
                                    'No hay grabaciones en la comunidad.',
                                    style: TextStyle(color: Color(0xFF9E9E9E)),
                                  ),
                                ),
                              )
                            else
                              ...allPosts.map((p) => _buildAudioCard(p)),
                          ],

                          // Espacio para FAB y barra inferior
                          const SizedBox(height: 140),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            // Botón Flotante "+" (FAB) en vista "Todas" (Imagen 1)
            if (_selectedTabIndex == 0)
              Positioned(
                right: 24,
                bottom: 100,
                child: GestureDetector(
                  onTap: _abrirNuevaPublicacion,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D5BF7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D5BF7).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),

            // Barra de Navegación Flotante Inferior
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
