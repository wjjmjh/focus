import 'package:flutter/material.dart';

class AddTaskForm extends StatefulWidget {
  final Function(String, String, int, DateTime?) addTaskHandler;
  final String? initialTitle;
  final String? initialDescription;
  final int? initialPriority;
  final DateTime? initialDueDate;

  const AddTaskForm({
    super.key,
    required this.addTaskHandler,
    this.initialTitle,
    this.initialDescription,
    this.initialPriority,
    this.initialDueDate,
  });

  @override
  _AddTaskFormState createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<AddTaskForm> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late int _selectedPriority;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _selectedPriority = widget.initialPriority ?? 3; // Default priority
    _selectedDueDate = widget.initialDueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(20)),
      child: Form(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              widget.initialTitle != null ? 'Edit Task' : 'Add Task',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              child: TextFormField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                controller: _titleController,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              child: TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Task Description',
                  border: OutlineInputBorder(),
                ),
                controller: _descriptionController,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              child: InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    hintText: 'Due Date (optional)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDueDate == null
                        ? 'Select due date'
                        : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                    style: TextStyle(
                      color:
                          _selectedDueDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            DropdownButtonFormField<int>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Priority',
              ),
              items: List.generate(5, (index) {
                return DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text('${index + 1}'),
                );
              }),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  widget.addTaskHandler(
                    _titleController.text.trim(),
                    _descriptionController.text.trim(),
                    _selectedPriority,
                    _selectedDueDate,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text(widget.initialTitle != null ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }
}
