import 'package:flutter/material.dart';
import '../models/food_item.dart';

class FoodCard extends StatelessWidget {
  final FoodItem foodItem;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  
  const FoodCard({
    super.key,
    required this.foodItem,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = foodItem.isExpired;
    final isExpiringSoon = foodItem.expiresSoon;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isExpired) {
      statusColor = Theme.of(context).colorScheme.error;
      statusIcon = Icons.warning;
      statusText = 'Expired';
    } else if (isExpiringSoon) {
      statusColor = Theme.of(context).colorScheme.secondary;
      statusIcon = Icons.schedule;
      statusText = 'Expires Soon';
    } else {
      statusColor = Theme.of(context).colorScheme.primary;
      statusIcon = Icons.check_circle;
      statusText = 'Fresh';
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Semantics(
        label: 'Food item: ${foodItem.name}, $statusText, expires ${_formatDate(foodItem.expiryDate)}',
        button: onTap != null,
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
                  // Food Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fastfood,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Food Name and Quantity
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          foodItem.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Quantity: ${foodItem.quantity}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions Menu
                  Tooltip(
                    message: 'More options',
                    child: PopupMenuButton<String>(
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
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status and Expiry Info
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Expiry Date
                  Text(
                    'Expires: ${_formatDate(foodItem.expiryDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              // Days until expiry (if not expired)
              if (!isExpired) ...[
                const SizedBox(height: 8),
                Text(
                  _getDaysUntilExpiry(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isExpiringSoon ? Theme.of(context).colorScheme.secondary : Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final expiryDay = DateTime(date.year, date.month, date.day);
      
      if (expiryDay == today) {
        return 'Today';
      } else if (expiryDay == tomorrow) {
        return 'Tomorrow';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }
  
  String _getDaysUntilExpiry() {
    try {
      final difference = foodItem.daysUntilExpiry;
      
      if (difference == 0) {
        return 'Expires today';
      } else if (difference == 1) {
        return 'Expires tomorrow';
      } else if (difference > 0) {
        return 'Expires in $difference ${difference == 1 ? 'day' : 'days'}';
      } else {
        return 'Expired ${difference.abs()} ${difference.abs() == 1 ? 'day' : 'days'} ago';
      }
    } catch (e) {
      return 'Unable to calculate expiry';
    }
  }
}