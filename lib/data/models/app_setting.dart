import 'package:isar/isar.dart';

part 'app_setting.g.dart';

@collection
class AppSetting {
  AppSetting({
    this.id = Isar.autoIncrement,
    this.userName,
    this.gasWebhookUrl,
    this.gasSecretToken,
    this.spreadsheetId,
    this.defaultCurrency,
    this.defaultBuyFeePercent = 0,
    this.defaultSellFeePercent = 0,
    this.biometricEnabled = true,
    this.lastLocalBackupAt,
    this.lastSpreadsheetSyncAt,
    this.lastSpreadsheetPullAt,
    this.lastSpreadsheetSyncStatus,
    this.lastSpreadsheetSyncMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  Id id;
  String? userName;
  String? gasWebhookUrl;
  String? gasSecretToken;
  String? spreadsheetId;
  String? defaultCurrency;
  double defaultBuyFeePercent;
  double defaultSellFeePercent;
  bool biometricEnabled;
  DateTime? lastLocalBackupAt;
  DateTime? lastSpreadsheetSyncAt;
  DateTime? lastSpreadsheetPullAt;
  String? lastSpreadsheetSyncStatus;
  String? lastSpreadsheetSyncMessage;
  DateTime createdAt;
  DateTime updatedAt;
}
