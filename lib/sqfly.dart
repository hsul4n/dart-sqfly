library sqfly;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:sqflite/sqflite.dart';
import 'package:sqfly/src/dao.dart';
import 'package:sqfly/src/migration.dart';

export 'src/converter.dart';
export 'src/dao.dart';
export 'src/include.dart';

export 'src/relations.dart';

class Sqfly {
  // your database name
  final String name;

  // your db version
  final int version;

  /// use to import database localy from `assets` folder default `false`
  /// if `true` make sure to locate db file at `assets/database.db`
  final bool import;

  /// list of migrations
  // final List<Migration> migrations;

  /// list of your daos `Data Access Object`
  // static final List<Dao> _daos = [];
  static final Map<Type, Dao> _daos = {};
  static Map<Type, Dao> get daos => _daos;

  static bool logger;

  static Sqfly _instance;
  static Sqfly get instance {
    if (_instance == null)
      throw Exception("Make sure that you called Sqfly.singlton");

    return _instance;
  }

  Sqfly.singlton({
    final this.name,
    @required final this.version,
    @required final List<Dao> daos,
    final this.import = false,
    final bool logger,
    final bool memory,
  }) {
    Sqfly._instance = Sqfly(
      name: name,
      version: version,
      daos: daos,
      import: import,
      logger: logger,
      memory: memory,
    );
  }

  Sqfly({
    final String name,
    @required final this.version,
    @required final List<Dao> daos,
    // final this.migrations = const [],
    final bool import,
    final bool logger,
    final bool memory = false,
  })  :
        // set null name when in-memory
        name = (memory != null && memory) ? null : name,
        assert(version != null && version > 0),
        assert(daos != null && daos.isNotEmpty),
        import = import ?? false

  // /// make sure that can't use memory with import
  // assert(name != null && !import)
  {
    Sqfly.logger = logger ?? kDebugMode;
    for (final dao in daos) Sqfly._daos[dao.runtimeType] = dao;
  }

  // static Dao<T> call2<T>(type) => _daos.firstWhere(
  //       (i) => i.runtimeType == type,
  //       orElse: () => null,
  //     );
  // static Dao get(type) => _daos.firstWhere(
  //       (i) => i.runtimeType == type,
  //       orElse: () => null,
  //     );

  // T call<T>() => _daos[T] as T;
  T call<T>() => _daos.values.whereType<T>().first;
  T get<T>() => this.call<T>();

  static Database _database;
  static Database get database => _database;

  Future<Sqfly> init() async {
    if (_database != null) return this;

    final path = name != null
        ? '${await getDatabasesPath()}/flutter_$name.db'
        : inMemoryDatabasePath;

    if (import) {
      final isExists = await databaseExists(path);

      if (!isExists) {
        // Should happen only the first time you launch your application
        if (logger) print("Creating new copy from assets.database.db");

        // Make sure the parent directory isExists
        try {
          final dir = path.split('/');
          dir.removeLast();

          await Directory(dir.join('/')).create(recursive: true);
        } catch (_) {}

        final data = await rootBundle.load('assets/database.db');

        // Convert to bytes
        final List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        // Write and flush the bytes written
        await File(path).writeAsBytes(bytes, flush: true);
      }
    }

    await openDatabase(
      path,
      version: version,
      onConfigure: (Database database) => Sqfly._database = database,
      onCreate: (_, __) async {
        await Future.forEach(
            _daos.values.map((dao) => dao.schema.sql), database.execute);

        // await Future.forEach(
        //   migrations.where((migration) =>
        //       migration.isUpgrade && migration.to <= version),
        //   (Migration migration) async {
        //     await migration.change(database);
        //   },
        // );
      },
      onUpgrade: (_, int from, int to) async {
        if (Sqfly.logger) print('Upgrading from $from to $to');
        await Future.forEach(Sqfly.daos.values, Migration.force);

        // await Future.forEach(
        //   migrations.where((migration) =>
        //       migration.isUpgrade &&
        //       migration.from >= from &&
        //       migration.to <= to),
        //   (Migration migration) async {
        //     await migration.change(database);
        //   },
        // );
      },
      onDowngrade: (_, int from, int to) async {
        if (Sqfly.logger) print('Downgrading from $from to $to');
        await Future.forEach(Sqfly.daos.values, Migration.force);
        // await Future.forEach(
        //   migrations.where((migration) =>
        //       !migration.isUpgrade &&
        //       migration.from <= from &&
        //       migration.to >= to),
        //   (Migration migration) async {
        //     await migration.change(database);
        //   },
        // );
      },
    );

    return this;
  }
}

// TODO:
// - Fix migrations
// - Finish calculations
// - Finish finders
// - Finish regex for remaining
// - Add test

// TODO:
// - Check UPDATE & DELETE TO USE builder
// - Add testing

// TOOD:
// - Add support for hasOne and belongsTo
// - Finish ReadMe
// - Add testings
