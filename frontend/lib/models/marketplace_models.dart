// Marketplace Models for ZeroWaste App

class Category {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
    };
  }
}

class WasteProduct {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String? categoryName;
  final double price;
  final bool isFree;
  final String quantity;
  final String unit;
  final String condition;
  final String status;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime availableFrom;
  final DateTime? availableUntil;
  final bool pickupAvailable;
  final bool deliveryAvailable;
  final int? deliveryRadius;
  final double estimatedWeight;
  final double carbonFootprintSaved;
  final String sellerId;
  final String? sellerName;
  final double? sellerRating;
  final List<ProductImage> images;
  final bool isAvailable;
  final bool isExpired;
  final DateTime createdAt;
  final DateTime updatedAt;

  WasteProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    this.categoryName,
    required this.price,
    required this.isFree,
    required this.quantity,
    required this.unit,
    required this.condition,
    required this.status,
    required this.location,
    this.latitude,
    this.longitude,
    required this.availableFrom,
    this.availableUntil,
    required this.pickupAvailable,
    required this.deliveryAvailable,
    this.deliveryRadius,
    required this.estimatedWeight,
    required this.carbonFootprintSaved,
    required this.sellerId,
    this.sellerName,
    this.sellerRating,
    required this.images,
    required this.isAvailable,
    required this.isExpired,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WasteProduct.fromJson(Map<String, dynamic> json) {
    return WasteProduct(
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'],
      categoryId: json['category'].toString(),
      categoryName: json['category_name'],
      price: double.parse(json['price'].toString()),
      isFree: json['is_free'],
      quantity: json['quantity'],
      unit: json['unit'],
      condition: json['condition'],
      status: json['status'],
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      availableFrom: DateTime.parse(json['available_from']),
      availableUntil: json['available_until'] != null 
          ? DateTime.parse(json['available_until'])
          : null,
      pickupAvailable: json['pickup_available'],
      deliveryAvailable: json['delivery_available'],
      deliveryRadius: json['delivery_radius'],
      estimatedWeight: double.parse(json['estimated_weight'].toString()),
      carbonFootprintSaved: double.parse(json['carbon_footprint_saved'].toString()),
      sellerId: json['seller'].toString(),
      sellerName: json['seller_name'],
      sellerRating: json['seller_rating']?.toDouble(),
      images: (json['images'] as List?)
          ?.map((img) => ProductImage.fromJson(img))
          .toList() ?? [],
      isAvailable: json['is_available'],
      isExpired: json['is_expired'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': categoryId,
      'price': price.toString(),
      'is_free': isFree,
      'quantity': quantity,
      'unit': unit,
      'condition': condition,
      'status': status,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'available_from': availableFrom.toIso8601String(),
      'available_until': availableUntil?.toIso8601String(),
      'pickup_available': pickupAvailable,
      'delivery_available': deliveryAvailable,
      'delivery_radius': deliveryRadius,
      'estimated_weight': estimatedWeight,
      'carbon_footprint_saved': carbonFootprintSaved,
    };
  }

  String? get primaryImageUrl {
    final primaryImage = images.where((img) => img.isPrimary).firstOrNull;
    return primaryImage?.bestImageUrl ?? images.firstOrNull?.bestImageUrl;
  }

  String get displayPrice {
    if (isFree) return 'Free';
    return '\$${price.toStringAsFixed(2)}';
  }

  String get conditionDisplay {
    switch (condition) {
      case 'excellent': return 'Excellent';
      case 'good': return 'Good';
      case 'fair': return 'Fair';
      case 'poor': return 'Poor';
      default: return condition;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'available': return 'Available';
      case 'reserved': return 'Reserved';
      case 'sold': return 'Sold';
      case 'expired': return 'Expired';
      default: return status;
    }
  }
}

class ProductImage {
  final String id;
  final String imageUrl;
  final String? cloudinaryUrl;
  final bool isPrimary;
  final DateTime uploadedAt;

  ProductImage({
    required this.id,
    required this.imageUrl,
    this.cloudinaryUrl,
    required this.isPrimary,
    required this.uploadedAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'].toString(),
      imageUrl: json['image'],
      cloudinaryUrl: json['cloudinary_url'],
      isPrimary: json['is_primary'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  // Get the best available image URL (prefer Cloudinary URL if available)
  String get bestImageUrl => cloudinaryUrl ?? imageUrl;
}

class Interest {
  final String id;
  final String productId;
  final String? productTitle;
  final String buyerId;
  final String? buyerName;
  final double? buyerRating;
  final String message;
  final double? offeredPrice;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Interest({
    required this.id,
    required this.productId,
    this.productTitle,
    required this.buyerId,
    this.buyerName,
    this.buyerRating,
    required this.message,
    this.offeredPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'].toString(),
      productId: json['product'].toString(),
      productTitle: json['product_title'],
      buyerId: json['buyer'].toString(),
      buyerName: json['buyer_name'],
      buyerRating: json['buyer_rating']?.toDouble(),
      message: json['message'] ?? '',
      offeredPrice: json['offered_price']?.toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      'message': message,
      'offered_price': offeredPrice?.toString(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'pending': return 'Pending';
      case 'accepted': return 'Accepted';
      case 'declined': return 'Declined';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }
}

class Message {
  final String id;
  final String interestId;
  final String senderId;
  final String? senderName;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.interestId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      interestId: json['interest'].toString(),
      senderId: json['sender'].toString(),
      senderName: json['sender_name'],
      content: json['content'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interest': interestId,
      'content': content,
    };
  }
}

class Review {
  final String id;
  final String reviewerId;
  final String? reviewerName;
  final String reviewedUserId;
  final String? reviewedUserName;
  final String productId;
  final String? productTitle;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.reviewerId,
    this.reviewerName,
    required this.reviewedUserId,
    this.reviewedUserName,
    required this.productId,
    this.productTitle,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'].toString(),
      reviewerId: json['reviewer'].toString(),
      reviewerName: json['reviewer_name'],
      reviewedUserId: json['reviewed_user'].toString(),
      reviewedUserName: json['reviewed_user_name'],
      productId: json['product'].toString(),
      productTitle: json['product_title'],
      rating: json['rating'],
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewed_user': reviewedUserId,
      'product': productId,
      'rating': rating,
      'comment': comment,
    };
  }
}

class UserProfile {
  final String id;
  final String userEmail;
  final String userName;
  final String bio;
  final String? avatarUrl;
  final String? avatarCloudinaryUrl;
  final String phone;
  final String address;
  final bool isVerified;
  final String? verificationDocumentUrl;
  final String? verificationCloudinaryUrl;
  final double totalWasteSold;
  final double totalWasteBought;
  final double carbonFootprintSaved;
  final int totalTransactions;
  final double averageRating;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userEmail,
    required this.userName,
    required this.bio,
    this.avatarUrl,
    this.avatarCloudinaryUrl,
    required this.phone,
    required this.address,
    required this.isVerified,
    this.verificationDocumentUrl,
    this.verificationCloudinaryUrl,
    required this.totalWasteSold,
    required this.totalWasteBought,
    required this.carbonFootprintSaved,
    required this.totalTransactions,
    required this.averageRating,
    required this.totalReviews,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      userEmail: json['user_email'],
      userName: json['user_name'],
      bio: json['bio'] ?? '',
      avatarUrl: json['avatar'],
      avatarCloudinaryUrl: json['avatar_cloudinary_url'],
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      isVerified: json['is_verified'],
      verificationDocumentUrl: json['verification_document'],
      verificationCloudinaryUrl: json['verification_cloudinary_url'],
      totalWasteSold: double.parse(json['total_waste_sold'].toString()),
      totalWasteBought: double.parse(json['total_waste_bought'].toString()),
      carbonFootprintSaved: double.parse(json['carbon_footprint_saved'].toString()),
      totalTransactions: json['total_transactions'],
      averageRating: double.parse(json['average_rating'].toString()),
      totalReviews: json['total_reviews'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'phone': phone,
      'address': address,
    };
  }
}

class Favorite {
  final String id;
  final String productId;
  final String? productTitle;
  final double? productPrice;
  final DateTime createdAt;

  Favorite({
    required this.id,
    required this.productId,
    this.productTitle,
    this.productPrice,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'].toString(),
      productId: json['product'].toString(),
      productTitle: json['product_title'],
      productPrice: json['product_price']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
    };
  }
}

// Helper extension
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
