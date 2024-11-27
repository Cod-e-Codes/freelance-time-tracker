import 'package:hive/hive.dart';
import 'time_log.dart';  // Import the TimeLog class

part 'project.g.dart';

@HiveType(typeId: 0)
class Project {
  @HiveField(0)
  String name;

  @HiveField(1)
  double hourlyRate;

  @HiveField(2)
  DateTime deadline;

  @HiveField(3)
  int totalTimeInSeconds;  // Store total time in seconds

  @HiveField(4)
  String clientEmail;

  @HiveField(5)
  List<TimeLog> timeLogs;  // Store time logs for this project

  Project({
    required this.name,
    required this.hourlyRate,
    required this.deadline,
    required this.clientEmail,
    this.totalTimeInSeconds = 0,
    this.timeLogs = const [],
  });

  // Get the total duration of the project
  Duration getTotalDuration() {
    return Duration(seconds: totalTimeInSeconds);
  }

  // Calculate the total bill for the project
  double getTotalBill() {
    return hourlyRate * totalTimeInSeconds / 3600;
  }

  // Add a new time log and update the total time
  void addTimeLog(TimeLog timeLog) {
    timeLogs.add(timeLog);
    totalTimeInSeconds += timeLog.getDuration().inSeconds;
  }
}
