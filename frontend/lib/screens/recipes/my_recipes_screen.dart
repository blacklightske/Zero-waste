import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/django_data_service.dart';
import '../../models/recipe.dart';
import '../../widgets/recipe_card.dart';
import 'add_custom_recipe_screen.dart';
import 'edit_recipe_screen.dart';
import 'recipe_detail_screen.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _sortBy = 'date_added'; // 'date_added', 'name', 'cooking_time'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddCustomRecipeScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.bookmark),
              text: 'Saved Recipes',
            ),
            Tab(
              icon: Icon(Icons.create),
              text: 'My Recipes',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSavedRecipesTab(),
                _buildCustomRecipesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "recipes_fab",
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddCustomRecipeScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildSavedRecipesTab() {
    return Consumer<DjangoDataService>(
        builder: (context, dataService, _) {
          if (dataService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredRecipes = _getFilteredRecipes(dataService.savedRecipes);
        
        if (filteredRecipes.isEmpty) {
          return _buildEmptyState(
            icon: Icons.bookmark_border,
            title: _searchQuery.isNotEmpty
                ? 'No saved recipes found'
                : 'No saved recipes yet',
            subtitle: _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'Save recipes from the Recipe Generator to see them here',
            actionText: 'Generate Recipes',
            onAction: () {
              // Navigate to recipe generator
              Navigator.of(context).pop();
            },
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await dataService.loadUserData();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredRecipes.length,
            itemBuilder: (context, index) {
              final recipe = filteredRecipes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RecipeCard(
                  recipe: recipe,
                  onTap: () => _navigateToRecipeDetail(recipe),
                  onUnsave: () => _unsaveRecipe(recipe), showDeleteButton: false, showEditButton: false,
// Remove duplicate onUnsave parameter since it was already specified above
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildCustomRecipesTab() {
    return Consumer<DjangoDataService>(
        builder: (context, dataService, _) {
          if (dataService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredRecipes = _getFilteredRecipes(dataService.customRecipes);
        
        if (filteredRecipes.isEmpty) {
          return _buildEmptyState(
            icon: Icons.create_outlined,
            title: _searchQuery.isNotEmpty
                ? 'No custom recipes found'
                : 'No custom recipes yet',
            subtitle: _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'Create your first custom recipe to get started',
            actionText: 'Add Recipe',
            onAction: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddCustomRecipeScreen(),
                ),
              );
            },
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await dataService.loadUserData();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredRecipes.length,
            itemBuilder: (context, index) {
              final recipe = filteredRecipes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RecipeCard(
                  recipe: recipe,
                  onTap: () => _navigateToRecipeDetail(recipe),
                  onEdit: () => _editRecipe(recipe),
                  onDelete: () => _deleteRecipe(recipe),
                  showEditButton: true,
                  showDeleteButton: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText),
              ),
          ],
        ),
      ),
    );
  }
  
  int _getEstimatedMinutes(String estimatedTime) {
    // Convert estimated time string to minutes for sorting
    if (estimatedTime.contains('15-20')) return 17;
    if (estimatedTime.contains('25-35')) return 30;
    if (estimatedTime.contains('40+')) return 45;
    return 30; // default
  }
  
  List<Recipe> _getFilteredRecipes(List<Recipe> recipes) {
    List<Recipe> filtered = recipes;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((recipe) {
        return recipe.name.toLowerCase().contains(_searchQuery) ||
               recipe.ingredients.any((ingredient) => 
                   ingredient.toLowerCase().contains(_searchQuery)) ||
               recipe.instructions.any((instruction) => 
                   instruction.toLowerCase().contains(_searchQuery));
      }).toList();
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'cooking_time':
        filtered.sort((a, b) => _getEstimatedMinutes(a.estimatedTime).compareTo(_getEstimatedMinutes(b.estimatedTime)));
        break;
      case 'date_added':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    
    return filtered;
  }
  
  void _navigateToRecipeDetail(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }
  
  void _editRecipe(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditRecipeScreen(recipe: recipe),
      ),
    );
  }
  
  Future<void> _deleteRecipe(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${recipe.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      try {
        final dataService = Provider.of<DjangoDataService>(context, listen: false);
    final success = await dataService.deleteCustomRecipe(recipe.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Recipe "${recipe.name}" deleted successfully'
                    : 'Failed to delete recipe',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting recipe: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _unsaveRecipe(Recipe recipe) async {
    try {
      final dataService = Provider.of<DjangoDataService>(context, listen: false);
    final success = await dataService.unsaveRecipe(recipe.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Recipe "${recipe.name}" removed from saved'
                  : 'Failed to remove recipe',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            action: success
                ? SnackBarAction(
                    label: 'Undo',
                    textColor: Colors.white,
                    onPressed: () async {
                      await dataService.saveRecipe(recipe);
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing recipe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Recipes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Date Added (Newest First)'),
              value: 'date_added',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Name (A-Z)'),
              value: 'name',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Cooking Time'),
              value: 'cooking_time',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}