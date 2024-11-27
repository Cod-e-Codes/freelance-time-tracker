import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  AddProjectScreenState createState() => AddProjectScreenState();
}

class AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  double _hourlyRate = 0;
  DateTime _deadline = DateTime.now(); // The user-selected deadline
  String _clientEmail = '';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
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
                decoration: const InputDecoration(labelText: 'Client Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) => _clientEmail = value!,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Due Date: ${_deadline.toLocal()}'.split(' ')[0]),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Select date'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final newProject = Project(
                      name: _name,
                      hourlyRate: _hourlyRate,
                      deadline: _deadline,
                      clientEmail: _clientEmail,
                    );
                    Provider.of<ProjectProvider>(context, listen: false)
                        .addProject(newProject);  // Save to Hive
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Project'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
