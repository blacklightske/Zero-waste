import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/django_data_service.dart';
import '../../models/recipe.dart';
import 'edit_recipe_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _recipe.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            actions: [
              // Save/Unsave button for AI recipes
              if (!_recipe.isCustom)
                IconButton(
                  icon: Icon(
                    _recipe.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _recipe.isSaved ? Colors.yellow[700] : Colors.white,
                  ),
                  onPressed: _toggleSaveRecipe,
                ),
              
              // Edit button for custom recipes
              if (_recipe.isCustom)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _editRecipe,
                ),
              
              // More options
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  if (_recipe.isCustom) ...[
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit Recipe'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Recipe', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ] else ...[
                    PopupMenuItem(
                      value: _recipe.isSaved ? 'unsave' : 'save',
                      child: Row(
                        children: [
                          Icon(_recipe.isSaved ? Icons.bookmark_remove : Icons.bookmark_add),
                          const SizedBox(width: 8),
                          Text(_recipe.isSaved ? 'Remove from Saved' : 'Save Recipe'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.schedule,
                          title: 'Cook Time',
                          value: _recipe.estimatedTime,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.signal_cellular_alt,
                          title: 'Difficulty',
                          value: _recipe.difficulty,
                          color: _getDifficultyColor(_recipe.difficulty),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.restaurant,
                          title: 'Type',
                          value: _recipe.isCustom ? 'Custom' : 'AI Generated',
                          color: _recipe.isCustom ? Colors.purple : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Ingredients Section
                  _buildIngredientsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Instructions Section
                  _buildInstructionsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Recipe Details
                  _buildRecipeDetails(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Floating Action Button
      floatingActionButton: _recipe.isCustom
          ? FloatingActionButton(
              heroTag: "recipe_detail_edit_fab",
              onPressed: _editRecipe,
              child: const Icon(Icons.edit),
            )
          : FloatingActionButton.extended(
              heroTag: "recipe_detail_save_fab",
              onPressed: _toggleSaveRecipe,
              icon: Icon(_recipe.isSaved ? Icons.bookmark_remove : Icons.bookmark_add),
              label: Text(_recipe.isSaved ? 'Unsave' : 'Save Recipe'),
            ),
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.list_alt,
                color: Colors.green[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Ingredients',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_recipe.ingredients.length} items',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: Column(
            children: _recipe.ingredients.asMap().entries.map((entry) {
              final index = entry.key;
              final ingredient = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index == _recipe.ingredients.length - 1 ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.format_list_numbered,
                color: Colors.blue[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Instructions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_recipe.instructions.length} steps',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Column(
            children: _recipe.instructions.asMap().entries.map((entry) {
              final index = entry.key;
              final instruction = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index == _recipe.instructions.length - 1 ? 0 : 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        instruction,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecipeDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recipe Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          _buildDetailRow('Recipe ID', _recipe.id),
          _buildDetailRow('Type', _recipe.isCustom ? 'Custom Recipe' : 'AI Generated'),
          if (_recipe.isSaved) _buildDetailRow('Status', 'Saved to Favorites'),
          _buildDetailRow('Created', _formatDate(_recipe.createdAt)),
          _buildDetailRow('Estimated Time', _recipe.estimatedTime),
          _buildDetailRow('Difficulty Level', _recipe.difficulty),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editRecipe();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
      case 'save':
      case 'unsave':
        _toggleSaveRecipe();
        break;
    }
  }
  
  void _editRecipe() {
    if (_recipe.isCustom) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditRecipeScreen(recipe: _recipe),
        ),
      ).then((_) {
        // Refresh recipe data after editing
        _refreshRecipeData();
      });
    }
  }
  
  Future<void> _toggleSaveRecipe() async {
    if (_recipe.isCustom) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataService = Provider.of<DjangoDataService>(context, listen: false);
      
      bool success;
      if (_recipe.isSaved) {
        success = await dataService.unsaveRecipe(_recipe.id);
      } else {
        success = await dataService.saveRecipe(_recipe);
      }
      
      if (success && mounted) {
        setState(() {
          _recipe = _recipe.copyWith(isSaved: !_recipe.isSaved);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _recipe.isSaved 
                  ? 'Recipe saved to favorites!' 
                  : 'Recipe removed from favorites',
            ),
            backgroundColor: _recipe.isSaved ? Colors.green : Colors.orange,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update recipe. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${_recipe.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteRecipe();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteRecipe() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataService = Provider.of<DjangoDataService>(context, listen: false);
      
      bool success;
      if (_recipe.isCustom) {
        success = await dataService.deleteCustomRecipe(_recipe.id);
      } else {
        success = await dataService.unsaveRecipe(_recipe.id);
      }
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe "${_recipe.name}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete recipe. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _refreshRecipeData() async {
    try {
      final dataService = Provider.of<DjangoDataService>(context, listen: false);
      await dataService.loadUserData();
      
      // Find updated recipe in the loaded data
      final updatedRecipe = dataService.customRecipes
          .firstWhere((r) => r.id == _recipe.id, orElse: () => _recipe);
      
      if (mounted) {
        setState(() {
          _recipe = updatedRecipe;
        });
      }
    } catch (e) {
      // Handle error silently or show a message
    }
  }
}