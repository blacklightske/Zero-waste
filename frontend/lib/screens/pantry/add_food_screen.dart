import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/django_data_service.dart';
import '../../services/notification_service.dart';
import '../../models/food_item.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food Item'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_shopping_cart,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add New Food Item',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your food to reduce waste',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Food Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Food Name *',
                  hintText: 'e.g., Milk, Bread, Apples',
                  prefixIcon: const Icon(Icons.fastfood),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a food name';
                  }
                  if (value.trim().length < 2) {
                    return 'Food name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Quantity Field
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity *',
                  hintText: 'e.g., 1 bottle, 2 pieces, 500g',
                  prefixIcon: const Icon(Icons.scale),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Expiry Date Field
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry Date *',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedDate != null
                                  ? DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate!)
                                  : 'Select expiry date',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: _selectedDate != null ? Colors.black87 : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_selectedDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getExpiryStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getExpiryStatusColor().withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getExpiryStatusIcon(),
                        color: _getExpiryStatusColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getExpiryStatusText(),
                          style: TextStyle(
                            color: _getExpiryStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Quick Date Buttons
              Text(
                'Quick Select:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickDateChip('Tomorrow', 1),
                  _buildQuickDateChip('3 days', 3),
                  _buildQuickDateChip('1 week', 7),
                  _buildQuickDateChip('2 weeks', 14),
                  _buildQuickDateChip('1 month', 30),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Add Button
              ElevatedButton(
                onPressed: _isLoading ? null : _addFoodItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add Food Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Cancel Button
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickDateChip(String label, int days) {
    final date = DateTime.now().add(Duration(days: days));
    final isSelected = _selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDate = selected ? date : null;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
  
  Color _getExpiryStatusColor() {
    if (_selectedDate == null) return Colors.grey;
    
    final now = DateTime.now();
    final difference = _selectedDate!.difference(now).inDays;
    
    if (difference < 0) {
      return Colors.red;
    } else if (difference <= 2) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  IconData _getExpiryStatusIcon() {
    if (_selectedDate == null) return Icons.info_outline;
    
    final now = DateTime.now();
    final difference = _selectedDate!.difference(now).inDays;
    
    if (difference < 0) {
      return Icons.error_outline;
    } else if (difference <= 2) {
      return Icons.warning_amber_outlined;
    } else {
      return Icons.check_circle_outline;
    }
  }
  
  String _getExpiryStatusText() {
    if (_selectedDate == null) return '';
    
    final now = DateTime.now();
    final difference = _selectedDate!.difference(now).inDays;
    
    if (difference < 0) {
      return 'This date has already passed';
    } else if (difference == 0) {
      return 'Expires today';
    } else if (difference == 1) {
      return 'Expires tomorrow';
    } else if (difference <= 2) {
      return 'Expires in $difference days (soon!)';
    } else {
      return 'Expires in $difference days';
    }
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select expiry date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _addFoodItem() async {
    debugPrint('Starting _addFoodItem validation...');
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }
    
    if (_selectedDate == null) {
      debugPrint('No expiry date selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expiry date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    debugPrint('Form validation passed, starting to add food item...');
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataService = Provider.of<DjangoDataService>(context, listen: false);
      
      final foodItem = FoodItem(
        id: '', // Will be generated by Django
        name: _nameController.text.trim(),
        quantity: _quantityController.text.trim(),
        expiryDate: _selectedDate!,
        createdAt: DateTime.now(),
      );
      
      debugPrint('Created FoodItem: ${foodItem.toJson()}');
      debugPrint('Calling dataService.addFoodItem...');
      
      final success = await dataService.addFoodItem(foodItem);
      debugPrint('addFoodItem returned: $success');
      
      if (success && mounted) {
        debugPrint('Food item added successfully, scheduling notification...');
        // Schedule notification for this food item
        try {
          await NotificationService.scheduleFoodExpiryNotification(foodItem);
          debugPrint('Notification scheduled successfully');
        } catch (notificationError) {
          debugPrint('Failed to schedule notification: $notificationError');
          // Don't fail the whole operation if notification fails
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${foodItem.name}" added successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
        
        Navigator.of(context).pop();
      } else if (mounted) {
        debugPrint('Failed to add food item - success was false');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add food item. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Exception in _addFoodItem: $e');
      debugPrint('Exception type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('Exception details: ${e.toString()}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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