part of 'package:sqfly/sqfly.dart';

class _SqflyImpl implements Sqfly {
  /// `Data Access Object (DAO)`
  final Map<Type, Dao> daos;

  /// print loggers `
  final bool logger;

  // Database instance
  final sqflite.Database database;

  T call<T extends Dao>() => get<T>();
  T get<T extends Dao>() => daos[T];

  const _SqflyImpl({final this.daos, final this.database, final this.logger});
}
