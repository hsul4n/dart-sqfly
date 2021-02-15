import 'package:sqfly/sqfly.dart';
import 'package:sqfly/src/dao.dart';

abstract class Relation<T extends Dao> {
  Dao get dao => Sqfly.daos[T];

  const Relation();
}
