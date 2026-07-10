import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../../shared/layouts/app_page.dart';

class KategoriScreen extends StatefulWidget {
  const KategoriScreen({super.key, required this.categoryRepository});

  final CategoryRepository categoryRepository;

  @override
  State<KategoriScreen> createState() => _KategoriScreenState();
}

class _KategoriScreenState extends State<KategoriScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: widget.categoryRepository.watchCategories(),
      builder: (BuildContext context, AsyncSnapshot<void> categorySnapshot) {
        return FutureBuilder<List<Category>>(
          future: _loadCategories(),
          builder: (BuildContext context, AsyncSnapshot<List<Category>> snapshot) {
            final List<Category> categories =
                snapshot.data ?? const <Category>[];
            final bool isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null;

            return AppPage(
              title: 'Kelola kategori',
              description:
                  'Atur kategori pemasukan dan pengeluaran untuk pencatatan manual maupun suara.',
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _openCategorySheet(),
                icon: const Icon(LucideIcons.plus),
                label: const Text('Tambah kategori'),
              ),
              children: <Widget>[
                _InfoBanner(activeCount: categories.length),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Filter tipe',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _categoryFilters
                      .map(
                        (_CategoryFilter option) => ChoiceChip(
                          label: Text(option.label),
                          selected: _selectedFilter == option.value,
                          onSelected: (bool isSelected) {
                            if (!isSelected) {
                              return;
                            }
                            setState(() {
                              _selectedFilter = option.value;
                            });
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError || categorySnapshot.hasError)
                  const _SectionMessage(
                    title: 'Daftar kategori belum bisa dimuat',
                    description:
                        'Coba buka kembali halaman ini. Jika kendala berlanjut, periksa data lokal aplikasi.',
                  )
                else if (categories.isEmpty)
                  _SectionMessage(
                    title: _selectedFilter == 'all'
                        ? 'Belum ada kategori aktif'
                        : 'Belum ada kategori untuk filter ini',
                    description: _selectedFilter == 'all'
                        ? 'Tambahkan kategori baru agar pencatatan transaksi lebih rapi.'
                        : 'Ganti filter atau tambahkan kategori baru sesuai tipe yang kamu butuhkan.',
                  )
                else
                  ..._buildCategoryList(categories),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Category>> _loadCategories() {
    if (_selectedFilter == 'income' || _selectedFilter == 'expense') {
      return widget.categoryRepository.getByType(_selectedFilter);
    }
    return widget.categoryRepository.getAllActiveCategories();
  }

  List<Widget> _buildCategoryList(List<Category> categories) {
    return <Widget>[
      for (int index = 0; index < categories.length; index++) ...<Widget>[
        _CategoryListTile(
          category: categories[index],
          onEdit: () => _openCategorySheet(category: categories[index]),
          onDelete: () => _confirmDelete(categories[index]),
        ),
        if (index < categories.length - 1) const Divider(height: 1),
      ],
    ];
  }

  Future<void> _openCategorySheet({Category? category}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return _CategoryFormSheet(
          categoryRepository: widget.categoryRepository,
          existingCategory: category,
        );
      },
    );
  }

  Future<void> _confirmDelete(Category category) async {
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kategori bawaan tetap disimpan agar alur pencatatan dan sinkronisasi tetap aman.',
          ),
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus kategori?'),
          content: Text(
            'Kategori "${category.name}" akan disembunyikan dari daftar aktif. Transaksi lama yang sudah memakai kategori ini tetap aman.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.categoryRepository.softDeleteCategory(category.uuid);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kategori "${category.name}" dipindahkan dari daftar aktif.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kategori belum berhasil dihapus. Coba lagi beberapa saat.',
          ),
        ),
      );
    }
  }
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({
    required this.categoryRepository,
    this.existingCategory,
  });

  final CategoryRepository categoryRepository;
  final Category? existingCategory;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedType;
  late String _selectedIconName;
  late String _selectedColorHex;
  bool _isSaving = false;

  bool get _isEditing => widget.existingCategory != null;

  bool get _isDefaultCategory => widget.existingCategory?.isDefault ?? false;

  @override
  void initState() {
    super.initState();
    final Category? category = widget.existingCategory;
    _nameController = TextEditingController(text: category?.name ?? '');
    _selectedType = category?.type ?? 'expense';
    _selectedIconName = category?.iconName ?? _iconOptions.first.name;
    _selectedColorHex =
        category?.colorHex ?? _defaultColorByType(_selectedType);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screenHorizontal,
          top: AppSpacing.lg,
          right: AppSpacing.screenHorizontal,
          bottom: mediaQuery.viewInsets.bottom + AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _isEditing ? 'Edit kategori' : 'Tambah kategori baru',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _isDefaultCategory
                      ? 'Kategori bawaan tetap aman. Kamu masih bisa menyesuaikan nama dan ikon, tetapi tipe tidak bisa diubah.'
                      : 'Lengkapi nama, tipe, ikon, dan warna agar kategori mudah dikenali saat mencatat transaksi.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama kategori',
                    hintText: 'Contoh: Ngopi, Bonus proyek, Dana darurat',
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama kategori wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Tipe kategori',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _typeOptions
                      .map(
                        (_CategoryTypeOption option) => ChoiceChip(
                          label: Text(option.label),
                          selected: _selectedType == option.value,
                          onSelected: _isDefaultCategory
                              ? null
                              : (bool isSelected) {
                                  if (!isSelected) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedType = option.value;
                                    _selectedColorHex = _defaultColorByType(
                                      option.value,
                                    );
                                  });
                                },
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Ikon kategori',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _selectedIconName,
                  decoration: const InputDecoration(labelText: 'Pilih ikon'),
                  items: _iconOptions
                      .map(
                        (_CategoryIconOption option) =>
                            DropdownMenuItem<String>(
                              value: option.name,
                              child: Row(
                                children: <Widget>[
                                  Icon(option.icon, size: 18),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(option.label),
                                ],
                              ),
                            ),
                      )
                      .toList(growable: false),
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedIconName = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Warna kategori',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _colorOptions
                      .map(
                        (String colorHex) => InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            setState(() {
                              _selectedColorHex = colorHex;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _parseColorHex(colorHex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColorHex == colorHex
                                    ? AppColors.textPrimary
                                    : AppColors.border,
                                width: _selectedColorHex == colorHex ? 2 : 1,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveCategory,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Text(
                        _isSaving
                            ? 'Menyimpan kategori...'
                            : (_isEditing
                                  ? 'Simpan perubahan'
                                  : 'Tambah kategori'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final String trimmedName = _nameController.text.trim();
    final String typeToSave = _isDefaultCategory
        ? widget.existingCategory!.type
        : _selectedType;

    setState(() {
      _isSaving = true;
    });

    try {
      final bool hasDuplicate = await widget.categoryRepository
          .hasActiveCategoryWithName(
            trimmedName,
            typeToSave,
            excludeUuid: widget.existingCategory?.uuid,
          );

      if (hasDuplicate) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nama kategori sudah dipakai pada tipe yang sama. Gunakan nama lain.',
            ),
          ),
        );
        return;
      }

      final DateTime now = DateTimeUtils.utcNow();
      final Category category =
          widget.existingCategory ??
          Category(
            uuid: IdGenerator.newUuid(),
            name: trimmedName,
            type: typeToSave,
            iconName: _selectedIconName,
            colorHex: _selectedColorHex,
            createdAt: now,
            updatedAt: now,
          );

      category.name = trimmedName;
      category.type = typeToSave;
      category.iconName = _selectedIconName;
      category.colorHex = _selectedColorHex;
      category.isDeleted = false;
      category.deletedAt = null;

      await widget.categoryRepository.upsertCategory(category);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Kategori berhasil diperbarui.'
                : 'Kategori baru berhasil ditambahkan.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kategori belum berhasil disimpan. Coba lagi beberapa saat.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _CategoryListTile extends StatelessWidget {
  const _CategoryListTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final _CategoryIconOption iconOption = _iconOptionByName(category.iconName);
    final bool isIncome = category.type == 'income';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _parseColorHex(category.colorHex).withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconOption.icon,
          color: _parseColorHex(category.colorHex),
          size: 20,
        ),
      ),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              category.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (category.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Bawaan',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(
          '${isIncome ? 'Pemasukan' : 'Pengeluaran'} - ${iconOption.label}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (String value) {
          if (value == 'edit') {
            onEdit();
            return;
          }
          if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: Text('Edit kategori'),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              enabled: !category.isDefault,
              child: Text(
                category.isDefault
                    ? 'Kategori bawaan tidak bisa dihapus'
                    : 'Hapus dari daftar aktif',
              ),
            ),
          ];
        },
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Kategori aktif',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$activeCount kategori siap dipakai untuk pencatatan transaksi manual maupun suara.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({required this.title, required this.description});

  final String title;
  final String description;

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
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter {
  const _CategoryFilter({required this.value, required this.label});

  final String value;
  final String label;
}

class _CategoryTypeOption {
  const _CategoryTypeOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _CategoryIconOption {
  const _CategoryIconOption({
    required this.name,
    required this.label,
    required this.icon,
  });

  final String name;
  final String label;
  final IconData icon;
}

const List<_CategoryFilter> _categoryFilters = <_CategoryFilter>[
  _CategoryFilter(value: 'all', label: 'Semua'),
  _CategoryFilter(value: 'income', label: 'Pemasukan'),
  _CategoryFilter(value: 'expense', label: 'Pengeluaran'),
];

const List<_CategoryTypeOption> _typeOptions = <_CategoryTypeOption>[
  _CategoryTypeOption(value: 'income', label: 'Pemasukan'),
  _CategoryTypeOption(value: 'expense', label: 'Pengeluaran'),
];

const List<String> _colorOptions = <String>[
  '#2563EB',
  '#1D4ED8',
  '#1E3A8A',
  '#0F766E',
  '#DC2626',
  '#64748B',
];

const List<_CategoryIconOption> _iconOptions = <_CategoryIconOption>[
  _CategoryIconOption(
    name: 'utensils',
    label: 'Makanan & Minuman',
    icon: LucideIcons.utensils,
  ),
  _CategoryIconOption(
    name: 'bus',
    label: 'Transportasi',
    icon: LucideIcons.bus,
  ),
  _CategoryIconOption(
    name: 'house',
    label: 'Rumah',
    icon: Icons.house_outlined,
  ),
  _CategoryIconOption(
    name: 'graduation-cap',
    label: 'Pendidikan',
    icon: LucideIcons.graduationCap,
  ),
  _CategoryIconOption(
    name: 'party-popper',
    label: 'Hiburan',
    icon: LucideIcons.partyPopper,
  ),
  _CategoryIconOption(
    name: 'heart-pulse',
    label: 'Kesehatan',
    icon: LucideIcons.heartPulse,
  ),
  _CategoryIconOption(
    name: 'shopping-bag',
    label: 'Belanja',
    icon: LucideIcons.shoppingBag,
  ),
  _CategoryIconOption(
    name: 'chart-column',
    label: 'Investasi',
    icon: LucideIcons.barChart3,
  ),
  _CategoryIconOption(
    name: 'piggy-bank',
    label: 'Tabungan',
    icon: LucideIcons.piggyBank,
  ),
  _CategoryIconOption(
    name: 'ellipsis',
    label: 'Lainnya',
    icon: Icons.more_horiz,
  ),
  _CategoryIconOption(
    name: 'hand-coins',
    label: 'Dukungan keluarga',
    icon: Icons.volunteer_activism_outlined,
  ),
  _CategoryIconOption(
    name: 'briefcase-business',
    label: 'Pekerjaan',
    icon: Icons.work_outline,
  ),
  _CategoryIconOption(
    name: 'badge-dollar-sign',
    label: 'Penghasilan',
    icon: Icons.attach_money,
  ),
  _CategoryIconOption(
    name: 'wallet',
    label: 'Dompet',
    icon: LucideIcons.wallet,
  ),
  _CategoryIconOption(
    name: 'landmark',
    label: 'Dividen',
    icon: LucideIcons.landmark,
  ),
  _CategoryIconOption(
    name: 'sparkles',
    label: 'Reward',
    icon: LucideIcons.sparkles,
  ),
  _CategoryIconOption(name: 'gift', label: 'Hadiah', icon: LucideIcons.gift),
];

_CategoryIconOption _iconOptionByName(String name) {
  return _iconOptions.firstWhere(
    (_CategoryIconOption option) => option.name == name,
    orElse: () => const _CategoryIconOption(
      name: 'ellipsis',
      label: 'Lainnya',
      icon: Icons.more_horiz,
    ),
  );
}

String _defaultColorByType(String type) {
  return type == 'income' ? '#0F766E' : '#2563EB';
}

Color _parseColorHex(String value) {
  final String cleaned = value.replaceFirst('#', '');
  final String normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.parse(normalized, radix: 16));
}
