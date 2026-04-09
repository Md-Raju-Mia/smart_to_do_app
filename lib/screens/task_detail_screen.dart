import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task? task;
  const TaskDetailScreen({super.key, this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late Priority _priority;
  late DateTime _dueDate;
  late bool _reminderActive;

  @override
  void initState() {
    super.initState();
    _title = widget.task?.title ?? '';
    _description = widget.task?.description ?? '';
    _priority = widget.task?.priority ?? Priority.medium;
    _dueDate = widget.task?.dueDate ?? DateTime.now().add(const Duration(hours: 1));
    _reminderActive = widget.task?.reminderActive ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
              onSaved: (val) => _title = val!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
              onSaved: (val) => _description = val ?? '',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
              items: Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
              onChanged: (val) => setState(() => _priority = val!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Due Date & Time'),
              subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(_dueDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDateTime,
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
            ),
            SwitchListTile(
              title: const Text('Set Reminder'),
              value: _reminderActive,
              onChanged: (val) => setState(() => _reminderActive = val),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Save Task'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );
      if (time != null) {
        setState(() {
          _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final task = Task(
        id: widget.task?.id,
        title: _title,
        description: _description,
        priority: _priority,
        dueDate: _dueDate,
        isCompleted: widget.task?.isCompleted ?? false,
        reminderActive: _reminderActive,
      );

      final provider = Provider.of<TaskProvider>(context, listen: false);
      if (widget.task == null) {
        provider.addTask(task);
      } else {
        provider.updateTask(task);
      }
      
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}
