import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CategoryIconMapper {
  const CategoryIconMapper._();

  static const Map<String, IconData> _iconsByCategoryName = <String, IconData>{
    'Makanan & Minuman': LucideIcons.utensils,
    'Transportasi': LucideIcons.bus,
    'Kos/Asrama': Icons.house_outlined,
    'Kuliah/Pendidikan': LucideIcons.graduationCap,
    'Hiburan': LucideIcons.partyPopper,
    'Kesehatan': LucideIcons.heartPulse,
    'Belanja': LucideIcons.shoppingBag,
    'Investasi': LucideIcons.barChart3,
    'Tabungan': LucideIcons.piggyBank,
    'Uang dari Orang Tua': Icons.volunteer_activism_outlined,
    'Freelance/Part-time': Icons.work_outline,
    'Beasiswa': Icons.attach_money,
    'Gaji': LucideIcons.wallet,
    'Dividen': LucideIcons.landmark,
    'Bunga/Reward': LucideIcons.sparkles,
    'Hadiah': LucideIcons.gift,
    'Lainnya': Icons.more_horiz,
  };

  static IconData fromCategoryName(String categoryName) {
    return _iconsByCategoryName[categoryName.trim()] ?? LucideIcons.wallet;
  }
}
