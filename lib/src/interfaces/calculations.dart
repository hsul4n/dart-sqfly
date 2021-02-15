/// https://api.rubyonrails.org/v6.0.3.2/classes/ActiveRecord/Calculations.html
abstract class Calculations<T> {
  /// #method-i-average
  Future<int> average(String column);

  /// #method-i-count
  Future<int> count([String column = '*']);

  /// #method-i-ids
  Future<List<dynamic>> get ids;

  /// #method-i-maximum
  Future<dynamic> maximum(String column);

  /// #method-i-minimum
  Future<dynamic> minimum(String column);

  /// #method-i-pick
  Future<List<dynamic>> pick(List<String> columns);

  /// #method-i-pluck
  Future<List<dynamic>> pluck(List<String> columns);

  /// #method-i-sum
  Future<int> sum(String column);
}
