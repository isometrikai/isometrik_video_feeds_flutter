import 'package:hive/hive.dart';

part 'local_event.g.dart'; // MUST match the file name

@HiveType(typeId: 0)
class LocalEvent {
  LocalEvent({
    required this.id,
    required this.payload,
    required this.timestamp,
  });

  @HiveField(0)
  String id; // unique identifier (UUID)

  @HiveField(1)
  Map<String, dynamic> payload; // flexible event data

  @HiveField(2)
  DateTime timestamp;
}
