abstract class Queryable<T> {
  /// alias for [toList()]
  Future<List<T>> get all;

  /// return items as list of objects
  Future<List<T>> toList();

  /// return items as list of map
  Future<List<Map<String, dynamic>>> toMap();
}
