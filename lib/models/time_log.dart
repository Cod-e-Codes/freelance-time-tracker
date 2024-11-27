import 'package:hive/hive.dart';

part 'time_log.g.dart';

@HiveType(typeId: 1)
class TimeLog {
  @HiveField(0)
  DateTime startTime;

  @HiveField(1)
  DateTime endTime;

  @HiveField(2)
  String? title; // Make title nullable

  TimeLog({
    required this.startTime,
    required this.endTime,
    this.title, // Make the title optional
  });

  // Calculate the duration between startTime and endTime
  Duration getDuration() {
    return endTime.difference(startTime);
  }
}


