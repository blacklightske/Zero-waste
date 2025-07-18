import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/django_data_service.dart';
import '../../models/food_item.dart';
import '../../utils/animations.dart';
import 'add_food_screen.dart';
import 'edit_food_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String _searchQuery = '';
  String _sortBy = 'expiry'; // 'expiry', 'name', 'date_added'
  bool _showExpiredOnly = false;
  bool _showExpiringSoonOnly = false;

  @override
  void initState() {
    super.initState();
    // Data is already loaded by home_screen.dart, no need to load again
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pantry'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddFoodScreen(),
                ),
              );
            },
          ),
        ],
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
                hintText: 'Search food items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          
          // Filter chips
          if (_showExpiredOnly || _showExpiringSoonOnly)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_showExpiredOnly)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Expired'),
                        selected: true,
                        onSelected: (selected) {
                          setState(() {
                            _showExpiredOnly = false;
                          });
                        },
                        backgroundColor: Colors.red.withOpacity(0.1),
                        selectedColor: Colors.red.withOpacity(0.2),
                      ),
                    ),
                  if (_showExpiringSoonOnly)
                    FilterChip(
                      label: const Text('Expiring Soon'),
                      selected: true,
                      onSelected: (selected) {
                        setState(() {
                          _showExpiringSoonOnly = false;
                        });
                      },
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      selectedColor: Colors.orange.withOpacity(0.2),
                    ),
                ],
              ),
            ),
          
          // Food items list
          Expanded(
            child: Consumer<DjangoDataService>(
              builder: (context, dataService, _) {
                if (dataService.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                final filteredItems = _getFilteredItems(dataService.foodItems);
                
                if (filteredItems.isEmpty) {
                  return _buildEmptyState();
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await dataService.loadUserData();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return AppAnimations.staggeredListItem(
                        index: index,
                        child: _buildFoodItemCard(context, item, dataService),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AppAnimations.scaleIn(
        child: FloatingActionButton(
          heroTag: "pantry_fab",
          onPressed: () {
            Navigator.of(context).push(
              SlidePageRoute(
                page: const AddFoodScreen(),
                direction: SlideDirection.up,
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
  
  List<FoodItem> _getFilteredItems(List<FoodItem> items) {
    List<FoodItem> filtered = items;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(_searchQuery) ||
               item.quantity.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    // Apply status filters
    if (_showExpiredOnly) {
      filtered = filtered.where((item) => item.isExpired).toList();
    } else if (_showExpiringSoonOnly) {
      filtered = filtered.where((item) => item.expiresSoon).toList();
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'expiry':
        filtered.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'date_added':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    
    return filtered;
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _showExpiredOnly || _showExpiringSoonOnly
                  ? 'No items found'
                  : 'Your pantry is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _showExpiredOnly || _showExpiringSoonOnly
                  ? 'Try adjusting your search or filters'
                  : 'Add your first food item to start tracking',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty && !_showExpiredOnly && !_showExpiringSoonOnly)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddFoodScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Food Item'),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFoodItemCard(BuildContext context, FoodItem item, DjangoDataService dataService) {
    final isExpired = item.isExpired;
    final expiresSoon = item.expiresSoon;
    
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.withOpacity(0.2);
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle_outline;
    String statusText = 'Fresh';
    
    if (isExpired) {
      cardColor = Colors.red.withOpacity(0.05);
      borderColor = Colors.red.withOpacity(0.3);
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = 'Expired';
    } else if (expiresSoon) {
      cardColor = Colors.orange.withOpacity(0.05);
      borderColor = Colors.orange.withOpacity(0.3);
      statusColor = Colors.orange;
      statusIcon = Icons.warning_outlined;
      statusText = 'Expires Soon';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
        ),
        title: Text(
          item.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: isExpired ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Quantity: ${item.quantity}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              'Expires: ${DateFormat('MMM dd, yyyy').format(item.expiryDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  statusIcon,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isExpired)
                  Text(
                    ' • ${item.daysUntilExpiry} days left',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditFoodScreen(foodItem: item),
                  ),
                );
                break;
              case 'delete':
                _showDeleteConfirmation(context, item, dataService);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter & Sort'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort by:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                RadioListTile<String>(
                  title: const Text('Expiry Date'),
                  value: 'expiry',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setDialogState(() {
                      _sortBy = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Name'),
                  value: 'name',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setDialogState(() {
                      _sortBy = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Date Added'),
                  value: 'date_added',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setDialogState(() {
                      _sortBy = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filter by:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                CheckboxListTile(
                  title: const Text('Show expired only'),
                  value: _showExpiredOnly,
                  onChanged: (value) {
                    setDialogState(() {
                      _showExpiredOnly = value!;
                      if (value) _showExpiringSoonOnly = false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Show expiring soon only'),
                  value: _showExpiringSoonOnly,
                  onChanged: (value) {
                    setDialogState(() {
                      _showExpiringSoonOnly = value!;
                      if (value) _showExpiredOnly = false;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _sortBy = 'expiry';
                _showExpiredOnly = false;
                _showExpiringSoonOnly = false;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, FoodItem item, DjangoDataService dataService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Food Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await dataService.deleteFoodItem(item.id);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Food item deleted successfully'
                          : 'Failed to delete food item',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}