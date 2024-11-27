import 'package:flutter/material.dart';
import 'edit_project_screen.dart';  // Make sure to import the EditProjectScreen
import '../models/project.dart';
import '../project_tabs/details_tab.dart';
import '../project_tabs/documents_tab.dart';
import '../project_tabs/goals_tab.dart';
import '../project_tabs/timeline_tab.dart';
import '../project_tabs/timesheet_tab.dart';
import '../project_tabs/invoice_tab.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen(this.project, {super.key});

  @override
  ProjectDetailScreenState createState() => ProjectDetailScreenState();
}

class ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to the EditProjectScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProjectScreen(project: widget.project), // Ensure that the project is passed
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          indicatorColor: Colors.grey,
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Documents'),
            Tab(text: 'Goals'),
            Tab(text: 'Timeline'),
            Tab(text: 'Timesheet'),
            Tab(text: 'Invoices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProjectDetailsTab(project: widget.project),  // Displays project details
          const DocumentsTab(),  // Handles document uploads
          GoalsTab(project: widget.project),  // Manages project goals
          TimelineTab(projectName: widget.project.name),  // Pass the project name here
          TimesheetTab(project: widget.project),  // Shows timesheet/logs
          InvoiceTab(project: widget.project),  // Displays invoices
        ],
      ),
    );
  }
}
