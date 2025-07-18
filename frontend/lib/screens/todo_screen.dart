import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/django_data_service.dart';
import '../models/todo.dart';
import '../widgets/todo_card.dart';
import 'add_todo_screen.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _sortBy = 'dueDate'; // dueDate, priority, name, created
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipe To-Do',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.list),
              text: 'All Tasks',
            ),
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Pending',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Completed',
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _handleSortOption,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'dueDate',
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: _sortBy == 'dueDate' ? Theme.of(context).primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sort by Due Date',
                      style: TextStyle(
                        fontWeight: _sortBy == 'dueDate' ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'priority',
                child: Row(
                  children: [
                    Icon(
                      Icons.priority_high,
                      color: _sortBy == 'priority' ? Theme.of(context).primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sort by Priority',
                      style: TextStyle(
                        fontWeight: _sortBy == 'priority' ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortBy == 'name' ? Theme.of(context).primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sort by Name',
                      style: TextStyle(
                        fontWeight: _sortBy == 'name' ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'created',
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: _sortBy == 'created' ? Theme.of(context).primaryColor : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sort by Created',
                      style: TextStyle(
                        fontWeight: _sortBy == 'created' ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'toggle_order',
                child: Row(
                  children: [
                    Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                    const SizedBox(width: 8),
                    Text(_sortAscending ? 'Ascending' : 'Descending'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Content
          Expanded(
            child: Consumer<DjangoDataService>(
              builder: (context, dataService, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // All Tasks
                    _buildTodoList(
                      dataService.todos,
                      'No tasks yet',
                      'Add your first recipe-related task to get started!',
                    ),
                    
                    // Pending Tasks
                    _buildTodoList(
                      dataService.pendingTodos,
                      'No pending tasks',
                      'All your tasks are completed! 🎉',
                    ),
                    
                    // Completed Tasks
                    _buildTodoList(
                      dataService.completedTodos,
                      'No completed tasks',
                      'Complete some tasks to see them here.',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "todo_fab",
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddTodoScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildTodoList(List<Todo> todos, String emptyTitle, String emptyMessage) {
    // Filter todos based on search query
    final filteredTodos = todos.where((todo) {
      if (_searchQuery.isEmpty) return true;
      return todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (todo.description.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
    
    // Sort todos
    _sortTodos(filteredTodos);
    
    if (filteredTodos.isEmpty) {
      return _buildEmptyState(emptyTitle, emptyMessage);
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        final dataService = Provider.of<DjangoDataService>(context, listen: false);
        await dataService.loadUserData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTodos.length,
        itemBuilder: (context, index) {
          final todo = filteredTodos[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TodoCard(
              todo: todo,
              onToggleComplete: (bool? _) => _toggleTodoComplete(todo),
              onEdit: () => _editTodo(todo),
              onDelete: () => _deleteTodo(todo),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Theme.of(context).primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddTodoScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _sortTodos(List<Todo> todos) {
    todos.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'dueDate':
          if (a.dueDate == null && b.dueDate == null) {
            comparison = 0;
          } else if (a.dueDate == null) {
            comparison = 1;
          } else if (b.dueDate == null) {
            comparison = -1;
          } else {
            comparison = a.dueDate!.compareTo(b.dueDate!);
          }
          break;
        case 'priority':
          comparison = b.priority.compareTo(a.priority); // Higher priority first
          break;
        case 'name':
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case 'created':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
  }
  
  void _handleSortOption(String option) {
    setState(() {
      if (option == 'toggle_order') {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = option;
      }
    });
  }
  
  Future<void> _toggleTodoComplete(Todo todo) async {
    try {
      final dataService = Provider.of<DjangoDataService>(context, listen: false);
      
      final updatedTodo = todo.copyWith(isCompleted: !todo.isCompleted);
      final success = await dataService.updateTodo(updatedTodo);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              todo.isCompleted 
                  ? 'Task marked as pending' 
                  : 'Task completed! 🎉',
            ),
            backgroundColor: todo.isCompleted ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update task. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _editTodo(Todo todo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTodoScreen(todo: todo),
      ),
    );
  }
  
  Future<void> _deleteTodo(Todo todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${todo.title}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final dataService = Provider.of<DjangoDataService>(context, listen: false);
        final success = await dataService.deleteTodo(todo.id);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task "${todo.title}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete task. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}