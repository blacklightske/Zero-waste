from django.contrib import admin
from .models import (
    FoodItem, Recipe, Todo, Category, WasteProduct, ProductImage,
    Interest, Message, Review, UserProfile, Favorite, Report
)


@admin.register(FoodItem)
class FoodItemAdmin(admin.ModelAdmin):
    list_display = ['name', 'user', 'quantity', 'expiry_date', 'is_expired', 'is_expiring_soon', 'created_at']
    list_filter = ['expiry_date', 'created_at', 'user']
    search_fields = ['name', 'user__email']
    ordering = ['expiry_date']
    readonly_fields = ['created_at', 'updated_at']
    
    def is_expired(self, obj):
        return obj.is_expired
    is_expired.boolean = True
    is_expired.short_description = 'Expired'
    
    def is_expiring_soon(self, obj):
        return obj.is_expiring_soon
    is_expiring_soon.boolean = True
    is_expiring_soon.short_description = 'Expiring Soon'


@admin.register(Recipe)
class RecipeAdmin(admin.ModelAdmin):
    list_display = ['name', 'user', 'difficulty', 'total_time', 'is_custom', 'is_saved', 'created_at']
    list_filter = ['difficulty', 'is_custom', 'is_saved', 'created_at', 'user']
    search_fields = ['name', 'description', 'user__email']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at']
    
    def total_time(self, obj):
        return f"{obj.total_time} min"
    total_time.short_description = 'Total Time'


@admin.register(Todo)
class TodoAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'is_completed', 'priority', 'due_date', 'is_overdue', 'created_at']
    list_filter = ['is_completed', 'priority', 'due_date', 'created_at', 'user']
    search_fields = ['title', 'description', 'user__email']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at', 'completed_at']
    
    def is_overdue(self, obj):
        return obj.is_overdue
    is_overdue.boolean = True
    is_overdue.short_description = 'Overdue'
    
    actions = ['mark_completed', 'mark_incomplete']
    
    def mark_completed(self, request, queryset):
        for todo in queryset:
            if not todo.is_completed:
                todo.toggle_completion()
        self.message_user(request, f"{queryset.count()} todos marked as completed.")
    mark_completed.short_description = "Mark selected todos as completed"
    
    def mark_incomplete(self, request, queryset):
        for todo in queryset:
            if todo.is_completed:
                todo.toggle_completion()
        self.message_user(request, f"{queryset.count()} todos marked as incomplete.")
    mark_incomplete.short_description = "Mark selected todos as incomplete"


# Marketplace Admin

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'description', 'icon', 'created_at']
    search_fields = ['name', 'description']
    ordering = ['name']


class ProductImageInline(admin.TabularInline):
    model = ProductImage
    extra = 1
    fields = ['image', 'is_primary']


@admin.register(WasteProduct)
class WasteProductAdmin(admin.ModelAdmin):
    list_display = [
        'title', 'seller', 'category', 'price', 'is_free', 'condition', 
        'status', 'location', 'is_available', 'created_at'
    ]
    list_filter = [
        'category', 'condition', 'status', 'is_free', 'pickup_available', 
        'delivery_available', 'created_at', 'seller'
    ]
    search_fields = ['title', 'description', 'location', 'seller__email']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at', 'is_available', 'is_expired']
    inlines = [ProductImageInline]
    
    fieldsets = (
        (None, {
            'fields': ('title', 'description', 'category', 'seller')
        }),
        ('Pricing', {
            'fields': ('price', 'is_free', 'quantity', 'unit')
        }),
        ('Status & Condition', {
            'fields': ('condition', 'status')
        }),
        ('Location', {
            'fields': ('location', 'latitude', 'longitude')
        }),
        ('Availability', {
            'fields': ('available_from', 'available_until', 'pickup_available', 'delivery_available', 'delivery_radius')
        }),
        ('Sustainability', {
            'fields': ('estimated_weight', 'carbon_footprint_saved')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'is_available', 'is_expired'),
            'classes': ('collapse',)
        }),
    )
    
    def is_available(self, obj):
        return obj.is_available
    is_available.boolean = True
    is_available.short_description = 'Available'


@admin.register(Interest)
class InterestAdmin(admin.ModelAdmin):
    list_display = ['product', 'buyer', 'status', 'offered_price', 'created_at']
    list_filter = ['status', 'created_at', 'product__category']
    search_fields = ['product__title', 'buyer__email', 'message']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at']
    
    actions = ['mark_accepted', 'mark_declined', 'mark_completed']
    
    def mark_accepted(self, request, queryset):
        queryset.update(status='accepted')
        self.message_user(request, f"{queryset.count()} interests marked as accepted.")
    mark_accepted.short_description = "Mark selected interests as accepted"
    
    def mark_declined(self, request, queryset):
        queryset.update(status='declined')
        self.message_user(request, f"{queryset.count()} interests marked as declined.")
    mark_declined.short_description = "Mark selected interests as declined"
    
    def mark_completed(self, request, queryset):
        queryset.update(status='completed')
        self.message_user(request, f"{queryset.count()} interests marked as completed.")
    mark_completed.short_description = "Mark selected interests as completed"


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ['interest', 'sender', 'content_preview', 'is_read', 'created_at']
    list_filter = ['is_read', 'created_at', 'sender']
    search_fields = ['content', 'sender__email', 'interest__product__title']
    ordering = ['-created_at']
    readonly_fields = ['created_at']
    
    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content Preview'


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ['reviewer', 'reviewed_user', 'product', 'rating', 'created_at']
    list_filter = ['rating', 'created_at']
    search_fields = ['reviewer__email', 'reviewed_user__email', 'product__title', 'comment']
    ordering = ['-created_at']
    readonly_fields = ['created_at']


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'is_verified', 'average_rating', 'total_reviews', 
        'total_transactions', 'carbon_footprint_saved'
    ]
    list_filter = ['is_verified', 'created_at']
    search_fields = ['user__email', 'user__first_name', 'user__last_name', 'bio']
    readonly_fields = [
        'total_waste_sold', 'total_waste_bought', 'carbon_footprint_saved',
        'total_transactions', 'average_rating', 'total_reviews', 
        'created_at', 'updated_at'
    ]
    
    fieldsets = (
        (None, {
            'fields': ('user', 'bio', 'avatar', 'phone', 'address')
        }),
        ('Verification', {
            'fields': ('is_verified', 'verification_document')
        }),
        ('Statistics', {
            'fields': (
                'total_waste_sold', 'total_waste_bought', 'carbon_footprint_saved',
                'total_transactions', 'average_rating', 'total_reviews'
            ),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ['user', 'product', 'created_at']
    list_filter = ['created_at', 'product__category']
    search_fields = ['user__email', 'product__title']
    ordering = ['-created_at']
    readonly_fields = ['created_at']


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ['reporter', 'reason', 'product', 'reported_user', 'is_resolved', 'created_at']
    list_filter = ['reason', 'is_resolved', 'created_at']
    search_fields = ['reporter__email', 'description', 'product__title']
    ordering = ['-created_at']
    readonly_fields = ['created_at']
    
    actions = ['mark_resolved', 'mark_unresolved']
    
    def mark_resolved(self, request, queryset):
        queryset.update(is_resolved=True)
        self.message_user(request, f"{queryset.count()} reports marked as resolved.")
    mark_resolved.short_description = "Mark selected reports as resolved"
    
    def mark_unresolved(self, request, queryset):
        queryset.update(is_resolved=False)
        self.message_user(request, f"{queryset.count()} reports marked as unresolved.")
    mark_unresolved.short_description = "Mark selected reports as unresolved"