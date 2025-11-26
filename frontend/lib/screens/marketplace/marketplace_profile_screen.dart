import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/marketplace_service.dart';
import '../../services/django_auth_service.dart';
import '../../models/marketplace_models.dart';
import 'product_card.dart';
import 'product_detail_screen.dart';

class MarketplaceProfileScreen extends StatefulWidget {
  final String? userId; // If null, shows current user's profile

  const MarketplaceProfileScreen({
    super.key,
    this.userId,
  });

  @override
  State<MarketplaceProfileScreen> createState() => _MarketplaceProfileScreenState();
}

class _MarketplaceProfileScreenState extends State<MarketplaceProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserProfile? _userProfile;
  List<WasteProduct> _userProducts = [];
  List<Review> _userReviews = [];
  bool _isLoading = true;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkIfCurrentUser();
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkIfCurrentUser() {
    final authService = context.read<DjangoAuthService>();
    _isCurrentUser = widget.userId == null || widget.userId == authService.userId;
  }

  Future<void> _loadProfileData() async {
    final marketplaceService = context.read<MarketplaceService>();
    
    try {
      if (_isCurrentUser) {
        // Load current user's profile
        await marketplaceService.loadUserProfile();
        _userProfile = marketplaceService.userProfile;
        
        // Load user's products
        await marketplaceService.loadProducts();
        _userProducts = marketplaceService.userProducts;
        
        // Load user's reviews
        await marketplaceService.loadUserReviews();
        _userReviews = marketplaceService.reviews;
      } else {
        // TODO: Load other user's profile by ID
        // This would require additional API endpoints
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text('Profile not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCurrentUser ? 'My Profile' : _userProfile!.userName),
        centerTitle: true,
        actions: [
          if (_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editProfile,
            ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildProfileHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildStatsSection(),
            ),
            SliverToBoxAdapter(
              child: _buildSustainabilityImpact(),
            ),
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              toolbarHeight: 0,
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Listings'),
                  Tab(text: 'Reviews'),
                  Tab(text: 'Activity'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildListingsTab(),
            _buildReviewsTab(),
            _buildActivityTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[400]!,
            Colors.green[600]!,
          ],
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: _userProfile!.avatarCloudinaryUrl != null
                    ? NetworkImage(_userProfile!.avatarCloudinaryUrl!)
                    : _userProfile!.avatarUrl != null
                        ? NetworkImage(_userProfile!.avatarUrl!)
                        : null,
                child: (_userProfile!.avatarCloudinaryUrl == null && _userProfile!.avatarUrl == null)
                    ? Text(
                        _userProfile!.userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      )
                    : null,
              ),
              if (_userProfile!.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile!.userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_userProfile!.bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _userProfile!.bio,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_userProfile!.averageRating > 0) ...[
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[300], size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _userProfile!.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' (${_userProfile!.totalReviews} reviews)',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  'No reviews yet',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Member since ${DateFormat('MMM yyyy').format(_userProfile!.createdAt)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Transactions',
              _userProfile!.totalTransactions.toString(),
              Icons.handshake,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Items Sold',
              '${(_userProfile!.totalWasteSold).toStringAsFixed(1)} kg',
              Icons.trending_up,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Items Bought',
              '${(_userProfile!.totalWasteBought).toStringAsFixed(1)} kg',
              Icons.shopping_cart,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilityImpact() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: Colors.green[600], size: 28),
              const SizedBox(width: 12),
              Text(
                'Environmental Impact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildImpactItem(
                  'CO₂ Saved',
                  '${_userProfile!.carbonFootprintSaved.toStringAsFixed(1)} kg',
                  Icons.cloud_off,
                ),
              ),
              Expanded(
                child: _buildImpactItem(
                  'Waste Diverted',
                  '${(_userProfile!.totalWasteSold + _userProfile!.totalWasteBought).toStringAsFixed(1)} kg',
                  Icons.recycling,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your contributions are making a positive impact on the environment!',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[600], size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildListingsTab() {
    if (_userProducts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        title: _isCurrentUser ? 'No listings yet' : 'No listings',
        subtitle: _isCurrentUser 
            ? 'Start selling your green waste!'
            : 'This user hasn\'t listed any products yet.',
        actionText: _isCurrentUser ? 'Add Product' : null,
        onAction: _isCurrentUser ? () => Navigator.of(context).pop() : null,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _userProducts.length,
      itemBuilder: (context, index) {
        final product = _userProducts[index];
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

  Widget _buildReviewsTab() {
    if (_userReviews.isEmpty) {
      return _buildEmptyState(
        icon: Icons.rate_review_outlined,
        title: 'No reviews yet',
        subtitle: _isCurrentUser 
            ? 'Complete transactions to receive reviews'
            : 'This user hasn\'t received any reviews yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userReviews.length,
      itemBuilder: (context, index) {
        final review = _userReviews[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        (review.reviewerName ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.reviewerName ?? 'Anonymous',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              ...List.generate(5, (starIndex) => Icon(
                                starIndex < review.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              )),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMM dd, yyyy').format(review.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(review.comment),
                ],
                if (review.productTitle != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Product: ${review.productTitle}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityTab() {
    return _buildEmptyState(
      icon: Icons.timeline,
      title: 'Activity Timeline',
      subtitle: 'Recent marketplace activity will appear here',
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
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
      ),
    );
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _EditProfileSheet(userProfile: _userProfile!),
    ).then((updated) {
      if (updated == true) {
        _loadProfileData();
      }
    });
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserProfile userProfile;

  const _EditProfileSheet({required this.userProfile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bioController.text = widget.userProfile.bio;
    _phoneController.text = widget.userProfile.phone;
    _addressController.text = widget.userProfile.address;
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell others about yourself...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                hintText: '+1 (555) 123-4567',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Your general location',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final marketplaceService = context.read<MarketplaceService>();
      
      final updatedProfile = UserProfile(
        id: widget.userProfile.id,
        userEmail: widget.userProfile.userEmail,
        userName: widget.userProfile.userName,
        bio: _bioController.text.trim(),
        avatarUrl: widget.userProfile.avatarUrl,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        isVerified: widget.userProfile.isVerified,
        totalWasteSold: widget.userProfile.totalWasteSold,
        totalWasteBought: widget.userProfile.totalWasteBought,
        carbonFootprintSaved: widget.userProfile.carbonFootprintSaved,
        totalTransactions: widget.userProfile.totalTransactions,
        averageRating: widget.userProfile.averageRating,
        totalReviews: widget.userProfile.totalReviews,
        createdAt: widget.userProfile.createdAt,
        updatedAt: DateTime.now(),
      );

      final success = await marketplaceService.updateUserProfile(updatedProfile);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
}
