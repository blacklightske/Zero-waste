from django.urls import path
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
    user_data_summary
)

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
]