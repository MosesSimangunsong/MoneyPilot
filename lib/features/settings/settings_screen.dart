import 'package:flutter/material.dart';

import '../../core/session/app_session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/app_setting.dart';
import '../../data/models/category.dart';
import '../../data/models/dividend.dart';
import '../../data/models/money_transaction.dart';
import '../../data/models/stock_transaction.dart';
import '../../data/models/watchlist_item.dart';
import '../../data/repositories/app_setting_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/local_data_maintenance_repository.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/services/backend_status_service.dart';
import '../../data/services/biometric_service.dart';
import '../../data/services/csv_export_service.dart';
import '../../data/services/spreadsheet_sync_service.dart';
import '../../shared/widgets/sync_status_indicator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.appSettingRepository,
    required this.categoryRepository,
    required this.localDataMaintenanceRepository,
    required this.portfolioRepository,
    required this.sessionController,
    required this.syncRepository,
    required this.transactionRepository,
  });

  final AppSettingRepository appSettingRepository;
  final CategoryRepository categoryRepository;
  final LocalDataMaintenanceRepository localDataMaintenanceRepository;
  final PortfolioRepository portfolioRepository;
  final AppSessionController sessionController;
  final SyncRepository syncRepository;
  final TransactionRepository transactionRepository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final BackendStatusService _backendStatusService = BackendStatusService();
  final BiometricService _biometricService = BiometricService();
  final CsvExportService _csvExportService = const CsvExportService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSyncing = false;
  bool _isExporting = false;
  bool _isResetting = false;
  bool _obscureToken = true;
  bool _biometricAvailable = false;
  bool _backendConnected = false;
  String? _backendMessage;
  String? _status;
  String? _statusMessage;
  DateTime? _lastSyncAt;
  DateTime? _lastBackupAt;
  DateTime? _backendServerTime;
  int _pendingCount = 0;

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
      appBar: AppBar(title: const Text('Pengaturan')),
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
                      'Kelola sinkronisasi, keamanan, export data, dan informasi privasi MoneyPilot dari satu tempat.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionCard(
                      title: 'Keamanan',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _KeyValueRow(
                            label: 'Status biometric',
                            value: _biometricAvailable
                                ? (widget.sessionController.biometricEnabled
                                      ? 'Aktif'
                                      : 'Nonaktif')
                                : 'Perangkat belum mendukung',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _biometricAvailable
                                ? 'Biometric diatur dari onboarding dan dipakai untuk mengunci aplikasi sesuai pengaturan user.'
                                : 'Perangkat ini belum mendukung biometric, jadi aplikasi tetap memakai akses lokal tanpa kunci biometric.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      title: 'Status Backend',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              SyncStatusIndicator(
                                status: _backendConnected
                                    ? 'success'
                                    : 'failed',
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  _backendMessage ??
                                      'Status backend belum diperiksa.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          if (_backendServerTime != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Waktu server: ${DateFormatter.formatDateTime(_backendServerTime!)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton(
                            onPressed: _loadBackendStatus,
                            child: const Text('Periksa Ulang Backend'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      title: 'Google Spreadsheet Sync',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (_status != null)
                            Row(
                              children: <Widget>[
                                SyncStatusIndicator(status: _status ?? 'belum'),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    _statusMessage ?? 'Belum ada status sync.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          if (_status != null)
                            const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _urlController,
                            enabled: !_isSaving && !_isSyncing,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: 'Google Apps Script Web App URL',
                              hintText:
                                  'https://script.google.com/macros/s/.../exec',
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
                              hintText:
                                  'Masukkan token rahasia Google Apps Script',
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
                            lastBackupAt: _lastBackupAt,
                            lastSyncAt: _lastSyncAt,
                            pendingCount: _pendingCount,
                            statusMessage: _statusMessage,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: _isSaving || _isSyncing
                                ? null
                                : _saveSettings,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: Text(
                                _isSaving
                                    ? 'Menyimpan...'
                                    : 'Simpan konfigurasi',
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton(
                            onPressed: _isSaving || _isSyncing
                                ? null
                                : _runSync,
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
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      title: 'Export CSV',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Export akan membuat file CSV lokal untuk transaksi, kategori, saham, dividen, dan watchlist aktif.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            onPressed: _isExporting ? null : _exportCsv,
                            child: Text(
                              _isExporting
                                  ? 'Menyiapkan export...'
                                  : 'Export Data ke CSV',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      title: 'Reset Data Lokal',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Aksi ini akan menghapus transaksi, portofolio, dividen, watchlist, voice transcript, dan log sync yang tersimpan lokal. Konfigurasi aplikasi dan pengaturan keamanan tetap disimpan.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton(
                            onPressed: _isResetting ? null : _confirmResetData,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                            ),
                            child: Text(
                              _isResetting
                                  ? 'Mereset data...'
                                  : 'Reset Data Lokal',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionCard(
                      title: 'Privasi dan Disclaimer',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'MoneyPilot menyimpan data transaksi pribadi secara lokal di perangkat user. Backend hanya dipakai untuk data market, berita, dan layanan analisis terkait berita atau symbol.',
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Informasi saham, market, dan analisis di aplikasi ini bersifat edukatif dan bukan rekomendasi beli atau jual.',
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Sebelum menghapus data lokal, pastikan kamu sudah melakukan sync atau export jika datanya masih dibutuhkan.',
                          ),
                        ],
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
    final int pendingCount = await widget.syncRepository
        .countPendingSyncItems();
    final bool biometricAvailable = await _biometricService.isAvailable();
    final BackendStatusResult backendStatus = await _backendStatusService
        .checkHealth();

    if (!mounted) {
      return;
    }

    setState(() {
      _urlController.text = settings.gasWebhookUrl ?? '';
      _tokenController.text = settings.gasSecretToken ?? '';
      _status = settings.lastSpreadsheetSyncStatus;
      _statusMessage = settings.lastSpreadsheetSyncMessage;
      _lastSyncAt = settings.lastSpreadsheetSyncAt;
      _lastBackupAt = settings.lastLocalBackupAt;
      _pendingCount = pendingCount;
      _biometricAvailable = biometricAvailable;
      _backendConnected = backendStatus.isConnected;
      _backendMessage = backendStatus.message;
      _backendServerTime = backendStatus.serverTime;
      _isLoading = false;
    });
  }

  Future<void> _loadBackendStatus() async {
    final BackendStatusResult backendStatus = await _backendStatusService
        .checkHealth();
    if (!mounted) {
      return;
    }
    setState(() {
      _backendConnected = backendStatus.isConnected;
      _backendMessage = backendStatus.message;
      _backendServerTime = backendStatus.serverTime;
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

      final SyncRunSummary summary = await widget.syncRepository.syncNow();

      if (!mounted) {
        return;
      }

      setState(() {
        _status = summary.status;
        _statusMessage = summary.message;
        _lastSyncAt = summary.completedAt;
        _pendingCount = summary.pendingCount;
      });

      final String summaryText =
          'Push kategori ${summary.pushedCategories}, transaksi ${summary.pushedTransactions}. Pull kategori ${summary.pulledCategories}, transaksi ${summary.pulledTransactions}.';

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

  Future<void> _exportCsv() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final List<MoneyTransaction> transactions = await widget
          .transactionRepository
          .getActiveTransactions();
      final List<Category> categories = await widget.categoryRepository
          .getAllActiveCategories();
      final List<StockTransaction> stockTransactions = await widget
          .portfolioRepository
          .getActiveStockTransactions();
      final List<Dividend> dividends = await widget.portfolioRepository
          .getActiveDividends();
      final List<WatchlistItem> watchlist = await widget.portfolioRepository
          .getWatchlist();

      final CsvExportResult result = await _csvExportService.exportAll(
        transactions: transactions,
        categories: categories,
        stockTransactions: stockTransactions,
        dividends: dividends,
        watchlist: watchlist,
      );
      await widget.appSettingRepository.updateLastLocalBackupAt(
        result.exportedAt,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lastBackupAt = result.exportedAt;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export CSV selesai. File disimpan di ${result.directoryPath}',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _confirmResetData() async {
    final bool? confirmedFirst = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset data lokal?'),
          content: const Text(
            'Semua data transaksi, portofolio, dividen, watchlist, voice transcript, dan log sync lokal akan dihapus.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Lanjut'),
            ),
          ],
        );
      },
    );

    if (confirmedFirst != true || !mounted) {
      return;
    }

    final TextEditingController confirmController = TextEditingController();
    final bool? confirmedSecond = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            final bool isMatch =
                confirmController.text.trim().toUpperCase() == 'RESET';
            return AlertDialog(
              title: const Text('Konfirmasi kedua'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Ketik RESET untuk memastikan kamu benar-benar ingin menghapus data lokal.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: confirmController,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Tulis RESET'),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: isMatch
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: const Text('Hapus Data Lokal'),
                ),
              ],
            );
          },
        );
      },
    );
    confirmController.dispose();

    if (confirmedSecond != true || !mounted) {
      return;
    }

    setState(() {
      _isResetting = true;
    });

    try {
      await widget.localDataMaintenanceRepository.resetAllLocalData();
      final int pendingCount = await widget.syncRepository
          .countPendingSyncItems();

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingCount = pendingCount;
        _status = 'belum';
        _statusMessage =
            'Data lokal telah direset. Konfigurasi aplikasi tetap disimpan.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reset data lokal selesai. Data utama telah dibersihkan.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({
    required this.lastBackupAt,
    required this.lastSyncAt,
    required this.pendingCount,
    required this.statusMessage,
  });

  final DateTime? lastBackupAt;
  final DateTime? lastSyncAt;
  final int pendingCount;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            lastSyncAt == null
                ? 'Sync terakhir: belum pernah'
                : 'Sync terakhir: ${DateFormatter.formatDateTime(lastSyncAt!)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            lastBackupAt == null
                ? 'Export CSV terakhir: belum pernah'
                : 'Export CSV terakhir: ${DateFormatter.formatDateTime(lastBackupAt!)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            pendingCount > 0
                ? '$pendingCount perubahan masih menunggu sync.'
                : 'Tidak ada perubahan lokal yang menunggu sync.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
