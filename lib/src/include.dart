import 'package:sqfly/sqfly.dart';
import 'package:sqfly/src/relations/relation.dart';

class ProxyInclude<T extends Dao, R extends Dao> extends Relation<T> {
  Dao get parent => Sqfly.daos[T];
  List<Dao> get children => [Sqfly.daos[R]];

  const ProxyInclude();

  @override
  String toString() {
    return 'ProxyInclude(parent: ${parent.runtimeType}, children: ${children.map((child) => child.runtimeType).toList()})';
  }
}

class ProxyInclude0<T extends Dao, R1 extends Dao, R2 extends Dao>
    extends ProxyInclude<T, R1> {
  List<Dao> get children => [...super.children, Sqfly.daos[R2]];

  const ProxyInclude0();
}

class ProxyInclude1<T extends Dao, R1 extends Dao, R2 extends Dao,
    R3 extends Dao> extends ProxyInclude0<T, R1, R2> {
  List<Dao> get children => [...super.children, Sqfly.daos[R3]];

  const ProxyInclude1();
}
