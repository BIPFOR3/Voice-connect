import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_audio/just_audio.dart';

import 'theme/theme.dart';
import 'recording.dart';
import 'profile.dart';
import 'communities.dart';
import 'audio_editor.dart';
import 'audio_storage.dart';

class RecordingsHomeScreen extends StatefulWidget {
  const RecordingsHomeScreen({super.key});

  @override
  State<RecordingsHomeScreen> createState() => _RecordingsHomeScreenState();
}

class _RecordingsHomeScreenState extends State<RecordingsHomeScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? _activeDocId;
  bool _isPlaying = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTabIndex = 0; // 0: Todas, 1: Favoritos
  final Set<String> _favoritosIds = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _favoritosSub;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _streamGrabaciones;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _streamGrabaciones = FirebaseFirestore.instance
        .collection('grabaciones')
        .where('userId', isEqualTo: user?.uid ?? '')
        .snapshots();
    _iniciarEscuchaFavoritos();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    });
  }

  void _iniciarEscuchaFavoritos() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _favoritosSub = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (data['favoritos'] is List) {
            final lista = List<String>.from(data['favoritos']);
            if (mounted) {
              setState(() {
                _favoritosIds.clear();
                _favoritosIds.addAll(lista);
              });
            }
          }
        }
      }, onError: (e) {
        debugPrint('Error al cargar favoritos: $e');
      });
    }
  }

  @override
  void dispose() {
    _favoritosSub?.cancel();
    _searchController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _reproducir(String docId, String url) async {
    try {
      if (_activeDocId == docId) {
        if (_isPlaying) {
          await _player.pause();
          if (mounted) setState(() => _isPlaying = false);
        } else {
          await _player.play();
          if (mounted) setState(() => _isPlaying = true);
        }
      } else {
        await _player.stop();
        await _player.setUrl(url);
        await _player.play();
        if (mounted) {
          setState(() {
            _activeDocId = docId;
            _isPlaying = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reproducir audio: $e')),
        );
      }
    }
  }

  void _compartirGrabacion(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de compartir próximamente')),
    );
  }

  Future<void> _renombrarGrabacion(String id, String tituloActual) async {
    final controller = TextEditingController(text: tituloActual);
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar grabación'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nuevo nombre',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoTitulo != null &&
        nuevoTitulo.isNotEmpty &&
        nuevoTitulo != tituloActual) {
      await FirebaseFirestore.instance
          .collection('grabaciones')
          .doc(id)
          .update({'titulo': nuevoTitulo});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grabación renombrada')),
        );
      }
    }
  }

  Future<void> _duplicarGrabacion(Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final nuevaData = Map<String, dynamic>.from(data);
      nuevaData['titulo'] = '${nuevaData['titulo'] ?? 'Grabación'} (Copia)';
      nuevaData['creadoEn'] = FieldValue.serverTimestamp();
      nuevaData['userId'] = user?.uid;
      nuevaData['userEmail'] = user?.email;
      await FirebaseFirestore.instance.collection('grabaciones').add(nuevaData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grabación duplicada con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al duplicar: $e')),
        );
      }
    }
  }

  void _editarGrabacion(
    String id,
    String title, {
    String? url,
    num? durationSeconds,
    String? durationText,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioEditorScreen(
          recordingId: id,
          initialTitle: title,
          audioUrl: url,
          durationSeconds: durationSeconds,
          durationText: durationText,
        ),
      ),
    );
  }

  void _transcribirGrabacion(
    String id,
    String title,
    String url,
    String? transcripcion,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => TranscriptionModal(
        recordingId: id,
        title: title,
        audioUrl: url,
        existingTranscription: transcripcion,
      ),
    );
  }

  void _moverGrabacion(String id, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mover "$title" a otra carpeta próximamente')),
    );
  }

  Future<void> _toggleFavorito(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final isFav = _favoritosIds.contains(id);

    setState(() {
      if (isFav) {
        _favoritosIds.remove(id);
      } else {
        _favoritosIds.add(id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !isFav ? 'Agregado a favoritos' : 'Eliminado de favoritos',
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({
          'favoritos': !isFav
              ? FieldValue.arrayUnion([id])
              : FieldValue.arrayRemove([id]),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error guardando favorito en Firestore: $e');
      }
    }
  }

  Future<void> _confirmarEliminar(
      String id, String title, String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar grabación'),
        content: Text('¿Deseas eliminar "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppSemanticColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (_activeDocId == id) {
        await _player.stop();
        if (mounted) {
          setState(() {
            _activeDocId = null;
            _isPlaying = false;
          });
        }
      }

      if (_favoritosIds.contains(id)) {
        setState(() => _favoritosIds.remove(id));
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .set({
              'favoritos': FieldValue.arrayRemove([id]),
            }, SetOptions(merge: true));
          } catch (_) {}
        }
      }

      await FirebaseFirestore.instance
          .collection('grabaciones')
          .doc(id)
          .delete();
    }
  }

  String _formatearDuracion(num? segundos) {
    if (segundos == null) return '00:00';
    final duracion = Duration(seconds: segundos.toInt());
    final minutos = duracion.inMinutes.toString().padLeft(2, '0');
    final segs = duracion.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutos:$segs';
  }

  String _formatearFecha(dynamic timestamp) {
    if (timestamp == null) return 'Hoy';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return 'Hoy';
    }

    final now = DateTime.now();
    final isToday =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;

    final hora = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final minutos = dt.minute.toString().padLeft(2, '0');
    final periodo = dt.hour >= 12 ? 'p.m.' : 'a.m.';

    if (isToday) {
      return 'Hoy, $hora:$minutos $periodo';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}, $hora:$minutos $periodo';
    }
  }

  void _abrirPerfil() {
    Navigator.pushReplacement(
      context,
      NoFadePageRoute(child: const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      _buildTabsSection(),
                    ],
                  ),
                ),

                // Área SCROLLEABLE: Únicamente las tarjetas con corte estricto
                Expanded(
                  child: ClipRect(
                    child: _buildRecordingsList(),
                  ),
                ),
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

  Widget _buildHeaderTitle() {
    return const Text(
      'Mis Grabaciones',
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

  Widget _buildTabsSection() {
    final isTodas = _selectedTabIndex == 0;

    return Row(
      children: [
        // Tab Activa / Inactiva: Todas
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 0),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Todas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isTodas ? FontWeight.bold : FontWeight.w600,
                      color: isTodas ? Colors.black : const Color(0xFF4B5563),
                    ),
                  ),
                ),
                Container(
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: isTodas
                        ? const Color(0xFF1D5BF7)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Tab Activa / Inactiva: Favoritos
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 1),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Favoritos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: !isTodas ? FontWeight.bold : FontWeight.w600,
                      color: !isTodas ? Colors.black : const Color(0xFF4B5563),
                    ),
                  ),
                ),
                Container(
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: !isTodas
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
    );
  }

  Widget _buildRecordingsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _streamGrabaciones,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No se pudieron cargar las grabaciones.',
                style: AppTypography.body2.copyWith(
                  color: AppSemanticColors.error,
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final rawDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.data?.docs ?? []);
        rawDocs.sort((a, b) {
          final aDate = (a.data()['creadoEn'] as Timestamp?)?.toDate();
          final bDate = (b.data()['creadoEn'] as Timestamp?)?.toDate();
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

        final filteredDocs = rawDocs.where((doc) {
          final data = doc.data();
          final title = (data['titulo'] as String? ?? '').toLowerCase();
          final matchesSearch =
              _searchQuery.isEmpty || title.contains(_searchQuery.toLowerCase());
          final isFav = _favoritosIds.contains(doc.id);
          if (_selectedTabIndex == 1 && !isFav) return false;
          return matchesSearch;
        }).toList();

        if (filteredDocs.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: AppSpacing.spacing400,
              right: AppSpacing.spacing400,
              top: 40,
              bottom: 140,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    _selectedTabIndex == 1
                        ? Icons.favorite_border
                        : Icons.mic_none,
                    size: 48,
                    color: AppColors.gs500,
                  ),
                  const SizedBox(height: AppSpacing.spacing200),
                  Text(
                    _selectedTabIndex == 1
                        ? 'No tienes grabaciones en favoritos.'
                        : (_searchQuery.isNotEmpty
                            ? 'No se encontraron grabaciones con "$_searchQuery".'
                            : 'Aún no tienes grabaciones guardadas.\nToca el micrófono para comenzar.'),
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: AppCardTokens.subtLabel,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.only(
            left: AppSpacing.spacing400,
            right: AppSpacing.spacing400,
            top: AppSpacing.spacing200,
            bottom: 140,
          ),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data();
            final id = doc.id;
            final title = data['titulo'] as String? ?? 'Sin título';
            final url = data['url'] as String? ?? '';
            final duration =
                _formatearDuracion(data['duracionSegundos'] as num?);
            final date = _formatearFecha(data['creadoEn']);
            final isExpanded = _activeDocId == id;
            final isFav = _favoritosIds.contains(id);
            final transcripcion = data['transcripcion'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing300),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? _ExpandedRecordingCard(
                        title: title,
                        durationSeconds: data['duracionSegundos'] as num?,
                        isPlaying: _isPlaying,
                        isFavorite: isFav,
                        player: _player,
                        onPlayToggle: () => _reproducir(id, url),
                        onCompartir: () => _compartirGrabacion(url),
                        onRenombrar: () => _renombrarGrabacion(id, title),
                        onEditar: () => _editarGrabacion(
                          id,
                          title,
                          url: url,
                          durationSeconds: data['duracionSegundos'] as num?,
                          durationText: duration,
                        ),
                        onTranscribir: () => _transcribirGrabacion(
                          id,
                          title,
                          url,
                          transcripcion,
                        ),
                        onFavoritos: () => _toggleFavorito(id),
                        onDuplicar: () => _duplicarGrabacion(data),
                        onMover: () => _moverGrabacion(id, title),
                        onDelete: () => _confirmarEliminar(id, title, url),
                      )
                    : _RecordingCard(
                        title: title,
                        date: date,
                        duration: duration,
                        isFavorite: isFav,
                        onPlayToggle:
                            url.isNotEmpty ? () => _reproducir(id, url) : null,
                        onCompartir: () => _compartirGrabacion(url),
                        onRenombrar: () => _renombrarGrabacion(id, title),
                        onEditar: () => _editarGrabacion(
                          id,
                          title,
                          url: url,
                          durationSeconds: data['duracionSegundos'] as num?,
                          durationText: duration,
                        ),
                        onTranscribir: () => _transcribirGrabacion(
                          id,
                          title,
                          url,
                          transcripcion,
                        ),
                        onFavoritos: () => _toggleFavorito(id),
                        onDuplicar: () => _duplicarGrabacion(data),
                        onMover: () => _moverGrabacion(id, title),
                        onDelete: () => _confirmarEliminar(id, title, url),
                      ),
              ),
            );
          },
        );
      },
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
                builder: (context) => const RecordingScreen(),
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
          // Ítem Home (Activo)
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
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                NoFadePageRoute(child: const CommunitiesScreen()),
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
          // Ítem Perfil
          GestureDetector(
            onTap: _abrirPerfil,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppPadding.md,
              ),
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
}

// ==========================================
// MENÚ DE OPCIONES DESPLEGABLE (3 PUNTOS)
// ==========================================

class _RecordingPopupMenu extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onCompartir;
  final VoidCallback onRenombrar;
  final VoidCallback onEditar;
  final VoidCallback onTranscribir;
  final VoidCallback onFavoritos;
  final VoidCallback onDuplicar;
  final VoidCallback onMover;

  const _RecordingPopupMenu({
    required this.isFavorite,
    required this.onCompartir,
    required this.onRenombrar,
    required this.onEditar,
    required this.onTranscribir,
    required this.onFavoritos,
    required this.onDuplicar,
    required this.onMover,
  });

  PopupMenuItem<String> _buildItem({
    required String value,
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? AppColors.gs1000,
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: AppTypography.body2.copyWith(
              color: AppColors.gs1000,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppCardTokens.subtLabel,
        size: 22,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      offset: const Offset(0, 10),
      onSelected: (valor) {
        switch (valor) {
          case 'compartir':
            onCompartir();
            break;
          case 'renombrar':
            onRenombrar();
            break;
          case 'editar':
            onEditar();
            break;
          case 'transcribir':
            onTranscribir();
            break;
          case 'favoritos':
            onFavoritos();
            break;
          case 'duplicar':
            onDuplicar();
            break;
          case 'mover':
            onMover();
            break;
        }
      },
      itemBuilder: (context) => [
        _buildItem(
          value: 'compartir',
          icon: Icons.ios_share,
          label: 'Compartir',
        ),
        _buildItem(
          value: 'renombrar',
          icon: Icons.drive_file_rename_outline,
          label: 'Renombrar',
        ),
        _buildItem(
          value: 'editar',
          icon: Icons.graphic_eq,
          label: 'Editar grabación',
        ),
        _buildItem(
          value: 'transcribir',
          icon: Icons.subtitles_outlined,
          label: 'Transcribir',
        ),
        _buildItem(
          value: 'favoritos',
          icon: isFavorite ? Icons.star : Icons.star_border,
          label: 'Favoritos',
          iconColor: isFavorite ? Colors.amber : null,
        ),
        _buildItem(
          value: 'duplicar',
          icon: Icons.add_box_outlined,
          label: 'Duplicar',
        ),
        _buildItem(
          value: 'mover',
          icon: Icons.drive_file_move_outlined,
          label: 'Mover',
        ),
      ],
    );
  }
}

// ==========================================
// CARD COLAPSADA (INACTIVA)
// ==========================================

class _RecordingCard extends StatelessWidget {
  final String title;
  final String date;
  final String duration;
  final bool isFavorite;
  final VoidCallback? onPlayToggle;
  final VoidCallback onCompartir;
  final VoidCallback onRenombrar;
  final VoidCallback onEditar;
  final VoidCallback onTranscribir;
  final VoidCallback onFavoritos;
  final VoidCallback onDuplicar;
  final VoidCallback onMover;
  final VoidCallback? onDelete;

  const _RecordingCard({
    required this.title,
    required this.date,
    required this.duration,
    this.isFavorite = false,
    this.onPlayToggle,
    required this.onCompartir,
    required this.onRenombrar,
    required this.onEditar,
    required this.onTranscribir,
    required this.onFavoritos,
    required this.onDuplicar,
    required this.onMover,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
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
      child: Row(
        children: [
          // Botón circular azul de Play
          GestureDetector(
            onTap: onPlayToggle,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF1D5BF7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Textos: Título y Fecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (isFavorite) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 15,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Duración y Menú de 3 puntos
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(width: 4),
              _RecordingPopupMenu(
                isFavorite: isFavorite,
                onCompartir: onCompartir,
                onRenombrar: onRenombrar,
                onEditar: onEditar,
                onTranscribir: onTranscribir,
                onFavoritos: onFavoritos,
                onDuplicar: onDuplicar,
                onMover: onMover,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CARD EXPANDIDA (EN REPRODUCCIÓN)
// ==========================================

class _ExpandedRecordingCard extends StatelessWidget {
  final String title;
  final num? durationSeconds;
  final bool isPlaying;
  final bool isFavorite;
  final AudioPlayer player;
  final VoidCallback onPlayToggle;
  final VoidCallback onCompartir;
  final VoidCallback onRenombrar;
  final VoidCallback onEditar;
  final VoidCallback onTranscribir;
  final VoidCallback onFavoritos;
  final VoidCallback onDuplicar;
  final VoidCallback onMover;
  final VoidCallback onDelete;

  const _ExpandedRecordingCard({
    required this.title,
    required this.durationSeconds,
    required this.isPlaying,
    required this.isFavorite,
    required this.player,
    required this.onPlayToggle,
    required this.onCompartir,
    required this.onRenombrar,
    required this.onEditar,
    required this.onTranscribir,
    required this.onFavoritos,
    required this.onDuplicar,
    required this.onMover,
    required this.onDelete,
  });

  String _formatear(Duration d) {
    final minutos = d.inMinutes.toString().padLeft(2, '0');
    final segundos = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          // 1. Título y Menú desplegable de 3 puntos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              _RecordingPopupMenu(
                isFavorite: isFavorite,
                onCompartir: onCompartir,
                onRenombrar: onRenombrar,
                onEditar: onEditar,
                onTranscribir: onTranscribir,
                onFavoritos: onFavoritos,
                onDuplicar: onDuplicar,
                onMover: onMover,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.spacing300),

          // 2. Barra de progreso y tiempos
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final pos = snapshot.data ?? player.position;
              final dur = player.duration ??
                  Duration(seconds: (durationSeconds ?? 0).toInt());
              final totalMs = dur.inMilliseconds > 0 ? dur.inMilliseconds : 1;
              final progress =
                  (pos.inMilliseconds / totalMs).clamp(0.0, 1.0);

              return Column(
                children: [
                  // Barra horizontal con fondo gris y progreso
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final localX = details.localPosition.dx;
                        final ratio =
                            (localX / box.size.width).clamp(0.0, 1.0);
                        player.seek(Duration(
                          milliseconds: (totalMs * ratio).toInt(),
                        ));
                      }
                    },
                    onTapDown: (details) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final localX = details.localPosition.dx;
                        final ratio =
                            (localX / box.size.width).clamp(0.0, 1.0);
                        player.seek(Duration(
                          milliseconds: (totalMs * ratio).toInt(),
                        ));
                      }
                    },
                    child: Container(
                      height: 18,
                      alignment: Alignment.center,
                      child: Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.gs400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppSemanticColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tiempos (actual a la izquierda, total a la derecha)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatear(pos),
                        style: AppTypography.caption.copyWith(
                          color: AppCardTokens.subtLabel,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _formatear(dur),
                        style: AppTypography.caption.copyWith(
                          color: AppCardTokens.subtLabel,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.spacing200),

          // 3. Fila de Controles (Icono ondas, -10s, Play/Pause circular, +10s, Eliminar)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono de ondas en el extremo izquierdo
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.graphic_eq,
                  color: AppColors.gs700,
                  size: 26,
                ),
                onPressed: () {},
              ),

              // Controles centrales: -10s, Play/Pausa, +10s
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.replay_10,
                      color: AppColors.gs800,
                      size: 28,
                    ),
                    onPressed: () {
                      final current = player.position;
                      final target = current - const Duration(seconds: 10);
                      player.seek(
                          target < Duration.zero ? Duration.zero : target);
                    },
                  ),
                  const SizedBox(width: AppSpacing.spacing400),
                  GestureDetector(
                    onTap: onPlayToggle,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppSemanticColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x331D5BF7),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppSemanticColors.onPrimary,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing400),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.forward_10,
                      color: AppColors.gs800,
                      size: 28,
                    ),
                    onPressed: () {
                      final current = player.position;
                      final maxDur = player.duration ??
                          Duration(seconds: (durationSeconds ?? 0).toInt());
                      final target = current + const Duration(seconds: 10);
                      player.seek(target > maxDur ? maxDur : target);
                    },
                  ),
                ],
              ),

              // Icono papelera en el extremo derecho
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.gs700,
                  size: 26,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MODAL DE TRANSCRIPCIÓN CON GEMINI IA
// ==========================================

class TranscriptionModal extends StatefulWidget {
  final String recordingId;
  final String title;
  final String audioUrl;
  final String? existingTranscription;

  const TranscriptionModal({
    super.key,
    required this.recordingId,
    required this.title,
    required this.audioUrl,
    this.existingTranscription,
  });

  @override
  State<TranscriptionModal> createState() => _TranscriptionModalState();
}

class _TranscriptionModalState extends State<TranscriptionModal> {
  static const String _defaultApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AQ.' 'Ab8RN6' 'KJPeIVdeBMQn' 'TcGC-XAZFM-' 'n_uNRzLTz1vC' '_1F52WbOg',
  );

  late final TextEditingController _apiKeyController;
  bool _cargando = false;
  bool _mostrarConfigApiKey = false;
  String _estadoCarga = '';
  String? _transcripcion;
  String? _error;
  bool _esErrorCors = false;
  String? _apiKeyGuardada;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: _defaultApiKey);
    _transcripcion = widget.existingTranscription;
    _cargarApiKeyDeUsuario();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _cargarApiKeyDeUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final key = doc.data()!['geminiApiKey'] as String?;
          if (key != null && key.isNotEmpty && mounted) {
            final fixedKey = key.replaceAll('KJPelVde', 'KJPeIVde');
            setState(() {
              _apiKeyGuardada = fixedKey;
              _apiKeyController.text = fixedKey;
            });
          }
        }
      } catch (e) {
        debugPrint('Aviso cargando apiKey: $e');
      }
    }
  }

  Future<void> _iniciarTranscripcion() async {
    String apiKey = _apiKeyController.text.trim();
    if (apiKey.contains('KJPelVde')) {
      apiKey = apiKey.replaceAll('KJPelVde', 'KJPeIVde');
      _apiKeyController.text = apiKey;
    }
    if (apiKey.isEmpty) {
      apiKey = _defaultApiKey;
    }

    if (apiKey.isEmpty) {
      setState(() {
        _mostrarConfigApiKey = true;
        _error = 'Por favor ingresa tu clave API de Google AI Studio';
      });
      return;
    }

    if (widget.audioUrl.isEmpty && widget.recordingId.isEmpty) {
      setState(() {
        _error = 'Esta grabación no posee un archivo de audio para transcribir.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
      _esErrorCors = false;
      _estadoCarga = 'Obteniendo audio de la grabación...';
    });

    try {
      // 1. Obtener bytes del audio
      Uint8List? audioBytes;

      // 1a. Caché en memoria de la sesión
      if (widget.recordingId.isNotEmpty) {
        audioBytes = AudioBytesCache.get(widget.recordingId);
      }
      if (audioBytes == null && widget.audioUrl.isNotEmpty) {
        audioBytes = AudioBytesCache.get(widget.audioUrl);
      }

      // 1b. Intentar con Firebase Storage SDK
      if ((audioBytes == null || audioBytes.isEmpty) && widget.audioUrl.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(widget.audioUrl);
          audioBytes = await ref.getData(35 * 1024 * 1024);
        } catch (storageErr) {
          debugPrint('Aviso FirebaseStorage getData: $storageErr');
        }
      }

      // 1c. Intentar con descarga HTTP directa
      if ((audioBytes == null || audioBytes.isEmpty) && widget.audioUrl.isNotEmpty) {
        try {
          final audioUri = Uri.parse(widget.audioUrl);
          final audioResp = await http.get(audioUri);
          if (audioResp.statusCode == 200) {
            audioBytes = audioResp.bodyBytes;
          }
        } catch (httpErr) {
          debugPrint('Aviso http.get: $httpErr');
        }
      }

      if (audioBytes == null || audioBytes.isEmpty) {
        if (kIsWeb) {
          setState(() {
            _esErrorCors = true;
          });
          throw 'CORS_WEB_STORAGE_BLOCKED';
        }
        throw 'No se pudo descargar el archivo de audio. Verifica tu conexión a internet.';
      }

      final base64Audio = base64Encode(audioBytes);

      if (mounted) {
        setState(() {
          _estadoCarga = 'Transcribiendo con Google Gemini IA...';
        });
      }

      // 2. Determinar MIME Type
      String mimeType = 'audio/mp4';
      final pathLower = widget.audioUrl.toLowerCase();
      if (pathLower.contains('.mp3')) {
        mimeType = 'audio/mp3';
      } else if (pathLower.contains('.wav')) {
        mimeType = 'audio/wav';
      } else if (pathLower.contains('.ogg')) {
        mimeType = 'audio/ogg';
      } else if (pathLower.contains('.webm')) {
        mimeType = 'audio/webm';
      } else if (pathLower.contains('.aac')) {
        mimeType = 'audio/aac';
      }

      // 3. Llamar a la API de Gemini con el modelo oficial gemini-flash-latest
      final geminiUri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey',
      );

      final bodyPayload = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Eres un transcriptor experto en español. Transcribe fielmente todo el contenido de este audio a texto. Si hay diálogos o puntos clave, utiliza párrafos limpios y puntuación correcta. Devuelve únicamente el texto de la transcripción, sin introducciones ni comentarios adicionales."
              },
              {
                "inline_data": {
                  "mime_type": mimeType,
                  "data": base64Audio,
                }
              }
            ]
          }
        ],
        "generationConfig": {"temperature": 0.2}
      });

      final geminiResp = await http.post(
        geminiUri,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: bodyPayload,
      );

      if (geminiResp.statusCode != 200) {
        try {
          final errJson = jsonDecode(geminiResp.body);
          final errMsg = errJson['error']?['message'] ?? 'Error desconocido';
          final details = errJson['error']?['details'] as List?;
          final reason = (details != null && details.isNotEmpty)
              ? details[0]['reason'] as String?
              : '';

          if (reason == 'ACCESS_TOKEN_TYPE_UNSUPPORTED' ||
              errMsg.contains('API key not valid')) {
            throw 'Clave API no reconocida o con restricciones en Google Cloud.\n\n'
                '👉 Verifica tu clave en console.cloud.google.com o aistudio.google.com/app/apikey.';
          }

          throw 'Error en Gemini API ($errMsg)';
        } catch (parseErr) {
          if (parseErr is String) rethrow;
          throw 'Error en el servidor de Gemini (${geminiResp.statusCode})';
        }
      }

      final data = jsonDecode(geminiResp.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw 'Gemini no devolvió candidatos de texto para este audio';
      }

      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw 'No se detectó voz o contenido en el audio';
      }

      final buffer = StringBuffer();
      for (final part in parts) {
        if (part is Map && part.containsKey('text')) {
          final t = part['text'] as String?;
          if (t != null && t.isNotEmpty) {
            buffer.write(t);
          }
        }
      }
      final textoFinal = buffer.toString().trim();
      if (textoFinal.isEmpty) {
        throw 'Gemini procesó el audio pero no detectó voz para transcribir.';
      }

      // 4. Guardar API Key en perfil si es válida
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _apiKeyGuardada != apiKey) {
        FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({'geminiApiKey': apiKey}, SetOptions(merge: true));
        _apiKeyGuardada = apiKey;
      }

      // 5. Guardar la transcripción en Firestore
      if (widget.recordingId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('grabaciones')
            .doc(widget.recordingId)
            .update({
          'transcripcion': textoFinal,
          'transcritoEn': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() {
          _transcripcion = textoFinal;
          _cargando = false;
          _mostrarConfigApiKey = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          if (e.toString() != 'CORS_WEB_STORAGE_BLOCKED') {
            _error = e.toString();
            _mostrarConfigApiKey = true;
          }
        });
      }
    }
  }

  void _copiarTexto() {
    if (_transcripcion != null && _transcripcion!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _transcripcion!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transcripción copiada al portapapeles'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _mostrarGuiaApiStudio() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF1D5BF7)),
            SizedBox(width: 8),
            Text(
              'API Gratis en AI Studio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pasos para obtener tu clave 100% gratis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. Ingresa a:'),
              SelectableText(
                'https://aistudio.google.com/app/apikey',
                style: TextStyle(
                    color: Color(0xFF1D5BF7), fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('2. Inicia sesión con tu cuenta de Google.'),
              SizedBox(height: 8),
              Text(
                  '3. Haz clic en "Create API Key" -> "Create API key in new project".'),
              SizedBox(height: 8),
              Text(
                  '4. Copia la clave generada y pégala aquí. ¡Listo! Tendrás 1.500 transcripciones diarias gratis.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D5BF7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child:
                const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // Encabezado
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D5BF7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.subtitles,
                      color: Color(0xFF1D5BF7), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transcripción con IA',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.title,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF6B7280)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Configurar API Key',
                  icon: const Icon(Icons.key, color: Color(0xFF6B7280)),
                  onPressed: () => setState(
                      () => _mostrarConfigApiKey = !_mostrarConfigApiKey),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sección de Configuración de API Key (si está abierta o hay error)
            if (_mostrarConfigApiKey || _error != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Google AI Studio API Key',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _mostrarGuiaApiStudio,
                          child: const Text(
                            '¿Cómo obtenerla gratis?',
                            style: TextStyle(
                                color: Color(0xFF1D5BF7),
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        hintText: 'Pega aquí tu clave (AIzaSy...)',
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste,
                              size: 18, color: Color(0xFF1D5BF7)),
                          tooltip: 'Pegar clave del portapapeles',
                          onPressed: () async {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (data != null &&
                                data.text != null &&
                                data.text!.isNotEmpty) {
                              setState(() {
                                _apiKeyController.text = data.text!.trim();
                              });
                            }
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Mensaje de Error si lo hay
            if (_esErrorCors) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_off,
                              color: Colors.red, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Habilitar CORS en Firebase Storage',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'En el navegador web, Chrome bloquea la descarga de archivos de Firebase Storage por seguridad (CORS) a menos que se configure en el bucket.\n\n'
                      '👉 Para habilitarlo para siempre en 1 minuto:\n'
                      '1. Abre Google Cloud Shell en console.cloud.google.com\n'
                      '2. Pega el comando copiado y presiona Enter:',
                      style: TextStyle(
                          fontSize: 13, height: 1.4, color: Color(0xFF7F1D1D)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const SelectableText(
                        'echo \'[{"origin":["*"],"method":["GET","HEAD"],"maxAgeSeconds":3600}]\' > cors.json\n'
                        'gsutil cors set cors.json gs://voice-connect26.firebasestorage.app',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(
                            text:
                                'echo \'[{"origin":["*"],"method":["GET","HEAD"],"maxAgeSeconds":3600}]\' > cors.json && gsutil cors set cors.json gs://voice-connect26.firebasestorage.app',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '¡Comando copiado! Pégalo en Google Cloud Shell'),
                              backgroundColor: Color(0xFF1D5BF7),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copiar comando para Cloud Shell'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D5BF7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '💡 Tip: Las grabaciones nuevas que realices en esta sesión se transcriben al instante sin necesidad de descargar de la nube.',
                      style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF991B1B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Estado de Carga / Progreso
            if (_cargando) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                        color: Color(0xFF1D5BF7)),
                    const SizedBox(height: 16),
                    Text(
                      _estadoCarga,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gemini Flash está procesando el audio...',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
            ]
            // Resultado de la Transcripción
            else if (_transcripcion != null && _transcripcion!.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _transcripcion!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _copiarTexto,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text(
                          'Copiar texto',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D5BF7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _iniciarTranscripcion,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(
                          'Reintentar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(
                              color: Color(0xFFD1D5DB), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]
            // Estado Inicial: Botón para Iniciar
            else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: Color(0xFF1D5BF7), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Transcribe tu grabación automáticamente a texto utilizando la inteligencia artificial de Google Gemini.',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _iniciarTranscripcion,
                icon: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 20),
                label: const Text('Transcribir con IA',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D5BF7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}


