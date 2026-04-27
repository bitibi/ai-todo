import 'package:flutter/material.dart';
import '../models/models.dart';

class CategoryTile extends StatelessWidget {
  final TodoList list;
  final VoidCallback onTap;
  final List<Color> gradientColors;

  const CategoryTile({
    super.key, 
    required this.list, 
    required this.onTap,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    int count = (list.tasks?.length ?? 0);
    if (list.sections != null) {
      for (var s in list.sections!) {
        count += (s.tasks?.length ?? 0);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              list.icon ?? '📋',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 6),
            Text(
              list.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$count tasks',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
