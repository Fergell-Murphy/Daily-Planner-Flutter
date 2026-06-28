import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../data/models/task.dart';
import '../providers/planner_provider.dart';

class ScreenHeader extends ConsumerWidget {
  const ScreenHeader({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: AppDecorations.gradientIcon(),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title ?? AppConstants.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: () => _showSearchModal(context, ref),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.white,
                elevation: 0,
                side: BorderSide(
                  color: AppColors.gray200.withValues(alpha: 0.8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              icon: const Icon(AppIcons.search, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchSheet(ref: ref),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _query = '';
  List<Task> _results = [];

  Future<void> _search(String text) async {
    setState(() => _query = text);
    if (text.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    final found = await widget.ref
        .read(plannerProvider.notifier)
        .findTasks(text);
    if (mounted) setState(() => _results = found);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Tasks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            onChanged: _search,
            decoration: const InputDecoration(
              hintText: 'Search by task name...',
              filled: true,
              fillColor: AppColors.gray100,
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ..._results.map(
                  (task) => ListTile(
                    title: Text(
                      task.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(task.date),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/edit-task?taskId=${task.id}');
                    },
                  ),
                ),
                if (_query.trim().isNotEmpty && _results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No tasks found',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.gray400),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
