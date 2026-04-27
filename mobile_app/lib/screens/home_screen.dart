import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    
    // Calculate stats
    int urgentCount = 0;
    int openCount = 0;
    List<Task> urgentTasks = [];
    
    for (var list in provider.listDetails.values) {
      if (list.tasks != null) {
        for (var t in list.tasks!) {
          if (!t.isCompleted) openCount++;
          if (!t.isCompleted && t.priority == 'urgent') {
            urgentCount++;
            urgentTasks.add(t);
          }
        }
      }
      if (list.sections != null) {
        for (var sec in list.sections!) {
          if (sec.tasks != null) {
            for (var t in sec.tasks!) {
              if (!t.isCompleted) openCount++;
              if (!t.isCompleted && t.priority == 'urgent') {
                urgentCount++;
                urgentTasks.add(t);
              }
            }
          }
        }
      }
    }

    Task? upNext = urgentTasks.isNotEmpty ? urgentTasks.first : null;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SATURDAY 25 APRIL', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Good morning,\n${user?.fullName ?? 'User'}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 28),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: AppTheme.card,
                    child: Text(user?.fullName?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              if (upNext != null) ...[
                // UP NEXT Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UP NEXT', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.accent)),
                      const SizedBox(height: 12),
                      Text(upNext.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.urgent.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                            child: Text('URGENT', style: TextStyle(color: AppTheme.urgent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text('· ${upNext.timeEstimate ?? '10 min'}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              context.read<AppProvider>().completeTask(upNext.id, upNext.listId);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(20)),
                              child: const Row(
                                children: [
                                  Text('Complete', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                  SizedBox(width: 4),
                                  Icon(Icons.check, color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // STATS GRID
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, urgentCount.toString(), 'URGENT')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(context, openCount.toString(), 'OPEN')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(context, '2h\n10m', 'TODAY')),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // URGENT LIST
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.urgent, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('URGENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 8),
                  Text('$urgentCount', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const Spacer(),
                  const Text('See all →', style: TextStyle(color: AppTheme.accent, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              
              if (urgentTasks.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No urgent tasks!', style: TextStyle(color: AppTheme.textSecondary))))
              else
                ...urgentTasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.read<AppProvider>().completeTask(t.id, t.listId),
                        child: Icon(t.isCompleted ? Icons.check_circle : Icons.circle_outlined, color: t.isCompleted ? AppTheme.accent : AppTheme.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(t.title, style: TextStyle(color: Colors.white, decoration: t.isCompleted ? TextDecoration.lineThrough : null))),
                      Text(t.timeEstimate ?? '-', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                )),
                
              const SizedBox(height: 80), // bottom nav spacing
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, letterSpacing: 1.1)),
        ],
      ),
    );
  }
}
