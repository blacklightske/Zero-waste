import 'package:flutter/material.dart';
import '../models/todo.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;
  final ValueChanged<bool?>? onToggleComplete;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  
  const TodoCard({
    super.key,
    required this.todo,
    this.onToggleComplete,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = todo.isOverdue;
    final isDueToday = todo.isDueToday;
    final priority = todo.priority;
    
    Color priorityColor;
    IconData priorityIcon;
    
    switch (priority) {
      case 'High':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        priorityIcon = Icons.remove;
        break;
      case 'Low':
        priorityColor = Colors.green;
        priorityIcon = Icons.keyboard_arrow_down;
        break;
      default:
        priorityColor = Colors.grey;
        priorityIcon = Icons.help_outline;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue 
              ? Colors.red.withOpacity(0.3)
              : isDueToday 
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Checkbox
                  Checkbox(
                    value: todo.isCompleted,
                    onChanged: onToggleComplete,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Todo Title
                  Expanded(
                    child: Text(
                      todo.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: todo.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: todo.isCompleted 
                            ? Colors.grey[600] 
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: priorityColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          priorityIcon,
                          size: 14,
                          color: priorityColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          priority,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Actions Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Description (if available)
              if (todo.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Text(
                    todo.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: todo.isCompleted 
                          ? Colors.grey[500] 
                          : Colors.grey[700],
                      decoration: todo.isCompleted 
                          ? TextDecoration.lineThrough 
                          : null,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Footer with dates and status
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Row(
                  children: [
                    // Due Date
                    if (todo.dueDate != null) ...[
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: isOverdue 
                            ? Colors.red 
                            : isDueToday 
                                ? Colors.orange 
                                : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_formatDate(todo.dueDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isOverdue 
                              ? Colors.red 
                              : isDueToday 
                                  ? Colors.orange 
                                  : Colors.grey[600],
                          fontWeight: isOverdue || isDueToday 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                    
                    const Spacer(),
                    
                    // Status indicators
                    if (isOverdue && !todo.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          'OVERDUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      )
                    else if (isDueToday && !todo.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Text(
                          'DUE TODAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      )
                    else if (todo.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(
                          'COMPLETED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Related Recipe (if available)
              if (todo.relatedRecipeId != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Related to recipe',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Created date
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Created: ${_formatDate(todo.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);
    
    if (dateDay == today) {
      return 'Today';
    } else if (dateDay == tomorrow) {
      return 'Tomorrow';
    } else if (dateDay == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}