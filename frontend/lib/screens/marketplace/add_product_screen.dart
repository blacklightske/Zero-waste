import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/marketplace_service.dart';
import '../../services/django_auth_service.dart';
import '../../services/location_service.dart';
import '../../services/image_upload_service.dart';
import '../../models/marketplace_models.dart';
import '../../widgets/image_upload_widget.dart';
import '../../widgets/location_picker_widget.dart';

class AddProductScreen extends StatefulWidget {
  final WasteProduct? product; // For editing existing products

  const AddProductScreen({
    super.key,
    this.product,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _weightController = TextEditingController();
  final _deliveryRadiusController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedUnit = 'kg';
  String _selectedCondition = 'excellent';
  bool _isFree = false;
  bool _pickupAvailable = true;
  bool _deliveryAvailable = false;
  DateTime? _availableFrom;
  DateTime? _availableUntil;
  bool _isLoading = false;
  List<File> _images = [];
  LocationData? _selectedLocation;

  final List<String> _units = ['kg', 'g', 'pieces', 'liters', 'ml', 'cups', 'bags'];
  final List<String> _conditions = ['excellent', 'good', 'fair', 'poor'];

  @override
  void initState() {
    super.initState();
    _availableFrom = DateTime.now();
    _loadCategories();
    
    if (widget.product != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final product = widget.product!;
    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _quantityController.text = product.quantity;
    _locationController.text = product.location;
    _weightController.text = product.estimatedWeight.toString();
    _deliveryRadiusController.text = product.deliveryRadius?.toString() ?? '';
    
    _selectedCategoryId = product.categoryId;
    _selectedUnit = product.unit;
    _selectedCondition = product.condition;
    _isFree = product.isFree;
    _pickupAvailable = product.pickupAvailable;
    _deliveryAvailable = product.deliveryAvailable;
    _availableFrom = product.availableFrom;
    _availableUntil = product.availableUntil;
  }

  Future<void> _loadCategories() async {
    final marketplaceService = context.read<MarketplaceService>();
    if (marketplaceService.categories.isEmpty) {
      await marketplaceService.loadCategories();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _weightController.dispose();
    _deliveryRadiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildPriceSection(),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 24),
              _buildQuantitySection(),
              const SizedBox(height: 24),
              _buildLocationSection(),
              const SizedBox(height: 24),
              _buildAvailabilitySection(),
              const SizedBox(height: 24),
              _buildDeliverySection(),
              const SizedBox(height: 24),
              _buildImageSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 16),
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            widget.product != null ? Icons.edit : Icons.add_business,
            size: 48,
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          Text(
            widget.product != null ? 'Edit Your Product' : 'List Your Green Waste',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Help reduce waste by sharing with your community',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Product Title *',
            hintText: 'e.g., Fresh Vegetables, Organic Compost',
            prefixIcon: const Icon(Icons.title),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a product title';
            }
            if (value.trim().length < 3) {
              return 'Title must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description *',
            hintText: 'Describe your product, its condition, and benefits',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            if (value.trim().length < 10) {
              return 'Description must be at least 10 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Free Item'),
          subtitle: const Text('Mark this as a free giveaway'),
          value: _isFree,
          onChanged: (value) {
            setState(() {
              _isFree = value;
              if (value) {
                _priceController.text = '0';
              }
            });
          },
          activeColor: Colors.green,
        ),
        if (!_isFree) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'Price (\$)',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (!_isFree && (value == null || value.trim().isEmpty)) {
                return 'Please enter a price';
              }
              if (!_isFree && double.tryParse(value!) == null) {
                return 'Please enter a valid price';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySection() {
    return Consumer<MarketplaceService>(
      builder: (context, marketplaceService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'Select Category *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: marketplaceService.categories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: InputDecoration(
                labelText: 'Condition *',
                prefixIcon: const Icon(Icons.stars),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _conditions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition.substring(0, 1).toUpperCase() + condition.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value!;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity & Weight',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity *',
                  hintText: '1',
                  prefixIcon: const Icon(Icons.scale),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter quantity';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _units.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _weightController,
          decoration: InputDecoration(
            labelText: 'Estimated Weight (kg) *',
            hintText: 'e.g., 2.5',
            prefixIcon: const Icon(Icons.fitness_center),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter estimated weight';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid weight';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LocationPickerWidget(
          initialLocation: _selectedLocation,
          onLocationChanged: (location) {
            setState(() {
              _selectedLocation = location;
              if (location != null) {
                _locationController.text = location.address;
              } else {
                _locationController.clear();
              }
            });
          },
          label: 'Product Location',
          hint: 'Enter or select product location',
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _selectDate(isStartDate: true),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available From *',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _availableFrom != null
                            ? DateFormat('EEEE, MMM dd, yyyy').format(_availableFrom!)
                            : 'Select start date',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _selectDate(isStartDate: false),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(Icons.event_busy, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Until (Optional)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _availableUntil != null
                            ? DateFormat('EEEE, MMM dd, yyyy').format(_availableUntil!)
                            : 'No end date (until sold)',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _availableUntil != null ? Colors.black87 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_availableUntil != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _availableUntil = null),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Options',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Pickup Available'),
          subtitle: const Text('Buyers can collect from your location'),
          value: _pickupAvailable,
          onChanged: (value) {
            setState(() {
              _pickupAvailable = value;
            });
          },
          activeColor: Colors.green,
        ),
        SwitchListTile(
          title: const Text('Delivery Available'),
          subtitle: const Text('You can deliver to buyers'),
          value: _deliveryAvailable,
          onChanged: (value) {
            setState(() {
              _deliveryAvailable = value;
            });
          },
          activeColor: Colors.green,
        ),
        if (_deliveryAvailable) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _deliveryRadiusController,
            decoration: InputDecoration(
              labelText: 'Delivery Radius (km)',
              hintText: 'e.g., 10',
              prefixIcon: const Icon(Icons.local_shipping),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_deliveryAvailable && (value == null || value.trim().isEmpty)) {
                return 'Please enter delivery radius';
              }
              if (_deliveryAvailable && int.tryParse(value!) == null) {
                return 'Please enter a valid radius';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ImageUploadWidget(
          initialImages: _images,
          onImagesChanged: (images) {
            setState(() {
              _images = images;
            });
          },
          maxImages: 5,
          emptyText: 'Add Product Photos',
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitProduct,
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
          : Text(
              widget.product != null ? 'Update Product' : 'List Product',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
      child: const Text('Cancel'),
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_availableFrom ?? DateTime.now())
          : (_availableUntil ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: isStartDate ? DateTime.now() : (_availableFrom ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: isStartDate ? 'Select start date' : 'Select end date',
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _availableFrom = picked;
          // Reset end date if it's before start date
          if (_availableUntil != null && _availableUntil!.isBefore(picked)) {
            _availableUntil = null;
          }
        } else {
          _availableUntil = picked;
        }
      });
    }
  }



  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_availableFrom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an availability start date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedLocation == null && _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final marketplaceService = context.read<MarketplaceService>();
      final authService = context.read<DjangoAuthService>();

      // First, create or update the product
      final product = WasteProduct(
        id: widget.product?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId!,
        price: _isFree ? 0.0 : double.parse(_priceController.text),
        isFree: _isFree,
        quantity: _quantityController.text.trim(),
        unit: _selectedUnit,
        condition: _selectedCondition,
        status: 'available',
        location: _selectedLocation?.address ?? _locationController.text.trim(),
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
        availableFrom: _availableFrom!,
        availableUntil: _availableUntil,
        pickupAvailable: _pickupAvailable,
        deliveryAvailable: _deliveryAvailable,
        deliveryRadius: _deliveryAvailable ? int.tryParse(_deliveryRadiusController.text) : null,
        estimatedWeight: double.parse(_weightController.text),
        carbonFootprintSaved: double.parse(_weightController.text) * 2.5, // Estimate
        sellerId: authService.userId ?? '',
        images: [],
        isAvailable: true,
        isExpired: false,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      String? productId;
      
      if (widget.product != null) {
        success = await marketplaceService.updateProduct(product);
        productId = success ? widget.product!.id : null;
      } else {
        productId = await marketplaceService.createProduct(product);
        success = productId != null;
      }

      // Upload images if any were selected and product creation/update was successful
      if (success && _images.isNotEmpty && productId != null && productId.isNotEmpty) {
        final uploadedImages = await ImageUploadService.uploadProductImages(productId, _images);
        if (uploadedImages.isNotEmpty) {
          debugPrint('Successfully uploaded ${uploadedImages.length} images for product $productId');
          // Log Cloudinary URLs for debugging
          for (var image in uploadedImages) {
            debugPrint('Image ID: ${image['id']}, URL: ${image['cloudinary_url']}');
          }
        }
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product != null
                ? 'Product updated successfully!'
                : 'Product listed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product != null
                ? 'Failed to update product'
                : 'Failed to list product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
