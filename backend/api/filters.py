from django_filters import rest_framework as filters
from django.db.models import Q
from django.utils import timezone
from datetime import date, timedelta
from decimal import Decimal
from .models import FoodItem, WasteProduct


class FoodItemFilter(filters.FilterSet):
    is_expired = filters.BooleanFilter(method='filter_is_expired')
    is_expiring_soon = filters.BooleanFilter(method='filter_is_expiring_soon')

    class Meta:
        model = FoodItem
        fields = ['is_expired', 'is_expiring_soon']

    def filter_is_expired(self, queryset, name, value):
        return queryset.filter(expiry_date__lt=date.today()) if value else queryset

    def filter_is_expiring_soon(self, queryset, name, value):
        return queryset.filter(expiry_date__gte=date.today(), expiry_date__lte=date.today() + timedelta(days=3)) if value else queryset


class WasteProductFilter(filters.FilterSet):
    # Basic filters
    category = filters.CharFilter(field_name='category__name', lookup_expr='icontains')
    category_id = filters.NumberFilter(field_name='category__id')
    condition = filters.ChoiceFilter(choices=WasteProduct.CONDITION_CHOICES)
    status = filters.ChoiceFilter(choices=WasteProduct.STATUS_CHOICES)
    
    # Price filters
    price_min = filters.NumberFilter(field_name='price', lookup_expr='gte')
    price_max = filters.NumberFilter(field_name='price', lookup_expr='lte')
    price_range = filters.RangeFilter(field_name='price')
    is_free = filters.BooleanFilter()
    
    # Location filters
    location = filters.CharFilter(lookup_expr='icontains')
    has_coordinates = filters.BooleanFilter(method='filter_has_coordinates')
    
    # Availability filters
    pickup_available = filters.BooleanFilter()
    delivery_available = filters.BooleanFilter()
    available_now = filters.BooleanFilter(method='filter_available_now')
    
    # Date filters
    created_after = filters.DateTimeFilter(field_name='created_at', lookup_expr='gte')
    created_before = filters.DateTimeFilter(field_name='created_at', lookup_expr='lte')
    available_until_after = filters.DateTimeFilter(field_name='available_until', lookup_expr='gte')
    
    # Seller filters
    seller_verified = filters.BooleanFilter(method='filter_seller_verified')
    seller_rating_min = filters.NumberFilter(method='filter_seller_rating_min')
    
    # Weight and sustainability
    weight_min = filters.NumberFilter(field_name='estimated_weight', lookup_expr='gte')
    weight_max = filters.NumberFilter(field_name='estimated_weight', lookup_expr='lte')
    
    class Meta:
        model = WasteProduct
        fields = [
            'category', 'category_id', 'condition', 'status', 'is_free',
            'pickup_available', 'delivery_available', 'location'
        ]
    
    def filter_has_coordinates(self, queryset, name, value):
        if value:
            return queryset.filter(latitude__isnull=False, longitude__isnull=False)
        else:
            return queryset.filter(Q(latitude__isnull=True) | Q(longitude__isnull=True))
    
    def filter_available_now(self, queryset, name, value):
        if value:
            return queryset.filter(
                status='available',
                available_from__lte=timezone.now()
            ).filter(
                Q(available_until__isnull=True) | Q(available_until__gte=timezone.now())
            )
        return queryset
    
    def filter_seller_verified(self, queryset, name, value):
        if value:
            return queryset.filter(seller__profile__is_verified=True)
        return queryset
    
    def filter_seller_rating_min(self, queryset, name, value):
        return queryset.filter(seller__profile__average_rating__gte=value)