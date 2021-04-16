import 'package:sqfly/sqfly.dart';
import 'package:sqfly/src/dao.dart';

abstract class Relation<T extends Dao> {
  Dao get dao => Sqfly.instance.daos[T];

  const Relation();
}
