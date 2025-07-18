import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/django_data_service.dart';
import '../../services/ai_service.dart';
import '../../models/food_item.dart';
import '../../models/recipe.dart';
import '../../widgets/recipe_card.dart';

class RecipeGeneratorScreen extends StatefulWidget {
  const RecipeGeneratorScreen({super.key});

  @override
  State<RecipeGeneratorScreen> createState() => _RecipeGeneratorScreenState();
}

class _RecipeGeneratorScreenState extends State<RecipeGeneratorScreen> {
  final _customIngredientsController = TextEditingController();
  
  final List<FoodItem> _selectedIngredients = [];
  List<Recipe> _generatedRecipes = [];
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _customIngredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Generator'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'AI Recipe Generator',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Turn your ingredients into delicious recipes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Ingredients Selection
            _buildIngredientsSection(),
            
            const SizedBox(height: 24),
            
            // Custom Ingredients Input
            _buildCustomIngredientsSection(),
            
            const SizedBox(height: 24),
            
            // Generate Button
            _buildGenerateButton(),
            
            const SizedBox(height: 24),
            
            // Error Message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Loading Indicator
            if (_isGenerating) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Generating recipes...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a few seconds',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Generated Recipes
            if (_generatedRecipes.isNotEmpty) ...[
              Text(
                'Generated Recipes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._generatedRecipes.map((recipe) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RecipeCard(
                  showDeleteButton: false,
                  recipe: recipe,
                  onSave: () => _saveRecipe(recipe),
                  showSaveButton: true, showEditButton: false,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildIngredientsSection() {
    return Consumer<DjangoDataService>(
          builder: (context, dataService, _) {
            final availableIngredients = dataService.foodItems
            .where((item) => !item.isExpired)
            .toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select from Your Pantry',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (availableIngredients.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No ingredients in your pantry',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add some food items to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Selected ingredients
              if (_selectedIngredients.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Ingredients (${_selectedIngredients.length})',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedIngredients.map((ingredient) {
                          return Chip(
                            label: Text(ingredient.name),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _selectedIngredients.remove(ingredient);
                              });
                            },
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Available ingredients
              Text(
                'Available Ingredients',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  itemCount: availableIngredients.length,
                  itemBuilder: (context, index) {
                    final ingredient = availableIngredients[index];
                    final isSelected = _selectedIngredients.contains(ingredient);
                    
                    return CheckboxListTile(
                      title: Text(ingredient.name),
                      subtitle: Text('${ingredient.quantity} • Expires in ${ingredient.daysUntilExpiry} days'),
                      value: isSelected,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedIngredients.add(ingredient);
                          } else {
                            _selectedIngredients.remove(ingredient);
                          }
                        });
                      },
                      secondary: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ingredient.expiresSoon
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          ingredient.expiresSoon
                              ? Icons.warning_outlined
                              : Icons.check_circle_outline,
                          color: ingredient.expiresSoon ? Colors.orange : Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
  
  Widget _buildCustomIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit_outlined,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Add Custom Ingredients',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _customIngredientsController,
          decoration: InputDecoration(
            hintText: 'e.g., onions, garlic, olive oil, salt',
            prefixIcon: const Icon(Icons.add),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        Text(
          'Separate multiple ingredients with commas',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildGenerateButton() {
    final hasIngredients = _selectedIngredients.isNotEmpty || 
                          _customIngredientsController.text.trim().isNotEmpty;
    
    return ElevatedButton(
      onPressed: hasIngredients && !_isGenerating ? _generateRecipes : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isGenerating)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            const Icon(Icons.auto_awesome),
          const SizedBox(width: 8),
          Text(
            _isGenerating ? 'Generating...' : 'Generate Recipes',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _generateRecipes() async {
    debugPrint('Starting recipe generation...');
    
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedRecipes.clear();
    });
    
    try {
      // Combine selected ingredients and custom ingredients
      final ingredients = <String>[];
      
      // Add selected pantry ingredients
      ingredients.addAll(_selectedIngredients.map((item) => item.name));
      
      // Add custom ingredients
      final customIngredients = _customIngredientsController.text
          .split(',')
          .map((ingredient) => ingredient.trim())
          .where((ingredient) => ingredient.isNotEmpty)
          .toList();
      ingredients.addAll(customIngredients);
      
      debugPrint('Ingredients for recipe generation: $ingredients');
      
      if (ingredients.isEmpty) {
        setState(() {
          _errorMessage = 'Please select or add some ingredients';
          _isGenerating = false;
        });
        return;
      }
      
      debugPrint('Calling AIService.generateRecipes...');
      final recipes = await AIService.generateRecipes(ingredients);
      debugPrint('Received ${recipes.length} recipes');
      
      if (mounted) {
        setState(() {
          _generatedRecipes = recipes;
          _isGenerating = false;
        });
        
        if (recipes.isEmpty) {
          setState(() {
            _errorMessage = 'No recipes could be generated. Try different ingredients.';
          });
        }
      }
    } catch (e) {
      debugPrint('Error generating recipes: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to generate recipes: ${e.toString()}';
          _isGenerating = false;
        });
      }
    }
  }
  
  Future<void> _saveRecipe(Recipe recipe) async {
    try {
      final dataService = Provider.of<DjangoDataService>(context, listen: false);
    final success = await dataService.saveRecipe(recipe);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Recipe "${recipe.name}" saved successfully!'
                  : 'Failed to save recipe',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            action: success
                ? SnackBarAction(
                    label: 'View',
                    textColor: Colors.white,
                    onPressed: () {
                      // Navigate to My Recipes tab
                      Navigator.of(context).pop();
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
            content: Text('Error saving recipe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}