from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    FoodItem, Recipe, Todo, WasteProduct, Category, ProductImage, 
    Interest, Message, Review, UserProfile, Favorite, Report
)

User = get_user_model()


class FoodItemSerializer(serializers.ModelSerializer):
    expiry_date = serializers.DateField(input_formats=['%Y-%m-%dT%H:%M:%S.%fZ', '%Y-%m-%d'])
    is_expired = serializers.ReadOnlyField()
    is_expiring_soon = serializers.ReadOnlyField()
    days_until_expiry = serializers.ReadOnlyField()
    
    class Meta:
        model = FoodItem
        fields = [
            'id', 'name', 'quantity', 'expiry_date', 'created_at', 'updated_at',
            'is_expired', 'is_expiring_soon', 'days_until_expiry'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class RecipeSerializer(serializers.ModelSerializer):
    total_time = serializers.ReadOnlyField()
    estimated_time = serializers.ReadOnlyField()
    
    class Meta:
        model = Recipe
        fields = [
            'id', 'name', 'description', 'ingredients', 'instructions',
            'prep_time', 'cook_time', 'servings', 'difficulty', 'tags',
            'image_url', 'is_custom', 'is_saved', 'created_at', 'updated_at',
            'total_time', 'estimated_time'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
    
    def validate_ingredients(self, value):
        if not isinstance(value, list):
            raise serializers.ValidationError("Ingredients must be a list")
        if not value:
            raise serializers.ValidationError("At least one ingredient is required")
        return value
    
    def validate_instructions(self, value):
        if not isinstance(value, list):
            raise serializers.ValidationError("Instructions must be a list")
        if not value:
            raise serializers.ValidationError("At least one instruction is required")
        return value


class TodoSerializer(serializers.ModelSerializer):
    is_overdue = serializers.ReadOnlyField()
    is_due_today = serializers.ReadOnlyField()
    
    class Meta:
        model = Todo
        fields = [
            'id', 'title', 'description', 'is_completed', 'priority',
            'due_date', 'completed_at', 'created_at', 'updated_at',
            'is_overdue', 'is_due_today'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'completed_at']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class TodoToggleSerializer(serializers.Serializer):
    """Serializer for toggling todo completion status"""
    pass


# Summary serializers for dashboard/overview
class FoodItemSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodItem
        fields = ['id', 'name', 'expiry_date', 'is_expired', 'is_expiring_soon']


class RecipeSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Recipe
        fields = ['id', 'name', 'difficulty', 'estimated_time', 'is_custom']


class TodoSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Todo
        fields = ['id', 'title', 'is_completed', 'priority', 'is_overdue', 'is_due_today']


# Marketplace Serializers

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'description', 'icon', 'created_at']
        read_only_fields = ['id', 'created_at']


class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['id', 'image', 'cloudinary_url', 'is_primary', 'uploaded_at']
        read_only_fields = ['id', 'uploaded_at']


class UserProfileSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_name = serializers.CharField(source='user.full_name', read_only=True)
    
    class Meta:
        model = UserProfile
        fields = [
            'id', 'user_email', 'user_name', 'bio', 'avatar', 'avatar_cloudinary_url',
            'phone', 'address', 'is_verified', 'verification_document', 'verification_cloudinary_url',
            'total_waste_sold', 'total_waste_bought', 'carbon_footprint_saved', 
            'total_transactions', 'average_rating', 'total_reviews', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'user_email', 'user_name', 'is_verified', 'total_waste_sold', 
            'total_waste_bought', 'carbon_footprint_saved', 'total_transactions',
            'average_rating', 'total_reviews', 'created_at', 'updated_at'
        ]


class WasteProductSerializer(serializers.ModelSerializer):
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    seller_rating = serializers.FloatField(source='seller.profile.average_rating', read_only=True)
    images = ProductImageSerializer(many=True, read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    is_available = serializers.ReadOnlyField()
    is_expired = serializers.ReadOnlyField()
    
    class Meta:
        model = WasteProduct
        fields = [
            'id', 'title', 'description', 'category', 'category_name', 'price', 
            'is_free', 'quantity', 'unit', 'condition', 'status', 'location',
            'latitude', 'longitude', 'available_from', 'available_until',
            'pickup_available', 'delivery_available', 'delivery_radius',
            'estimated_weight', 'carbon_footprint_saved', 'seller', 'seller_name',
            'seller_rating', 'images', 'is_available', 'is_expired',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'seller', 'seller_name', 'seller_rating', 'category_name',
            'images', 'is_available', 'is_expired', 'created_at', 'updated_at'
        ]
    
    def create(self, validated_data):
        validated_data['seller'] = self.context['request'].user
        return super().create(validated_data)


class WasteProductListSerializer(serializers.ModelSerializer):
    seller_name = serializers.CharField(source='seller.full_name', read_only=True)
    seller_rating = serializers.FloatField(source='seller.profile.average_rating', read_only=True)
    primary_image = serializers.SerializerMethodField()
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = WasteProduct
        fields = [
            'id', 'title', 'price', 'is_free', 'quantity', 'unit', 'condition',
            'status', 'location', 'seller_name', 'seller_rating', 'primary_image',
            'category_name', 'estimated_weight', 'created_at'
        ]
    
    def get_primary_image(self, obj):
        primary_image = obj.images.filter(is_primary=True).first()
        if primary_image:
            return primary_image.image.url
        elif obj.images.exists():
            return obj.images.first().image.url
        return None


class InterestSerializer(serializers.ModelSerializer):
    buyer_name = serializers.CharField(source='buyer.full_name', read_only=True)
    buyer_rating = serializers.FloatField(source='buyer.profile.average_rating', read_only=True)
    product_title = serializers.CharField(source='product.title', read_only=True)
    
    class Meta:
        model = Interest
        fields = [
            'id', 'product', 'product_title', 'buyer', 'buyer_name', 'buyer_rating',
            'message', 'offered_price', 'status', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'buyer', 'buyer_name', 'buyer_rating', 'product_title',
            'created_at', 'updated_at'
        ]
    
    def create(self, validated_data):
        validated_data['buyer'] = self.context['request'].user
        return super().create(validated_data)


class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source='sender.full_name', read_only=True)
    
    class Meta:
        model = Message
        fields = [
            'id', 'interest', 'sender', 'sender_name', 'content', 'is_read', 'created_at'
        ]
        read_only_fields = ['id', 'sender', 'sender_name', 'created_at']
    
    def create(self, validated_data):
        validated_data['sender'] = self.context['request'].user
        return super().create(validated_data)


class ReviewSerializer(serializers.ModelSerializer):
    reviewer_name = serializers.CharField(source='reviewer.full_name', read_only=True)
    reviewed_user_name = serializers.CharField(source='reviewed_user.full_name', read_only=True)
    product_title = serializers.CharField(source='product.title', read_only=True)
    
    class Meta:
        model = Review
        fields = [
            'id', 'reviewer', 'reviewer_name', 'reviewed_user', 'reviewed_user_name',
            'product', 'product_title', 'rating', 'comment', 'created_at'
        ]
        read_only_fields = [
            'id', 'reviewer', 'reviewer_name', 'reviewed_user_name', 
            'product_title', 'created_at'
        ]
    
    def create(self, validated_data):
        validated_data['reviewer'] = self.context['request'].user
        return super().create(validated_data)


class FavoriteSerializer(serializers.ModelSerializer):
    product_title = serializers.CharField(source='product.title', read_only=True)
    product_price = serializers.DecimalField(source='product.price', max_digits=10, decimal_places=2, read_only=True)
    
    class Meta:
        model = Favorite
        fields = [
            'id', 'product', 'product_title', 'product_price', 'created_at'
        ]
        read_only_fields = ['id', 'product_title', 'product_price', 'created_at']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class ReportSerializer(serializers.ModelSerializer):
    reporter_name = serializers.CharField(source='reporter.full_name', read_only=True)
    
    class Meta:
        model = Report
        fields = [
            'id', 'reporter', 'reporter_name', 'product', 'reported_user',
            'reason', 'description', 'is_resolved', 'created_at'
        ]
        read_only_fields = ['id', 'reporter', 'reporter_name', 'created_at']
    
    def create(self, validated_data):
        validated_data['reporter'] = self.context['request'].user
        return super().create(validated_data)