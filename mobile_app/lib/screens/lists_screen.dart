import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';
import 'list_detail_screen.dart';

class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  final List<List<Color>> _tileGradients = const [
    [Color(0xFFE63946), Color(0xFFFF6B6B)],
    [Color(0xFF00B894), Color(0xFF55EFC4)],
    [Color(0xFF0984E3), Color(0xFF74B9FF)],
    [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    [Color(0xFFE67E22), Color(0xFFFDCB6E)],
    [Color(0xFF00CEC9), Color(0xFF81ECEC)],
    [Color(0xFFFD79A8), Color(0xFFE84393)],
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lists = provider.lists;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${lists.length} LISTS', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text('Lists', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 28)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          final ctrl = TextEditingController();
                          return AlertDialog(
                            backgroundColor: AppTheme.card,
                            title: const Text('New List', style: TextStyle(color: Colors.white)),
                            content: TextField(
                              controller: ctrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(hintText: 'List name', hintStyle: TextStyle(color: AppTheme.textSecondary)),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
                              TextButton(
                                onPressed: () {
                                  if (ctrl.text.isNotEmpty) {
                                    provider.addList(ctrl.text);
                                    Navigator.pop(ctx);
                                  }
                                },
                                child: const Text('Add', style: TextStyle(color: AppTheme.accent)),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.accent,
                backgroundColor: AppTheme.card,
                onRefresh: () => provider.loadData(),
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    final gradient = _tileGradients[index % _tileGradients.length];
                    return _buildListTile(context, list, gradient);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, TodoList list, List<Color> gradient) {
    final detail = context.read<AppProvider>().listDetails[list.id];
    int taskCount = 0;
    if (detail != null) {
      taskCount += detail.tasks?.length ?? 0;
      if (detail.sections != null) {
        for (var s in detail.sections!) {
          taskCount += s.tasks?.length ?? 0;
        }
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ListDetailScreen(list: list)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              gradient[0].withOpacity(0.15),
              AppTheme.card,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: gradient[0].withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gradient[0].withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(list.icon ?? '📝', style: const TextStyle(fontSize: 18)),
            ),
            const Spacer(),
            Text(
              list.name,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$taskCount tasks',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
