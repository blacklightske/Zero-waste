from django_filters import rest_framework as filters
from .models import FoodItem

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