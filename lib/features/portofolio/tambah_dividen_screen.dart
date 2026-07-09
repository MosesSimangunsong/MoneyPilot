import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/repositories/portfolio_repository.dart';

class TambahDividenScreen extends StatefulWidget {
  const TambahDividenScreen({super.key, required this.portfolioRepository});

  final PortfolioRepository portfolioRepository;

  @override
  State<TambahDividenScreen> createState() => _TambahDividenScreenState();
}

class _TambahDividenScreenState extends State<TambahDividenScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _grossAmountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController(text: '0');
  final TextEditingController _netAmountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isSaving = false;
  DateTime? _selectedDate = DateTime.now().toUtc();

  @override
  void dispose() {
    _symbolController.dispose();
    _companyNameController.dispose();
    _grossAmountController.dispose();
    _taxController.dispose();
    _netAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catat Dividen')),
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
                'Dividen yang disimpan di sini akan otomatis masuk ke tab Keuangan sebagai pemasukan kategori Dividen.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
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
                decoration: const InputDecoration(
                  labelText: 'Nama Perusahaan',
                  hintText: 'Opsional',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _grossAmountController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Dividen Kotor',
                  hintText: 'Opsional',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _taxController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Pajak',
                  hintText: 'Contoh: 5000',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _netAmountController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Dividen Bersih',
                  hintText: 'Contoh: 50000',
                ),
                validator: (String? value) {
                  final double? netAmount = _parseAmount(value);
                  if (netAmount == null || netAmount <= 0) {
                    return 'Dividen bersih wajib diisi dan harus lebih dari 0.';
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
                    labelText: 'Tanggal diterima',
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
                onPressed: _isSaving ? null : _saveDividend,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(_isSaving ? 'Menyimpan...' : 'Simpan dividen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _saveDividend() async {
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal diterima wajib dipilih.')),
      );
      return;
    }

    final double? netAmount = _parseAmount(_netAmountController.text);
    final double tax = _parseAmount(_taxController.text) ?? 0;
    final double? grossAmount = _parseAmount(_grossAmountController.text);

    if (netAmount == null || netAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dividen bersih wajib diisi dan harus lebih dari 0.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.portfolioRepository.createDividendWithIncomeTransaction(
        symbol: _symbolController.text,
        companyName: _companyNameController.text,
        grossAmount: grossAmount,
        tax: tax,
        netAmount: netAmount,
        receivedDate: _selectedDate!,
        note: _noteController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dividen berhasil dicatat.')),
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
