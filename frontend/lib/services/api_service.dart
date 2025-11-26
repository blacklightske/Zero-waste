import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/food_item.dart';
import '../models/recipe.dart';
import '../models/todo.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    } else {
      return 'http://10.0.2.2:8000/api'; // Android emulator
    }
  }
  
  static const _storage = FlutterSecureStorage();
  
  late final Dio _dio;
  
  ApiService() {
    debugPrint('ApiService initialized with baseUrl: $baseUrl');
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add interceptor for authentication and debugging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('API Request: ${options.method} ${options.uri}');
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('API Response: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) async {
        debugPrint('API Error: ${error.response?.statusCode} ${error.requestOptions.uri}');
        debugPrint('Error details: ${error.response?.data}');
        
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await refreshToken();
          if (refreshed) {
            // Retry the original request
            final token = await _storage.read(key: 'auth_token');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } else {
            // Token refresh failed, clear storage
            await _storage.delete(key: 'auth_token');
            await _storage.delete(key: 'refresh_token');
            await _storage.delete(key: 'user_id');
          }
        }
        handler.next(error);
      },
    ));
  }
  
  // Get Dio options with auth token
  BaseOptions getDioOptions() {
    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }
  
  // Refresh token method
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;
      
      final response = await Dio().post(
        '$baseUrl/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );
      
      if (response.statusCode == 200) {
        await _storage.write(key: 'auth_token', value: response.data['access']);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }
  
  // Note: The private _refreshToken method was removed to avoid duplication
  // as it's now replaced by the public refreshToken() method above
  
  // User authentication methods are defined below


  
  // Authentication methods
  Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _dio.post('/auth/register/', data: {
        'email': email,
        'password': password,
        'name': name,
      });
      
      if (response.statusCode == 201) {
        final data = response.data;
        await _storage.write(key: 'auth_token', value: data['access']);
        await _storage.write(key: 'refresh_token', value: data['refresh']);
        await _storage.write(key: 'user_id', value: data['user']['id'].toString());
        return data;
      }
    } on DioException catch (e) {
      debugPrint('Sign up error: ${e.response?.data}');
      throw _handleError(e);
    }
    return null;
  }
  
  Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login/', data: {
        'email': email,
        'password': password,
      });
      
      if (response.statusCode == 200) {
        final data = response.data;
        await _storage.write(key: 'auth_token', value: data['access']);
        await _storage.write(key: 'refresh_token', value: data['refresh']);
        await _storage.write(key: 'user_id', value: data['user']['id'].toString());
        return data;
      }
    } on DioException catch (e) {
      debugPrint('Sign in error: ${e.response?.data}');
      throw _handleError(e);
    }
    return null;
  }
  
  Future<void> signOut() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        await _dio.post('/auth/logout/', data: {'refresh': refreshToken});
      }
    } catch (e) {
      debugPrint('Sign out error: $e');
    } finally {
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'user_id');
    }
  }
  
  Future<bool> resetPassword({required String email}) async {
    try {
      final response = await _dio.post('/auth/reset-password/', data: {
        'email': email,
      });
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('Reset password error: ${e.response?.data}');
      throw _handleError(e);
    }
  }
  
  // Food Items methods
  Future<List<FoodItem>> getFoodItems() async {
    try {
      final response = await _dio.get('/food-items/');
      final responseData = response.data;
      
      debugPrint('getFoodItems response type: ${responseData.runtimeType}');
      debugPrint('getFoodItems response data: $responseData');
      
      // Handle paginated response
      final List<dynamic> data = responseData is List 
          ? responseData 
          : responseData['results'] ?? [];
      
      debugPrint('getFoodItems extracted data: $data');
      return data.map((item) => FoodItem.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<FoodItem> createFoodItem(FoodItem foodItem) async {
    try {
      final response = await _dio.post('/food-items/', data: foodItem.toJson());
      return FoodItem.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<FoodItem> updateFoodItem(FoodItem foodItem) async {
    try {
      final response = await _dio.put('/food-items/${foodItem.id}/', data: foodItem.toJson());
      return FoodItem.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> deleteFoodItem(String id) async {
    try {
      await _dio.delete('/food-items/$id/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Recipes methods
  Future<List<Recipe>> getRecipes() async {
    try {
      final response = await _dio.get('/recipes/');
      final responseData = response.data;
      
      debugPrint('getRecipes response type: ${responseData.runtimeType}');
      debugPrint('getRecipes response data: $responseData');
      
      // Handle paginated response
      final List<dynamic> data = responseData is List 
          ? responseData 
          : responseData['results'] ?? [];
      
      debugPrint('getRecipes extracted data: $data');
      return data.map((recipe) => Recipe.fromJson(recipe)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Recipe> createRecipe(Recipe recipe) async {
    try {
      final response = await _dio.post('/recipes/', data: recipe.toJson());
      return Recipe.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Recipe> updateRecipe(Recipe recipe) async {
    try {
      final response = await _dio.put('/recipes/${recipe.id}/', data: recipe.toJson());
      return Recipe.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> deleteRecipe(String id) async {
    try {
      await _dio.delete('/recipes/$id/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Todos methods
  Future<List<Todo>> getTodos() async {
    try {
      final response = await _dio.get('/todos/');
      final responseData = response.data;
      
      debugPrint('getTodos response type: ${responseData.runtimeType}');
      debugPrint('getTodos response data: $responseData');
      
      // Handle paginated response
      final List<dynamic> data = responseData is List 
          ? responseData 
          : responseData['results'] ?? [];
      
      debugPrint('getTodos extracted data: $data');
      return data.map((todo) => Todo.fromJson(todo)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Todo> createTodo(Todo todo) async {
    try {
      final response = await _dio.post('/todos/', data: todo.toJson());
      return Todo.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Todo> updateTodo(Todo todo) async {
    try {
      final response = await _dio.put('/todos/${todo.id}/', data: todo.toJson());
      return Todo.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> deleteTodo(String id) async {
    try {
      await _dio.delete('/todos/$id/');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Utility methods
  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }
  
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null;
  }

  // Generic HTTP methods for marketplace and other services
  Future<dynamic> get(String path) async {
    try {
      final response = await _dio.get(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String path, dynamic data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String path, dynamic data) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Token refresh method is already defined above
  
  String _handleError(DioException e) {
    debugPrint('Handling DioException: ${e.type}, Message: ${e.message}');
    
    if (e.response != null) {
      final data = e.response!.data;
      debugPrint('Response data: $data');
      
      if (data is Map<String, dynamic>) {
        if (data.containsKey('detail')) {
          return data['detail'];
        }
        if (data.containsKey('error')) {
          return data['error'];
        }
        // Handle field-specific errors
        final errors = <String>[];
        data.forEach((key, value) {
          if (value is List) {
            errors.addAll(value.cast<String>());
          } else if (value is String) {
            errors.add(value);
          }
        });
        if (errors.isNotEmpty) {
          return errors.join(', ');
        }
      }
      return 'Server error: ${e.response!.statusCode}';
    }
    
    // Enhanced error handling for mobile connectivity issues
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection and ensure the server is running.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server response timeout. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      if (kIsWeb) {
        return 'Connection error. Please check your internet connection.';
      } else {
        return 'Cannot connect to server. Please ensure:\n1. Your device is connected to the internet\n2. The Django server is running\n3. You are using the correct IP address';
      }
    }
    if (e.type == DioExceptionType.unknown) {
      return 'Network error. Please check your connection and try again.';
    }
    
    return 'An unexpected error occurred: ${e.message ?? "Unknown error"}';
  }
}