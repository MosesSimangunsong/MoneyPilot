import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/voice_transcript_repository.dart';
import '../../data/services/transaction_parser_service.dart';
import 'add_edit_transaction_screen.dart';

class VoiceConfirmationArguments {
  const VoiceConfirmationArguments({
    required this.transcriptUuid,
    required this.parseResult,
  });

  final String transcriptUuid;
  final VoiceTransactionParseResult parseResult;
}

class VoiceConfirmationScreen extends StatefulWidget {
  const VoiceConfirmationScreen({
    super.key,
    required this.arguments,
    required this.categoryRepository,
    required this.transactionRepository,
    required this.voiceTranscriptRepository,
  });

  final VoiceConfirmationArguments arguments;
  final CategoryRepository categoryRepository;
  final TransactionRepository transactionRepository;
  final VoiceTranscriptRepository voiceTranscriptRepository;

  @override
  State<VoiceConfirmationScreen> createState() =>
      _VoiceConfirmationScreenState();
}

class _VoiceConfirmationScreenState extends State<VoiceConfirmationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late String? _type;
  late DateTime _date;
  late String _paymentMethod;
  String? _categoryUuid;
  bool _isSaving = false;
  List<Category> _categories = const <Category>[];

  VoiceTransactionParseResult get _parseResult => widget.arguments.parseResult;

  @override
  void initState() {
    super.initState();
    _type = _parseResult.transactionType;
    _date = _parseResult.transactionDate;
    _paymentMethod = 'Tidak Dicatat';
    _categoryUuid = _parseResult.categoryUuid;
    _titleController = TextEditingController(text: _parseResult.description);
    _amountController = TextEditingController(
      text: _parseResult.amount == null
          ? ''
          : _formatAmount(_parseResult.amount!),
    );
    _noteController = TextEditingController(
      text: _parseResult.originalTranscript,
    );
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Transaksi Suara')),
      body: SafeArea(
        child: Form(
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
                'Data ini berasal dari input suara. Periksa dan ubah jika diperlukan sebelum disimpan.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildVoiceBadge(context),
              const SizedBox(height: AppSpacing.lg),
              _Section(
                label: 'Transkrip suara asli',
                child: Text(_parseResult.originalTranscript),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Section(
                label: 'Tingkat keyakinan parser',
                child: Text(
                  '${_parseResult.confidenceScore}% (${_parseResult.confidenceLabel})',
                ),
              ),
              if (_parseResult.warnings.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                _buildWarnings(context),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Tipe transaksi',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'expense',
                    label: Text('Pengeluaran'),
                  ),
                  ButtonSegment<String>(
                    value: 'income',
                    label: Text('Pemasukan'),
                  ),
                ],
                selected: _type == null ? const <String>{} : <String>{_type!},
                emptySelectionAllowed: true,
                onSelectionChanged: _isSaving
                    ? null
                    : (Set<String> values) {
                        setState(() {
                          _type = values.isEmpty ? null : values.first;
                          _categoryUuid = null;
                        });
                        _loadCategories();
                      },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _titleController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi transaksi',
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi transaksi wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _amountController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Nominal'),
                validator: (String? value) {
                  final double? amount = _parseAmount(value);
                  if (amount == null || amount <= 0) {
                    return 'Nominal wajib diisi dan harus lebih dari 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _categoryUuid,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: _categories
                    .map(
                      (Category category) => DropdownMenuItem<String>(
                        value: category.uuid,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (String? value) {
                        setState(() {
                          _categoryUuid = value;
                        });
                      },
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kategori wajib dipilih.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isSaving ? null : _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal transaksi',
                  ),
                  child: Text(DateFormatter.formatShortDate(_date)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Metode pembayaran',
                ),
                items: paymentMethods
                    .map(
                      (String method) => DropdownMenuItem<String>(
                        value: method,
                        child: Text(method),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (String? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _paymentMethod = value;
                        });
                      },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _noteController,
                enabled: !_isSaving,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: _isSaving ? null : _saveTransaction,
                child: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: _isSaving ? null : _openManualEdit,
                child: const Text('Ubah manual'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text('Coba rekam lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.mic, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Sumber: Input suara',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildWarnings(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Perlu diperiksa',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: AppColors.warning),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final String warning in _parseResult.warnings) ...<Widget>[
            Text(
              '• $warning',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.warning),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }

  Future<void> _loadCategories() async {
    if (_type == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = const <Category>[];
        _categoryUuid = null;
      });
      return;
    }

    final List<Category> categories = await widget.categoryRepository.getByType(
      _type!,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _categories = categories;
      if (_categoryUuid != null &&
          categories.every((Category item) => item.uuid != _categoryUuid)) {
        _categoryUuid = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime localDate = _date.toLocal();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: localDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(localDate.year + 5),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _date = DateTime.utc(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _saveTransaction() async {
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    if (_type == null) {
      _showError('Pilih tipe transaksi terlebih dahulu.');
      return;
    }

    final double? amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Nominal wajib diisi dan harus lebih dari 0.');
      return;
    }

    if (_categoryUuid == null || _categoryUuid!.isEmpty) {
      _showError('Kategori wajib dipilih.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final transaction = await widget.transactionRepository.createTransaction(
        type: _type!,
        title: _titleController.text.trim(),
        amount: amount,
        categoryUuid: _categoryUuid!,
        paymentMethod: _paymentMethod,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        source: 'voice',
        transactionDate: _date,
      );
      await widget.voiceTranscriptRepository.markConverted(
        transcriptUuid: widget.arguments.transcriptUuid,
        transactionUuid: transaction.uuid,
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaksi suara tersimpan: ${CurrencyFormatter.formatRupiah(transaction.amount)}',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _openManualEdit() async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return AddEditTransactionScreen(
            categoryRepository: widget.categoryRepository,
            transactionRepository: widget.transactionRepository,
            arguments: AddEditTransactionArguments(
              source: 'voice',
              transcriptUuid: widget.arguments.transcriptUuid,
              initialType: _type,
              initialTitle: _titleController.text,
              initialAmount: _parseAmount(_amountController.text),
              initialCategoryUuid: _categoryUuid,
              initialPaymentMethod: _paymentMethod,
              initialNote: _noteController.text,
              initialTransactionDate: _date,
              originalTranscript: _parseResult.originalTranscript,
            ),
            voiceTranscriptRepository: widget.voiceTranscriptRepository,
          );
        },
      ),
    );
    if (!mounted || result != true) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ],
    );
  }
}

double? _parseAmount(String? value) {
  if (value == null) {
    return null;
  }
  String normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }
  normalized = normalized.replaceAll(RegExp(r'[^0-9,\.]'), '');
  if (normalized.contains('.') && normalized.contains(',')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else if (normalized.contains(',')) {
    normalized = normalized.replaceAll(',', '.');
  }
  if (normalized.indexOf('.') != normalized.lastIndexOf('.')) {
    normalized = normalized.replaceAll('.', '');
  }
  return double.tryParse(normalized);
}

String _formatAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}
