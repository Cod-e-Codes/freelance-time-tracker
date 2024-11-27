import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import '../models/project.dart';
import '../providers/project_provider.dart';

class EditProjectScreen extends StatefulWidget {
  final Project project;

  const EditProjectScreen({required this.project, super.key});

  @override
  EditProjectScreenState createState() => EditProjectScreenState();
}

class EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _hourlyRate;
  late DateTime _deadline;
  late String _clientEmail;

  @override
  void initState() {
    super.initState();
    _name = widget.project.name;
    _hourlyRate = widget.project.hourlyRate;
    _deadline = widget.project.deadline;
    _clientEmail = widget.project.clientEmail;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format the selected or default deadline date using DateFormat
    final String formattedDeadline = DateFormat('yyyy-MM-dd').format(_deadline);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Project Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _hourlyRate.toString(),
                decoration: const InputDecoration(labelText: 'Hourly Rate'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Please enter a valid hourly rate';
                  }
                  return null;
                },
                onSaved: (value) => _hourlyRate = double.parse(value!),
              ),
              TextFormField(
                initialValue: _clientEmail,
                decoration: const InputDecoration(labelText: 'Client Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) => _clientEmail = value!,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Display the selected or default due date
                  Text('Due Date: $formattedDeadline'),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Select date'),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final updatedProject = Project(
                      name: _name,
                      hourlyRate: _hourlyRate,
                      deadline: _deadline,
                      clientEmail: _clientEmail,
                      totalTimeInSeconds: widget.project.totalTimeInSeconds,
                    );
                    // Update the project in the provider
                    Provider.of<ProjectProvider>(context, listen: false)
                        .addProject(updatedProject);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Update Project'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
