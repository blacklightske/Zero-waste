from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import date, timedelta

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