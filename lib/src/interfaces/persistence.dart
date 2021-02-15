import 'package:sqfly/src/interfaces/queryable.dart';

/// https://api.rubyonrails.org/v6.0.3.2/classes/ActiveRecord/Persistence/ClassMethods.html
abstract class Persistence<T> implements Queryable<T> {
  /// #method-i-create
  Future<dynamic> create(T item);

  /// same [create] but as list
  Future createAll(List<T> items);

  /// #method-i-insert
  Future<dynamic> insert(Map<String, dynamic> item);

  /// same [insert] but as list
  Future insertAll(List<Map<String, dynamic>> items);

  /// #method-i-update
  Future<int> update(T item);

  /// #method-i-delete
  Future<int> delete(T item);

  /// #method-i-destroy
  Future<int> destroy(int id);
  Future<int> destroyAll();
}
