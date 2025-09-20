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
  State<AddTaskForm> createState() => _AddTaskFormState();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                widget.initialTitle != null ? 'Edit Task' : 'Add Task',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                child: TextFormField(
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    hintText: 'Task Title',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
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
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    hintText: 'Task Description',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  controller: _descriptionController,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                child: InkWell(
                  onTap: _selectDueDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: 'Due Date (optional)',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedDueDate != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDueDate = null;
                                });
                              },
                              child: const Icon(Icons.clear,
                                  color: Colors.white, size: 20),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today, color: Colors.white),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                    child: Text(
                      _selectedDueDate == null
                          ? 'Select Due Date'
                          : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                      style: TextStyle(
                        color: _selectedDueDate == null
                            ? Colors.grey
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              DropdownButtonFormField<int>(
                value: _selectedPriority,
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.grey.shade800,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Priority',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                items: List.generate(5, (index) {
                  return DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text('${index + 1}',
                        style: const TextStyle(color: Colors.white)),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
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
              ),
            ],
          ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
              secondary: Colors.white,
              onSecondary: Colors.black,
              surfaceVariant: Colors.black,
              onSurfaceVariant: Colors.white,
              outline: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
            canvasColor: Colors.black,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }
}
