import 'package:sqfly/sqfly.dart';
import 'package:sqfly/src/dao.dart';
import 'package:sqfly/src/relations/relation.dart';

class HasOne<T extends Dao> extends Relation<T> {
  const HasOne();
}
