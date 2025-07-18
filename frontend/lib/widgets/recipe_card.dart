import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onUnsave;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showSaveButton;
  final bool isSaved;
  
  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onSave,
    this.onUnsave,
    this.onEdit,
    this.onDelete,
    this.showSaveButton = false,
    this.isSaved = false, required bool showDeleteButton, required bool showEditButton,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                  // Recipe Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Recipe Name
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Save/Unsave Button (for AI recipes)
                      if (showSaveButton)
                        IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved ? Colors.amber : Colors.grey,
                          ),
                          onPressed: isSaved ? onUnsave : onSave,
                          tooltip: isSaved ? 'Unsave Recipe' : 'Save Recipe',
                        ),
                      
                      // Menu for custom recipes
                      if (!showSaveButton)
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
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Recipe Details
              Row(
                children: [
                  // Cooking Time
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    recipe.estimatedTime,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Difficulty
                  Icon(
                    Icons.bar_chart,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    recipe.difficulty,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Recipe Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: recipe.isCustom 
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: recipe.isCustom 
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      recipe.isCustom ? 'Custom' : 'AI Generated',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: recipe.isCustom ? Colors.blue[700] : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Ingredients Preview
              if (recipe.ingredients.isNotEmpty) ...[
                Text(
                  'Ingredients:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.ingredients.take(3).join(', ') + 
                      (recipe.ingredients.length > 3 ? '...' : ''),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Instructions Preview
              if (recipe.instructions.isNotEmpty) ...[
                Text(
                  'Instructions:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.instructions.first,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (recipe.instructions.length > 1)
                  Text(
                    '... and ${recipe.instructions.length - 1} more steps',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
              
              const SizedBox(height: 12),
              
              // Footer
              Row(
                children: [
                  Text(
                    'Created: ${_formatDate(recipe.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Share button
                  IconButton(
                    onPressed: () => _shareRecipe(context),
                    icon: Icon(
                      Icons.share,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: 'Share Recipe',
                  ),
                  
                  // Tap to view indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tap to view',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _shareRecipe(BuildContext context) {
    final recipeText = '''
🍽️ ${recipe.name}

📝 Ingredients:
${recipe.ingredients.map((ingredient) => '• $ingredient').join('\n')}

👨‍🍳 Instructions:
${recipe.instructions.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}').join('\n')}

📱 Shared from ZeroWaste App
''';

    Clipboard.setData(ClipboardData(text: recipeText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recipe copied to clipboard!'),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () {
            // Here you could integrate with platform share dialog
            // For now, we'll just show another snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recipe is ready to share!'),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);
    
    if (dateDay == today) {
      return 'Today';
    } else if (dateDay == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}