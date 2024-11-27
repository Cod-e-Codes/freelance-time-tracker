import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:backdrop/backdrop.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';

class GoalsTab extends StatefulWidget {
  final Project project;

  const GoalsTab({required this.project, super.key});

  @override
  GoalsTabState createState() => GoalsTabState();
}

class GoalsTabState extends State<GoalsTab> {
  List<Map<String, dynamic>> _goals = [];
  final _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goalBox = await Hive.openBox('goals_${widget.project.name}');
    if (!mounted) return;  // Prevent accessing context if the widget is not mounted anymore
    setState(() {
      _goals = goalBox.values.map((goal) {
        if (goal is String) {
          return {'goal': goal, 'completed': false};
        } else {
          return Map<String, dynamic>.from(goal as Map);
        }
      }).toList();
    });
  }

  Future<void> _addGoal(String goal) async {
    final goalBox = await Hive.openBox('goals_${widget.project.name}');
    final newGoal = {'goal': goal, 'completed': false};
    await goalBox.add(newGoal);
    if (!mounted) return;
    _loadGoals();
    _goalController.clear();

    // Notify project provider to update the progress
    if (mounted) {
      Provider.of<ProjectProvider>(context, listen: false).updateProject(widget.project);
    }
  }

  Future<void> _toggleGoalCompletion(int index) async {
    final goalBox = await Hive.openBox('goals_${widget.project.name}');
    _goals[index]['completed'] = !_goals[index]['completed'];
    await goalBox.putAt(index, _goals[index]);
    if (!mounted) return;
    _loadGoals();

    // Notify project provider to update the progress
    if (mounted) {
      Provider.of<ProjectProvider>(context, listen: false).updateProject(widget.project);
    }
  }

  Future<void> _deleteGoal(int index) async {
    final goalBox = await Hive.openBox('goals_${widget.project.name}');
    await goalBox.deleteAt(index);
    if (!mounted) return;
    _loadGoals();

    // Notify project provider to update the progress
    if (mounted) {
      Provider.of<ProjectProvider>(context, listen: false).updateProject(widget.project);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropScaffold(
      appBar: BackdropAppBar(
        title: const Text("Project Goals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF6750A4),
        leading: const BackdropToggleButton(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backLayer: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _goalController,
              decoration: const InputDecoration(labelText: 'Goal', labelStyle: TextStyle(color: Colors.white)),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_goalController.text.isNotEmpty) {
                  _addGoal(_goalController.text);
                }
              },
              child: const Text('Add Goal'),
            ),
          ],
        ),
      ),
      frontLayer: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _goals.isEmpty
            ? const Center(child: Text('No goals added yet.'))
            : ListView.builder(
          itemCount: _goals.length,
          itemBuilder: (context, index) {
            final goal = _goals[index];
            final isCompleted = goal['completed'] as bool;
            return ListTile(
              title: Text(
                goal['goal'],
                style: TextStyle(
                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  color: isCompleted ? Colors.grey : Colors.black,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isCompleted ? Colors.green[300] : Colors.grey,
                    ),
                    onPressed: () => _toggleGoalCompletion(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => _deleteGoal(index),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
