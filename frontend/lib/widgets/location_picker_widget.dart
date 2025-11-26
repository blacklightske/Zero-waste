import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationPickerWidget extends StatefulWidget {
  final LocationData? initialLocation;
  final Function(LocationData?) onLocationChanged;
  final String label;
  final String hint;

  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    required this.onLocationChanged,
    this.label = 'Location',
    this.hint = 'Enter or select location',
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final TextEditingController _controller = TextEditingController();
  LocationData? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _controller.text = widget.initialLocation!.address;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Use current location',
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchLocation,
                    tooltip: 'Search location',
                  ),
                ],
              ],
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a location';
            }
            return null;
          },
          onChanged: (value) {
            if (value.isEmpty) {
              _selectedLocation = null;
              widget.onLocationChanged(null);
            }
          },
        ),
        if (_selectedLocation != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _selectedLocation!.address,
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                        'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: _clearLocation,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final locationData = await LocationService.getLocationWithPermission(context);
      if (locationData != null) {
        setState(() {
          _selectedLocation = locationData;
          _controller.text = locationData.address;
        });
        widget.onLocationChanged(locationData);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchLocation() async {
    final String query = _controller.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a location to search'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final locations = await LocationService.searchPlaces(query);
      if (locations.isNotEmpty) {
        if (locations.length == 1) {
          // If only one result, use it directly
          _selectLocation(locations.first);
        } else {
          // Show selection dialog
          _showLocationSelectionDialog(locations);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No locations found for this search'),
            ),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLocationSelectionDialog(List<LocationData> locations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(location.address),
                subtitle: Text(
                  'Lat: ${location.latitude.toStringAsFixed(4)}, '
                  'Lng: ${location.longitude.toStringAsFixed(4)}',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _selectLocation(location);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _selectLocation(LocationData location) {
    setState(() {
      _selectedLocation = location;
      _controller.text = location.address;
    });
    widget.onLocationChanged(location);
  }

  void _clearLocation() {
    setState(() {
      _selectedLocation = null;
      _controller.clear();
    });
    widget.onLocationChanged(null);
  }
}

class SimpleLocationPicker extends StatefulWidget {
  final String? initialAddress;
  final Function(String) onAddressChanged;
  final String label;
  final String hint;

  const SimpleLocationPicker({
    super.key,
    this.initialAddress,
    required this.onAddressChanged,
    this.label = 'Location',
    this.hint = 'Enter your location',
  });

  @override
  State<SimpleLocationPicker> createState() => _SimpleLocationPickerState();
}

class _SimpleLocationPickerState extends State<SimpleLocationPicker> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _controller.text = widget.initialAddress!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: IconButton(
          icon: const Icon(Icons.my_location),
          onPressed: _getCurrentLocation,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a location';
        }
        return null;
      },
      onChanged: widget.onAddressChanged,
    );
  }

  Future<void> _getCurrentLocation() async {
    final locationData = await LocationService.getLocationWithPermission(context);
    if (locationData != null) {
      setState(() {
        _controller.text = locationData.address;
      });
      widget.onAddressChanged(locationData.address);
    }
  }
}
