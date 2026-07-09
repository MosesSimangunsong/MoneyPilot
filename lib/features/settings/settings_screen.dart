import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/app_setting.dart';
import '../../data/repositories/app_setting_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/services/spreadsheet_sync_service.dart';
import '../../shared/widgets/sync_status_indicator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.appSettingRepository,
    required this.syncRepository,
  });

  final AppSettingRepository appSettingRepository;
  final SyncRepository syncRepository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSyncing = false;
  bool _obscureToken = true;
  String? _status;
  String? _statusMessage;
  DateTime? _lastSyncAt;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xxl,
                  ),
                  children: <Widget>[
                    Text(
                      'Hubungkan MoneyPilot ke Google Spreadsheet untuk backup dan edit ringan.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_status != null)
                      Row(
                        children: <Widget>[
                          SyncStatusIndicator(status: _status ?? 'belum'),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              _statusMessage ?? 'Belum ada status sync.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    if (_status != null) const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _urlController,
                      enabled: !_isSaving && !_isSyncing,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Google Apps Script Web App URL',
                        hintText: 'https://script.google.com/macros/s/.../exec',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'URL Web App wajib diisi.';
                        }
                        final Uri? uri = Uri.tryParse(value.trim());
                        if (uri == null ||
                            !uri.hasScheme ||
                            !uri.hasAuthority) {
                          return 'URL Web App tidak valid.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _tokenController,
                      enabled: !_isSaving && !_isSyncing,
                      obscureText: _obscureToken,
                      decoration: InputDecoration(
                        labelText: 'Secret token',
                        hintText: 'Masukkan token rahasia Apps Script',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureToken = !_obscureToken;
                            });
                          },
                          icon: Icon(
                            _obscureToken
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Secret token wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _MetadataCard(
                      lastSyncAt: _lastSyncAt,
                      statusMessage: _statusMessage,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _isSaving || _isSyncing ? null : _saveSettings,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          _isSaving ? 'Menyimpan...' : 'Simpan konfigurasi',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: _isSaving || _isSyncing ? null : _runSync,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          _isSyncing
                              ? 'Menjalankan sync...'
                              : 'Jalankan sync manual',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _loadSettings() async {
    final AppSetting settings = await widget.appSettingRepository
        .getOrCreateSettings();
    if (!mounted) {
      return;
    }

    setState(() {
      _urlController.text = settings.gasWebhookUrl ?? '';
      _tokenController.text = settings.gasSecretToken ?? '';
      _status = settings.lastSpreadsheetSyncStatus;
      _statusMessage = settings.lastSpreadsheetSyncMessage;
      _lastSyncAt = settings.lastSpreadsheetSyncAt;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final AppSetting savedSettings = await widget.appSettingRepository
          .updateSpreadsheetConfig(
            gasWebhookUrl: _urlController.text,
            gasSecretToken: _tokenController.text,
          );

      _urlController.text = savedSettings.gasWebhookUrl ?? '';
      _tokenController.text = savedSettings.gasSecretToken ?? '';
      debugPrint(
        'SettingsScreen: konfigurasi sync disimpan untuk url=${savedSettings.gasWebhookUrl ?? '-'}',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfigurasi sync berhasil disimpan.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _runSync() async {
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      final AppSetting savedSettings = await widget.appSettingRepository
          .updateSpreadsheetConfig(
            gasWebhookUrl: _urlController.text,
            gasSecretToken: _tokenController.text,
          );
      _urlController.text = savedSettings.gasWebhookUrl ?? '';
      _tokenController.text = savedSettings.gasSecretToken ?? '';
      debugPrint(
        'SettingsScreen: jalankan sync manual menggunakan url=${savedSettings.gasWebhookUrl ?? '-'}',
      );

      final SyncRunSummary summary = await widget.syncRepository.syncNow();

      if (!mounted) {
        return;
      }

      setState(() {
        _status = summary.status;
        _statusMessage = summary.message;
        _lastSyncAt = summary.completedAt;
      });

      final String summaryText =
          'Push kategori ${summary.pushedCategories}, transaksi ${summary.pushedTransactions}, saham ${summary.pushedStockTransactions}, dividen ${summary.pushedDividends}. Pull kategori ${summary.pulledCategories}, transaksi ${summary.pulledTransactions}, saham ${summary.pulledStockTransactions}, dividen ${summary.pulledDividends}.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            summary.status == 'success'
                ? 'Sync selesai. $summaryText'
                : summary.message,
          ),
          backgroundColor: summary.status == 'success'
              ? null
              : Theme.of(context).colorScheme.error,
        ),
      );
    } on SpreadsheetSyncException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'failed';
        _statusMessage = error.message;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'failed';
        _statusMessage = error.message;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.lastSyncAt, required this.statusMessage});

  final DateTime? lastSyncAt;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Metadata sync', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            lastSyncAt == null
                ? 'Sync terakhir: belum pernah'
                : 'Sync terakhir: ${DateFormatter.formatDateTime(lastSyncAt!)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (statusMessage != null &&
              statusMessage!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              statusMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
