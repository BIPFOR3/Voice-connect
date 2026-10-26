import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';

import 'firebase_options.dart';
import 'theme/theme.dart';
import 'recording.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

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

  final Stream<QuerySnapshot<Map<String, dynamic>>> _streamGrabaciones =
      FirebaseFirestore.instance
          .collection('grabaciones')
          .orderBy('creadoEn', descending: true)
          .snapshots();

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
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
        return;
      }

      await _player.stop();
      setState(() {
        _activeDocId = docId;
        _isPlaying = true;
      });

      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reproducir el audio: $e')),
        );
      }
    }
  }

  Future<void> _compartirGrabacion(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay enlace disponible para compartir')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enlace de la grabación copiado al portapapeles'),
        ),
      );
    }
  }

  Future<void> _renombrarGrabacion(String id, String tituloActual) async {
    final controller = TextEditingController(text: tituloActual);
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.gs50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Renombrar grabación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Título',
            filled: true,
            fillColor: AppTextInputTokens.defaultBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.s),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppSemanticColors.primary,
              foregroundColor: AppSemanticColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
            ),
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
      final nuevaData = Map<String, dynamic>.from(data);
      nuevaData['titulo'] = '${nuevaData['titulo'] ?? 'Grabación'} (Copia)';
      nuevaData['creadoEn'] = FieldValue.serverTimestamp();
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

  void _editarGrabacion(String id, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editor de audio para "$title" próximamente')),
    );
  }

  void _moverGrabacion(String id, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mover "$title" a otra carpeta próximamente')),
    );
  }

  void _toggleFavorito(String id) {
    setState(() {
      if (_favoritosIds.contains(id)) {
        _favoritosIds.remove(id);
      } else {
        _favoritosIds.add(id);
      }
    });
    final isFav = _favoritosIds.contains(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav ? 'Agregado a favoritos' : 'Eliminado de favoritos',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
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
    if (timestamp == null) return 'Reciente';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return 'Reciente';
    }

    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hora = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minutos = dt.minute.toString().padLeft(2, '0');
    final periodo = dt.hour >= 12 ? 'p.m.' : 'a.m.';

    if (isToday) {
      return 'Hoy, $hora:$minutos $periodo';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}, $hora:$minutos $periodo';
    }
  }

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
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
              style: AppTypography.body1,
              decoration: InputDecoration(
                hintText: 'Buscar grabaciones...',
                hintStyle: AppTypography.body2.copyWith(
                  color: AppTextInputTokens.holder,
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
                Icons.clear,
                color: AppColors.gs600,
                size: 20,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Todas',
                  style: AppTypography.subtitle1.copyWith(
                    color: AppColors.gs1000,
                    fontWeight: isTodas ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing100),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: isTodas
                        ? AppSemanticColors.primary
                        : AppColors.gs300,
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing400),
        // Tab Activa / Inactiva: Favoritos
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 1),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favoritos',
                  style: AppTypography.subtitle1.copyWith(
                    color: AppColors.gs1000,
                    fontWeight: !isTodas ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing100),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: !isTodas
                        ? AppSemanticColors.primary
                        : AppColors.gs300,
                    borderRadius: BorderRadius.circular(AppRadius.s),
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

        final docs = snapshot.data?.docs ?? [];
        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          final title = (data['titulo'] as String? ?? '').toLowerCase();
          final matchesSearch =
              _searchQuery.isEmpty || title.contains(_searchQuery.toLowerCase());
          final isFav = _favoritosIds.contains(doc.id);
          if (_selectedTabIndex == 1 && !isFav) return false;
          return matchesSearch;
        }).toList();

        if (filteredDocs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
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

        return Column(
          children: filteredDocs.map((doc) {
            final data = doc.data();
            final id = doc.id;
            final title = data['titulo'] as String? ?? 'Sin título';
            final url = data['url'] as String? ?? '';
            final duration =
                _formatearDuracion(data['duracionSegundos'] as num?);
            final date = _formatearFecha(data['creadoEn']);
            final isExpanded = _activeDocId == id;
            final isFav = _favoritosIds.contains(id);

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
                        onEditar: () => _editarGrabacion(id, title),
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
                        onEditar: () => _editarGrabacion(id, title),
                        onFavoritos: () => _toggleFavorito(id),
                        onDuplicar: () => _duplicarGrabacion(data),
                        onMover: () => _moverGrabacion(id, title),
                        onDelete: () => _confirmarEliminar(id, title, url),
                      ),
              ),
            );
          }).toList(),
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
// MENÚ DE OPCIONES DESPLEGABLE (3 PUNTOS)
// ==========================================

class _RecordingPopupMenu extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onCompartir;
  final VoidCallback onRenombrar;
  final VoidCallback onEditar;
  final VoidCallback onFavoritos;
  final VoidCallback onDuplicar;
  final VoidCallback onMover;

  const _RecordingPopupMenu({
    required this.isFavorite,
    required this.onCompartir,
    required this.onRenombrar,
    required this.onEditar,
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
    required this.onFavoritos,
    required this.onDuplicar,
    required this.onMover,
    this.onDelete,
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
          // Botón circular azul de Play
          GestureDetector(
            onTap: onPlayToggle,
            child: Container(
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
          ),
          const SizedBox(width: AppSpacing.spacing300),

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
                        style: AppTypography.subtitle1.copyWith(
                          color: AppCardTokens.defaultLabel,
                          fontWeight: FontWeight.w600,
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
          const SizedBox(width: AppSpacing.spacing200),

          // Duración y Menú de 3 puntos
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                duration,
                style: AppTypography.body2.copyWith(
                  color: AppCardTokens.subtLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing100),
              _RecordingPopupMenu(
                isFavorite: isFavorite,
                onCompartir: onCompartir,
                onRenombrar: onRenombrar,
                onEditar: onEditar,
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
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: AppCardTokens.defaultBg,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(
          color: AppColors.gs300.withValues(alpha: 0.5),
          width: 0.5,
        ),
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
                  style: AppTypography.subtitle1.copyWith(
                    color: AppColors.gs1000,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _RecordingPopupMenu(
                isFavorite: isFavorite,
                onCompartir: onCompartir,
                onRenombrar: onRenombrar,
                onEditar: onEditar,
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