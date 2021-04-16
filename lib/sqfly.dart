library sqfly;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqfly/src/dao.dart';
import 'package:sqfly/src/migration.dart';

export 'src/converter.dart';
export 'src/dao.dart';
export 'src/include.dart';

export 'src/relations.dart';

part 'src/sqfly_impl.dart';

abstract class Sqfly {
  static _SqflyImpl _instance;
  static _SqflyImpl get instance {
    assert(_instance != null,
        'No instance found, please make sure to call [initialize] before getting instance');
    return _instance;
  }

  static Future<_SqflyImpl> initialize({
    final String name,
    @required final int version,
    @required final List<Dao> daos,
    final String path,
    final bool logger = kDebugMode,
    final bool import = false,
    final bool inMemory = false,
  }) async {
    assert(version != null && version > 0);
    assert(daos != null && daos.isNotEmpty);
    assert(logger != null);
    assert(import != null);
    assert(inMemory != null);
    if (!inMemory)
      assert(
        name != null,
        'Name property is required while not using in-memory database',
      );

    final databasePath = inMemory
        ? sqflite.inMemoryDatabasePath
        : '${path ?? await sqflite.getDatabasesPath()}/$name.db';

    if (import) {
      final isExists = await sqflite.databaseExists(databasePath);

      if (!isExists) {
        // Should happen only the first time you launch your application
        if (logger) print('Creating new copy from "assets/$name.db"');

        // Make sure the parent directory isExists
        try {
          final dir = path.split('/');
          dir.removeLast();

          await Directory(dir.join('/')).create(recursive: true);
        } catch (_) {}

        final data = await rootBundle.load('assets/$name.db');

        // Convert to bytes
        final List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        // Write and flush the bytes written
        await File(path).writeAsBytes(bytes, flush: true);
      }
    }

    return _instance = _SqflyImpl(
      logger: logger,
      daos: Map<Type, Dao>.fromIterable(
        daos,
        key: (dao) => dao.runtimeType,
        value: (dao) => dao,
      ),
      database: await sqflite.openDatabase(
        databasePath,
        version: version,
        onCreate: (database, _) async {
          await Future.forEach(
              daos.map((dao) => dao.schema.sql), database.execute);
        },
        onUpgrade: (sqflite.Database database, int from, int to) async {
          if (logger) print('Upgrading from $from to $to');
          final migration = Migration(database: database, logger: logger);
          await Future.forEach(daos, migration.force);
        },
        onDowngrade: (sqflite.Database database, int from, int to) async {
          if (logger) print('Downgrading from $from to $to');
          final migration = Migration(database: database, logger: logger);
          await Future.forEach(daos, migration.force);
        },
      ),
    );
  }
}
