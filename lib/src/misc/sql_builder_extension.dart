// ignore: implementation_imports
import 'package:sqflite_common/src/sql_builder.dart';

extension SqlBuilderExtension on SqlBuilder {
  String get fullSql {
    String sqlWithArguments = sql;

    int lastIndex = 0;
    for (int i = 0; i < arguments.length; i++) {
      lastIndex = sqlWithArguments.indexOf('?', lastIndex + 1);
      sqlWithArguments =
          sqlWithArguments.replaceFirst('?', '${arguments[i]}', lastIndex);
    }

    return sqlWithArguments;
  }
}
