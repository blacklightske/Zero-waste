import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/marketplace_service.dart';
import '../../services/location_service.dart';
import '../../models/marketplace_models.dart';
import '../../widgets/app_shimmer.dart';
import 'product_card.dart';
import 'product_detail_screen.dart';

class SearchProductsScreen extends StatefulWidget {
  const SearchProductsScreen({super.key});

  @override
  State<SearchProductsScreen> createState() => _SearchProductsScreenState();
}

class _SearchProductsScreenState extends State<SearchProductsScreen> {
  final _searchController = TextEditingController();
  final _locationController = TextEditingController();
  
  List<WasteProduct> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  
  // Filters
  String? _selectedCategory;
  double? _maxPrice;
  bool _freeItemsOnly = false;
  bool _pickupAvailable = false;
  bool _deliveryAvailable = false;
  String _sortBy = 'newest';
  LocationData? _userLocation;

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFiltersDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onSubmitted: (_) => _performSearch(),
            textInputAction: TextInputAction.search,
          ),
          
          const SizedBox(height: 12),
          
          // Location and search button row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Location (optional)',
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: _getCurrentLocation,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSearching ? null : _performSearch,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Search'),
              ),
            ],
          ),
          
          // Active filters
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 12),
            _buildActiveFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    List<Widget> filterChips = [];

    if (_selectedCategory != null) {
      filterChips.add(_buildFilterChip(
        'Category: ${_getCategoryName(_selectedCategory!)}',
        () => setState(() => _selectedCategory = null),
      ));
    }

    if (_maxPrice != null) {
      filterChips.add(_buildFilterChip(
        'Max: \$${_maxPrice!.toStringAsFixed(0)}',
        () => setState(() => _maxPrice = null),
      ));
    }

    if (_freeItemsOnly) {
      filterChips.add(_buildFilterChip(
        'Free only',
        () => setState(() => _freeItemsOnly = false),
      ));
    }

    if (_pickupAvailable) {
      filterChips.add(_buildFilterChip(
        'Pickup',
        () => setState(() => _pickupAvailable = false),
      ));
    }

    if (_deliveryAvailable) {
      filterChips.add(_buildFilterChip(
        'Delivery',
        () => setState(() => _deliveryAvailable = false),
      ));
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filterChips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => filterChips[index],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Colors.blue[50],
      deleteIconColor: Colors.blue[600],
      side: BorderSide(color: Colors.blue[200]!),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return _buildSearchSuggestions();
    }

    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildResultsHeader(),
        Expanded(child: _buildResultsGrid()),
      ],
    );
  }

  Widget _buildSearchSuggestions() {
    return Consumer<MarketplaceService>(
      builder: (context, marketplaceService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.search,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Search for green waste products',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find food waste, compost, and other sustainable products in your area',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Popular searches:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSuggestionChip('Compost'),
                  _buildSuggestionChip('Vegetables'),
                  _buildSuggestionChip('Fruits'),
                  _buildSuggestionChip('Garden waste'),
                  _buildSuggestionChip('Kitchen scraps'),
                  _buildSuggestionChip('Free items'),
                ],
              ),
              const SizedBox(height: 24),
              if (marketplaceService.categories.isNotEmpty) ...[
                Text(
                  'Browse by category:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: marketplaceService.categories.length,
                  itemBuilder: (context, index) {
                    final category = marketplaceService.categories[index];
                    return _buildCategoryCard(category);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _searchController.text = text;
        _performSearch();
      },
      backgroundColor: Colors.green[50],
      side: BorderSide(color: Colors.green[200]!),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category.id;
          });
          _performSearch();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category.icon),
                color: Colors.green[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: AppShimmer.buildProductCardShimmer,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clearSearch,
              child: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_searchResults.length} ${_searchResults.length == 1 ? 'result' : 'results'} found',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DropdownButton<String>(
            value: _sortBy,
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
              _sortResults();
            },
            items: const [
              DropdownMenuItem(value: 'newest', child: Text('Newest')),
              DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
              DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
              DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
              DropdownMenuItem(value: 'distance', child: Text('Distance')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return ProductCard(
          product: product,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(productId: product.id),
              ),
            );
          },
        );
      },
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null ||
        _maxPrice != null ||
        _freeItemsOnly ||
        _pickupAvailable ||
        _deliveryAvailable;
  }

  String _getCategoryName(String categoryId) {
    final marketplaceService = context.read<MarketplaceService>();
    final category = marketplaceService.categories
        .where((c) => c.id == categoryId)
        .firstOrNull;
    return category?.name ?? 'Unknown';
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'fa-apple-alt': return Icons.apple;
      case 'fa-seedling': return Icons.grass;
      case 'fa-tractor': return Icons.agriculture;
      case 'fa-utensils': return Icons.restaurant;
      case 'fa-recycle': return Icons.recycling;
      case 'fa-tree': return Icons.park;
      case 'fa-newspaper': return Icons.article;
      case 'fa-paw': return Icons.pets;
      default: return Icons.category;
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty && !_hasActiveFilters()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a search term or apply filters'),
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final marketplaceService = context.read<MarketplaceService>();
      
      // Build search parameters
      final searchParams = <String, String>{};
      
      if (query.isNotEmpty) {
        searchParams['search'] = query;
      }
      
      if (_selectedCategory != null) {
        searchParams['category'] = _selectedCategory!;
      }
      
      if (_locationController.text.isNotEmpty) {
        searchParams['location'] = _locationController.text.trim();
      }

      // Perform the search
      await marketplaceService.loadProducts(
        category: _selectedCategory,
        search: query.isNotEmpty ? query : null,
        location: _locationController.text.isNotEmpty ? _locationController.text.trim() : null,
      );

      // Apply additional filters
      _searchResults = marketplaceService.products.where((product) {
        // Price filters
        if (_freeItemsOnly && !product.isFree) return false;
        if (_maxPrice != null && product.price > _maxPrice!) return false;
        
        // Delivery filters
        if (_pickupAvailable && !product.pickupAvailable) return false;
        if (_deliveryAvailable && !product.deliveryAvailable) return false;
        
        return true;
      }).toList();

      _sortResults();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _sortResults() {
    switch (_sortBy) {
      case 'newest':
        _searchResults.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        _searchResults.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'price_low':
        _searchResults.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        _searchResults.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'distance':
        if (_userLocation != null) {
          _searchResults.sort((a, b) {
            final distanceA = _calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              a.latitude ?? 0,
              a.longitude ?? 0,
            );
            final distanceB = _calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              b.latitude ?? 0,
              b.longitude ?? 0,
            );
            return distanceA.compareTo(distanceB);
          });
        }
        break;
    }
    setState(() {});
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _locationController.clear();
      _searchResults.clear();
      _hasSearched = false;
      _selectedCategory = null;
      _maxPrice = null;
      _freeItemsOnly = false;
      _pickupAvailable = false;
      _deliveryAvailable = false;
      _sortBy = 'newest';
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await LocationService.getLocationWithPermission(context);
      if (locationData != null) {
        setState(() {
          _userLocation = locationData;
          _locationController.text = locationData.address;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedCategory = null;
                          _maxPrice = null;
                          _freeItemsOnly = false;
                          _pickupAvailable = false;
                          _deliveryAvailable = false;
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Category filter
                Consumer<MarketplaceService>(
                  builder: (context, marketplaceService, child) {
                    return DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All categories'),
                        ),
                        ...marketplaceService.categories.map((category) =>
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          _selectedCategory = value;
                        });
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Price filter
                Text(
                  'Maximum Price: ${_maxPrice?.toStringAsFixed(0) ?? 'No limit'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: _maxPrice ?? 100,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: _maxPrice?.toStringAsFixed(0) ?? 'No limit',
                  onChanged: (value) {
                    setModalState(() {
                      _maxPrice = value == 100 ? null : value;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Checkboxes
                CheckboxListTile(
                  title: const Text('Free items only'),
                  value: _freeItemsOnly,
                  onChanged: (value) {
                    setModalState(() {
                      _freeItemsOnly = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Pickup available'),
                  value: _pickupAvailable,
                  onChanged: (value) {
                    setModalState(() {
                      _pickupAvailable = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Delivery available'),
                  value: _deliveryAvailable,
                  onChanged: (value) {
                    setModalState(() {
                      _deliveryAvailable = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 24),
                
                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {}); // Update main state
                      if (_hasSearched) {
                        _performSearch();
                      }
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Helper extension
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
