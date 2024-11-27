import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import '../models/project.dart';

class ProjectDetailsTab extends StatelessWidget {
  final Project project;

  const ProjectDetailsTab({required this.project, super.key});

  @override
  Widget build(BuildContext context) {
    // Format the deadline date using DateFormat from intl package
    final String formattedDeadline = DateFormat('yyyy-MM-dd').format(project.deadline);

    // Calculate the total logged hours
    final double totalLoggedHours = _getTotalLoggedHours(project);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project Name: ${project.name}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Hourly Rate: \$${project.hourlyRate.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Text('Client Email: ${project.clientEmail}'),
          const SizedBox(height: 8),
          Text('Due Date: $formattedDeadline'), // Display formatted deadline
          const SizedBox(height: 8),
          Text('Total Time Logged: $totalLoggedHours hours'), // Display total logged hours
        ],
      ),
    );
  }

  // Function to calculate total logged hours from time logs
  double _getTotalLoggedHours(Project project) {
    int totalSeconds = project.timeLogs.fold(0, (sum, log) => sum + log.getDuration().inSeconds);
    return totalSeconds / 3600;  // Convert total seconds to hours
  }
}
