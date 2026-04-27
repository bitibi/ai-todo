import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../screens/task_detail_screen.dart';

class TaskItem extends StatefulWidget {
  final Task task;
  final int index;
  final bool showListBadge;
  final String? listName;
  final VoidCallback? onComplete;

  const TaskItem({
    super.key,
    required this.task,
    required this.index,
    this.showListBadge = false,
    this.listName,
    this.onComplete,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  bool isExpanded = false;

  Color _getPriorityColor() {
    switch (widget.task.priority) {
      case 'urgent': return AppTheme.urgent;
      case 'high': return AppTheme.high;
      case 'medium': return AppTheme.medium;
      case 'low': return AppTheme.textSecondary;
      default: return AppTheme.textSecondary;
    }
  }

  Color _getPriorityBg() {
    switch (widget.task.priority) {
      case 'urgent': return AppTheme.urgent.withValues(alpha: 0.15);
      case 'high': return AppTheme.high.withValues(alpha: 0.15);
      case 'medium': return AppTheme.medium.withValues(alpha: 0.15);
      case 'low': return AppTheme.textSecondary.withValues(alpha: 0.15);
      default: return AppTheme.textSecondary.withValues(alpha: 0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${widget.index}',
                  style: AppTheme.monoStyle.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: widget.task)));
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade600),
                      borderRadius: BorderRadius.circular(6),
                      color: AppTheme.card,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.showListBadge && widget.listName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.listName!,
                      style: const TextStyle(fontSize: 9, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityBg(),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.task.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: _getPriorityColor(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.task.timeEstimate ?? '—',
                  style: AppTheme.monoStyle.copyWith(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (widget.onComplete != null) widget.onComplete!();
                    context.read<AppProvider>().completeTask(widget.task.id, widget.task.listId);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0), // Increase touch target
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: widget.task.isCompleted ? AppTheme.accent : Colors.transparent,
                        border: Border.all(
                          color: widget.task.isCompleted ? AppTheme.accent : Colors.grey.shade600, 
                          width: 1.5
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: widget.task.isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
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
