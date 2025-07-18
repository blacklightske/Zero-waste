from django.contrib import admin
from .models import FoodItem, Recipe, Todo


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