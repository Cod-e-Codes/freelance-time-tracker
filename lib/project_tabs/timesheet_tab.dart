import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:backdrop/backdrop.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../models/time_log.dart';
import '../providers/project_provider.dart';

class TimesheetTab extends StatefulWidget {
  final Project project;

  const TimesheetTab({required this.project, super.key});

  @override
  TimesheetTabState createState() => TimesheetTabState();
}

class TimesheetTabState extends State<TimesheetTab> {
  DateTime? _selectedStartTime;
  DateTime? _selectedEndTime;
  final TextEditingController _titleController = TextEditingController(); // Controller for title input

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStartTime}) async {
    DateTime now = DateTime.now();

    if (!mounted) return;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );

      if (pickedTime != null && mounted) {
        final fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStartTime) {
            _selectedStartTime = fullDateTime;
          } else {
            _selectedEndTime = fullDateTime;
          }
        });
      }
    }
  }

  Future<void> _addTimeLog() async {
    if (_selectedStartTime != null && _selectedEndTime != null && _selectedEndTime!.isAfter(_selectedStartTime!) && _titleController.text.isNotEmpty) {
      widget.project.addTimeLog(TimeLog(
        startTime: _selectedStartTime!,
        endTime: _selectedEndTime!,
        title: _titleController.text, // Add title here
      ));

      if (mounted) {
        Provider.of<ProjectProvider>(context, listen: false).updateProject(widget.project);

        setState(() {
          _selectedStartTime = null;
          _selectedEndTime = null;
          _titleController.clear(); // Clear title input after adding the log
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields and select valid times.')),
        );
      }
    }
  }

  void _deleteTimeLog(int index) {
    setState(() {
      widget.project.timeLogs.removeAt(index);
      Provider.of<ProjectProvider>(context, listen: false).updateProject(widget.project);
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Select Time';
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropScaffold(
      appBar: BackdropAppBar(
        title: const Text(
          "Project Timesheet",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6750A4),
        leading: const BackdropToggleButton(
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      backLayer: SingleChildScrollView( // Wrap in SingleChildScrollView to avoid overflow
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Time Log',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController, // Title input field
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.white),
                hintText: 'Enter a title for the time log',
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text(
                'Start Time',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                _formatDateTime(_selectedStartTime),
                style: const TextStyle(color: Colors.white),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                onPressed: () => _pickDateTime(isStartTime: true),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text(
                'End Time',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                _formatDateTime(_selectedEndTime),
                style: const TextStyle(color: Colors.white),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                onPressed: () => _pickDateTime(isStartTime: false),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addTimeLog,
              child: const Text('Add Time Log'),
            ),
          ],
        ),
      ),
      frontLayer: Padding(
        padding: const EdgeInsets.all(16.0),
        child: widget.project.timeLogs.isEmpty
            ? const Center(child: Text('No time logs added yet.'))
            : ListView.builder(
          itemCount: widget.project.timeLogs.length,
          itemBuilder: (context, index) {
            final log = widget.project.timeLogs[index];
            final duration = log.getDuration();
            return ListTile(
              title: Text(
                'Title: ${log.title}\nStart: ${_formatDateTime(log.startTime)} - End: ${_formatDateTime(log.endTime)}',
                style: const TextStyle(color: Colors.black),
              ),
              subtitle: Text(
                'Duration: ${duration.inHours} hours and ${duration.inMinutes % 60} minutes',
                style: const TextStyle(color: Colors.black),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () => _deleteTimeLog(index),
              ),
            );
          },
        ),
      ),
    );
  }
}
