import 'package:flutter/foundation.dart'; // For compute
import 'package:hive/hive.dart';
import '../models/project.dart';

class ProjectProvider with ChangeNotifier {
  List<Project> _projects = [];
  late Box<Project> _projectBox;

  List<Project> get projects => _projects;

  // Load projects from Hive and move the heavy operation to a background isolate
  Future<void> loadProjects() async {
    _projectBox = await Hive.openBox<Project>('projects');

    // Offload conversion of Hive values to list using compute
    _projects = await compute(_getProjectsListFromBox, _projectBox.values.toList());

    notifyListeners();
  }

  // Add a project
  Future<void> addProject(Project project) async {
    _projects.add(project);
    await _projectBox.put(project.name, project);
    notifyListeners();
  }

  // Update a project
  Future<void> updateProject(Project project) async {
    await _projectBox.put(project.name, project);
    notifyListeners();
  }

  // Remove a project
  Future<void> removeProject(Project project) async {
    _projects.remove(project);
    await _projectBox.delete(project.name);
    notifyListeners();
  }
}

// Helper function to move list conversion to a background isolate
List<Project> _getProjectsListFromBox(List<Project> projectList) {
  return projectList; // In case of heavy transformation, it can be handled here
}
