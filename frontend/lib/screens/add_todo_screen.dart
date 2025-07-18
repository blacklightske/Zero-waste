import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/django_data_service.dart';
import '../models/todo.dart';

class AddTodoScreen extends StatefulWidget {
  final Todo? todo; // For editing existing todo
  
  const AddTodoScreen({super.key, this.todo});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  DateTime? _selectedDueDate;
  String? _selectedRecipeId;
  bool _isLoading = false;
  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.todo?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.todo?.description ?? '',
    );
    _selectedDueDate = widget.todo?.dueDate;
    _selectedRecipeId = widget.todo?.relatedRecipeId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Task' : 'Add New Task',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isEditing ? Icons.edit : Icons.add_task,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditing ? 'Edit Your Task' : 'Create New Task',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditing 
                          ? 'Update your task details'
                          : 'Add a recipe-related task to your to-do list',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Task Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g., Buy onions for pasta recipe',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  if (value.trim().length < 3) {
                    return 'Task title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Task Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add more details about this task...',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              
              const SizedBox(height: 16),
              
              // Due Date
              InkWell(
                onTap: _selectDueDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Due Date (Optional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedDueDate != null
                                  ? _formatDate(_selectedDueDate!)
                                  : 'No due date set',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDueDate != null
                                    ? Colors.black87
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedDueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _selectedDueDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Quick Due Date Options
              if (_selectedDueDate == null) ...[
                Text(
                  'Quick Options:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickDateChip('Today', DateTime.now()),
                    _buildQuickDateChip('Tomorrow', DateTime.now().add(const Duration(days: 1))),
                    _buildQuickDateChip('This Weekend', _getNextWeekend()),
                    _buildQuickDateChip('Next Week', DateTime.now().add(const Duration(days: 7))),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Related Recipe
              Consumer<DjangoDataService>(
                builder: (context, dataService, child) {
                  final allRecipes = [
                    ...dataService.savedRecipes,
                    ...dataService.customRecipes,
                  ];
                  
                  if (allRecipes.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No recipes available to link',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedRecipeId,
                    decoration: InputDecoration(
                      labelText: 'Related Recipe (Optional)',
                      prefixIcon: const Icon(Icons.restaurant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    hint: const Text('Select a recipe'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No recipe selected'),
                      ),
                      ...allRecipes.map((recipe) {
                        return DropdownMenuItem<String>(
                          value: recipe.id,
                          child: Row(
                            children: [
                              Icon(
                                recipe.isCustom ? Icons.edit : Icons.auto_awesome,
                                size: 16,
                                color: recipe.isCustom ? Colors.purple : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  recipe.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRecipeId = value;
                      });
                    },
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTodo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Task' : 'Add Task',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Cancel Button
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickDateChip(String label, DateTime date) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _selectedDueDate = date;
        });
      },
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  
  DateTime _getNextWeekend() {
    final now = DateTime.now();
    final daysUntilSaturday = (6 - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
  }
  
  Future<void> _selectDueDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select due date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );
    
    if (selectedDate != null) {
      setState(() {
        _selectedDueDate = selectedDate;
      });
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == tomorrow) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    }
  }
  
  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataService = Provider.of<DjangoDataService>(context, listen: false);
      
      bool success;
      
      if (_isEditing) {
        // Update existing todo
        final updatedTodo = widget.todo!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          dueDate: _selectedDueDate,
          relatedRecipeId: _selectedRecipeId,
        );
        
        success = await dataService.updateTodo(updatedTodo);
      } else {
        // Create new todo
        final newTodo = Todo.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? '' 
              : _descriptionController.text.trim(),
          dueDate: _selectedDueDate,
          relatedRecipeId: _selectedRecipeId,
        );
        
        success = await dataService.addTodo(newTodo);
      }
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                  ? 'Task updated successfully!' 
                  : 'Task added successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                  ? 'Failed to update task. Please try again.' 
                  : 'Failed to add task. Please try again.',
            ),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}