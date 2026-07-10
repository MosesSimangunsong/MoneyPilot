import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/watchlist_item.dart';

class WatchlistFormDialog extends StatefulWidget {
  const WatchlistFormDialog({super.key, this.initialItem, this.initialSymbol});

  final WatchlistItem? initialItem;
  final String? initialSymbol;

  static Future<WatchlistFormValue?> show(
    BuildContext context, {
    WatchlistItem? initialItem,
    String? initialSymbol,
  }) {
    return showDialog<WatchlistFormValue>(
      context: context,
      builder: (BuildContext context) {
        return WatchlistFormDialog(
          initialItem: initialItem,
          initialSymbol: initialSymbol,
        );
      },
    );
  }

  @override
  State<WatchlistFormDialog> createState() => _WatchlistFormDialogState();
}

class _WatchlistFormDialogState extends State<WatchlistFormDialog> {
  late final TextEditingController _symbolController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _targetPriceController;
  late final TextEditingController _noteController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _symbolController = TextEditingController(
      text: widget.initialItem?.symbol ?? widget.initialSymbol ?? '',
    );
    _companyNameController = TextEditingController(
      text: widget.initialItem?.companyName ?? '',
    );
    _targetPriceController = TextEditingController(
      text: widget.initialItem?.targetPrice?.toStringAsFixed(0) ?? '',
    );
    _noteController = TextEditingController(
      text: widget.initialItem?.note ?? '',
    );
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _companyNameController.dispose();
    _targetPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialItem != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Watchlist' : 'Tambah Watchlist'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _symbolController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Symbol',
                  hintText: 'Contoh: BBCA',
                ),
                validator: (String? value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Symbol wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Perusahaan',
                  hintText: 'Opsional',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _targetPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Target Harga',
                  hintText: 'Opsional',
                ),
                validator: (String? value) {
                  final String rawValue = (value ?? '').trim();
                  if (rawValue.isEmpty) {
                    return null;
                  }
                  if (double.tryParse(rawValue) == null) {
                    return 'Masukkan angka yang valid.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gunakan sebagai catatan pribadi pemantauan, bukan rekomendasi investasi.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText: 'Opsional',
                ),
                minLines: 3,
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      WatchlistFormValue(
        symbol: _symbolController.text.trim().toUpperCase(),
        companyName: _companyNameController.text.trim(),
        targetPrice: _targetPriceController.text.trim().isEmpty
            ? null
            : double.tryParse(_targetPriceController.text.trim()),
        note: _noteController.text.trim(),
      ),
    );
  }
}

class WatchlistFormValue {
  const WatchlistFormValue({
    required this.symbol,
    required this.companyName,
    required this.targetPrice,
    required this.note,
  });

  final String symbol;
  final String companyName;
  final double? targetPrice;
  final String note;
}
