import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/marketplace_service.dart';
import '../../models/marketplace_models.dart' as mp;
import '../../widgets/app_shimmer.dart';
import 'product_card.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';
import 'search_products_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final marketplaceService = context.read<MarketplaceService>();
    await marketplaceService.loadCategories();
    await marketplaceService.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Green Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchProductsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.storefront), text: 'Browse'),
            Tab(icon: Icon(Icons.inventory), text: 'My Listings'),
            Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(),
          _buildMyListingsTab(),
          _buildFavoritesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBrowseTab() {
    return Consumer<MarketplaceService>(
      builder: (context, marketplaceService, child) {
        if (marketplaceService.isLoading && marketplaceService.products.isEmpty) {
          return _buildLoadingState();
        }

        return RefreshIndicator(
          onRefresh: () => marketplaceService.loadProducts(),
          child: Column(
            children: [
              if (marketplaceService.categories.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: _buildCategoriesRow(marketplaceService.categories),
                ),
              Expanded(
                child: _buildProductGrid(marketplaceService.products),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyListingsTab() {
    return Consumer<MarketplaceService>(
      builder: (context, marketplaceService, child) {
        final userProducts = marketplaceService.userProducts;
        
        if (userProducts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inventory,
            title: 'No listings yet',
            subtitle: 'Start selling your green waste!',
            actionText: 'Add Product',
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProductScreen()),
              );
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () => marketplaceService.loadProducts(),
          child: _buildProductGrid(userProducts),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return Consumer<MarketplaceService>(
      builder: (context, marketplaceService, child) {
        final favorites = marketplaceService.favorites;
        
        if (favorites.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'No favorites yet',
            subtitle: 'Save products you\'re interested in',
          );
        }

        return RefreshIndicator(
          onRefresh: () => marketplaceService.loadFavorites(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return Card(
                child: ListTile(
                  title: Text(favorite.productTitle ?? 'Product'),
                  subtitle: Text(favorite.productPrice != null 
                      ? '\$${favorite.productPrice!.toStringAsFixed(2)}'
                      : 'Free'),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      marketplaceService.toggleFavorite(favorite.productId);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(productId: favorite.productId),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoriesRow(List<mp.Category> categories) {
    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category.id;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = isSelected ? null : category.id;
              });
              _filterByCategory();
            },
            child: Container(
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.grey[200],
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCategoryIcon(category.icon),
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<mp.WasteProduct> products) {
    if (products.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shopping_basket_outlined,
        title: 'No products found',
        subtitle: 'Try adjusting your search or filters',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
          ],
        ],
      ),
    );
  }

  void _filterByCategory() {
    final marketplaceService = context.read<MarketplaceService>();
    marketplaceService.loadProducts(category: _selectedCategory);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Free items only'),
              value: false,
              onChanged: (value) {
                // TODO: Implement filter logic
              },
            ),
            CheckboxListTile(
              title: const Text('Pickup available'),
              value: false,
              onChanged: (value) {
                // TODO: Implement filter logic
              },
            ),
            CheckboxListTile(
              title: const Text('Delivery available'),
              value: false,
              onChanged: (value) {
                // TODO: Implement filter logic
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Apply filters
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
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
}
