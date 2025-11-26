from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    FoodItemListCreateView,
    FoodItemDetailView,
    RecipeListCreateView,
    RecipeDetailView,
    TodoListCreateView,
    TodoDetailView,
    TodoToggleView,
    dashboard_summary,
    food_items_expiring,
    todos_due_today,
    user_data_summary,
    # Marketplace ViewSets
    CategoryViewSet,
    WasteProductViewSet,
    InterestViewSet,
    MessageViewSet,
    ReviewViewSet,
    UserProfileViewSet,
    FavoriteViewSet,
    ReportViewSet,
    ProductImageViewSet,
    # Marketplace function views
    marketplace_summary,
    marketplace_stats,
    user_conversations
)

# Create router for marketplace ViewSets
router = DefaultRouter()
router.register(r'marketplace/categories', CategoryViewSet, basename='category')
router.register(r'marketplace/products', WasteProductViewSet, basename='product')
router.register(r'marketplace/interests', InterestViewSet, basename='interest')
router.register(r'marketplace/messages', MessageViewSet, basename='message')
router.register(r'marketplace/reviews', ReviewViewSet, basename='review')
router.register(r'marketplace/profiles', UserProfileViewSet, basename='profile')
router.register(r'marketplace/favorites', FavoriteViewSet, basename='favorite')
router.register(r'marketplace/reports', ReportViewSet, basename='report')
router.register(r'marketplace/images', ProductImageViewSet, basename='productimage')

app_name = 'api'

urlpatterns = [
    # Food Items
    path('food-items/', FoodItemListCreateView.as_view(), name='food_item_list_create'),
    path('food-items/<int:pk>/', FoodItemDetailView.as_view(), name='food_item_detail'),
    path('food-items/expiring/', food_items_expiring, name='food_items_expiring'),
    
    # Recipes
    path('recipes/', RecipeListCreateView.as_view(), name='recipe_list_create'),
    path('recipes/<int:pk>/', RecipeDetailView.as_view(), name='recipe_detail'),
    
    # Todos
    path('todos/', TodoListCreateView.as_view(), name='todo_list_create'),
    path('todos/<int:pk>/', TodoDetailView.as_view(), name='todo_detail'),
    path('todos/<int:pk>/toggle/', TodoToggleView.as_view(), name='todo_toggle'),
    path('todos/due-today/', todos_due_today, name='todos_due_today'),
    
    # Dashboard and Summary
    path('dashboard/', dashboard_summary, name='dashboard_summary'),
    path('user-data/', user_data_summary, name='user_data_summary'),
    
    # Marketplace summary endpoints
    path('marketplace/summary/', marketplace_summary, name='marketplace_summary'),
    path('marketplace/stats/', marketplace_stats, name='marketplace_stats'),
    path('marketplace/conversations/', user_conversations, name='user_conversations'),
    
    # Include marketplace router URLs
    path('', include(router.urls)),
]