import 'package:isar/isar.dart';

import '../../core/utils/date_time_utils.dart';
import '../models/category.dart';

class CategoryRepository {
  CategoryRepository(this._isar);

  final Isar _isar;

  static const List<_DefaultCategorySeed> _defaultSeeds =
      <_DefaultCategorySeed>[
        _DefaultCategorySeed(
          uuid: '08f0a5ea-16ba-4b26-9cb1-c92bf39af2dc',
          type: 'expense',
          name: 'Makanan & Minuman',
          iconName: 'utensils',
          colorHex: '#2563EB',
        ),
        _DefaultCategorySeed(
          uuid: '7a3f0d95-c68d-43ff-b1d0-8db55ca1a8f8',
          type: 'expense',
          name: 'Transportasi',
          iconName: 'bus',
          colorHex: '#1D4ED8',
        ),
        _DefaultCategorySeed(
          uuid: '79a15a36-9e6f-47b2-a9ec-db8f5d278d6f',
          type: 'expense',
          name: 'Kos/Asrama',
          iconName: 'house',
          colorHex: '#0F172A',
        ),
        _DefaultCategorySeed(
          uuid: '9d3c2f85-4b55-4e0c-9b8e-9957eb6d457a',
          type: 'expense',
          name: 'Kuliah/Pendidikan',
          iconName: 'graduation-cap',
          colorHex: '#1E3A8A',
        ),
        _DefaultCategorySeed(
          uuid: '36216d45-9d68-45d8-bfc4-db4d68a02577',
          type: 'expense',
          name: 'Hiburan',
          iconName: 'party-popper',
          colorHex: '#3B82F6',
        ),
        _DefaultCategorySeed(
          uuid: '6b0f537d-b3e8-4d6f-9e79-f607c77180e6',
          type: 'expense',
          name: 'Kesehatan',
          iconName: 'heart-pulse',
          colorHex: '#2563EB',
        ),
        _DefaultCategorySeed(
          uuid: '69934a92-d087-458a-9593-20301766f70f',
          type: 'expense',
          name: 'Belanja',
          iconName: 'shopping-bag',
          colorHex: '#1E40AF',
        ),
        _DefaultCategorySeed(
          uuid: 'cfe9a2ef-64de-4be7-aac0-d6db2ea8ec31',
          type: 'expense',
          name: 'Investasi',
          iconName: 'chart-column',
          colorHex: '#1D4ED8',
        ),
        _DefaultCategorySeed(
          uuid: '1cc2a718-1770-4e80-985c-6e59e1f729df',
          type: 'expense',
          name: 'Tabungan',
          iconName: 'piggy-bank',
          colorHex: '#0F172A',
        ),
        _DefaultCategorySeed(
          uuid: '9c05f636-0c7f-4401-9c10-0f2dfddf0ba7',
          type: 'expense',
          name: 'Lainnya',
          iconName: 'ellipsis',
          colorHex: '#64748B',
        ),
        _DefaultCategorySeed(
          uuid: '40ce0da9-aa0c-4f1d-abcb-67ccf111d99c',
          type: 'income',
          name: 'Uang dari Orang Tua',
          iconName: 'hand-coins',
          colorHex: '#2563EB',
        ),
        _DefaultCategorySeed(
          uuid: '17f9c1d2-30a3-4aaf-a2f3-69235d27cd8e',
          type: 'income',
          name: 'Freelance/Part-time',
          iconName: 'briefcase-business',
          colorHex: '#1D4ED8',
        ),
        _DefaultCategorySeed(
          uuid: 'f9532f5b-553d-4d6f-b01a-23aa52439c1d',
          type: 'income',
          name: 'Beasiswa',
          iconName: 'badge-dollar-sign',
          colorHex: '#0F172A',
        ),
        _DefaultCategorySeed(
          uuid: '62088dbb-47f8-44f6-ae14-8f2fec75e264',
          type: 'income',
          name: 'Gaji',
          iconName: 'wallet',
          colorHex: '#1E3A8A',
        ),
        _DefaultCategorySeed(
          uuid: '17f520c4-593f-44d7-abd8-6909b83a8198',
          type: 'income',
          name: 'Dividen',
          iconName: 'landmark',
          colorHex: '#3B82F6',
        ),
        _DefaultCategorySeed(
          uuid: '1e25df61-cbfc-4566-980f-d0ebf2e2ad4e',
          type: 'income',
          name: 'Bunga/Reward',
          iconName: 'sparkles',
          colorHex: '#2563EB',
        ),
        _DefaultCategorySeed(
          uuid: '67287c49-bdaa-4678-a0fd-145e9623fcad',
          type: 'income',
          name: 'Hadiah',
          iconName: 'gift',
          colorHex: '#1E40AF',
        ),
        _DefaultCategorySeed(
          uuid: '6170ba30-b6fb-4fa8-a122-0c69be474612',
          type: 'income',
          name: 'Lainnya',
          iconName: 'ellipsis',
          colorHex: '#64748B',
        ),
      ];

  Future<List<Category>> getAllActiveCategories() {
    return _isar.categorys
        .filter()
        .isDeletedEqualTo(false)
        .sortByType()
        .thenByName()
        .findAll();
  }

  Future<List<Category>> getByType(String type) {
    return _isar.categorys
        .filter()
        .typeEqualTo(type)
        .and()
        .isDeletedEqualTo(false)
        .sortByName()
        .findAll();
  }

  Future<void> seedDefaultCategoriesIfNeeded() async {
    final List<Category> existing = await _isar.categorys.where().findAll();
    final Set<String> existingUuids = existing
        .map((Category item) => item.uuid)
        .toSet();
    final DateTime now = DateTimeUtils.utcNow();

    final List<Category> missing = _defaultSeeds
        .where((seed) => !existingUuids.contains(seed.uuid))
        .map(
          (seed) => Category(
            uuid: seed.uuid,
            name: seed.name,
            type: seed.type,
            iconName: seed.iconName,
            colorHex: seed.colorHex,
            isDefault: true,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();

    if (missing.isEmpty) {
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.categorys.putAll(missing);
    });
  }

  Future<Category> upsertCategory(Category category) async {
    final DateTime now = DateTimeUtils.utcNow();
    category.updatedAt = now;
    category.createdAt = DateTimeUtils.normalizeUtc(category.createdAt);
    if (category.createdAt.isAfter(now)) {
      category.createdAt = now;
    }
    category.deletedAt = category.isDeleted
        ? (category.deletedAt == null
              ? now
              : DateTimeUtils.normalizeUtc(category.deletedAt!))
        : null;

    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });

    return category;
  }

  Future<void> softDeleteCategory(String uuid) async {
    final Category? category = await _isar.categorys
        .filter()
        .uuidEqualTo(uuid)
        .findFirst();
    if (category == null || category.isDeleted) {
      return;
    }

    final DateTime now = DateTimeUtils.utcNow();
    category.isDeleted = true;
    category.deletedAt = now;
    category.updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });
  }

  Future<Category?> getByUuid(String uuid) {
    return _isar.categorys.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<int> countActiveCategories() {
    return _isar.categorys.filter().isDeletedEqualTo(false).count();
  }
}

class _DefaultCategorySeed {
  const _DefaultCategorySeed({
    required this.uuid,
    required this.type,
    required this.name,
    required this.iconName,
    required this.colorHex,
  });

  final String uuid;
  final String type;
  final String name;
  final String iconName;
  final String colorHex;
}
