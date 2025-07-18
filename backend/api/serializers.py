from rest_framework import serializers
from .models import FoodItem, Recipe, Todo


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