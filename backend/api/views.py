from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.db.models import Q
from datetime import date, timedelta
from .models import FoodItem, Recipe, Todo
from .serializers import (
    FoodItemSerializer,
    RecipeSerializer,
    TodoSerializer,
    TodoToggleSerializer,
    FoodItemSummarySerializer,
    RecipeSummarySerializer,
    TodoSummarySerializer
)
from .filters import FoodItemFilter


# Food Item Views
class FoodItemListCreateView(generics.ListCreateAPIView):
    serializer_class = FoodItemSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = FoodItemFilter
    search_fields = ['name']
    ordering_fields = ['name', 'expiry_date', 'created_at']
    ordering = ['expiry_date']
    
    def get_queryset(self):
        return FoodItem.objects.filter(user=self.request.user)


class FoodItemDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = FoodItemSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return FoodItem.objects.filter(user=self.request.user)


# Recipe Views
class RecipeListCreateView(generics.ListCreateAPIView):
    serializer_class = RecipeSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['difficulty', 'is_custom', 'is_saved']
    search_fields = ['name', 'description', 'ingredients']
    ordering_fields = ['name', 'difficulty', 'total_time', 'created_at']
    ordering = ['-created_at']
    
    def get_queryset(self):
        return Recipe.objects.filter(user=self.request.user)


class RecipeDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = RecipeSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Recipe.objects.filter(user=self.request.user)


# Todo Views
class TodoListCreateView(generics.ListCreateAPIView):
    serializer_class = TodoSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['is_completed', 'priority']
    search_fields = ['title', 'description']
    ordering_fields = ['title', 'priority', 'due_date', 'created_at']
    ordering = ['-created_at']
    
    def get_queryset(self):
        return Todo.objects.filter(user=self.request.user)


class TodoDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = TodoSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Todo.objects.filter(user=self.request.user)


class TodoToggleView(generics.UpdateAPIView):
    serializer_class = TodoToggleSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Todo.objects.filter(user=self.request.user)
    
    def update(self, request, *args, **kwargs):
        todo = self.get_object()
        todo.toggle_completion()
        serializer = TodoSerializer(todo)
        return Response(serializer.data)


# Dashboard/Summary Views
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def dashboard_summary(request):
    """Get summary data for dashboard"""
    user = request.user
    
    # Food items summary
    food_items = FoodItem.objects.filter(user=user)
    expired_items = food_items.filter(expiry_date__lt=date.today())
    expiring_soon = food_items.filter(
        expiry_date__gte=date.today(),
        expiry_date__lte=date.today() + timedelta(days=3)
    )
    
    # Recipes summary
    recipes = Recipe.objects.filter(user=user)
    custom_recipes = recipes.filter(is_custom=True)
    saved_recipes = recipes.filter(is_saved=True)
    
    # Todos summary
    todos = Todo.objects.filter(user=user)
    completed_todos = todos.filter(is_completed=True)
    pending_todos = todos.filter(is_completed=False)
    overdue_todos = todos.filter(
        is_completed=False,
        due_date__lt=date.today()
    )
    
    return Response({
        'food_items': {
            'total': food_items.count(),
            'expired': expired_items.count(),
            'expiring_soon': expiring_soon.count(),
            'expired_items': FoodItemSummarySerializer(expired_items[:5], many=True).data,
            'expiring_soon_items': FoodItemSummarySerializer(expiring_soon[:5], many=True).data,
        },
        'recipes': {
            'total': recipes.count(),
            'custom': custom_recipes.count(),
            'saved': saved_recipes.count(),
            'recent': RecipeSummarySerializer(recipes[:5], many=True).data,
        },
        'todos': {
            'total': todos.count(),
            'completed': completed_todos.count(),
            'pending': pending_todos.count(),
            'overdue': overdue_todos.count(),
            'recent_pending': TodoSummarySerializer(pending_todos[:5], many=True).data,
        }
    })


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def food_items_expiring(request):
    """Get food items expiring soon"""
    user = request.user
    days = int(request.GET.get('days', 7))  # Default to 7 days
    
    expiring_items = FoodItem.objects.filter(
        user=user,
        expiry_date__gte=date.today(),
        expiry_date__lte=date.today() + timedelta(days=days)
    ).order_by('expiry_date')
    
    serializer = FoodItemSerializer(expiring_items, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def todos_due_today(request):
    """Get todos due today"""
    user = request.user
    
    due_today = Todo.objects.filter(
        user=user,
        is_completed=False,
        due_date__date=date.today()
    ).order_by('due_date')
    
    serializer = TodoSerializer(due_today, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_data_summary(request):
    """Get all user data for initial app load"""
    user = request.user
    
    food_items = FoodItem.objects.filter(user=user)
    recipes = Recipe.objects.filter(user=user)
    todos = Todo.objects.filter(user=user)
    
    return Response({
        'food_items': FoodItemSerializer(food_items, many=True).data,
        'recipes': RecipeSerializer(recipes, many=True).data,
        'todos': TodoSerializer(todos, many=True).data,
    })