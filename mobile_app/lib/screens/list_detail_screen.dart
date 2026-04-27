import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/task_item.dart';

class ListDetailScreen extends StatefulWidget {
  final TodoList list;

  const ListDetailScreen({super.key, required this.list});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AppProvider>().loadListDetail(widget.list.id));
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return AppTheme.card;
    switch (colorStr) {
      case 'orange': return const Color(0xFFFFF3E0);
      case 'blue': return const Color(0xFFE3F2FD);
      case 'purple': return const Color(0xFFEDE7F6);
      case 'pink': return const Color(0xFFFCE4EC);
      case 'green': return const Color(0xFFEAF5EC);
      default: return AppTheme.card;
    }
  }

  Color _parseTextColor(String? colorStr) {
    if (colorStr == null) return AppTheme.textSecondary;
    switch (colorStr) {
      case 'orange': return const Color(0xFFE67E22);
      case 'blue': return const Color(0xFF2980B9);
      case 'purple': return const Color(0xFF7E57C2);
      case 'pink': return const Color(0xFFC2185B);
      case 'green': return const Color(0xFF2D6A4F);
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currentList = provider.listDetails[widget.list.id] ?? widget.list;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('${currentList.icon ?? ''} ${currentList.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppTheme.bg,
        foregroundColor: AppTheme.text,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.card,
        onRefresh: () => context.read<AppProvider>().loadListDetail(widget.list.id),
        child: ReorderableListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          onReorder: (oldIndex, newIndex) {
            // Logic for reordering tasks in memory and calling provider to update backend
            // Since sections make this complex, we'll keep it simple for the prototype
          },
          children: [
            if (currentList.sections != null)
              for (var section in currentList.sections!)
                _buildSection(section, currentList),
            if (currentList.tasks != null)
              for (var i = 0; i < currentList.tasks!.length; i++)
                _buildDraggableTask(currentList.tasks![i], i, null, currentList),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) {
              final ctrl = TextEditingController();
              return AlertDialog(
                title: const Text('New Task'),
                content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Task title')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        context.read<AppProvider>().addTask(ctrl.text, currentList.id);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSection(Section section, TodoList currentList) {
    return Container(
      key: ValueKey('section_${section.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '${section.name}'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${section.tasks?.length ?? 0}',
                style: AppTheme.monoStyle.copyWith(fontSize: 10, color: AppTheme.textSecondary),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (section.tasks != null)
            for (var i = 0; i < section.tasks!.length; i++)
              _buildDraggableTask(section.tasks![i], i, section.id, currentList)
        ],
      ),
    );
  }

  Widget _buildDraggableTask(Task task, int index, String? sectionId, TodoList currentList) {
    return Padding(
      key: ValueKey('task_${task.id}'),
      padding: sectionId != null ? const EdgeInsets.only(left: 20) : EdgeInsets.zero,
      child: Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.horizontal,
        background: Container(
          color: Colors.green.shade600,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.check, color: Colors.white),
        ),
        secondaryBackground: Container(
          color: AppTheme.urgent.withValues(alpha: 0.8),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            context.read<AppProvider>().completeTask(task.id, currentList.id);
            return false;
          } else {
            context.read<AppProvider>().deleteTask(task.id, currentList.id);
            return true;
          }
        },
        child: TaskItem(task: task, index: index + 1),
      ),
    );
  }
}
