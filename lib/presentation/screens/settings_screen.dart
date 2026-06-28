import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_icons.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../providers/planner_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/screen_header.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = ref.watch(plannerProvider);

    if (_nameController.text != planner.userName && !_saved) {
      _nameController.text = planner.userName;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const ScreenHeader(title: 'Settings'),
        _SettingsCard(
          icon: AppIcons.user,
          iconBg: AppColors.navy100,
          iconColor: AppColors.navy500,
          title: 'Profile',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Name', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  fillColor: AppColors.gray50,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;
                    await ref.read(plannerProvider.notifier).setUserName(name);
                    setState(() => _saved = true);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _saved = false);
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy500,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(_saved ? 'Saved!' : 'Save Name'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: AppIcons.bell,
          iconBg: AppColors.amber100,
          iconColor: AppColors.amber500,
          title: 'Notifications',
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Task alarms',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.navy500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get notified when a task is scheduled to start.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: planner.notificationsEnabled,
                onChanged: (enabled) async {
                  final success = await ref
                      .read(plannerProvider.notifier)
                      .setNotificationsEnabled(enabled);
                  if (!success && enabled && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enable notifications in your device settings to receive task alarms.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: AppIcons.database,
          iconBg: AppColors.sage100,
          iconColor: AppColors.sage500,
          title: 'Categories',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: planner.categories
                    .map(
                      (cat) => CategoryChip(
                        name: cat.name,
                        color: parseHexColor(cat.color),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Add new categories when creating or editing tasks.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'About',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Planner stores all your tasks locally on your device using SQLite. Your data works fully offline and persists between sessions — no account or internet required.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Version ${AppConstants.appVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.child,
    this.icon,
    this.iconBg,
    this.iconColor,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color? iconBg;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          child,
        ],
      ),
    );
  }
}
