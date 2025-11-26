import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/marketplace_models.dart';
import '../../services/marketplace_service.dart';
import '../../services/django_auth_service.dart';
import 'express_interest_screen.dart';
import 'chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  WasteProduct? product;
  bool isLoading = true;
  int currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final marketplaceService = context.read<MarketplaceService>();
    final loadedProduct = await marketplaceService.getProduct(widget.productId);
    
    setState(() {
      product = loadedProduct;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product!.title),
        actions: [
          Consumer<MarketplaceService>(
            builder: (context, marketplaceService, child) {
              return IconButton(
                icon: Icon(
                  marketplaceService.isFavorite(product!.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: marketplaceService.isFavorite(product!.id)
                      ? Colors.red
                      : null,
                ),
                onPressed: () {
                  marketplaceService.toggleFavorite(product!.id);
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(),
            const SizedBox(height: 8),
            _buildProductInfo(),
            const SizedBox(height: 8),
            _buildSellerInfo(),
            const SizedBox(height: 16),
            _buildSustainabilityInfo(),
            const SizedBox(height: 8),
            _buildLocationInfo(),
            const SizedBox(height: 8),
            _buildDeliveryInfo(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildImageCarousel() {
    if (product!.images.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.eco, size: 80, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: product!.images.length,
        onPageChanged: (index) => setState(() => currentImageIndex = index),
        itemBuilder: (context, index) {
          return Image.network(
            product!.images[index].bestImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.eco, size: 80, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product!.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            product!.displayPrice,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: product!.isFree ? Colors.green : Colors.blue[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${product!.quantity} ${product!.unit} • ${product!.conditionDisplay}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product!.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green,
            child: Text(
              product!.sellerName?.substring(0, 1).toUpperCase() ?? 'S',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product!.sellerName ?? 'Seller',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (product!.sellerRating != null) ...[
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        product!.sellerRating!.toStringAsFixed(1),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Navigate to seller profile
            },
            child: const Text('View Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilityInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text(
                'Environmental Impact',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildImpactItem(
                  'Weight',
                  '${product!.estimatedWeight.toStringAsFixed(1)} kg',
                ),
              ),
              Expanded(
                child: _buildImpactItem(
                  'CO₂ Saved',
                  '${product!.carbonFootprintSaved.toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return ListTile(
      leading: const Icon(Icons.location_on),
      title: const Text('Location'),
      subtitle: Text(product!.location),
      trailing: TextButton(
        onPressed: () {
          // TODO: Open map
        },
        child: const Text('View Map'),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Availability',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (product!.pickupAvailable) ...[
                Icon(Icons.local_shipping, color: Colors.green[600]),
                const SizedBox(width: 4),
                const Text('Pickup available'),
                const SizedBox(width: 16),
              ],
              if (product!.deliveryAvailable) ...[
                Icon(Icons.delivery_dining, color: Colors.green[600]),
                const SizedBox(width: 4),
                Text('Delivery within ${product!.deliveryRadius} km'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    switch (product!.status) {
      case 'available':
        chipColor = Colors.green;
        break;
      case 'reserved':
        chipColor = Colors.orange;
        break;
      case 'sold':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        product!.statusDisplay,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildBottomActions() {
    final authService = context.read<DjangoAuthService>();
    final isOwner = product!.sellerId == authService.userId;
    
    if (isOwner) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Edit product
                },
                child: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: View interests/messages
                },
                child: const Text('View Interests'),
              ),
            ),
          ],
        ),
      );
    }

    if (product!.status != 'available') {
      return Container(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: null,
            child: Text('${product!.statusDisplay} - Unavailable'),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to chat if interest exists
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(productId: product!.id),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Message'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpressInterestScreen(product: product!),
                  ),
                );
              },
              icon: const Icon(Icons.handshake),
              label: const Text('Express Interest'),
            ),
          ),
        ],
      ),
    );
  }
}
