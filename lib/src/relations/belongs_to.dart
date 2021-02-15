import 'package:sqfly/src/dao.dart';
import 'package:sqfly/src/relations/relation.dart';

class BelongsTo<T extends Dao> extends Relation<T> {
  const BelongsTo();
}
