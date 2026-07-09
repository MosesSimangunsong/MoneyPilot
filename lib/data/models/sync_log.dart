import 'package:isar/isar.dart';

part 'sync_log.g.dart';

@collection
class SyncLog {
  SyncLog({
    this.id = Isar.autoIncrement,
    required this.uuid,
    required this.entityType,
    required this.entityUuid,
    required this.action,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    this.syncedAt,
  });

  Id id;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String entityType;

  @Index()
  late String entityUuid;

  @Index()
  late String action;

  @Index()
  late String status;

  String? errorMessage;

  @Index()
  late DateTime createdAt;

  DateTime? syncedAt;
}
