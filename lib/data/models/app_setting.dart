import 'package:isar/isar.dart';

part 'app_setting.g.dart';

@collection
class AppSetting {
  AppSetting({
    this.id = Isar.autoIncrement,
    this.userName,
    this.gasWebhookUrl,
    this.spreadsheetId,
    this.defaultCurrency,
    this.defaultBuyFeePercent = 0,
    this.defaultSellFeePercent = 0,
    this.biometricEnabled = true,
    this.lastLocalBackupAt,
    this.lastSpreadsheetSyncAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Id id;
  String? userName;
  String? gasWebhookUrl;
  String? spreadsheetId;
  String? defaultCurrency;
  double defaultBuyFeePercent;
  double defaultSellFeePercent;
  bool biometricEnabled;
  DateTime? lastLocalBackupAt;
  DateTime? lastSpreadsheetSyncAt;
  DateTime createdAt;
  DateTime updatedAt;
}
