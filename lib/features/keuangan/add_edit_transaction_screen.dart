import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/category.dart';
import '../../data/models/money_transaction.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/voice_transcript_repository.dart';

class AddEditTransactionArguments {
  const AddEditTransactionArguments({
    this.source = 'manual',
    this.transcriptUuid,
    this.initialType,
    this.initialTitle,
    this.initialAmount,
    this.initialCategoryUuid,
    this.initialPaymentMethod,
    this.initialNote,
    this.initialTransactionDate,
  });

  final String source;
  final String? transcriptUuid;
  final String? initialType;
  final String? initialTitle;
  final double? initialAmount;
  final String? initialCategoryUuid;
  final String? initialPaymentMethod;
  final String? initialNote;
  final DateTime? initialTransactionDate;
}

class AddEditTransactionScreen extends StatefulWidget {
  const AddEditTransactionScreen({
    super.key,
    required this.categoryRepository,
    required this.transactionRepository,
    this.voiceTranscriptRepository,
    this.arguments,
    this.transactionUuid,
  });

  final CategoryRepository categoryRepository;
  final TransactionRepository transactionRepository;
  final VoiceTranscriptRepository? voiceTranscriptRepository;
  final AddEditTransactionArguments? arguments;
  final String? transactionUuid;

  bool get isEditing => transactionUuid != null && transactionUuid!.isNotEmpty;

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _transactionType = 'expense';
  String? _selectedCategoryUuid;
  String _paymentMethod = 'Tidak Dicatat';
  DateTime? _selectedDate;
  List<Category> _categories = const <Category>[];
  String? _categoryHelperText;
  MoneyTransaction? _initialTransaction;

  @override
  void initState() {
    super.initState();
    _initializeForm();
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
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
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
                      widget.isEditing
                          ? 'Perbarui detail transaksi manualmu.'
                          : 'Isi detail transaksi manualmu dengan rapi.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
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
                      selected: <String>{_transactionType},
                      onSelectionChanged: _isSaving
                          ? null
                          : (Set<String> values) {
                              _handleTypeChanged(values.first);
                            },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _titleController,
                      enabled: !_isSaving,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Judul transaksi',
                        hintText: 'Contoh: Makan siang',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul wajib diisi.';
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
                      decoration: const InputDecoration(
                        labelText: 'Nominal',
                        hintText: 'Contoh: 25000',
                      ),
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
                      initialValue: _selectedCategoryUuid,
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
                                _selectedCategoryUuid = value;
                              });
                            },
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Kategori wajib dipilih.';
                        }
                        return null;
                      },
                    ),
                    if (_categoryHelperText != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _categoryHelperText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isSaving ? null : _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal transaksi',
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Pilih tanggal'
                              : DateFormatter.formatShortDate(_selectedDate!),
                        ),
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
                        hintText: 'Opsional',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    FilledButton(
                      onPressed: _isSaving ? null : _saveTransaction,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          _isSaving
                              ? 'Menyimpan...'
                              : widget.isEditing
                              ? 'Simpan perubahan'
                              : 'Simpan transaksi',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _initializeForm() async {
    if (widget.isEditing) {
      final MoneyTransaction? transaction = await widget.transactionRepository
          .getByUuid(widget.transactionUuid!);
      if (!mounted) {
        return;
      }
      if (transaction == null || transaction.isDeleted) {
        Navigator.of(context).pop();
        return;
      }

      _initialTransaction = transaction;
      _transactionType = transaction.type;
      _titleController.text = transaction.title;
      _amountController.text = _formatAmountInput(transaction.amount);
      _noteController.text = transaction.note ?? '';
      _selectedDate = transaction.transactionDate;
      _paymentMethod = transaction.paymentMethod.trim().isEmpty
          ? 'Tidak Dicatat'
          : transaction.paymentMethod;
      _selectedCategoryUuid = transaction.categoryUuid;
    } else {
      final AddEditTransactionArguments? arguments = widget.arguments;
      _transactionType = arguments?.initialType ?? 'expense';
      _titleController.text = arguments?.initialTitle ?? '';
      if (arguments?.initialAmount != null) {
        _amountController.text = _formatAmountInput(arguments!.initialAmount!);
      }
      _noteController.text = arguments?.initialNote ?? '';
      _selectedDate =
          arguments?.initialTransactionDate?.toUtc() ?? DateTime.now().toUtc();
      _paymentMethod = arguments?.initialPaymentMethod ?? 'Tidak Dicatat';
      _selectedCategoryUuid = arguments?.initialCategoryUuid;
    }

    await _loadCategories();
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadCategories() async {
    final List<Category> categories = await widget.categoryRepository.getByType(
      _transactionType,
    );
    String? helperText;
    String? categoryUuid = _selectedCategoryUuid;

    if (categoryUuid != null &&
        categories.every((Category item) => item.uuid != categoryUuid)) {
      categoryUuid = null;
      helperText =
          'Kategori lama sudah tidak aktif. Pilih kategori yang masih tersedia.';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _categories = categories;
      _selectedCategoryUuid = categoryUuid;
      _categoryHelperText = helperText;
    });
  }

  Future<void> _pickDate() async {
    final DateTime initialDate = _selectedDate?.toLocal() ?? DateTime.now();
    final DateTime firstDate = DateTime(2020);
    final DateTime lastDate = DateTime(initialDate.year + 5);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = DateTime.utc(picked.year, picked.month, picked.day);
    });
  }

  void _handleTypeChanged(String value) {
    if (_transactionType == value) {
      return;
    }

    setState(() {
      _transactionType = value;
      _selectedCategoryUuid = null;
      _categoryHelperText = null;
    });
    _loadCategories();
  }

  Future<void> _saveTransaction() async {
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal transaksi wajib dipilih.')),
      );
      return;
    }

    if (_selectedCategoryUuid == null || _selectedCategoryUuid!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kategori wajib dipilih.')));
      return;
    }

    final double? amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal wajib diisi dan harus lebih dari 0.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing && _initialTransaction != null) {
        await widget.transactionRepository.updateTransaction(
          uuid: _initialTransaction!.uuid,
          type: _transactionType,
          title: _titleController.text,
          amount: amount,
          categoryUuid: _selectedCategoryUuid!,
          transactionDate: _selectedDate!,
          paymentMethod: _paymentMethod,
          note: _noteController.text,
        );
      } else {
        final created = await widget.transactionRepository.createTransaction(
          type: _transactionType,
          title: _titleController.text,
          amount: amount,
          categoryUuid: _selectedCategoryUuid!,
          paymentMethod: _paymentMethod,
          note: _noteController.text,
          source: widget.arguments?.source ?? 'manual',
          transactionDate: _selectedDate!,
        );
        if (widget.arguments?.transcriptUuid != null &&
            widget.voiceTranscriptRepository != null) {
          await widget.voiceTranscriptRepository!.markConverted(
            transcriptUuid: widget.arguments!.transcriptUuid!,
            transactionUuid: created.uuid,
          );
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Transaksi berhasil diperbarui.'
                : 'Transaksi berhasil disimpan.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

const List<String> paymentMethods = <String>[
  'Tunai',
  'QRIS',
  'Transfer',
  'Kartu Debit',
  'E-Wallet',
  'Lainnya',
  'Tidak Dicatat',
];

double? _parseAmount(String? value) {
  if (value == null) {
    return null;
  }

  String normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }

  normalized = normalized.replaceAll(RegExp(r'[^0-9,\.]'), '');
  if (normalized.contains(',') && normalized.contains('.')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else if (normalized.contains(',')) {
    normalized = normalized.replaceAll(',', '.');
  }

  if (normalized.indexOf('.') != normalized.lastIndexOf('.')) {
    normalized = normalized.replaceAll('.', '');
  }

  return double.tryParse(normalized);
}

String _formatAmountInput(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toStringAsFixed(0);
  }
  return amount.toString();
}
