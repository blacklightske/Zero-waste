import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/recipe.dart';

class AIService {
  // Get API key from environment variables
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  // Generate recipe suggestions based on ingredients
  static Future<List<Recipe>> generateRecipes(List<String> ingredients) async {
    try {
      print('AIService.generateRecipes called with: $ingredients');
      
      if (ingredients.isEmpty) {
        print('No ingredients provided, throwing exception');
        throw Exception('No ingredients provided');
      }
      
      // Check if API key is configured, if not use demo recipes
      if (!isConfigured) {
        print('API key not configured, using demo recipes');
        return getDemoRecipes(ingredients);
      }
      
      print('API key configured, making API call...');
      final prompt = _buildPrompt(ingredients);
      final response = await _makeAPICall(prompt);
      
      return _parseRecipeResponse(response);
    } catch (e) {
      print('Error in generateRecipes: $e');
      // Fallback to demo recipes if API call fails
      return getDemoRecipes(ingredients);
    }
  }
  
  // Build the prompt for OpenAI
  static String _buildPrompt(List<String> ingredients) {
    final ingredientList = ingredients.join(', ');
    
    return '''
Give me 2 simple recipes using these ingredients: $ingredientList.

For each recipe, provide:
1. Recipe name
2. Complete ingredients list (including the provided ingredients and any additional common ingredients needed)
3. 3-5 step cooking instructions

Format your response as JSON with this exact structure:
{
  "recipes": [
    {
      "name": "Recipe Name",
      "ingredients": ["ingredient 1", "ingredient 2", "ingredient 3"],
      "instructions": ["Step 1", "Step 2", "Step 3"]
    }
  ]
}

Make the recipes simple, practical, and suitable for home cooking. Focus on reducing food waste by using the provided ingredients effectively.''';
  }
  
  // Make API call to OpenAI
  static Future<String> _makeAPICall(String prompt) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };
    
    final body = json.encode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {
          'role': 'system',
          'content': 'You are a helpful cooking assistant focused on reducing food waste. Always respond with valid JSON format.'
        },
        {
          'role': 'user',
          'content': prompt
        }
      ],
      'max_tokens': 1000,
      'temperature': 0.7,
    });
    
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: headers,
      body: body,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API key. Please check your OpenAI API key.');
    } else if (response.statusCode == 429) {
      throw Exception('API rate limit exceeded. Please try again later.');
    } else {
      throw Exception('API request failed with status: ${response.statusCode}');
    }
  }
  
  // Parse the API response and create Recipe objects
  static List<Recipe> _parseRecipeResponse(String response) {
    try {
      // Clean the response to extract JSON
      String cleanResponse = response.trim();
      
      // Remove any markdown code blocks if present
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      
      final data = json.decode(cleanResponse);
      final recipesData = data['recipes'] as List<dynamic>;
      
      return recipesData.map((recipeData) {
        return Recipe.fromAI(
          name: recipeData['name'] ?? 'Untitled Recipe',
          ingredients: List<String>.from(recipeData['ingredients'] ?? []),
          instructions: List<String>.from(recipeData['instructions'] ?? []),
        );
      }).toList();
    } catch (e) {
      // Fallback: try to parse as a simpler format or return default recipes
      return _createFallbackRecipes(response);
    }
  }
  
  // Create fallback recipes if parsing fails
  static List<Recipe> _createFallbackRecipes(String response) {
    // Try to extract recipe information from plain text response
    final lines = response.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    if (lines.isEmpty) {
      return [_getDefaultRecipe()];
    }
    
    // Simple parsing attempt
    try {
      String recipeName = 'Simple Recipe';
      List<String> ingredients = [];
      List<String> instructions = [];
      
      String currentSection = '';
      
      for (String line in lines) {
        final trimmedLine = line.trim();
        
        if (trimmedLine.toLowerCase().contains('recipe') && recipeName == 'Simple Recipe') {
          recipeName = trimmedLine.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
        } else if (trimmedLine.toLowerCase().contains('ingredient')) {
          currentSection = 'ingredients';
        } else if (trimmedLine.toLowerCase().contains('instruction') || 
                   trimmedLine.toLowerCase().contains('step')) {
          currentSection = 'instructions';
        } else if (currentSection == 'ingredients' && trimmedLine.isNotEmpty) {
          ingredients.add(trimmedLine.replaceAll(RegExp(r'^[-•*\d\.\s]+'), ''));
        } else if (currentSection == 'instructions' && trimmedLine.isNotEmpty) {
          instructions.add(trimmedLine.replaceAll(RegExp(r'^[-•*\d\.\s]+'), ''));
        }
      }
      
      if (ingredients.isNotEmpty && instructions.isNotEmpty) {
        return [Recipe.fromAI(
          name: recipeName,
          ingredients: ingredients.take(10).toList(), // Limit ingredients
          instructions: instructions.take(8).toList(), // Limit instructions
        )];
      }
    } catch (e) {
      // If all parsing fails, return default recipe
    }
    
    return [_getDefaultRecipe()];
  }
  
  // Get a default recipe when all else fails
  static Recipe _getDefaultRecipe() {
    return Recipe.fromAI(
      name: 'Simple Stir-Fry',
      ingredients: [
        'Available vegetables from your pantry',
        '2 tablespoons cooking oil',
        'Salt and pepper to taste',
        'Optional: soy sauce or seasonings'
      ],
      instructions: [
        'Heat oil in a large pan or wok over medium-high heat',
        'Add your vegetables, starting with harder ones first',
        'Stir-fry for 5-7 minutes until vegetables are tender-crisp',
        'Season with salt, pepper, and any available sauces',
        'Serve hot and enjoy your waste-reducing meal!'
      ],
    );
  }
  
  // Check if API key is configured
  static bool get isConfigured {
    return _apiKey.isNotEmpty && _apiKey != 'your-openai-api-key-here';
  }
  
  // Get demo recipes when API is not configured
  static List<Recipe> getDemoRecipes(List<String> ingredients) {
    print('getDemoRecipes called with: $ingredients');
    final ingredientText = ingredients.join(', ');
    
    final recipes = [
      Recipe.fromAI(
        name: 'Quick Veggie Scramble',
        ingredients: [
          ...ingredients,
          '2-3 eggs',
          '1 tablespoon oil',
          'Salt and pepper',
          'Optional: cheese'
        ],
        instructions: [
          'Heat oil in a pan over medium heat',
          'Add your vegetables and cook for 3-4 minutes',
          'Beat eggs and pour into the pan',
          'Scramble everything together until eggs are cooked',
          'Season with salt and pepper, add cheese if desired'
        ],
      ),
      Recipe.fromAI(
        name: 'Simple Soup',
        ingredients: [
          ...ingredients,
          '2 cups water or broth',
          '1 tablespoon oil',
          'Salt and herbs to taste'
        ],
        instructions: [
          'Heat oil in a pot over medium heat',
          'Add your ingredients and sauté for 2-3 minutes',
          'Add water or broth and bring to a boil',
          'Simmer for 15-20 minutes until vegetables are tender',
          'Season with salt and herbs before serving'
        ],
      ),
    ];
    
    print('Returning ${recipes.length} demo recipes');
    return recipes;
  }
}