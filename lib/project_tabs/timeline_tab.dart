import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:backdrop/backdrop.dart';
import 'package:timelines/timelines.dart';

class TimelineTab extends StatefulWidget {
  final String projectName;

  const TimelineTab({required this.projectName, super.key});

  @override
  TimelineTabState createState() => TimelineTabState();
}

class TimelineTabState extends State<TimelineTab> {
  List<Map<String, String>> _events = [];
  final _eventTitleController = TextEditingController();
  final _eventDateController = TextEditingController();
  int? _editingIndex; // Keep track of the event being edited

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    final timelineBox = await Hive.openBox('timeline_${widget.projectName}');
    setState(() {
      _events = timelineBox.values.map((e) => Map<String, String>.from(e as Map)).toList();
    });
  }

  Future<void> _addOrEditEvent(String title, String date) async {
    final timelineBox = await Hive.openBox('timeline_${widget.projectName}');

    if (_editingIndex == null) {
      // Add a new event
      await timelineBox.add({'title': title, 'date': date});
    } else {
      // Edit an existing event
      await timelineBox.putAt(_editingIndex!, {'title': title, 'date': date});
      _editingIndex = null; // Reset after editing
    }

    _loadTimeline();
    _eventTitleController.clear();
    _eventDateController.clear();
  }

  void _editEvent(int index) {
    setState(() {
      _eventTitleController.text = _events[index]['title']!;
      _eventDateController.text = _events[index]['date']!;
      _editingIndex = index; // Track the index for editing
    });
  }

  Future<void> _deleteEvent(int index) async {
    final timelineBox = await Hive.openBox('timeline_${widget.projectName}');
    await timelineBox.deleteAt(index);
    _loadTimeline();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropScaffold(
      appBar: BackdropAppBar(
        title: const Text("Project Timeline",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
        backgroundColor: const Color(0xFF6750A4),
        leading: const BackdropToggleButton(
          color: Colors.white, // Toggle button color
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Leading icon color
        ),
      ),
      backLayer: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add or Edit Timeline Event',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _eventTitleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            TextFormField(
              controller: _eventDateController,
              decoration: const InputDecoration(
                labelText: 'Event Date (YYYY-MM-DD)',
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_eventTitleController.text.isNotEmpty && _eventDateController.text.isNotEmpty) {
                  _addOrEditEvent(_eventTitleController.text, _eventDateController.text);
                }
              },
              child: Text(_editingIndex == null ? 'Add Event' : 'Edit Event'),
            ),
          ],
        ),
      ),
      frontLayer: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _events.isEmpty
            ? const Center(child: Text('No events added yet.'))
            : Timeline.tileBuilder(
          builder: TimelineTileBuilder.connected(
            connectionDirection: ConnectionDirection.before,
            connectorBuilder: (context, index, type) => const SolidLineConnector(),
            indicatorBuilder: (context, index) => const OutlinedDotIndicator(),
            contentsAlign: ContentsAlign.alternating,
            contentsBuilder: (context, index) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _events[index]['title']!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _events[index]['date']!,
                      style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _editEvent(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => _deleteEvent(index),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            itemCount: _events.length,
          ),
        ),
      ),
    );
  }
}
