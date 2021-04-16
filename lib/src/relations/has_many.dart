import 'package:sqfly/sqfly.dart';
import 'package:sqfly/src/dao.dart';
import 'package:sqfly/src/relations/relation.dart';

class ProxyHasMany<T extends Dao, R extends Dao> extends Relation<T> {
  List<Dao> get includes => [Sqfly.instance.daos[R]];

  const ProxyHasMany();
}

class Proxy0HasMany<T extends Dao, R1 extends Dao, R2 extends Dao>
    extends ProxyHasMany<T, R1> {
  List<Dao> get includes => super.includes..add(Sqfly.instance.daos[R2]);

  const Proxy0HasMany();
}

class Proxy1HasMany<T extends Dao, R1 extends Dao, R2 extends Dao,
    R3 extends Dao> extends Proxy0HasMany<T, R1, R2> {
  List<Dao> get includes => super.includes..add(Sqfly.instance.daos[R3]);

  const Proxy1HasMany();
}

class HasMany<T extends Dao> extends Relation<T> {
  const HasMany();
}
