import 'package:flutter/foundation.dart';

class Converter<T> {
  final T Function(Map<String, dynamic>) encode;
  final Map<String, dynamic> Function(T) decode;

  const Converter({@required final this.encode, @required final this.decode});
}
