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
    required this.draft,
  });

  final String transcriptUuid;
  final ParsedVoiceTransaction draft;
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
  late String? _type;
  late String _title;
  late String _note;
  late double? _amount;
  late DateTime _date;
  late String _paymentMethod;
  String? _categoryUuid;
  bool _isSaving = false;
  List<Category> _categories = const <Category>[];

  @override
  void initState() {
    super.initState();
    final ParsedVoiceTransaction draft = widget.arguments.draft;
    _type = draft.type;
    _title = draft.title;
    _note = draft.note ?? draft.rawText;
    _amount = draft.amount;
    _date = DateTime.now().toUtc();
    _paymentMethod = 'Tidak Dicatat';
    _categoryUuid = draft.categoryUuid;
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final ParsedVoiceTransaction draft = widget.arguments.draft;
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Transaksi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.xxl,
          ),
          children: <Widget>[
            Text(
              'Periksa hasil deteksi suara sebelum transaksi disimpan.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Section(label: 'Transcript suara', child: Text(draft.rawText)),
            const SizedBox(height: AppSpacing.lg),
            _Section(
              label: 'Confidence score',
              child: Text('${(draft.confidenceScore * 100).round()}%'),
            ),
            const SizedBox(height: AppSpacing.lg),
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
              onSelectionChanged: (Set<String> values) {
                setState(() {
                  _type = values.isEmpty ? null : values.first;
                  _categoryUuid = null;
                });
                _loadCategories();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(labelText: 'Judul transaksi'),
              onChanged: (String value) => _title = value,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              initialValue: _amount == null ? '' : _formatAmount(_amount!),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Nominal'),
              onChanged: (String value) => _amount = _parseAmount(value),
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
              onChanged: (String? value) {
                setState(() {
                  _categoryUuid = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tanggal'),
                child: Text(DateFormatter.formatShortDate(_date)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Metode pembayaran'),
              items: paymentMethods
                  .map(
                    (String method) => DropdownMenuItem<String>(
                      value: method,
                      child: Text(method),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
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
              initialValue: _note,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                alignLabelWithHint: true,
              ),
              onChanged: (String value) => _note = value,
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: _isSaving ? null : _saveTransaction,
              child: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: _isSaving ? null : _openManualEdit,
              child: const Text('Edit manual'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Ulangi rekaman'),
            ),
          ],
        ),
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
    if (_type == null) {
      _showError('Pilih tipe transaksi terlebih dahulu.');
      return;
    }
    if (_title.trim().isEmpty) {
      _showError('Judul transaksi wajib diisi.');
      return;
    }
    if (_amount == null || _amount! <= 0) {
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
        title: _title.trim(),
        amount: _amount!,
        categoryUuid: _categoryUuid!,
        paymentMethod: _paymentMethod,
        note: _note.trim().isEmpty ? null : _note.trim(),
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
              initialTitle: _title,
              initialAmount: _amount,
              initialCategoryUuid: _categoryUuid,
              initialPaymentMethod: _paymentMethod,
              initialNote: _note,
              initialTransactionDate: _date,
            ),
            voiceTranscriptRepository: widget.voiceTranscriptRepository,
          );
        },
      ),
    );
    if (!mounted || result != true) {
      return;
    }
    Navigator.of(context).pop();
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

double? _parseAmount(String value) {
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
