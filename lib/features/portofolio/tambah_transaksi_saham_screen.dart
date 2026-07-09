import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/stock_transaction.dart';
import '../../data/repositories/portfolio_repository.dart';

class TambahTransaksiSahamScreen extends StatefulWidget {
  const TambahTransaksiSahamScreen({
    super.key,
    required this.portfolioRepository,
    this.transactionUuid,
  });

  final PortfolioRepository portfolioRepository;
  final String? transactionUuid;

  bool get isEditing => transactionUuid != null && transactionUuid!.isNotEmpty;

  @override
  State<TambahTransaksiSahamScreen> createState() =>
      _TambahTransaksiSahamScreenState();
}

class _TambahTransaksiSahamScreenState
    extends State<TambahTransaksiSahamScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _lotController = TextEditingController();
  final TextEditingController _sharesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _feeController = TextEditingController(text: '0');
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _sharesEditedManually = false;
  bool _isApplyingAutoShares = false;
  String _actionType = 'buy';
  DateTime? _selectedDate;
  StockTransaction? _initialTransaction;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _companyNameController.dispose();
    _lotController.dispose();
    _sharesController.dispose();
    _priceController.dispose();
    _feeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Transaksi Saham' : 'Tambah Transaksi Saham',
        ),
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
                          ? 'Perbarui detail transaksi sahammu.'
                          : 'Isi detail beli atau jual saham secara manual.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Aksi', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<String>(
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'buy',
                          label: Text('Beli'),
                        ),
                        ButtonSegment<String>(
                          value: 'sell',
                          label: Text('Jual'),
                        ),
                      ],
                      selected: <String>{_actionType},
                      onSelectionChanged: _isSaving
                          ? null
                          : (Set<String> value) {
                              setState(() {
                                _actionType = value.first;
                              });
                            },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _symbolController,
                      enabled: !_isSaving,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Kode Saham',
                        hintText: 'Contoh: BBCA',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Kode saham wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _companyNameController,
                      enabled: !_isSaving,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama Perusahaan',
                        hintText: 'Opsional',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _lotController,
                            enabled: !_isSaving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Lot',
                              hintText: 'Contoh: 1',
                            ),
                            onChanged: _handleLotChanged,
                            validator: (String? value) {
                              final int? lot = _parseInt(value);
                              final int? shares = _parseInt(
                                _sharesController.text,
                              );
                              if ((lot == null || lot <= 0) &&
                                  (shares == null || shares <= 0)) {
                                return 'Lot atau shares wajib lebih dari 0.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _sharesController,
                            enabled: !_isSaving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Shares',
                              hintText: 'Contoh: 100',
                            ),
                            onChanged: (String value) {
                              if (_isApplyingAutoShares) {
                                return;
                              }
                              _sharesEditedManually = true;
                            },
                            validator: (String? value) {
                              final int? shares = _parseInt(value);
                              final int? lot = _parseInt(_lotController.text);
                              if ((shares == null || shares <= 0) &&
                                  (lot == null || lot <= 0)) {
                                return 'Lot atau shares wajib lebih dari 0.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _priceController,
                      enabled: !_isSaving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Harga per Saham',
                        hintText: 'Contoh: 9000',
                      ),
                      validator: (String? value) {
                        final double? price = _parseAmount(value);
                        if (price == null || price <= 0) {
                          return 'Harga wajib diisi dan harus lebih dari 0.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _feeController,
                      enabled: !_isSaving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Biaya/Fee',
                        hintText: 'Contoh: 1500',
                      ),
                    ),
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
                              : 'Simpan transaksi saham',
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
      final StockTransaction? transaction = await widget.portfolioRepository
          .getStockTransactionByUuid(widget.transactionUuid!);
      if (!mounted) {
        return;
      }
      if (transaction == null || transaction.isDeleted) {
        Navigator.of(context).pop();
        return;
      }

      _initialTransaction = transaction;
      _symbolController.text = transaction.symbol;
      _companyNameController.text = transaction.companyName ?? '';
      _actionType = transaction.actionType;
      _lotController.text = transaction.lot.toString();
      _sharesController.text = transaction.shares.toString();
      _priceController.text = _formatAmountInput(transaction.price);
      _feeController.text = _formatAmountInput(transaction.fee);
      _noteController.text = transaction.note ?? '';
      _selectedDate = transaction.transactionDate;
      _sharesEditedManually = false;
    } else {
      _selectedDate = DateTime.now().toUtc();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _handleLotChanged(String value) {
    final int? lot = _parseInt(value);
    if (lot == null || lot <= 0) {
      return;
    }

    final int autoShares = lot * 100;
    final int? currentShares = _parseInt(_sharesController.text);
    if (!_sharesEditedManually ||
        currentShares == null ||
        currentShares == 0 ||
        currentShares == autoShares) {
      _sharesEditedManually = false;
      _isApplyingAutoShares = true;
      _sharesController.text = autoShares.toString();
      _sharesController.selection = TextSelection.fromPosition(
        TextPosition(offset: _sharesController.text.length),
      );
      _isApplyingAutoShares = false;
    }
  }

  Future<void> _pickDate() async {
    final DateTime initialDate = _selectedDate?.toLocal() ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(initialDate.year + 5),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = DateTime.utc(picked.year, picked.month, picked.day);
    });
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

    final int? lotInput = _parseInt(_lotController.text);
    final int? sharesInput = _parseInt(_sharesController.text);
    final int normalizedShares = (sharesInput != null && sharesInput > 0)
        ? sharesInput
        : ((lotInput ?? 0) * 100);
    final int normalizedLot = (lotInput != null && lotInput > 0)
        ? lotInput
        : (normalizedShares / 100).floor();
    final double? price = _parseAmount(_priceController.text);
    final double fee = _parseAmount(_feeController.text) ?? 0;

    if (normalizedShares <= 0 || normalizedLot <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lot atau shares wajib lebih dari 0.')),
      );
      return;
    }

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harga wajib diisi dan harus lebih dari 0.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing && _initialTransaction != null) {
        await widget.portfolioRepository.updateStockTransaction(
          _initialTransaction!.uuid,
          symbol: _symbolController.text,
          companyName: _companyNameController.text,
          actionType: _actionType,
          lot: normalizedLot,
          shares: normalizedShares,
          price: price,
          fee: fee,
          transactionDate: _selectedDate!,
          note: _noteController.text,
        );
      } else {
        await widget.portfolioRepository.createStockTransaction(
          symbol: _symbolController.text,
          companyName: _companyNameController.text,
          actionType: _actionType,
          lot: normalizedLot,
          shares: normalizedShares,
          price: price,
          fee: fee,
          transactionDate: _selectedDate!,
          note: _noteController.text,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Transaksi saham berhasil diperbarui.'
                : 'Transaksi saham berhasil disimpan.',
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

int? _parseInt(String? value) {
  final double? parsed = _parseAmount(value);
  if (parsed == null) {
    return null;
  }
  return parsed.round();
}

String _formatAmountInput(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toStringAsFixed(0);
  }
  return amount.toString();
}
