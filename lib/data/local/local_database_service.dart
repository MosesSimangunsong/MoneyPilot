import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'isar_collections.dart';

class LocalDatabaseService {
  LocalDatabaseService();

  Isar? _isar;

  Isar get isar {
    final Isar? instance = _isar;
    if (instance == null) {
      throw StateError('Database belum diinisialisasi.');
    }
    return instance;
  }

  Future<void> init({String? directoryPath}) async {
    if (_isar != null) {
      return;
    }

    final String targetDirectory =
        directoryPath ?? await _resolveDirectoryPath();
    _isar = await Isar.open(
      moneyPilotSchemas,
      directory: targetDirectory,
      name: 'money_pilot',
      inspector: false,
    );
  }

  Future<void> close() async {
    final Isar? instance = _isar;
    if (instance == null || !instance.isOpen) {
      return;
    }

    await instance.close();
    _isar = null;
  }

  Future<String> _resolveDirectoryPath() async {
    final Directory directory = await getApplicationSupportDirectory();
    return directory.path;
  }
}
