import 'package:hive/hive.dart';

part 'local_event.g.dart'; // MUST match the file name

@HiveType(typeId: 0)
class LocalEvent {
  LocalEvent({
    required this.id,
    required this.eventName,
    required this.payload,
    required this.timestamp,
  });

  @HiveField(0)
  String id; // unique identifier (UUID)

  @HiveField(1)
  String eventName; // event name

  @HiveField(2)
  Map<String, dynamic> payload; // flexible event data

  @HiveField(3)
  DateTime timestamp;
}
