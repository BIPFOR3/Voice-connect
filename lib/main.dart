import 'package:flutter/material.dart';

import 'profile.dart';
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

class RecordingsHomeScreen extends StatefulWidget {
  const RecordingsHomeScreen({super.key});

  @override
  State<RecordingsHomeScreen> createState() => _RecordingsHomeScreenState();
}

class _RecordingsHomeScreenState extends State<RecordingsHomeScreen> {
  int _selectedIndex = 0;

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
            IndexedStack(
              index: _selectedIndex,
              children: [
                _buildRecordingsContent(context),
                _buildCommunityContent(context),
                const ProfileScreen(),
              ],
            ),

            if (_selectedIndex == 0)
              Positioned(
                right: AppSpacing.spacing400,
                bottom: AppSizes.micFabBottomOffset,
                child: _buildMicFab(),
              ),

            Positioned(
              left: AppSizes.zero,
              right: AppSizes.zero,
              bottom: AppSpacing.spacing400,
              child: Center(child: _buildFloatingBottomBar()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingsContent(BuildContext context) {
    return ListView(
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing400,
        vertical: AppSpacing.spacing200,
      ),
      children: [
        _buildTopMenu(),
        const SizedBox(height: AppSpacing.spacing300),
        _buildHeaderTitle(context),
        const SizedBox(height: AppSpacing.spacing300),
        _buildSearchBar(context),
        const SizedBox(height: AppSpacing.spacing400),
        _buildTabsSection(context),
        const SizedBox(height: AppSpacing.spacing400),
        _buildRecordingsList(),
        const SizedBox(height: AppSizes.bottomNavigationReservedSpace),
      ],
    );
  }

  Widget _buildCommunityContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing400,
        vertical: AppSpacing.spacing200,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopMenu(),
          const SizedBox(height: AppSpacing.spacing300),
          Text(
            'Comunidad',
            style: Theme.of(context).textTheme.headlineLarge!
                .copyWith(color: AppColors.gs1000, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMenu() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(
          Icons.menu,
          color: AppColors.gs1000,
          size: AppIconSizes.xl,
        ),
        onPressed: () {},
      ),
    );
  }

  Widget _buildHeaderTitle(BuildContext context) {
    return Text(
      'Mis Grabaciones',
      style: Theme.of(context).textTheme.headlineLarge!
          .copyWith(color: AppColors.gs1000, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
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
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: '',
                hintStyle: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(color: AppTextInputTokens.holder),
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

  Widget _buildTabsSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Todas',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppColors.gs1000,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing100),
              Container(
                height: AppSizes.indicatorHeight,
                decoration: BoxDecoration(
                  color: AppSemanticColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.spacing400),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favoritos',
                style: Theme.of(context).textTheme.titleLarge!
                    .copyWith(color: AppColors.gs1000),
              ),
              const SizedBox(height: AppSpacing.spacing100),
              Container(
                height: AppSizes.indicatorHeight,
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
              MaterialPageRoute(builder: (context) => RecordingScreen()),
            );
          },
          child: Container(
            width: AppSizes.micFab,
            height: AppSizes.micFab,
            decoration: const BoxDecoration(
              color: AppButtonTokens.filledBg,
              shape: BoxShape.circle,
              boxShadow: [AppElevations.level2],
            ),
            child: const Icon(
              Icons.mic,
              color: AppButtonTokens.filledLabel,
              size: AppIconSizes.mic,
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
        borderRadius: BorderRadius.circular(AppRadius.radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomBarItem(
            index: 0,
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            iconSize: AppIconSizes.lg,
          ),
          const SizedBox(width: AppSpacing.spacing400),
          _buildBottomBarItem(
            index: 1,
            icon: Icons.groups_outlined,
            selectedIcon: Icons.groups,
            iconSize: AppIconSizes.xl,
          ),
          const SizedBox(width: AppSpacing.spacing400),
          _buildBottomBarItem(
            index: 2,
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            iconSize: AppIconSizes.lg,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required double iconSize,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? AppPadding.lg : AppPadding.md,
          vertical: AppPadding.sm,
        ),
        decoration: BoxDecoration(
          color:
              isSelected ? AppSemanticColors.surfaceMain : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.radius),
        ),
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: AppColors.gs1000,
          size: iconSize,
        ),
      ),
    );
  }
}

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
          width: AppStroke.hairline,
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
          Container(
            width: AppSizes.playButton,
            height: AppSizes.playButton,
            decoration: const BoxDecoration(
              color: AppSemanticColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: AppSemanticColors.onPrimary,
              size: AppIconSizes.lg,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing300),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: AppCardTokens.defaultLabel,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSizes.hairlineGap),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppCardTokens.subtLabel,
                      ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.spacing200),
                child: Text(
                  duration,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppCardTokens.subtLabel,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing100),
              Icon(
                Icons.more_vert,
                color: AppCardTokens.subtLabel,
                size: AppIconSizes.sm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}