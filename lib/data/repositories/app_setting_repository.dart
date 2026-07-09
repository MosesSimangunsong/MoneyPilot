import 'package:isar/isar.dart';

import '../../core/utils/date_time_utils.dart';
import '../models/app_setting.dart';

class AppSettingRepository {
  AppSettingRepository(this._isar);

  final Isar _isar;

  Future<AppSetting> getOrCreateSettings() async {
    final AppSetting? existing = await _isar.appSettings.where().findFirst();
    if (existing != null) {
      return existing;
    }

    final DateTime now = DateTimeUtils.utcNow();
    final AppSetting setting = AppSetting(
      createdAt: now,
      updatedAt: now,
      defaultCurrency: 'IDR',
      defaultBuyFeePercent: 0.15,
      defaultSellFeePercent: 0.25,
    );

    await _isar.writeTxn(() async {
      await _isar.appSettings.put(setting);
    });

    return setting;
  }

  Future<AppSetting> updateUserName(String? userName) async {
    final AppSetting setting = await getOrCreateSettings();
    setting.userName = _normalizeNullable(userName);
    setting.updatedAt = DateTimeUtils.utcNow();
    await _save(setting);
    return setting;
  }

  Future<AppSetting> updateBiometricEnabled(bool enabled) async {
    final AppSetting setting = await getOrCreateSettings();
    setting.biometricEnabled = enabled;
    setting.updatedAt = DateTimeUtils.utcNow();
    await _save(setting);
    return setting;
  }

  Future<AppSetting> updateSpreadsheetConfig({
    String? gasWebhookUrl,
    String? spreadsheetId,
    String? defaultCurrency,
  }) async {
    final AppSetting setting = await getOrCreateSettings();
    setting.gasWebhookUrl = _normalizeNullable(gasWebhookUrl);
    setting.spreadsheetId = _normalizeNullable(spreadsheetId);
    setting.defaultCurrency = _normalizeNullable(defaultCurrency) ?? 'IDR';
    setting.updatedAt = DateTimeUtils.utcNow();
    await _save(setting);
    return setting;
  }

  Future<AppSetting> updateDefaultFees({
    required double defaultBuyFeePercent,
    required double defaultSellFeePercent,
  }) async {
    final AppSetting setting = await getOrCreateSettings();
    setting.defaultBuyFeePercent = defaultBuyFeePercent;
    setting.defaultSellFeePercent = defaultSellFeePercent;
    setting.updatedAt = DateTimeUtils.utcNow();
    await _save(setting);
    return setting;
  }

  Future<void> updateLastLocalBackupAt(DateTime? value) async {
    final AppSetting setting = await getOrCreateSettings();
    setting.lastLocalBackupAt = value == null
        ? null
        : DateTimeUtils.normalizeUtc(value);
    setting.updatedAt = DateTimeUtils.utcNow();
    await _save(setting);
  }

  Future<void> updateLastSpreadsheetSyncAt(DateTime? value) async {
    final AppSetting setting = await getOrCreateSettings();
    setting.lastSpreadsheetSyncAt = value == null
        ? null
        : DateTimeUtils.normalizeUtc(value);
    setting.updatedAt = DateTimeUtils.utcNow();
    await _save(setting);
  }

  Future<void> ensureSeeded({
    required String userName,
    required bool biometricEnabled,
  }) async {
    final AppSetting setting = await getOrCreateSettings();
    var changed = false;

    if (setting.userName != userName) {
      setting.userName = userName;
      changed = true;
    }

    if (setting.biometricEnabled != biometricEnabled) {
      setting.biometricEnabled = biometricEnabled;
      changed = true;
    }

    if (!changed) {
      return;
    }

    setting.updatedAt = DateTimeUtils.utcNow();
    await _save(setting);
  }

  Future<void> _save(AppSetting setting) async {
    await _isar.writeTxn(() async {
      await _isar.appSettings.put(setting);
    });
  }

  String? _normalizeNullable(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
