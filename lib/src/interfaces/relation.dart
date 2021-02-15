/// https://api.rubyonrails.org/v6.0.3.2/classes/ActiveRecord/Relation.html#method-i-any-3F
abstract class Relation<T> {
  /// TODO #method-i-empty-3F | #method-i-none-3F
  // Future<bool> get isEmpty;

  /// TODO #method-i-any-3F
  // Future<bool> get isNotEmpty;

  /// TODO #method-i-many-3F
  // Future<bool> get hasMore;

  /// TODO #method-i-one-3F
  // Future<bool> get hasOne;

  /// TODO #method-i-delete_by
  /// doesn't use callback
  // Future deleteBy({Map<String, dynamic> args});

  /// TODO #method-i-delete_all
  // Future deleteAll();

  /// TODO #method-i-destroy_all
  // Future<List<T>> destroyAll();

  /// TODO #method-i-destroy_by
  // Future destroyBy({Map<String, dynamic> args});

  /// #method-i-to_sql
  String toSql();

  /// #method-i-update_all
  Future updateAll(Map<String, dynamic> args);
}
