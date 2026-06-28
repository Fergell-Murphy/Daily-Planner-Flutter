import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_icons.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/format_utils.dart';
import '../../data/models/task.dart';
import '../providers/planner_provider.dart';
import '../widgets/category_chip.dart';

class EditTaskScreen extends ConsumerStatefulWidget {
  const EditTaskScreen({super.key, this.taskId, this.date});

  final int? taskId;
  final String? date;

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;
  int _startTime = 8 * 60;
  int _endTime = 9 * 60;
  int? _categoryId;
  late String _taskDate;
  bool _alarmEnabled = true;
  final _newCategoryController = TextEditingController();

  void _showNewCategoryModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _NewCategorySheet(
        controller: _newCategoryController,
        onCancel: () {
          _newCategoryController.clear();
          Navigator.pop(context);
        },
        onSave: (name) async {
          await _addCategory(name);
          _newCategoryController.clear();
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showTimePicker({required bool isStart}) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _TimePickerSheet(
        initial: minutesToDate(isStart ? _startTime : _endTime),
        onDone: (date) {
          setState(() {
            if (isStart) {
              _startTime = dateToMinutes(date);
            } else {
              _endTime = dateToMinutes(date);
            }
          });
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    _taskDate = widget.date ?? formatDateKey(DateTime.now());
    _loading = _isEditing;
    if (_isEditing) _loadTask();
  }

  Future<void> _loadTask() async {
    final task = await ref
        .read(plannerProvider.notifier)
        .getTask(widget.taskId!);
    if (task != null && mounted) {
      setState(() {
        _nameController.text = task.name;
        _startTime = task.startTime;
        _endTime = task.endTime;
        _categoryId = task.categoryId;
        _taskDate = task.date;
        _alarmEnabled = task.alarmEnabled;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showAlert('Missing Name', 'Please enter a task name.');
      return;
    }
    if (_endTime <= _startTime) {
      _showAlert('Invalid Time', 'End time must be after start time.');
      return;
    }

    final categories = ref.read(plannerProvider).categories;
    final categoryId = _categoryId ?? categories.first.id;

    final input = TaskInput(
      name: name,
      startTime: _startTime,
      endTime: _endTime,
      completion: 0,
      categoryId: categoryId,
      date: _taskDate,
      alarmEnabled: _alarmEnabled,
    );

    if (!mounted) return;
    context.pop();

    if (_isEditing) {
      await ref.read(plannerProvider.notifier).editTask(widget.taskId!, input);
    } else {
      await ref.read(plannerProvider.notifier).addTask(input);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red500),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.taskId != null) {
      await ref.read(plannerProvider.notifier).removeTask(widget.taskId!);
      if (mounted) context.pop();
    }
  }

  void _showAlert(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory(String name) async {
    if (name.trim().isEmpty) return;
    final categories = ref.read(plannerProvider).categories;
    final color = AppConstants
        .categoryColors[categories.length % AppConstants.categoryColors.length];
    final cat = await ref
        .read(plannerProvider.notifier)
        .addCategory(name.trim(), color);
    setState(() => _categoryId = cat.id);
  }

  @override
  Widget build(BuildContext context) {
    final planner = ref.watch(plannerProvider);

    if (!planner.isReady || _loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.navy500),
        ),
      );
    }

    final categoryId = _categoryId ?? planner.categories.firstOrNull?.id;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isEditing)
            PopupMenuButton<String>(
              icon: const Icon(AppIcons.moreVertical),
              onSelected: (value) {
                if (value == 'delete') _delete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(AppIcons.trash2, color: AppColors.red500, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Delete Task',
                        style: TextStyle(color: AppColors.red500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('Task Name', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'e.g., Morning Medication',
            ),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: 'Start Time',
                  value: minutesToTimeString(_startTime),
                  onTap: () => _showTimePicker(isStart: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TimeField(
                  label: 'End Time',
                  value: minutesToTimeString(_endTime),
                  onTap: () => _showTimePicker(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppDecorations.sectionCard(),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.navy100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(AppIcons.bell, color: AppColors.navy500),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Remind at start and when complete',
                        style: TextStyle(
                          color: AppColors.gray500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _alarmEnabled,
                  onChanged: (v) => setState(() => _alarmEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Categories', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...planner.categories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      name: cat.name,
                      color: parseHexColor(cat.color),
                      selected: categoryId == cat.id,
                      onTap: () => setState(() => _categoryId = cat.id),
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _showNewCategoryModal,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: const BorderSide(
                      color: AppColors.gray300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Text('+ New Category'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            onPressed: _save,
            icon: const Icon(AppIcons.save),
            label: const Text('Save Task'),
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: AppDecorations.sectionCard(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({
    required this.initial,
    required this.onDone,
    required this.onCancel,
  });

  final DateTime initial;
  final ValueChanged<DateTime> onDone;
  final VoidCallback onCancel;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      color: AppColors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => widget.onDone(_selected),
                child: const Text('Done'),
              ),
            ],
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: widget.initial,
              onDateTimeChanged: (date) => _selected = date,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewCategorySheet extends StatelessWidget {
  const _NewCategorySheet({
    required this.controller,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController controller;
  final VoidCallback onCancel;
  final ValueChanged<String> onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New Category', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Category name',
              fillColor: AppColors.gray100,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => onSave(controller.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy500,
                  ),
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
