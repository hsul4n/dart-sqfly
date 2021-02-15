import 'package:sqfly/src/interfaces/calculations.dart';
import 'package:sqfly/src/interfaces/finders.dart';
import 'package:sqfly/src/interfaces/queryable.dart';
import 'package:sqfly/src/interfaces/relation.dart';

/// https://api.rubyonrails.org/v6.0.3.2/classes/ActiveRecord/QueryMethods.html
abstract class Queries<T>
    implements Relation<T>, Finders<T>, Calculations<T>, Queryable<T> {
  /// #method-i-select
  Queries<T> select(List<String> args);

  /// #method-i-where
  Queries<T> where(Map<String, dynamic> args);

  /// #method-i-or
  Queries<T> or(Map<String, dynamic> args);

  /// https://api.rubyonrails.org/v6.0.3.2/classes/ActiveRecord/QueryMethods/WhereChain.html#method-i-not
  Queries<T> not(Map<String, dynamic> args);

  /// #method-i-includes
  Queries<T> includes(List<Type> args);

  /// #method-i-joins
  Queries<T> joins(List<Type> args);

  /// #method-i-limit
  Queries<T> limit(int value);

  /// #method-i-offset
  Queries<T> offset(int value);

  /// #method-i-group
  Queries<T> group(List<String> args);

  /// #method-i-having
  Queries<T> having(String args);

  /// #method-i-distinct
  Queries<T> distinct([bool value = true]);

  /// #method-i-order
  Queries<T> order(List<String> args);
}
