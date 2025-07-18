import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import '../models/recipe.dart';
import '../models/todo.dart';
import 'api_service.dart';
import 'django_auth_service.dart';

class DjangoDataService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DjangoAuthService _authService;
  
  List<FoodItem> _foodItems = [];
  List<Recipe> _savedRecipes = [];
  List<Recipe> _customRecipes = [];
  List<Todo> _todos = [];
  
  List<FoodItem> get foodItems => _foodItems;
  List<Recipe> get savedRecipes => _savedRecipes;
  List<Recipe> get customRecipes => _customRecipes;
  List<Recipe> get recipes => [..._savedRecipes, ..._customRecipes]; // All recipes combined
  List<Todo> get todos => _todos;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DjangoDataService(this._authService);

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    _setLoading(false);
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load all user data
  Future<void> loadUserData() async {
    if (!_authService.isAuthenticated) {
      debugPrint('Not authenticated, skipping data load.');
      return;
    }
    
    if (_isLoading) {
      debugPrint('Already loading user data, skipping...');
      return;
    }
    
    debugPrint('Starting to load user data...');
    try {
      _setLoading(true);
      
      // Load all data in parallel
      final results = await Future.wait([
        _apiService.getFoodItems(),
        _apiService.getRecipes(),
        _apiService.getTodos(),
      ]);
      
      _foodItems = results[0] as List<FoodItem>;
      debugPrint('Loaded ${_foodItems.length} food items.');
      final allRecipes = results[1] as List<Recipe>;
      _todos = results[2] as List<Todo>;
      
      // Separate saved and custom recipes
      _savedRecipes = allRecipes.where((recipe) => !recipe.isCustom && recipe.isSaved).toList();
      _customRecipes = allRecipes.where((recipe) => recipe.isCustom).toList();
      
      _setLoading(false);
      debugPrint('Finished loading data, notifying listeners...');
      notifyListeners(); // Explicitly notify after setting loading to false
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _setError('Failed to load data: $e');
    }
  }

  // FOOD ITEMS METHODS
  
  // Add food item
  Future<bool> addFoodItem(FoodItem foodItem) async {
    debugPrint('DjangoDataService.addFoodItem called with: ${foodItem.toJson()}');
    
    if (!_authService.isAuthenticated) {
      debugPrint('User not authenticated, cannot add food item');
      return false;
    }
    
    debugPrint('User is authenticated, proceeding with API call...');
    
    try {
      debugPrint('Calling _apiService.createFoodItem...');
      final newItem = await _apiService.createFoodItem(foodItem);
      debugPrint('API call successful, received: ${newItem.toJson()}');
      
      _foodItems.add(newItem);
      debugPrint('Added to local list, total items: ${_foodItems.length}');
      
      notifyListeners();
      debugPrint('Notified listeners, returning true');
      return true;
    } catch (e) {
      debugPrint('Exception in addFoodItem: $e');
      debugPrint('Exception type: ${e.runtimeType}');
      _setError('Failed to add food item: $e');
      return false;
    }
  }
  
  // Update food item
  Future<bool> updateFoodItem(FoodItem updatedItem) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      final updated = await _apiService.updateFoodItem(updatedItem);
      final index = _foodItems.indexWhere((item) => item.id == updated.id);
      if (index != -1) {
        _foodItems[index] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update food item: $e');
      return false;
    }
  }
  
  // Delete food item
  Future<bool> deleteFoodItem(String itemId) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      await _apiService.deleteFoodItem(itemId);
      _foodItems.removeWhere((item) => item.id == itemId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete food item: $e');
      return false;
    }
  }

  // RECIPE METHODS
  
  // Save recipe (AI-generated or custom)
  Future<bool> saveRecipe(Recipe recipe) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      final savedRecipe = await _apiService.createRecipe(recipe);
      
      if (savedRecipe.isCustom) {
        _customRecipes.add(savedRecipe);
      } else {
        _savedRecipes.add(savedRecipe);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to save recipe: $e');
      return false;
    }
  }
  
  // Update recipe
  Future<bool> updateRecipe(Recipe updatedRecipe) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      final updated = await _apiService.updateRecipe(updatedRecipe);
      
      if (updated.isCustom) {
        final index = _customRecipes.indexWhere((r) => r.id == updated.id);
        if (index != -1) {
          _customRecipes[index] = updated;
        }
      } else {
        final index = _savedRecipes.indexWhere((r) => r.id == updated.id);
        if (index != -1) {
          _savedRecipes[index] = updated;
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update recipe: $e');
      return false;
    }
  }
  
  // Delete recipe
  Future<bool> deleteRecipe(String recipeId, bool isCustom) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      await _apiService.deleteRecipe(recipeId);
      
      if (isCustom) {
        _customRecipes.removeWhere((recipe) => recipe.id == recipeId);
      } else {
        _savedRecipes.removeWhere((recipe) => recipe.id == recipeId);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete recipe: $e');
      return false;
    }
  }
  
  // Delete custom recipe
  Future<bool> deleteCustomRecipe(String recipeId) async {
    return await deleteRecipe(recipeId, true);
  }
  
  // Unsave recipe (remove from saved recipes)
  Future<bool> unsaveRecipe(String recipeId) async {
    return await deleteRecipe(recipeId, false);
  }
  
  // Update custom recipe
  Future<bool> updateCustomRecipe(Recipe updatedRecipe) async {
    return await updateRecipe(updatedRecipe);
  }
  
  // Add custom recipe
  Future<bool> addCustomRecipe(Recipe recipe) async {
    return await saveRecipe(recipe);
  }

  // TODO METHODS
  
  // Add todo
  Future<bool> addTodo(Todo todo) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      final newTodo = await _apiService.createTodo(todo);
      _todos.add(newTodo);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add todo: $e');
      return false;
    }
  }
  
  // Update todo
  Future<bool> updateTodo(Todo updatedTodo) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      final updated = await _apiService.updateTodo(updatedTodo);
      final index = _todos.indexWhere((todo) => todo.id == updated.id);
      if (index != -1) {
        _todos[index] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update todo: $e');
      return false;
    }
  }
  
  // Delete todo
  Future<bool> deleteTodo(String todoId) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      await _apiService.deleteTodo(todoId);
      _todos.removeWhere((todo) => todo.id == todoId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete todo: $e');
      return false;
    }
  }
  
  // Toggle todo completion
  Future<bool> toggleTodoCompletion(String todoId) async {
    final todo = _todos.firstWhere((t) => t.id == todoId);
    return await updateTodo(todo.copyWith(isCompleted: !todo.isCompleted));
  }

  // UTILITY METHODS
  
  // Get expired food items
  List<FoodItem> get expiredFoodItems {
    return _foodItems.where((item) => item.isExpired).toList();
  }
  
  // Get soon-to-expire food items
  List<FoodItem> get soonToExpireFoodItems {
    return _foodItems.where((item) => item.expiresSoon).toList();
  }
  
  // Get pending todos
  List<Todo> get pendingTodos {
    return _todos.where((todo) => !todo.isCompleted).toList();
  }
  
  // Get completed todos
  List<Todo> get completedTodos {
    return _todos.where((todo) => todo.isCompleted).toList();
  }
  
  // Get all recipes (saved + custom)
  List<Recipe> get allRecipes {
    return [..._savedRecipes, ..._customRecipes];
  }
}