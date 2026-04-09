import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'task_detail_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart To-Do'),
        actions: [
          IconButton(
            icon: Icon(context.watch<TaskProvider>().isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => context.read<TaskProvider>().toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAnalyticsCard(),
          _buildFilters(),
          Expanded(child: _buildTaskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToTaskDetail(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _analyticsItem('Completed', provider.completedTasksCount.toString()),
                _analyticsItem('Rate', '${(provider.completionRate * 100).toStringAsFixed(0)}%'),
                _analyticsItem('Total', provider.tasks.length.toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _analyticsItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Today', 'Upcoming', 'Completed'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskList() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final filteredTasks = provider.getTasksByFilter(_selectedFilter);
        if (filteredTasks.isEmpty) {
          return const Center(child: Text('No tasks found.'));
        }
        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];
            return ListTile(
              leading: Checkbox(
                value: task.isCompleted,
                onChanged: (val) {
                  provider.updateTask(task.copyWith(isCompleted: val ?? false));
                },
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(task.dueDate)),
              trailing: _priorityBadge(task.priority),
              onTap: () => _navigateToTaskDetail(context, task: task),
              onLongPress: () => _showDeleteDialog(context, task),
            );
          },
        );
      },
    );
  }

  Widget _priorityBadge(Priority priority) {
    Color color;
    switch (priority) {
      case Priority.high: color = Colors.red; break;
      case Priority.medium: color = Colors.orange; break;
      case Priority.low: color = Colors.green; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _navigateToTaskDetail(BuildContext context, {Task? task}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
  }

  void _showDeleteDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (!context.mounted) return;
              Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
