import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/marketplace_models.dart' as mp;
import 'django_auth_service.dart';

class MarketplaceService extends ChangeNotifier {
  final DjangoAuthService _authService;
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  List<mp.Category> _categories = [];
  List<mp.WasteProduct> _products = [];
  List<mp.Interest> _userInterests = [];
  List<mp.Message> _messages = [];
  List<mp.Review> _reviews = [];
  List<mp.Favorite> _favorites = [];
  mp.UserProfile? _userProfile;

  List<mp.Category> get categories => _categories;
  List<mp.WasteProduct> get products => _products;
  List<mp.Interest> get userInterests => _userInterests;
  List<mp.Message> get messages => _messages;
  List<mp.Review> get reviews => _reviews;
  List<mp.Favorite> get favorites => _favorites;
  mp.UserProfile? get userProfile => _userProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MarketplaceService(this._authService) : _dio = Dio() {
    final baseUrl = kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api';
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers['Content-Type'] = 'application/json';
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setLoading(false);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // CATEGORIES
  Future<void> loadCategories() async {
    try {
      _setLoading(true);
      final response = await _dio.get('/marketplace/categories/');
      final data = response.data;
      if (data['results'] != null) {
        _categories = (data['results'] as List)
            .map((json) => mp.Category.fromJson(json))
            .toList();
      } else {
        _categories = (data as List)
            .map((json) => mp.Category.fromJson(json))
            .toList();
      }
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load categories: $e');
    }
  }

  // PRODUCTS
  Future<void> loadProducts({String? category, String? search, String? location}) async {
    try {
      _setLoading(true);
      String url = '/marketplace/products/';
      List<String> params = [];
      
      if (category != null) params.add('category=$category');
      if (search != null) params.add('search=$search');
      if (location != null) params.add('location=$location');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await _dio.get(url);
      _products = (response.data['results'] as List)
          .map((json) => mp.WasteProduct.fromJson(json))
          .toList();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load products: $e');
    }
  }

  Future<mp.WasteProduct?> getProduct(String productId) async {
    try {
      final response = await _dio.get('/marketplace/products/$productId/');
      return mp.WasteProduct.fromJson(response.data);
    } catch (e) {
      _setError('Failed to get product: $e');
      return null;
    }
  }

  Future<String?> createProduct(mp.WasteProduct product) async {
    if (!_authService.isAuthenticated) return null;
    
    try {
      final response = await _dio.post('/marketplace/products/', data: product.toJson());
      final newProduct = mp.WasteProduct.fromJson(response.data);
      _products.insert(0, newProduct);
      notifyListeners();
      return newProduct.id;
    } catch (e) {
      _setError('Failed to create product: $e');
      return null;
    }
  }

  Future<bool> updateProduct(mp.WasteProduct product) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      final response = await _dio.put('/marketplace/products/${product.id}/', data: product.toJson());
      final updatedProduct = mp.WasteProduct.fromJson(response.data);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      await _dio.delete('/marketplace/products/$productId/');
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete product: $e');
      return false;
    }
  }

  Future<bool> toggleFavorite(String productId) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      final existingFavorite = _favorites.where((f) => f.productId == productId).firstOrNull;
      
      if (existingFavorite != null) {
        // Remove favorite
        await _dio.delete('/marketplace/favorites/${existingFavorite.id}/');
        _favorites.removeWhere((f) => f.productId == productId);
      } else {
        // Add favorite
        final response = await _dio.post('/marketplace/favorites/', data: {'product': productId});
        final newFavorite = mp.Favorite.fromJson(response.data);
        _favorites.add(newFavorite);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to toggle favorite: $e');
      return false;
    }
  }

  // INTERESTS
  Future<bool> expressInterest(String productId, String message, {double? offeredPrice}) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      final interestData = {
        'product': productId,
        'message': message,
        if (offeredPrice != null) 'offered_price': offeredPrice.toString(),
      };
      
      final response = await _dio.post('/marketplace/interests/', data: interestData);
      final newInterest = mp.Interest.fromJson(response.data);
      _userInterests.add(newInterest);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to express interest: $e');
      return false;
    }
  }

  Future<void> loadUserInterests() async {
    if (!_authService.isAuthenticated) return;
    
    try {
      final response = await _dio.get('/marketplace/interests/');
      _userInterests = (response.data['results'] as List)
          .map((json) => mp.Interest.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load interests: $e');
    }
  }

  Future<bool> updateInterestStatus(String interestId, String status) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      await _dio.post('/marketplace/interests/$interestId/$status/');
      final index = _userInterests.indexWhere((i) => i.id == interestId);
      if (index != -1) {
        // Reload interests to get updated data
        await loadUserInterests();
      }
      return true;
    } catch (e) {
      _setError('Failed to update interest status: $e');
      return false;
    }
  }

  // MESSAGES
  Future<void> loadMessages(String interestId) async {
    if (!_authService.isAuthenticated) return;
    
    try {
      final response = await _dio.get('/marketplace/messages/?interest=$interestId');
      _messages = (response.data['results'] as List)
          .map((json) => mp.Message.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load messages: $e');
    }
  }

  Future<bool> sendMessage(String interestId, String content) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      final messageData = {
        'interest': interestId,
        'content': content,
      };
      
      final response = await _dio.post('/marketplace/messages/', data: messageData);
      final newMessage = mp.Message.fromJson(response.data);
      _messages.add(newMessage);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to send message: $e');
      return false;
    }
  }

  // USER PROFILE
  Future<void> loadUserProfile() async {
    if (!_authService.isAuthenticated) return;
    
    try {
      final response = await _dio.get('/marketplace/profiles/me/');
      _userProfile = mp.UserProfile.fromJson(response.data);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load profile: $e');
    }
  }

  Future<bool> updateUserProfile(mp.UserProfile profile) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      final response = await _dio.put('/marketplace/profiles/me/', data: profile.toJson());
      _userProfile = mp.UserProfile.fromJson(response.data);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    }
  }

  // REVIEWS
  Future<bool> addReview(String reviewedUserId, String productId, int rating, String comment) async {
    if (!_authService.isAuthenticated) return false;
    
    try {
      final reviewData = {
        'reviewed_user': reviewedUserId,
        'product': productId,
        'rating': rating,
        'comment': comment,
      };
      
      final response = await _dio.post('/marketplace/reviews/', data: reviewData);
      final newReview = mp.Review.fromJson(response.data);
      _reviews.add(newReview);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add review: $e');
      return false;
    }
  }

  Future<void> loadUserReviews() async {
    if (!_authService.isAuthenticated) return;
    
    try {
      final response = await _dio.get('/marketplace/reviews/');
      _reviews = (response.data['results'] as List)
          .map((json) => mp.Review.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load reviews: $e');
    }
  }

  // FAVORITES
  Future<void> loadFavorites() async {
    if (!_authService.isAuthenticated) return;
    
    try {
      final response = await _dio.get('/marketplace/favorites/');
      _favorites = (response.data['results'] as List)
          .map((json) => mp.Favorite.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load favorites: $e');
    }
  }

  // SEARCH AND FILTER
  Future<List<mp.WasteProduct>> searchProducts(String query) async {
    try {
      final response = await _dio.get('/marketplace/products/?search=$query');
      return (response.data['results'] as List)
          .map((json) => mp.WasteProduct.fromJson(json))
          .toList();
    } catch (e) {
      _setError('Failed to search products: $e');
      return [];
    }
  }

  Future<List<mp.WasteProduct>> getNearbyProducts(double latitude, double longitude, double radius) async {
    try {
      final response = await _dio.get('/marketplace/products/nearby/?lat=$latitude&lng=$longitude&radius=$radius');
      return (response.data['results'] as List)
          .map((json) => mp.WasteProduct.fromJson(json))
          .toList();
    } catch (e) {
      _setError('Failed to get nearby products: $e');
      return [];
    }
  }

  // UTILITY METHODS
  bool isFavorite(String productId) {
    return _favorites.any((f) => f.productId == productId);
  }

  List<mp.WasteProduct> get userProducts {
    return _products.where((p) => p.sellerId == _authService.userId).toList();
  }

  List<mp.WasteProduct> getProductsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  // Load all marketplace data
  Future<void> loadAllData() async {
    if (!_authService.isAuthenticated) return;
    
    await Future.wait([
      loadCategories(),
      loadProducts(),
      loadUserProfile(),
      loadUserInterests(),
      loadFavorites(),
    ]);
  }
}

// Helper extension
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
