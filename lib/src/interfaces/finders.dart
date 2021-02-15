/// https://api.rubyonrails.org/v6.0.3.2/classes/ActiveRecord/FinderMethods.html
abstract class Finders<T> {
  /// #method-i-exists-3F
  Future<bool> isExists(Map<String, dynamic> args);

  /// #method-i-find_by
  Future<T> findBy(Map<String, dynamic> args);

  /// #method-i-find
  Future<T> find(int id);

  /// #method-i-first
  Future<T> get first;

  /// #method-i-last
  Future<T> get last;

  /// #method-i-take
  Future<List<T>> take([int limit = 1]);
}
