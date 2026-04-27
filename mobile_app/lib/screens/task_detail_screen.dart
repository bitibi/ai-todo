import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _detailsCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _timeEstimateCtrl;
  DateTime? _dueDate;
  late String _priority;

  @override
  void initState() {
    super.initState();
    _priority = widget.task.priority;
    _titleCtrl = TextEditingController(text: widget.task.title);
    _detailsCtrl = TextEditingController(text: widget.task.details);
    _notesCtrl = TextEditingController(text: widget.task.subText);
    _timeEstimateCtrl = TextEditingController(text: widget.task.timeEstimate);
    if (widget.task.dueDate != null) {
      _dueDate = DateTime.tryParse(widget.task.dueDate!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _detailsCtrl.dispose();
    _notesCtrl.dispose();
    _timeEstimateCtrl.dispose();
    super.dispose();
  }

  void _saveTask() {
    final updates = <String, dynamic>{};
    if (_titleCtrl.text != widget.task.title) updates['title'] = _titleCtrl.text;
    if (_detailsCtrl.text != widget.task.details) updates['details'] = _detailsCtrl.text;
    if (_notesCtrl.text != widget.task.subText) updates['sub_text'] = _notesCtrl.text;
    if (_timeEstimateCtrl.text != widget.task.timeEstimate) updates['time_estimate'] = _timeEstimateCtrl.text;
    if (_priority != widget.task.priority) updates['priority'] = _priority;
    
    if (_dueDate != null) {
      updates['due_date'] = _dueDate!.toIso8601String();
    }

    if (updates.isNotEmpty) {
      context.read<AppProvider>().updateTask(widget.task.id, widget.task.listId, updates);
    }
    Navigator.pop(context);
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accent,
              onPrimary: Colors.white,
              surface: AppTheme.card,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _dueDate != null ? TimeOfDay.fromDateTime(_dueDate!) : TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.accent,
                onPrimary: Colors.white,
                surface: AppTheme.card,
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      
      setState(() {
        if (pickedTime != null) {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        } else {
          _dueDate = pickedDate;
        }
      });
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final loc = MaterialLocalizations.of(context);
    final dateStr = loc.formatMediumDate(date);
    if (date.hour == 0 && date.minute == 0) {
      return dateStr;
    }
    final timeStr = loc.formatTimeOfDay(TimeOfDay.fromDateTime(date));
    return '$dateStr at $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text('Save', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.text),
              decoration: const InputDecoration(
                hintText: 'Task Title',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 32),
            
            _buildSectionLabel('PRIORITY'),
            const SizedBox(height: 12),
            _buildPrioritySelector(),
            const SizedBox(height: 32),

            _buildSectionLabel('DUE DATE'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate != null ? _formatDate(context, _dueDate!) : 'Set a due date...',
                      style: TextStyle(color: _dueDate != null ? AppTheme.text : AppTheme.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('DESCRIPTION'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _detailsCtrl,
                style: const TextStyle(color: AppTheme.text, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Add details...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                ),
                maxLines: 4,
                minLines: 2,
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('NOTES'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _notesCtrl,
                style: const TextStyle(color: AppTheme.text, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Add extra notes...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                ),
                maxLines: 3,
                minLines: 2,
              ),
            ),
            const SizedBox(height: 40),

            _buildSectionLabel('TIME ESTIMATION'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _timeEstimateCtrl,
                style: const TextStyle(color: AppTheme.text, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'e.g. 2h 30m',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: null, // Disabled placeholder for future LLM hookup
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Auto-Estimate with AI'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                disabledForegroundColor: AppTheme.accent.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPrioritySelector() {
    final priorities = [
      {'val': 'low', 'color': AppTheme.low, 'label': 'LOW'},
      {'val': 'medium', 'color': AppTheme.medium, 'label': 'MEDIUM'},
      {'val': 'high', 'color': AppTheme.high, 'label': 'HIGH'},
      {'val': 'urgent', 'color': AppTheme.urgent, 'label': 'URGENT'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: priorities.map((p) {
        final isSel = _priority == p['val'];
        return GestureDetector(
          onTap: () => setState(() => _priority = p['val'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? (p['color'] as Color).withValues(alpha: 0.15) : AppTheme.card,
              border: Border.all(
                color: isSel ? (p['color'] as Color) : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              p['label'] as String,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSel ? (p['color'] as Color) : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
