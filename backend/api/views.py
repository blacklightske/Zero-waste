from rest_framework import generics, status, permissions, viewsets
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.db.models import Q, Avg, Count
from datetime import date, timedelta
from django.contrib.auth import get_user_model
from .models import (
    FoodItem, Recipe, Todo, WasteProduct, Category, ProductImage, 
    Interest, Message, Review, UserProfile, Favorite, Report
)
from .serializers import (
    FoodItemSerializer,
    RecipeSerializer,
    TodoSerializer,
    TodoToggleSerializer,
    FoodItemSummarySerializer,
    RecipeSummarySerializer,
    TodoSummarySerializer,
    WasteProductSerializer,
    WasteProductListSerializer,
    CategorySerializer,
    ProductImageSerializer,
    InterestSerializer,
    MessageSerializer,
    ReviewSerializer,
    UserProfileSerializer,
    FavoriteSerializer,
    ReportSerializer
)
from .filters import FoodItemFilter, WasteProductFilter

User = get_user_model()


class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow owners of an object to edit it.
    """
    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to any request,
        # so we'll always allow GET, HEAD or OPTIONS requests.
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write permissions are only allowed to the owner of the object.
        if hasattr(obj, 'user'):
            return obj.user == request.user
        elif hasattr(obj, 'seller'):
            return obj.seller == request.user
        elif hasattr(obj, 'buyer'):
            return obj.buyer == request.user
        elif hasattr(obj, 'reporter'):
            return obj.reporter == request.user
        elif hasattr(obj, 'reviewer'):
            return obj.reviewer == request.user
        return False


class IsSellerOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow sellers to edit their products.
    """
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.seller == request.user


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


# Marketplace ViewSets

class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for categories - read-only for users
    """
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['name', 'description']
    ordering = ['name']


class WasteProductViewSet(viewsets.ModelViewSet):
    """
    ViewSet for waste products with advanced filtering and search
    """
    serializer_class = WasteProductSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsSellerOrReadOnly]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = WasteProductFilter
    search_fields = ['title', 'description', 'location']
    ordering_fields = ['created_at', 'price', 'title', 'available_from']
    ordering = ['-created_at']
    
    def get_queryset(self):
        queryset = WasteProduct.objects.select_related('seller', 'category').prefetch_related('images')
        
        # Filter by status if not owner
        if self.action == 'list':
            queryset = queryset.filter(status='available')
        
        return queryset
    
    def get_serializer_class(self):
        if self.action == 'list':
            return WasteProductListSerializer
        return WasteProductSerializer
    
    @action(detail=True, methods=['post'])
    def toggle_favorite(self, request, pk=None):
        """Toggle favorite status for a product"""
        product = self.get_object()
        favorite, created = Favorite.objects.get_or_create(
            user=request.user,
            product=product
        )
        
        if not created:
            favorite.delete()
            return Response({'favorited': False})
        
        return Response({'favorited': True})
    
    @action(detail=True, methods=['post'])
    def express_interest(self, request, pk=None):
        """Express interest in a product"""
        product = self.get_object()
        
        if product.seller == request.user:
            return Response(
                {'error': 'Cannot express interest in your own product'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        interest, created = Interest.objects.get_or_create(
            product=product,
            buyer=request.user,
            defaults={
                'message': request.data.get('message', ''),
                'offered_price': request.data.get('offered_price')
            }
        )
        
        if not created:
            return Response(
                {'error': 'Interest already expressed'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = InterestSerializer(interest)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['get'])
    def interests(self, request, pk=None):
        """Get all interests for a product (seller only)"""
        product = self.get_object()
        
        if product.seller != request.user:
            return Response(
                {'error': 'Only seller can view interests'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        interests = product.interests.all()
        serializer = InterestSerializer(interests, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def mark_sold(self, request, pk=None):
        """Mark product as sold"""
        product = self.get_object()
        
        if product.seller != request.user:
            return Response(
                {'error': 'Only seller can mark as sold'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        product.status = 'sold'
        product.save()
        
        serializer = self.get_serializer(product)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def my_products(self, request):
        """Get current user's products"""
        products = WasteProduct.objects.filter(seller=request.user)
        page = self.paginate_queryset(products)
        if page is not None:
            serializer = WasteProductListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = WasteProductListSerializer(products, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def nearby(self, request):
        """Get products near user's location"""
        lat = request.query_params.get('latitude')
        lng = request.query_params.get('longitude')
        radius = float(request.query_params.get('radius', 10))  # Default 10km
        
        if not lat or not lng:
            return Response(
                {'error': 'Latitude and longitude required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Simple distance filter - for production, use proper geospatial queries
        products = WasteProduct.objects.filter(
            status='available',
            latitude__isnull=False,
            longitude__isnull=False
        ).exclude(seller=request.user)
        
        # Basic distance calculation (not accurate for large distances)
        nearby_products = []
        for product in products:
            if product.latitude and product.longitude:
                lat_diff = abs(float(lat) - product.latitude)
                lng_diff = abs(float(lng) - product.longitude)
                # Rough approximation: 1 degree ≈ 111km
                distance = ((lat_diff ** 2 + lng_diff ** 2) ** 0.5) * 111
                if distance <= radius:
                    nearby_products.append(product)
        
        page = self.paginate_queryset(nearby_products)
        if page is not None:
            serializer = WasteProductListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = WasteProductListSerializer(nearby_products, many=True)
        return Response(serializer.data)


class InterestViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing interests
    """
    serializer_class = InterestSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['status', 'product']
    ordering = ['-created_at']
    
    def get_queryset(self):
        # Users can see interests they made or received
        return Interest.objects.filter(
            Q(buyer=self.request.user) | Q(product__seller=self.request.user)
        ).select_related('product', 'buyer')
    
    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        """Accept an interest (seller only)"""
        interest = self.get_object()
        
        if interest.product.seller != request.user:
            return Response(
                {'error': 'Only seller can accept interest'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        interest.status = 'accepted'
        interest.save()
        
        # Mark product as reserved
        interest.product.status = 'reserved'
        interest.product.save()
        
        serializer = self.get_serializer(interest)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def decline(self, request, pk=None):
        """Decline an interest (seller only)"""
        interest = self.get_object()
        
        if interest.product.seller != request.user:
            return Response(
                {'error': 'Only seller can decline interest'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        interest.status = 'declined'
        interest.save()
        
        serializer = self.get_serializer(interest)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark transaction as completed"""
        interest = self.get_object()
        
        if interest.product.seller != request.user and interest.buyer != request.user:
            return Response(
                {'error': 'Only involved parties can complete transaction'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        interest.status = 'completed'
        interest.save()
        
        # Mark product as sold
        interest.product.status = 'sold'
        interest.product.save()
        
        serializer = self.get_serializer(interest)
        return Response(serializer.data)


class MessageViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing messages within interests
    """
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    ordering = ['created_at']
    
    def get_queryset(self):
        # Users can see messages from interests they're involved in
        return Message.objects.filter(
            Q(interest__buyer=self.request.user) | 
            Q(interest__product__seller=self.request.user)
        ).select_related('sender', 'interest')
    
    def create(self, request, *args, **kwargs):
        interest_id = request.data.get('interest')
        try:
            interest = Interest.objects.get(
                id=interest_id,
                buyer=request.user
            ) or Interest.objects.get(
                id=interest_id,
                product__seller=request.user
            )
        except Interest.DoesNotExist:
            return Response(
                {'error': 'Interest not found or access denied'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        return super().create(request, *args, **kwargs)
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark message as read"""
        message = self.get_object()
        
        if message.sender == request.user:
            return Response(
                {'error': 'Cannot mark your own message as read'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        message.is_read = True
        message.save()
        
        serializer = self.get_serializer(message)
        return Response(serializer.data)


class ReviewViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing reviews
    """
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['rating', 'reviewed_user']
    ordering = ['-created_at']
    
    def get_queryset(self):
        return Review.objects.all().select_related('reviewer', 'reviewed_user', 'product')
    
    def create(self, request, *args, **kwargs):
        # Validate that user can review
        reviewed_user_id = request.data.get('reviewed_user')
        product_id = request.data.get('product')
        
        if reviewed_user_id == request.user.id:
            return Response(
                {'error': 'Cannot review yourself'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if user was involved in transaction
        try:
            Interest.objects.get(
                Q(buyer=request.user, product_id=product_id, product__seller_id=reviewed_user_id) |
                Q(product__seller=request.user, buyer_id=reviewed_user_id, product_id=product_id),
                status='completed'
            )
        except Interest.DoesNotExist:
            return Response(
                {'error': 'Can only review users you completed transactions with'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        return super().create(request, *args, **kwargs)


class UserProfileViewSet(viewsets.ModelViewSet):
    """
    ViewSet for user profiles
    """
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return UserProfile.objects.all().select_related('user')
    
    def get_object(self):
        if self.action in ['update', 'partial_update', 'destroy']:
            # Users can only edit their own profile
            return UserProfile.objects.get(user=self.request.user)
        return super().get_object()
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        """Get current user's profile"""
        profile, created = UserProfile.objects.get_or_create(user=request.user)
        serializer = self.get_serializer(profile)
        return Response(serializer.data)
        
    def update(self, request, *args, **kwargs):
        response = super().update(request, *args, **kwargs)
        
        # If Cloudinary is configured, update the cloudinary URL fields
        if response.status_code == status.HTTP_200_OK:
            try:
                profile = self.get_object()
                
                # Update avatar_cloudinary_url if avatar is set
                if 'avatar' in response.data and profile.avatar and not profile.avatar_cloudinary_url:
                    profile.avatar_cloudinary_url = response.data['avatar']
                    profile.save(update_fields=['avatar_cloudinary_url'])
                    response.data['avatar_cloudinary_url'] = profile.avatar_cloudinary_url
                
                # Update verification_cloudinary_url if verification_document is set
                if 'verification_document' in response.data and profile.verification_document and not profile.verification_cloudinary_url:
                    profile.verification_cloudinary_url = response.data['verification_document']
                    profile.save(update_fields=['verification_cloudinary_url'])
                    response.data['verification_cloudinary_url'] = profile.verification_cloudinary_url
            except UserProfile.DoesNotExist:
                pass
        
        return response


class FavoriteViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing favorites
    """
    serializer_class = FavoriteSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]
    ordering = ['-created_at']
    
    def get_queryset(self):
        return Favorite.objects.filter(user=self.request.user).select_related('product')


class ReportViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing reports
    """
    serializer_class = ReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]
    ordering = ['-created_at']
    
    def get_queryset(self):
        # Users can only see their own reports
        return Report.objects.filter(reporter=self.request.user)


class ProductImageViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing product images
    """
    serializer_class = ProductImageSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Users can only manage images for their own products
        return ProductImage.objects.filter(product__seller=self.request.user)
    
    def create(self, request, *args, **kwargs):
        product_id = request.data.get('product')
        try:
            product = WasteProduct.objects.get(id=product_id, seller=request.user)
        except WasteProduct.DoesNotExist:
            return Response(
                {'error': 'Product not found or access denied'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        response = super().create(request, *args, **kwargs)
        
        # If Cloudinary is configured, update the cloudinary_url field
        if response.status_code == status.HTTP_201_CREATED and 'image' in response.data:
            try:
                # Get the newly created image object
                image_obj = ProductImage.objects.get(id=response.data['id'])
                
                # If the image has a URL and cloudinary_url is not set, update it
                if image_obj.image and not image_obj.cloudinary_url:
                    image_obj.cloudinary_url = response.data['image']
                    image_obj.save(update_fields=['cloudinary_url'])
                    
                    # Update the response data
                    response.data['cloudinary_url'] = image_obj.cloudinary_url
            except ProductImage.DoesNotExist:
                pass
        
        return response


# Marketplace Summary and Statistics Views

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def marketplace_summary(request):
    """Get marketplace summary data for dashboard"""
    user = request.user
    
    # User's products
    my_products = WasteProduct.objects.filter(seller=user)
    
    # User's interests
    my_interests = Interest.objects.filter(buyer=user)
    received_interests = Interest.objects.filter(product__seller=user)
    
    # User's reviews
    reviews_given = Review.objects.filter(reviewer=user)
    reviews_received = Review.objects.filter(reviewed_user=user)
    
    # User's favorites
    favorites = Favorite.objects.filter(user=user)
    
    # Recent activity
    recent_products = WasteProduct.objects.filter(status='available').exclude(seller=user)[:5]
    
    return Response({
        'my_products': {
            'total': my_products.count(),
            'available': my_products.filter(status='available').count(),
            'sold': my_products.filter(status='sold').count(),
            'reserved': my_products.filter(status='reserved').count(),
        },
        'interests': {
            'expressed': my_interests.count(),
            'received': received_interests.count(),
            'pending': my_interests.filter(status='pending').count(),
            'accepted': my_interests.filter(status='accepted').count(),
        },
        'reviews': {
            'given': reviews_given.count(),
            'received': reviews_received.count(),
            'average_rating': reviews_received.aggregate(avg=Avg('rating'))['avg'] or 0,
        },
        'favorites_count': favorites.count(),
        'recent_products': WasteProductListSerializer(recent_products, many=True).data,
    })


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def marketplace_stats(request):
    """Get overall marketplace statistics"""
    
    # Overall stats
    total_products = WasteProduct.objects.count()
    available_products = WasteProduct.objects.filter(status='available').count()
    total_users = User.objects.count()
    total_transactions = Interest.objects.filter(status='completed').count()
    
    # Category stats
    categories_with_counts = Category.objects.annotate(
        product_count=Count('products')
    ).values('id', 'name', 'product_count')
    
    # Recent activity
    recent_products = WasteProduct.objects.filter(
        status='available'
    ).select_related('seller', 'category')[:10]
    
    return Response({
        'totals': {
            'products': total_products,
            'available_products': available_products,
            'users': total_users,
            'completed_transactions': total_transactions,
        },
        'categories': list(categories_with_counts),
        'recent_products': WasteProductListSerializer(recent_products, many=True).data,
    })


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_conversations(request):
    """Get all conversations for the current user"""
    user = request.user
    
    # Get all interests where user is buyer or seller
    interests = Interest.objects.filter(
        Q(buyer=user) | Q(product__seller=user)
    ).select_related('product', 'buyer').prefetch_related('messages')
    
    conversations = []
    for interest in interests:
        # Get latest message
        latest_message = interest.messages.first()
        unread_count = interest.messages.filter(
            is_read=False
        ).exclude(sender=user).count()
        
        # Determine other participant
        other_user = interest.buyer if interest.product.seller == user else interest.product.seller
        
        conversations.append({
            'interest_id': interest.id,
            'product_title': interest.product.title,
            'product_id': interest.product.id,
            'other_user': {
                'id': other_user.id,
                'name': other_user.full_name,
            },
            'status': interest.status,
            'latest_message': {
                'content': latest_message.content if latest_message else None,
                'created_at': latest_message.created_at if latest_message else None,
                'sender_name': latest_message.sender.full_name if latest_message else None,
            } if latest_message else None,
            'unread_count': unread_count,
            'created_at': interest.created_at,
        })
    
    # Sort by latest activity
    conversations.sort(key=lambda x: x['latest_message']['created_at'] if x['latest_message'] else x['created_at'], reverse=True)
    
    return Response(conversations)