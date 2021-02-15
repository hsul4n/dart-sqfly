import 'package:sqflite_common/src/sql_builder.dart';
import 'package:colorize/colorize.dart';

class Logger {
  static final _stopwatch = Stopwatch();

  Logger._start() {
    _stopwatch
      ..reset()
      ..start();
  }

  Logger.query(Type type, Future future, SqlBuilder builder) {
    Logger._start();
    future.whenComplete(() => print(
        '${_elapsed(type)} ${Colorize(builder.sql)..lightBlue()} [${builder.arguments.join(', ')}]'));
  }

  Logger.insert(Type type, Future future, SqlBuilder builder) {
    Logger._start();
    future.whenComplete(() => print(
        '${_elapsed(type)} ${Colorize(builder.sql)..lightGreen()} [${builder.arguments.join(', ')}]'));
  }

  Logger.update(Type type, Future future, SqlBuilder builder) {
    Logger._start();
    future.whenComplete(() => print(
        '${_elapsed(type)} ${Colorize(builder.sql)..lightYellow()} [${builder.arguments.join(', ')}]'));
  }

  Logger.destroy(Type type, Future future, SqlBuilder builder) {
    Logger._start();
    future.whenComplete(() => print(
        '${_elapsed(type)} ${Colorize(builder.sql)..lightRed()} [${builder.arguments.join(', ')}]'));
  }

  Logger.sql(Future future, String sql) {
    Logger._start();
    future.whenComplete(() => print(
        '${_elapsed('SQL')} ${Colorize(sql.replaceAll(RegExp(r'\s+'), ' ').trim())..lightMagenta()}'));
  }

  Colorize _elapsed(dynamic type) {
    return Colorize('$type (${_stopwatch.elapsed.inMilliseconds}ms)')
      ..lightCyan()
      ..red();
  }
}
