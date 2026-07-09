import 'dart:developer' as developer;

import 'package:isar/isar.dart';

import '../../core/utils/date_time_utils.dart';
import '../models/app_setting.dart';

class AppSettingRepository {
  AppSettingRepository(this._isar);

  final Isar _isar;

  Stream<void> watchSettings() {
    return _isar.appSettings.watchLazy(fireImmediately: true);
  }

  Future<AppSetting> getOrCreateSettings() async {
    final AppSetting? existing = await _isar.appSettings.where().findFirst();
    if (existing != null) {
      return _normalizeSettingDates(existing);
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

    return _normalizeSettingDates(setting);
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
    String? gasSecretToken,
    String? spreadsheetId,
    String? defaultCurrency,
  }) async {
    final AppSetting setting = await getOrCreateSettings();
    setting.gasWebhookUrl = _normalizeWebhookUrl(gasWebhookUrl);
    setting.gasSecretToken = _normalizeSecretToken(gasSecretToken);
    setting.spreadsheetId = _normalizeNullable(spreadsheetId);
    setting.defaultCurrency = _normalizeNullable(defaultCurrency) ?? 'IDR';
    setting.updatedAt = DateTimeUtils.utcNow();
    await _save(setting);
    developer.log(
      'Spreadsheet config saved. url=${setting.gasWebhookUrl ?? '-'} tokenSaved=${setting.gasSecretToken?.isNotEmpty == true}',
      name: 'AppSettingRepository',
    );
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

  Future<void> updateSpreadsheetPullAt(DateTime? value) async {
    final AppSetting setting = await getOrCreateSettings();
    setting.lastSpreadsheetPullAt = value == null
        ? null
        : DateTimeUtils.normalizeUtc(value);
    setting.updatedAt = DateTimeUtils.utcNow();
    await _save(setting);
  }

  Future<void> updateSpreadsheetSyncState({
    DateTime? lastSpreadsheetSyncAt,
    DateTime? lastSpreadsheetPullAt,
    String? status,
    String? message,
  }) async {
    final AppSetting setting = await getOrCreateSettings();
    setting.lastSpreadsheetSyncAt = lastSpreadsheetSyncAt == null
        ? setting.lastSpreadsheetSyncAt
        : DateTimeUtils.normalizeUtc(lastSpreadsheetSyncAt);
    setting.lastSpreadsheetPullAt = lastSpreadsheetPullAt == null
        ? setting.lastSpreadsheetPullAt
        : DateTimeUtils.normalizeUtc(lastSpreadsheetPullAt);
    setting.lastSpreadsheetSyncStatus = _normalizeNullable(status);
    setting.lastSpreadsheetSyncMessage = _normalizeNullable(message);
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
    _normalizeSettingDates(setting);
    await _isar.writeTxn(() async {
      await _isar.appSettings.put(setting);
    });
  }

  AppSetting _normalizeSettingDates(AppSetting setting) {
    setting.createdAt = DateTimeUtils.normalizeUtc(setting.createdAt);
    setting.updatedAt = DateTimeUtils.normalizeUtc(setting.updatedAt);
    if (setting.lastLocalBackupAt != null) {
      setting.lastLocalBackupAt = DateTimeUtils.normalizeUtc(
        setting.lastLocalBackupAt!,
      );
    }
    if (setting.lastSpreadsheetSyncAt != null) {
      setting.lastSpreadsheetSyncAt = DateTimeUtils.normalizeUtc(
        setting.lastSpreadsheetSyncAt!,
      );
    }
    if (setting.lastSpreadsheetPullAt != null) {
      setting.lastSpreadsheetPullAt = DateTimeUtils.normalizeUtc(
        setting.lastSpreadsheetPullAt!,
      );
    }
    return setting;
  }

  String? _normalizeNullable(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String? _normalizeWebhookUrl(String? value) {
    final String? compact = value
        ?.replaceAll(RegExp(r'[\r\n\t]'), '')
        .trim();
    if (compact == null || compact.isEmpty) {
      return null;
    }
    return compact;
  }

  String? _normalizeSecretToken(String? value) {
    final String? compact = value
        ?.replaceAll(RegExp(r'[\r\n\t]'), '')
        .trim();
    if (compact == null || compact.isEmpty) {
      return null;
    }
    return compact;
  }
}
