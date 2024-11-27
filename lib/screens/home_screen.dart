import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import 'add_project_screen.dart';
import 'project_detail_screen.dart';
import 'edit_project_screen.dart';
import 'package:flutter/foundation.dart'; // For compute

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Freelance Time Tracker'),
      ),
      body: projectProvider.projects.isEmpty
          ? const Center(child: Text('No projects added yet!'))
          : ListView.builder(
        itemCount: projectProvider.projects.length,
        itemBuilder: (context, index) {
          Project project = projectProvider.projects[index];

          // Use FutureBuilder to offload the total hours calculation and progress calculation
          return FutureBuilder(
            future: Future.wait([
              _computeTotalLoggedHours(project), // Move heavy calculation off main thread
              _getProgress(project), // Load progress asynchronously
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading data'));
              }

              final totalHours = snapshot.data![0];
              final progress = snapshot.data![1];

              final String formattedDeadline = DateFormat('yyyy-MM-dd').format(project.deadline);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text('Due: $formattedDeadline'),
                            Text('Client: ${project.clientEmail}'),
                            const SizedBox(height: 8),
                            Text('Total Time Logged: $totalHours hours'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[300],
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProjectDetailScreen(project),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 16.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Details'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '\$${project.getTotalBill().toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProjectScreen(project: project),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                onPressed: () => _confirmDelete(context, projectProvider, project),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProjectScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Use the compute function to offload heavy calculations to a background isolate
  Future<double> _computeTotalLoggedHours(Project project) async {
    return await compute(_calculateTotalLoggedHours, project);
  }

  double _calculateTotalLoggedHours(Project project) {
    int totalSeconds = project.timeLogs.fold(0, (sum, log) => sum + log.getDuration().inSeconds);
    return totalSeconds / 3600;
  }

  Future<double> _getProgress(Project project) async {
    final String boxName = 'goals_${project.name}';
    Box goalBox = await Hive.openBox(boxName); // Open the box asynchronously

    final totalGoals = goalBox.length;
    if (totalGoals == 0) return 0.0;

    final completedGoals = goalBox.values.where((goal) => goal['completed'] == true).length;
    return completedGoals / totalGoals;
  }

  void _confirmDelete(BuildContext context, ProjectProvider provider, Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeProject(project);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
