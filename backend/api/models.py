from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import date, timedelta
from django.core.validators import MinValueValidator, MaxValueValidator
from decimal import Decimal

User = get_user_model()


class FoodItem(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='food_items')
    name = models.CharField(max_length=255)
    quantity = models.CharField(max_length=100)
    expiry_date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['expiry_date', 'name']
    
    def __str__(self):
        return f"{self.name} - {self.quantity}"
    
    @property
    def is_expired(self):
        return self.expiry_date < date.today()
    
    @property
    def is_expiring_soon(self):
        return self.expiry_date <= date.today() + timedelta(days=3)
    
    @property
    def days_until_expiry(self):
        delta = self.expiry_date - date.today()
        return delta.days


class Recipe(models.Model):
    DIFFICULTY_CHOICES = [
        ('easy', 'Easy'),
        ('medium', 'Medium'),
        ('hard', 'Hard'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recipes')
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    ingredients = models.JSONField(default=list)  # List of ingredient strings
    instructions = models.JSONField(default=list)  # List of instruction strings
    prep_time = models.PositiveIntegerField(help_text="Preparation time in minutes", default=0)
    cook_time = models.PositiveIntegerField(help_text="Cooking time in minutes", default=0)
    servings = models.PositiveIntegerField(default=1)
    difficulty = models.CharField(max_length=10, choices=DIFFICULTY_CHOICES, default='easy')
    tags = models.JSONField(default=list)  # List of tag strings
    image_url = models.URLField(blank=True, null=True)
    is_custom = models.BooleanField(default=True)  # True for user-created recipes
    is_saved = models.BooleanField(default=False)  # True for saved recipes from external sources
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return self.name
    
    @property
    def total_time(self):
        return self.prep_time + self.cook_time
    
    @property
    def estimated_time(self):
        """Return estimated time as a string"""
        total = self.total_time
        if total < 60:
            return f"{total} min"
        else:
            hours = total // 60
            minutes = total % 60
            if minutes == 0:
                return f"{hours}h"
            return f"{hours}h {minutes}m"


class Todo(models.Model):
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='todos')
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    is_completed = models.BooleanField(default=False)
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    due_date = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return self.title
    
    @property
    def is_overdue(self):
        if self.due_date and not self.is_completed:
            return self.due_date < timezone.now()
        return False
    
    @property
    def is_due_today(self):
        if self.due_date and not self.is_completed:
            return self.due_date.date() == date.today()
        return False
    
    def toggle_completion(self):
        self.is_completed = not self.is_completed
        if self.is_completed:
            self.completed_at = timezone.now()
        else:
            self.completed_at = None
        self.save()


# Marketplace Models

class Category(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    icon = models.CharField(max_length=50, blank=True)  # Font awesome icon name
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['name']
        verbose_name_plural = 'Categories'
    
    def __str__(self):
        return self.name


class WasteProduct(models.Model):
    CONDITION_CHOICES = [
        ('excellent', 'Excellent'),
        ('good', 'Good'),
        ('fair', 'Fair'),
        ('poor', 'Poor'),
    ]
    
    STATUS_CHOICES = [
        ('available', 'Available'),
        ('reserved', 'Reserved'),
        ('sold', 'Sold'),
        ('expired', 'Expired'),
    ]
    
    seller = models.ForeignKey(User, on_delete=models.CASCADE, related_name='waste_products')
    title = models.CharField(max_length=255)
    description = models.TextField()
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='products')
    price = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal('0.00'))])
    is_free = models.BooleanField(default=False)
    quantity = models.CharField(max_length=100)
    unit = models.CharField(max_length=50, default='kg')
    condition = models.CharField(max_length=20, choices=CONDITION_CHOICES, default='good')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='available')
    
    # Location
    location = models.CharField(max_length=255)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    
    # Timing
    available_from = models.DateTimeField(default=timezone.now)
    available_until = models.DateTimeField(null=True, blank=True)
    pickup_available = models.BooleanField(default=True)
    delivery_available = models.BooleanField(default=False)
    delivery_radius = models.PositiveIntegerField(null=True, blank=True, help_text="Delivery radius in km")
    
    # Sustainability metrics
    estimated_weight = models.FloatField(help_text="Estimated weight in kg", default=0)
    carbon_footprint_saved = models.FloatField(default=0, help_text="Estimated CO2 saved in kg")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.title} by {self.seller.full_name}"
    
    @property
    def is_available(self):
        return self.status == 'available' and (
            not self.available_until or self.available_until > timezone.now()
        )
    
    @property
    def is_expired(self):
        return self.available_until and self.available_until < timezone.now()


class ProductImage(models.Model):
    product = models.ForeignKey(WasteProduct, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='products/')
    is_primary = models.BooleanField(default=False)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    cloudinary_url = models.URLField(blank=True, null=True)
    
    class Meta:
        ordering = ['-is_primary', 'uploaded_at']
    
    def __str__(self):
        return f"Image for {self.product.title}"
        
    def save(self, *args, **kwargs):
        # The actual image upload to Cloudinary will be handled by the storage backend
        super().save(*args, **kwargs)


class Interest(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('declined', 'Declined'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    product = models.ForeignKey(WasteProduct, on_delete=models.CASCADE, related_name='interests')
    buyer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='interests')
    message = models.TextField(blank=True)
    offered_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['product', 'buyer']
    
    def __str__(self):
        return f"{self.buyer.full_name} interested in {self.product.title}"


class Message(models.Model):
    interest = models.ForeignKey(Interest, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"Message from {self.sender.full_name}"


class Review(models.Model):
    RATING_CHOICES = [(i, i) for i in range(1, 6)]
    
    reviewer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews_given')
    reviewed_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews_received')
    product = models.ForeignKey(WasteProduct, on_delete=models.CASCADE, related_name='reviews')
    rating = models.PositiveIntegerField(choices=RATING_CHOICES, validators=[MinValueValidator(1), MaxValueValidator(5)])
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['reviewer', 'reviewed_user', 'product']
    
    def __str__(self):
        return f"{self.rating}★ review for {self.reviewed_user.full_name}"


class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    bio = models.TextField(blank=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    avatar_cloudinary_url = models.URLField(blank=True, null=True)
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    
    # Verification
    is_verified = models.BooleanField(default=False)
    verification_document = models.ImageField(upload_to='verification/', blank=True, null=True)
    verification_cloudinary_url = models.URLField(blank=True, null=True)
    
    # Sustainability metrics
    total_waste_sold = models.FloatField(default=0)
    total_waste_bought = models.FloatField(default=0)
    carbon_footprint_saved = models.FloatField(default=0)
    total_transactions = models.PositiveIntegerField(default=0)
    
    # Ratings
    average_rating = models.FloatField(default=0.0)
    total_reviews = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Profile of {self.user.full_name}"
    
    def calculate_average_rating(self):
        reviews = self.user.reviews_received.all()
        if reviews.exists():
            self.average_rating = reviews.aggregate(models.Avg('rating'))['rating__avg']
            self.total_reviews = reviews.count()
        else:
            self.average_rating = 0.0
            self.total_reviews = 0
        self.save()


class Favorite(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favorites')
    product = models.ForeignKey(WasteProduct, on_delete=models.CASCADE, related_name='favorited_by')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'product']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.full_name} favorited {self.product.title}"


class Report(models.Model):
    REASON_CHOICES = [
        ('inappropriate', 'Inappropriate Content'),
        ('spam', 'Spam'),
        ('fake', 'Fake Listing'),
        ('fraud', 'Fraudulent Activity'),
        ('other', 'Other'),
    ]
    
    reporter = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reports_made')
    product = models.ForeignKey(WasteProduct, on_delete=models.CASCADE, related_name='reports', null=True, blank=True)
    reported_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reports_received', null=True, blank=True)
    reason = models.CharField(max_length=20, choices=REASON_CHOICES)
    description = models.TextField()
    is_resolved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Report by {self.reporter.full_name}: {self.reason}"