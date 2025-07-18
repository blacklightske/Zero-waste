import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/django_auth_service.dart';
import '../../services/django_data_service.dart';
import '../../models/food_item.dart';
import '../../models/recipe.dart';
import '../../models/todo.dart';
import '../../utils/animations.dart';
import '../pantry/add_food_screen.dart';
import '../recipes/recipe_generator_screen.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final dataService = Provider.of<DjangoDataService>(context, listen: false);
            await dataService.loadUserData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                AppAnimations.slideInFromBottom(
                  child: _buildHeader(context),
                ),
                const SizedBox(height: 24),
                
                // Quick stats
                AppAnimations.staggeredListItem(
                  index: 0,
                  child: _buildQuickStats(context),
                ),
                const SizedBox(height: 24),
                
                // Expiring soon section
                AppAnimations.staggeredListItem(
                  index: 1,
                  child: _buildExpiringSoonSection(context),
                ),
                const SizedBox(height: 24),
                
                // Recent recipes section
                AppAnimations.staggeredListItem(
                  index: 2,
                  child: _buildRecentRecipesSection(context),
                ),
                const SizedBox(height: 24),
                
                // Pending todos section
                AppAnimations.staggeredListItem(
                  index: 3,
                  child: _buildPendingTodosSection(context),
                ),
                const SizedBox(height: 24),
                
                // Quick actions
                AppAnimations.staggeredListItem(
                  index: 4,
                  child: _buildQuickActions(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Consumer<DjangoAuthService>(
      builder: (context, authService, _) {
        final timeOfDay = _getTimeOfDay();
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$timeOfDay, ${authService.userName}! 👋',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Let\'s reduce food waste together',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              TweenAnimationBuilder(
                duration: const Duration(seconds: 2),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.rotate(
                    angle: value * 2 * 3.14159,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildQuickStats(BuildContext context) {
    return Consumer<DjangoDataService>(
      builder: (context, dataService, _) {
        final totalItems = dataService.foodItems.length;
        final expiredItems = dataService.expiredFoodItems.length;
        final soonToExpire = dataService.soonToExpireFoodItems.length;
        final totalRecipes = dataService.allRecipes.length;
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total Items',
                totalItems.toString(),
                Icons.inventory_2_outlined,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Expiring Soon',
                soonToExpire.toString(),
                Icons.warning_outlined,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Expired',
                expiredItems.toString(),
                Icons.error_outline,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Recipes',
                totalRecipes.toString(),
                Icons.restaurant_outlined,
                Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double animationValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animationValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 1000),
                  tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
                  builder: (context, int animatedValue, child) {
                    return Text(
                      animatedValue.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 24,
                        letterSpacing: 0.5,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildExpiringSoonSection(BuildContext context) {
    return Consumer<DjangoDataService>(
      builder: (context, dataService, _) {
        final expiringSoon = dataService.soonToExpireFoodItems;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expiring Soon ⚠️',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (expiringSoon.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // Navigate to pantry tab
                      // This would be handled by the parent widget
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (expiringSoon.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Great! No items expiring soon',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep up the good work!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...expiringSoon.take(3).map((item) => _buildFoodItemTile(context, item)),
          ],
        );
      },
    );
  }
  
  Widget _buildRecentRecipesSection(BuildContext context) {
    return Consumer<DjangoDataService>(
      builder: (context, dataService, _) {
        final recentRecipes = dataService.allRecipes
            .where((recipe) => recipe.createdAt.isAfter(
                DateTime.now().subtract(const Duration(days: 7))))
            .take(3)
            .toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Recipes 🍳',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RecipeGeneratorScreen(),
                      ),
                    );
                  },
                  child: const Text('Generate New'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentRecipes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_outlined,
                      color: Colors.blue,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent recipes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generate your first recipe!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recentRecipes.map((recipe) => _buildRecipeTile(context, recipe)),
          ],
        );
      },
    );
  }
  
  Widget _buildPendingTodosSection(BuildContext context) {
    return Consumer<DjangoDataService>(
      builder: (context, dataService, _) {
        final pendingTodos = dataService.pendingTodos.take(3).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Tasks ✅',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (pendingTodos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt_outlined,
                      color: Colors.purple,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All caught up!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.purple[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No pending tasks',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.purple[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...pendingTodos.map((todo) => _buildTodoTile(context, todo)),
          ],
        );
      },
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Add Food',
                Icons.add_circle_outline,
                Colors.green,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddFoodScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Generate Recipe',
                Icons.auto_awesome_outlined,
                Colors.orange,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RecipeGeneratorScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFoodItemTile(BuildContext context, FoodItem item) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double animationValue, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - animationValue), 0),
          child: Opacity(
            opacity: animationValue,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_outlined,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expires ${DateFormat('MMM dd').format(item.expiryDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[700],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${item.daysUntilExpiry} days',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRecipeTile(BuildContext context, Recipe recipe) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double animationValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animationValue), 0),
          child: Opacity(
            opacity: animationValue,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      recipe.isCustom ? Icons.edit_outlined : Icons.auto_awesome_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${recipe.ingredients.length} ingredients • ${recipe.difficulty}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (recipe.isSaved)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.star,
                        color: Colors.amber[700],
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTodoTile(BuildContext context, Todo todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.radio_button_unchecked,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (todo.description.isNotEmpty)
                  Text(
                    todo.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (todo.dueDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(todo.priority).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                todo.priority,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getPriorityColor(todo.priority),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}