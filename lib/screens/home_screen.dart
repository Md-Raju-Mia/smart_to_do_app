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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TaskProvider>().loadTasks();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildAnalyticsCard(theme),
          _buildFilters(theme),
          Expanded(child: _buildTaskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToTaskDetail(context),
        icon: const Icon(Icons.add_task),
        label: const Text('Add Task'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final provider = context.watch<TaskProvider>();
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search tasks...',
                border: InputBorder.none,
              ),
              onChanged: (value) => context.read<TaskProvider>().setSearchQuery(value),
            )
          : const Text('Smart To-Do', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                context.read<TaskProvider>().setSearchQuery('');
              }
            });
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          onSelected: (value) => context.read<TaskProvider>().setSortBy(value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Due Date', child: Text('Sort by Due Date')),
            const PopupMenuItem(value: 'Priority', child: Text('Sort by Priority')),
          ],
        ),
        IconButton(
          icon: Icon(provider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          onPressed: () => context.read<TaskProvider>().toggleTheme(),
        ),
      ],
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
    );
  }

  Widget _buildAnalyticsCard(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daily Progress', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(
                    '${(provider.completionRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: provider.completionRate,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _analyticsItem(provider.completedTasksCount.toString(), 'Done'),
                  _analyticsItem((provider.tasks.length - provider.completedTasksCount).toString(), 'Pending'),
                  _analyticsItem(provider.tasks.length.toString(), 'Total'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _analyticsItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildFilters(ThemeData theme) {
    final filters = ['All', 'Today', 'Upcoming', 'Completed'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter, style: const TextStyle(fontSize: 13)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
              selectedColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final filteredTasks = provider.getFilteredTasks(_selectedFilter);
        if (filteredTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text('No tasks found!', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];
            return _buildTaskItem(task, provider);
          },
        );
      },
    );
  }

  Widget _buildTaskItem(Task task, TaskProvider provider) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(task.id.toString()),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => provider.deleteTask(task.id!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Checkbox(
            value: task.isCompleted,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) {
              provider.updateTask(task.copyWith(isCompleted: val ?? false));
            },
          ),
          title: Text(
            task.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: task.isCompleted ? Colors.grey : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.access_time, size: 12, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, hh:mm a').format(task.dueDate),
                style: TextStyle(fontSize: 11, color: theme.colorScheme.secondary),
              ),
            ],
          ),
          trailing: _priorityBadge(task.priority),
          onTap: () => _navigateToTaskDetail(context, task: task),
        ),
      ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _navigateToTaskDetail(BuildContext context, {Task? task}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
  }
}
