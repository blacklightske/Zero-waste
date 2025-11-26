import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_upload_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final List<File> initialImages;
  final Function(List<File>) onImagesChanged;
  final int maxImages;
  final String emptyText;

  const ImageUploadWidget({
    super.key,
    required this.initialImages,
    required this.onImagesChanged,
    this.maxImages = 5,
    this.emptyText = 'Add Photos',
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  List<File> _images = [];

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isEmpty) _buildEmptyState() else _buildImageGrid(),
        if (_images.length < widget.maxImages) _buildAddButton(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: _pickImages,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              widget.emptyText,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to add up to ${widget.maxImages} photos',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _images[index],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                if (index == 0)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Primary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: _pickImages,
        icon: const Icon(Icons.add_photo_alternate),
        label: Text(
          _images.isEmpty
              ? 'Add Photos'
              : 'Add More (${_images.length}/${widget.maxImages})',
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final List<File>? newImages = await ImageUploadService.showMultipleImagePicker(
      context,
      maxImages: widget.maxImages - _images.length,
    );

    if (newImages != null && newImages.isNotEmpty) {
      setState(() {
        _images.addAll(newImages);
        if (_images.length > widget.maxImages) {
          _images = _images.take(widget.maxImages).toList();
        }
      });
      widget.onImagesChanged(_images);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onImagesChanged(_images);
  }
}

class SingleImageUploadWidget extends StatefulWidget {
  final File? initialImage;
  final Function(File?) onImageChanged;
  final String emptyText;
  final double height;
  final double width;

  const SingleImageUploadWidget({
    super.key,
    this.initialImage,
    required this.onImageChanged,
    this.emptyText = 'Add Photo',
    this.height = 200,
    this.width = double.infinity,
  });

  @override
  State<SingleImageUploadWidget> createState() => _SingleImageUploadWidgetState();
}

class _SingleImageUploadWidgetState extends State<SingleImageUploadWidget> {
  File? _image;

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _image == null ? _buildEmptyState() : _buildImageDisplay(),
    );
  }

  Widget _buildEmptyState() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            widget.emptyText,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _image!,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final File? newImage = await ImageUploadService.showImageSourceDialog(context);
    if (newImage != null) {
      setState(() {
        _image = newImage;
      });
      widget.onImageChanged(_image);
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
    widget.onImageChanged(null);
  }
}
