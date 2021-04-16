import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqfly/sqfly.dart';
import 'package:sqfly/src/definitions/foreign_key.dart';
import 'misc/sql_builder_extension.dart';
import 'package:sqfly/src/interfaces/persistence.dart';
import 'package:sqfly/src/converter.dart';
import 'package:sqflite/sqflite.dart' show Database;
import 'package:sqfly/src/interfaces/queries.dart';
import 'package:sqfly/src/logger.dart';
import 'package:sqfly/src/relations/relation.dart';
import 'package:sqfly/src/relations/has_one.dart';
import 'package:sqfly/src/definitions/schema.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/sql_builder.dart';
import 'package:core_extension/core_extension.dart';

class Dao<T> implements Queries<T>, Persistence<T> {
  final Schema schema;
  final Converter<T> converter;
  final List<Relation> relations;

  Dao(
    final String sql, {
    @required final this.converter,
    this.relations = const [],
  })  : assert(sql != null),
        assert(converter != null),
        schema = Schema(sql);

  Type get type => T;
  Database get database => Sqfly.instance.database;
  bool get isLogger => Sqfly.instance.logger;

  final List<String> _select = [];
  final List<String> _columns = [];
  final Map<String, dynamic> _where = {};
  final Map<String, dynamic> _or = {};
  final List<String> _group = [];
  final List<String> _having = [];
  final List<String> _order = [];
  final List<Dao> _includes = [];
  final List<Dao> _joins = [];
  int _limit, _offset;
  bool _distinct;

  String get _whereQuery => _where.isEmpty && _or.isEmpty
      ? null
      : [_where.keys.join(' AND '), _or.keys.map((key) => ' OR $key').join()]
          .join();

  List<dynamic> get _whereArgs => [..._where.values, ..._or.values].flatten;

  /// Relation
  @override
  Future<int> updateAll(Map<String, dynamic> values) async {
    final builder = SqlBuilder.update(
      schema.table,
      values,
      where: _whereQuery,
      whereArgs: _whereArgs,
    );

    final completer = Completer<int>()
      ..complete(database.rawUpdate(builder.sql, builder.arguments));

    if (isLogger) Logger.update(type, completer.future, builder);

    return await completer.future.whenComplete(clear);
  }

  @override
  String toSql() {
    final builder = _copyQueryWith();
    clear();
    return builder.fullSql;
  }

  /// Calculations
  @override
  Future<int> average(String column) async {
    final builder = _copyQueryWith(columns: ['AVG($column)']);

    final completer = Completer<List<Map<String, dynamic>>>()
      ..complete(database.rawQuery(builder.sql, builder.arguments));

    if (isLogger) Logger.query(type, completer.future, builder);
    final result = await completer.future;

    return result?.first?.values?.firstOrNull as int;
  }

  @override
  Future<int> count([String column = '*']) async {
    final builder = _copyQueryWith(columns: ['COUNT($column)']);

    final completer = Completer<List<Map<String, dynamic>>>()
      ..complete(database.rawQuery(builder.sql, builder.arguments));

    if (isLogger) Logger.query(type, completer.future, builder);
    final result = await completer.future;

    return result?.firstOrNull?.values?.firstOrNull as int;
  }

  @override
  Future<List<dynamic>> get ids async {
    final builder =
        _copyQueryWith(columns: ['${schema.table}.${schema.primaryKey}']);

    final completer = Completer<List<Map<String, dynamic>>>()
      ..complete(database.rawQuery(builder.sql, builder.arguments));

    if (isLogger) Logger.query(type, completer.future, builder);
    final result = await completer.future;

    return result.expand((item) => item.values).toList();
  }

  @override
  Future<int> maximum(String column) async {
    final builder = _copyQueryWith(columns: ['MAX($column)']);

    final completer = Completer<List<Map<String, dynamic>>>()
      ..complete(database.rawQuery(builder.sql, builder.arguments));

    if (isLogger) Logger.query(type, completer.future, builder);
    final result = await completer.future;

    return result.firstOrNull?.values?.firstOrNull as int;
  }

  @override
  Future<int> minimum(String column) async {
    final builder = _copyQueryWith(columns: ['MIN($column)']);

    final completer = Completer<List<Map<String, dynamic>>>()
      ..complete(database.rawQuery(builder.sql, builder.arguments));

    if (isLogger) Logger.query(type, completer.future, builder);
    final result = await completer.future;

    return result?.firstOrNull?.values?.firstOrNull as int;
  }

  @override
  Future<List<dynamic>> pick(List<String> columns) async {
    return limit(1).pluck(columns).then((value) => value.firstOrNull);
  }

  @override
  Future<List<dynamic>> pluck(List<String> columns) async {
    final builder = _copyQueryWith(
        columns: columns.map((column) => '${schema.table}.$column').toList());

    final completer = Completer<List<Map<String, dynamic>>>()
      ..complete(database.rawQuery(builder.sql, builder.arguments));

    if (isLogger) Logger.query(type, completer.future, builder);
    final result = await completer.future
        .then((value) => value.map((item) => item.values.toList()).toList())
        .whenComplete(clear);

    return columns.length == 1 ? result?.flatten : result;
  }

  @override
  Future<int> sum(String column) async {
    final builder = _copyQueryWith(columns: ['SUM($column)']);

    final completer = Completer<List<Map<String, dynamic>>>()
      ..complete(database.rawQuery(builder.sql, builder.arguments));

    if (isLogger) Logger.query(type, completer.future, builder);
    final result = await completer.future;

    return result?.firstOrNull?.values?.firstOrNull as int;
  }

  // Queries
  @override
  Queries<T> select(List<String> args) {
    return this.._columns.addAll(args.map((arg) => '${schema.table}.$arg'));
  }

  @override
  Queries<T> distinct([bool value = true]) {
    return this.._distinct = value;
  }

  @override
  Queries<T> group(List<String> args) {
    return this.._group.addAll(args.map((arg) => '${schema.table}.$arg'));
  }

  @override
  Queries<T> having(String opts) {
    return this.._having.add(opts);
  }

  @override
  Queries<T> order(List<String> columns) {
    return this
      .._order.addAll(columns
          .map((item) => item.split(' ').length > 1 ? item : '$item ASC'));
  }

  @override
  Queries<T> where(Map<String, dynamic> args) {
    return this
      .._where.addAll(args.map((key, value) {
        key = key.trim();
        if (!key.contains(' ')) key += ' = ?';
        // if (value == null)
        return MapEntry('${schema.table}.$key', value);
      }));
  }

  @override
  Queries<T> or(Map<String, dynamic> args) {
    return this
      .._or.addAll(
          args.map((key, value) => MapEntry('${schema.table}.$key', value)));
  }

  /// where.not({'name = 'Sam'})
  /// `SELECT * FROM users WHERE NOT (name = 'Sam')`
  /// where.not({['name = ?', 'Sam']})
  /// `SELECT * FROM users WHERE NOT (name = 'Sam')`
  /// where.not({'name': 'Sam'})
  /// `SELECT * FROM users WHERE name != 'Sam'`
  /// where.not({'name': nil})
  /// `SELECT * FROM users WHERE name IS NOT NULL`
  /// where.not({'name': ['Ali', 'Sam']})
  /// `SELECT * FROM users WHERE name NOT IN ('Ko1', 'Nobu')`
  /// ```
  @override
  Queries<T> not(Map<String, dynamic> args) {
    throw UnimplementedError();
    // return where(args.map((key, value) => MapEntry('$key != ?', value)));
  }

  @override
  Queries<T> limit(int value) {
    return this.._limit = value;
  }

  @override
  Queries<T> offset(int value) {
    return this.._offset = value;
  }

  /// will include inside book currency
  /// {
  ///   accounting_book: {
  ///     id: 1,
  ///     ...
  ///   },
  ///   currency: {
  ///     id: 1,
  ///     ...
  ///   }
  /// }
  // ProxyInclude0<AccountingBookAuditDao, AccountingBookDao, CurrencyDao>(),
  @override
  Queries<T> includes(List args) {
    _includes
      ..clear()
      // ..addAll(args.map((arg) => Sqfly.daos[arg]).toList());
      ..addAll(args.map((arg) {
        // Dao dig(item) {
        //   Dao value;

        //   if (item is Dao)
        //     value = Sqfly.daos[arg];
        //   else if (arg is ProxyInclude) {
        //     value = arg.includes.removeAt(0);
        //     value.includes(arg.includes);
        //   } else if (arg is ProxyInclude0) {
        //     value = arg.includes.removeAt(0);
        //     value.includes(arg.includes);
        //   } else if (arg is ProxyInclude1) {
        //     value = arg.includes.removeAt(0);
        //     value.includes(arg.includes);
        //   }
        //   // else if (arg is Map) {
        //   //   value = Sqfly.daos[arg.keys.first];
        //   //   // value.includes(arg.values);
        //   //   // arg.values.forEach(dig);
        //   // }

        //   return value;
        // }

        Dao value;

        final isDao = Sqfly.instance.daos.containsKey(arg);

        if (isDao) {
          value = Sqfly.instance.daos[arg];
        } else if (arg is ProxyInclude) {
          value = arg.parent;
          value.includes(arg.children);
          print(arg);
        }

        return value;
      }));

    // _includes.forEach((inc) {
    //   print(inc);
    //   inc?._includes?.forEach(print);
    // });

    return this;
  }

  @override
  Queries<T> joins(List<Type> args) {
    _joins
      ..clear()
      ..addAll(
        args.map((arg) {
          final dao = Sqfly.instance.daos[arg];

          /// get [include] ForeignKey
          final foreignKey = schema.foreignKeys.find(
            (foreignKey) => foreignKey.reference.table == dao.schema.table,
          );

          /// Add inner join
          _select.add(
              'INNER JOIN ${dao.schema.table} ON ${dao.schema.table}.${dao.schema.primaryKey} = ${schema.table}.${foreignKey.parent}');

          /// Add inner join columns
          _columns.addAll(
            dao.schema.columns.map((column) {
              /// table.column AS type_column
              return '${dao.schema.table}.${column.name} AS ${dao.type.toString().toCamelCase()}_${column.name}';
            }).toList(),
          );

          return dao;
        }),
      );

    return this;
  }

  /// Finders
  @override
  Future<bool> isExists(Map<String, dynamic> args) async {
    return findBy(args).then((value) => value != null);
  }

  @override
  Future<T> find(int id) async {
    return where({schema.primaryKey: id}).first;
  }

  @override
  Future<T> findBy(Map<String, dynamic> args) async {
    return where(args).first;
  }

  @override
  Future<T> get first async {
    return this.limit(1).toList().then((value) => value.firstOrNull);
  }

  @override
  Future<T> get last async {
    return this.toList().then((value) => value.lastOrNull);
  }

  @override
  Future<List<T>> take([int limit = 1]) async {
    return this.limit(limit).toList();
  }

  /// Persistence
  @override
  Future<dynamic> create(T item) async {
    return await insert(converter.decode(item));
  }

  @override
  Future createAll(List<T> items) async {
    return await Future.forEach(items, (item) async => await create(item));
  }

  @override
  Future<dynamic> insert(Map<String, dynamic> values) async {
    Future<dynamic> call() async {
      final builder = SqlBuilder.insert(schema.table, values);

      final completer = Completer<int>()
        ..complete(database.rawInsert(builder.sql, builder.arguments));
      if (isLogger) Logger.insert(type, completer.future, builder);

      final id = await completer.future;

      // assign primary key to values if not exists
      if (values[schema.primaryKey] == null) values[schema.primaryKey] = id;

      /// assign primary key to values
      return values[schema.primaryKey];
    }

    for (final relation in relations) {
      /// [belongs-to]
      /// ```
      /// class DogDao extends Dao<Dog> {
      ///   DogDao()
      ///       : super(
      ///           '''
      ///           CREATE TABLE dogs (
      ///             id        INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      ///             person_id INTEGER NOT NULL,
      ///             name      TEXT    NOT NULL,
      ///
      ///             FOREIGN KEY (person_id) REFERENCES persons (id)
      ///           )
      ///           ''',
      ///           relations: [
      ///             BelongsTo<PersonDao>(),
      ///           ],
      ///           converter: Converter(
      ///             encode: (todo) => Dog.fromMap(todo),
      ///             decode: (todo) => todo.toMap(),
      ///           ),
      ///         );
      /// }
      /// ```
      /// When using [belongs-to] association we must add `FOREIGN KEY` to SQL defention
      /// Also `Dog` model class must have `Person` property as shown below
      /// ```
      /// class Dog {
      ///   final int id;
      ///   final String name;
      ///   final Person person;
      ///
      ///   const Dog({this.id, this.person, this.name});
      ///
      ///   Dog.fromMap(Map<String, dynamic> map)
      ///       : id = map['id'],
      ///         name = map['name'],
      ///         person = Person.fromMap(map['person']);
      ///
      ///   Map<String, dynamic> toMap() => {
      ///         'id': id,
      ///         'name': name,
      ///         'person': person?.toMap(),
      ///       };
      /// }
      /// ```
      /// Usage
      /// ```
      /// await Sqfly.instance<DogDao>().create(
      ///   Dog(
      ///     name: 'Dog-1',
      ///     person: Person(name: 'Person-1'),
      ///   ),
      /// );
      /// ```
      if (relation is BelongsTo) {
        print('$type ${relation.runtimeType}');

        /// 1. Insert master `Person` and return id
        /// 2. Add `person_id` foreign key to `Dog` assocation
        /// 3. Insert association

        /// Extract [belongs-to] association from master
        /// `Dog{ name: 'Roze', person: Person{ name: 'Hamzah' } }`
        /// `Person{ name: 'Hamzah' }`
        ///

        print('values $values');

        final assocation = values.remove('${relation.dao.type}'.toCamelCase())
            as Map<String, dynamic>;

        if (assocation != null) {
          final assocationRelation = relation.dao.relations
              .find((rel) => rel.dao.schema.table == schema.table);

          /// Convert relation to [has-one] or [has-many]
          /// and use insert which will trigger later the relation
          if (assocationRelation is HasOne)
            assocation['$type'.toCamelCase()] = values;
          else if (assocationRelation is HasMany)
            assocation[schema.table] = [values];

          return relation.dao.insert(assocation);

          /// `Person{ name: 'Hamzah', dog: { name: 'Roze' } }`
          /// `Person` doesn't have `id` so it need's to be inserted
          // if (assocation[relation.dao.schema.primaryKey] == null) {
          //   // find the relationship between Person & Dog ()
          //   /// if relationship between Person & Dog [has-one]
          //   /// `Dog{ name: 'Roze', person: Person{ name: 'Hamzah' }}`
          //   /// else if [has-many]
          //   /// `Dog{ name: 'Roze', people: [ { name: 'Hamzah' } ] }`

          //   // person
          //   print(assocation);

          //   // if ()
          //   // assocation[]

          //   // if (relation is has many);
          //   // reference[schema.table] = [values];
          //   // else // relation has one
          //   // reference['$type'.toCamelCase()] = values;

          //   // print(reference);

          //   /// call insert and will catch `HasMany` values
          //   // return relation.dao.insert(reference);

          //   return {};
          // }

          /// If reference was found for example:
          /// `Dog{ name: 'Roze' }`
          /// so we need to pass `Person` [primaryKey] into [values] for example:
          /// `Dog{ name: 'Roze', person_id: 4 }`
          /// don't use call because will call at end below
          // else {
          //   /// load `foreignKey`
          //   final foreignKey = schema.foreignKeys.find(
          //     (fk) => fk.reference.table == relation.dao.schema.table,
          //   );

          //   values[foreignKey.parent] =
          //       assocation[relation.dao.schema.primaryKey];
          // }
        }
      }

      /// [has-one]
      /// ```
      /// class PersonDao extends Dao<Person> {
      ///   PersonDao()
      ///       : super(
      ///           '''
      ///           CREATE TABLE people (
      ///             id     INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      ///             name   TEXT    NOT NULL
      ///           )
      ///           ''',
      ///           relations: [
      ///             HasOne<DogDao>(),
      ///           ],
      ///           converter: Converter(
      ///             encode: (person) => Person.fromMap(person),
      ///             decode: (person) => person.toMap(),
      ///           ),
      ///         );
      /// }
      /// ```
      /// When using [has-one] association `DogDao` must have `person_id` with `uniqueness` to avoid duplication
      /// Also `Person` model class must contain `Dog` property as shown below
      /// ```
      /// class Person {
      ///   final int id;
      ///   final String name;
      ///
      ///   final Dog dog;
      ///
      ///   const Person({this.id, this.name, this.dog});
      ///
      ///   Person.fromMap(Map<String, dynamic> map)
      ///       : id = map['id'],
      ///         name = map['name'],
      ///         dog = Dog.fromMap(map['dog']);
      ///
      ///   Map<String, dynamic> toMap() => {
      ///         'id': id,
      ///         'name': name,
      ///         'dog': dog?.toMap(),
      ///       };
      /// }
      /// ```
      /// Usage
      /// ```
      /// await Sqfly.instance<PersonDao>().create(
      ///   Person(
      ///     name: 'Person-1',
      ///     dog: Dog(name: 'Dog-1'),
      ///   ),
      /// );
      /// ```
      else if (relation is HasOne) {
        print('$type ${relation.runtimeType}');

        /// 1. Insert master `Person` and return id
        /// 2. Add `person_id` foreign key to `Dog` assocation
        /// 3. Insert association

        /// Make sure to remove `relation` object from master for example:
        /// `Person{ name: 'Hamzah', dogs: [ { name: 'Roze' }, ...])`
        /// need to be seprate array so we'll start insert master then `relation`
        /// `[Dog{ name: 'Roze' }, ...]`
        final association = values.remove('${relation.dao.type}'.toCamelCase())
            as Map<String, dynamic>;

        /// insert master will add id into values
        await call();

        if (values[schema.primaryKey] == -1)
          return throw Exception(
            'Something went wrong while inserting $runtimeType',
          );

        if (association != null) {
          final foreignKey = relation.dao.schema.foreignKeys.find(
            (fk) => fk.reference.table == schema.table,
          );

          if (foreignKey != null) {
            /// `dogs` now dependent on `person` to be inserted first for example:
            /// `Person{ name: 'Hamzah', dog_id: null }`
            /// so we need pass `foreignKey` into master for example:
            /// `Person{ name: 'Hamzah', dog: Dog{ id: 1, name: 'Roze' } }`
            /// use nested object to callback every relation between daos
            ///
            ///
            /// `[Dog{ name: 'Roze' }, ...]`
            /// `[Dog{ name: 'Roze', person_id: 1 }]`
            association[foreignKey.parent] = values[schema.primaryKey];

            await relation.dao.insert(association);

            /// Set `null` relation attribute to avoid `null` exception while converting
            values['$relation.dao.type}'.toCamelCase()] = null;

            // master['$type'.toCamelCase()] = association;

            /// add assocation to master
            // values['$type'.toCamelCase()] =await relation.dao.insert(association);
            // print();
            print(association);

            return values[schema.primaryKey];
          } else
            throw Exception(
              '''
              $runtimeType: couldn\'t find foreign key for ${schema.table}\n
              Make sure to add HasOne<${relation.dao.type}> in $runtimeType
              ''',
            );
        }
      }

      /// [has-many]
      /// ```
      /// class PersonDao extends Dao<Person> {
      ///   PersonDao()
      ///       : super(
      ///           '''
      ///           CREATE TABLE people (
      ///             id     INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      ///             name   TEXT    NOT NULL
      ///           )
      ///           ''',
      ///           relations: [
      ///             HasMany<DogDao>(),
      ///           ],
      ///           converter: Converter(
      ///             encode: (person) => Person.fromMap(person),
      ///             decode: (person) => person.toMap(),
      ///           ),
      ///         );
      /// }
      /// ```
      /// When using [has-many] association `DogDao` must have `person_id`
      /// Also `Person` model class should contain `List<Dog>` property as shown below
      /// ```
      /// class Person {
      ///   final int id;
      ///   final String name;
      ///   final List<Dog> dogs;
      ///
      ///   const Person({this.id, this.name, this.dogs});
      ///
      ///   Person.fromMap(Map<String, dynamic> map)
      ///       : id = map['id'],
      ///         name = map['name'],
      ///         dogs = map['dogs'].map((dog) => Dog.fromMap(dog)).toList();
      ///
      ///   Map<String, dynamic> toMap() => {
      ///         'id': id,
      ///         'name': name,
      ///         'dogs': dogs?.map((todo) => todo.toMap())?.toList(),
      ///       };
      /// }
      /// ```
      /// Usage
      /// ```
      /// await Sqfly.instance<PersonDao>().create(
      ///   Person(
      ///     name: 'Person-1',
      ///     dogs: List.generate(3, (i) => Dog(name: 'Dog-$i'),
      ///     ),
      ///   ),
      /// );
      /// ```
      else if (relation is HasMany) {
        /// 1. Remove relation attributes.
        /// 2. Insert master `Person` and return id
        /// 3. Loop throw all dogs attributes and add foreign key `person_id`
        /// 5. Insert associations

        print(
            '$runtimeType has_many ${relation.dao.type} via ${relation.dao.schema.table}');

        /// Make sure to remove `relation` object from master for example:
        /// `Person{ name: 'Hamzah', dogs: [ { name: 'Roze' }, ...])`
        /// need to be seprate array so we'll start insert master then `relation`
        /// `[Dog{ name: 'Roze' }, ...]`
        final associations = values.remove(relation.dao.schema.table)
            as List<Map<String, dynamic>>;

        /// insert master will fill id in values
        await call();

        /// make sure that insert was success
        if (values[schema.primaryKey] == -1)
          return throw Exception(
            'Something went wrong while inserting $runtimeType',
          );

        if (associations != null) {
          /// load foreign key
          final foreignKey = relation.dao.schema.foreignKeys.find(
            (fk) => fk.reference.table == schema.table,
          );

          if (foreignKey != null) {
            /// `dogs` now dependent on `person` to be inserted first for example:
            /// `Person{ name: 'Hamzah', dog_id: null }`
            /// so we need pass `foreignKey` into master for example:
            /// `Person{ name: 'Hamzah', dog: Dog{ id: 1, name: 'Roze' } }`
            /// use nested object to callback every relation between daos

            /// `[Dog{ name: 'Roze' }, ...]`
            /// `[Dog{ name: 'Roze', person_id: 1 }]`
            for (final association in associations)
              association[foreignKey.parent] = values[schema.primaryKey];
            // association['$type'.toCamelCase()] = values;

            await relation.dao.insertAll(associations);

            /// Set empty relation attribute to avoid `null` exception while converting
            values[relation.dao.schema.table] = [];

            return values[schema.primaryKey];
          } else
            throw Exception(
              '''
              $runtimeType: couldn\'t find foreign key for ${schema.table}
              Make sure to add HasMany<${relation.dao.type}> in $runtimeType
              ''',
            );
        }
      }
    }

    return call();
  }

  @override
  Future insertAll(List<Map<String, dynamic>> items) async {
    await Future.forEach(items, (item) async => await insert(item));
  }

  @override
  Future<int> update(T item) async {
    final values = converter.decode(item);

    where({schema.primaryKey: values.remove(schema.primaryKey)});

    /// Remove any relation attributes
    for (final relation in relations)
      if (relation is HasMany)
        values.remove(relation.dao.schema.table);
      else if (relation is BelongsTo) values.remove(relation.dao.type);

    final builder = SqlBuilder.update(
      schema.table,
      values,
      where: _whereQuery,
      whereArgs: _whereArgs,
    );

    final completer = Completer<int>()
      ..complete(database.rawUpdate(builder.sql, builder.arguments));

    if (isLogger) Logger.update(type, completer.future, builder);

    return await completer.future.whenComplete(clear);
  }

  @override
  Future<int> delete(T item) async {
    final values = converter.decode(item);

    where({schema.primaryKey: values.remove(schema.primaryKey)});

    final builder = SqlBuilder.delete(
      schema.table,
      where: _whereQuery,
      whereArgs: _whereArgs,
    );

    final completer = Completer<int>()
      ..complete(database.rawDelete(builder.sql, builder.arguments));

    if (isLogger) Logger.destroy(type, completer.future, builder);

    return await completer.future.whenComplete(clear);
  }

  @override
  Future<int> destroy(int id) async {
    final builder = SqlBuilder.delete(
      schema.table,
      where: '${schema.table}.${schema.primaryKey} = ?',
      whereArgs: [id],
    );

    final completer = Completer<int>()
      ..complete(database.rawDelete(builder.sql, builder.arguments));

    if (isLogger) Logger.destroy(type, completer.future, builder);

    return await completer.future;
  }

  @override
  Future<int> destroyAll() async {
    final builder = SqlBuilder.delete(schema.table, whereArgs: []);

    final completer = Completer<int>()
      ..complete(database.rawDelete(builder.sql, builder.arguments));

    if (isLogger) Logger.destroy(type, completer.future, builder);

    return await completer.future;
  }

  @override
  Future<List<T>> toList() async {
    return (await toMap()).map((item) => converter.encode(item)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> toMap() async {
    if (_offset != null && _limit == null)
      return throw UnsupportedError(
        'You need to pass LIMIT when using OFFSET\n'
        'Use: dao.limit(x).offset(x) instead of dao.offset(x)',
      );

    if (_having.isNotEmpty && _group.isEmpty)
      return throw UnsupportedError(
        'You need to pass GROUP BY when using HAVING\n'
        'Use: dao.having(x).group(x) instead of dao.having(x)',
      );

    if (_or.isNotEmpty && _where.isEmpty)
      return throw UnsupportedError(
        'You need to pass WHERE when using OR\n'
        'Use: dao.where(x).or(x) instead of dao.or(x)',
      );

    final builder = _copyQueryWith();

    final completer = Completer<List<Map<String, dynamic>>>()
      ..complete(database.rawQuery(builder.sql, builder.arguments));

    if (isLogger) Logger.query(type, completer.future, builder);

    /// use mapping to convert `QueryRow` into `Map` so we can edit that list
    final items = await completer.future.then(
      (values) => values.map((value) {
        var item = Map<String, dynamic>.from(value);

        /// Search for any join to convert join to nested attributes for example:
        /// ```sql
        /// SELECT
        ///   dogs.*,
        ///   persons.id AS person_id,
        ///   persons.name AS person_name,
        /// FROM dogs
        ///   INNER JOIN persons ON persons.id = dogs.person_id
        /// ```
        /// Will convert person_* attributes inside person mapped
        /// Dog{ id: 1, name: 'Roze', person: Person{ id: 1, name: 'Mike' } }
        // for (final join in _joins) item.nest('${join.type}'.toCamelCase());

        ///
        for (final relation in relations) {
          final join = _joins.find((join) => join.type == relation.dao.type);
          final include =
              _includes.find((include) => include.type == relation.dao.type);

          if (join != null) item.nest('${join.type}'.toCamelCase());

          /// nest item if no include
          if (include == null) {
            final foreignKey = schema.foreignKeys.find(
              (fk) => fk.reference.table == relation.dao.schema.table,
            );

            if (foreignKey != null)
              item.nest('${relation.dao.type}'.toCamelCase());
          }

          // if (include != null) {
          //   if (relation is BelongsTo) {
          //     foreignKeys[relation.dao.type] = schema.foreignKeys.find(
          //       (fk) => fk.reference.table == include.schema.table,
          //     );

          //     print('Belongs to ${foreignKeys[relation.dao.type]}');
          //   } else if (relation is HasOne) {
          //     foreignKeys[relation.dao.type] =
          //         relation.dao.schema.foreignKeys.find(
          //       (fk) => fk.reference.table == schema.table,
          //     );

          //     // Person hsa one dog
          //     print(relation.dao);
          //   }
          //   // for (final include in _includes){}
          //   /// TODO indludes
          // } else {
          //   final foreignKey = schema.foreignKeys.find(
          //     (fk) => fk.reference.table == relation.dao.schema.table,
          //   );

          //   if (foreignKey != null)
          //     item.nest('${relation.dao.type}'.toCamelCase());
          // }
        }

        return item;
      }).toList(),
    );

    /// include associations
    // for (final include in _includes)
    for (final include in _includes) {
      final relation = relations.find(
          (relation) => relation.dao.schema.table == include.schema.table);

      print(relation);

      // ForeignKey foreignKey;

      /// we should load dogs related to person
      /// ```dart
      /// sqfly<DogDao>().includes([PersonDao]).toList();
      /// ```
      /// ```sql
      /// SELECT * FROM people WHERE id = ?
      /// ```
      if (relation is BelongsTo) {
        final foreignKey = schema.foreignKeys.find(
          (fk) => fk.reference.table == include.schema.table,
        );

        /// collect ids to avoid duplication
        final foreignKeys =
            items.map((item) => item[foreignKey.parent]).toSet().toList();

        // if not empty
        if (foreignKeys.isNotEmpty) {
          /// if length is only one record then use a simple where statment
          if (foreignKeys.length == 1) {
            include.where({include.schema.primaryKey: foreignKeys.first});
          }

          /// else use where in
          else {
            include.where({
              '${include.schema.primaryKey} IN (${List.filled(foreignKeys.length, '?').join(',')})':
                  foreignKeys
            }).limit(foreignKeys.length);
          }

          final associations = await include.toMap();

          /// add all associations to object for example:
          /// `Dog{ name: 'Hamzah', person_id: 1 }`
          /// we need to remove `foreginKey` and add object for example:
          /// `Dog{ name: 'Hamzah', person: Person{ id: 1, name: 'Sam' } }`
          for (final item in items) {
            final association = associations.find(
              (association) {
                final primaryKey = association[include.schema.primaryKey];

                /// search for `primaryKey` that matches item `foreignKey` for example:
                /// `Person{ id: 1 } == Item{ personId: 1 }`
                return primaryKey == item[foreignKey.parent];
              },
            );

            /// remove foreignKey from item for example:
            /// `Dog{ name: 'Hamzah', person_id: 1 }`
            /// Will remove the `foreignKey` from map because it's already exists on [association] object
            /// `Dog{ name: 'Hamzah' }`
            // item.remove(foreignKey.parent);

            /// remove foreignKey from item:
            /// `Dog{ name: 'Hamzah', person: Person{ id: 1 } }`
            /// Will remove the `foreignKey` from map because it's already exists on [association] object
            /// `Dog{ name: 'Hamzah' }`
            // item.remove(foreignKey.parent);

            /// assign association to parent
            /// `Dog{ name: 'Hamzah' }`
            /// Will became
            /// `Dog{ name: 'Hamzah', person: Person{ id: 1, name: 'Sam' } }`
            item['${include.type}'.toCamelCase()] = association;
          }
        }
      }

      /// ```dart
      /// sqfly<PersonDao>().includes([DogDao]).toList();
      /// ```
      /// ```dart
      /// SELECT * FROM dogs WHERE person_id = ?
      /// ```
      /// if (relation is HasOne || relation is HasMany || relation is ProxyHasMany)
      else {
        final foreignKey = relation.dao.schema.foreignKeys.find(
          (fk) => fk.reference.table == schema.table,
        );

        /// just removed
        // if (relation is ProxyHasMany && relation.includes.isNotEmpty) {
        //   print(relation.includes);
        //   include
        //       .includes(relation.includes.map((i) => i.runtimeType).toList());
        // }

        /// collect ids to avoid duplication
        final primaryKeys =
            items.map((item) => item[schema.primaryKey]).toSet().toList();

        // if not empty
        if (primaryKeys.isNotEmpty) {
          /// if length is only one record then use a simple where statment
          if (primaryKeys.length == 1)
            include.where({foreignKey.parent: primaryKeys.first});

          /// else use where in
          else
            include.where({
              '${foreignKey.parent} IN (${List.filled(primaryKeys.length, '?').join(',')})':
                  primaryKeys
            }).limit(primaryKeys.length);

          final associations = await include.toMap();

          for (final item in items) {
            /// assign association to parent
            /// `Dog{ name: 'Hamzah' }`
            /// Will became
            /// `Dog{ name: 'Hamzah', person: Person{ id: 1, name: 'Sam' } }`
            if (relation is HasOne) {
              item['${include.type}'.toCamelCase()] = associations.find(
                (association) {
                  /// search for `primaryKey` that matches item `foreignKey` for example:
                  /// `Person{ id: 1 } == Item{ personId: 1 }`
                  return association[include.schema.primaryKey] ==
                      item[include.schema.primaryKey];
                },
              );
            }

            /// assign association to parent
            /// `Person{ name: 'Hamzah' }`
            /// Will became
            /// `Person{ name: 'Hamzah', dogs: [Dog{ id: 1, name: 'Roze' }, ...] }`

            // just removed  || relation is ProxyHasMany
            else if (relation is HasMany) {
              item[include.schema.table] = associations;
            }

            print('item: $item');
          }
        }
        // foreignKey

        // final ids =
        //     items.map((item) => item[foreignKey.parent]).toSet().toList();

        // print(ids);
      }

      /// ```dart
      /// sqfly<PersonDao>().includes([DogDao]).toList();
      /// ```
      /// ```dart
      /// SELECT * FROM dogs WHERE person_id IN (?, ?)
      /// ```
      // else if (relation is HasMany) {
      //   print('HasMany');
      // }

      // final foreignKey = foreignKeys[include.type];

      // include
      // for (final include in []) {
      /// TODO: loop throw all realtions instead of searching for foreignKey
      /// TODO: move for loop inisde above mapping

      /// load `foreignKey` for the include dao
      // print('foreignKey: $foreignKey');
      break;

      // if (include._where.isNotEmpty) {
      //   final associations = await include.toMap();

      //   /// add all associations to object for example:
      //   /// `Dog{ name: 'Hamzah', person_id: 1 }`
      //   /// we need to remove `foreginKey` and add object for example:
      //   /// `Dog{ name: 'Hamzah', person: Person{ id: 1, name: 'Sam' } }`
      //   for (final item in items) {
      //     final association = associations.find(
      //       (association) {
      //         final primaryKey = association[include.schema.primaryKey];

      //         /// search for `primaryKey` that matches item `foreignKey` for example:
      //         /// `Person{ id: 1 } == Item{ personId: 1 }`
      //         return primaryKey == item[foreignKey.parent];
      //       },
      //     );

      //     /// remove foreignKey from item for example:
      //     /// `Dog{ name: 'Hamzah', person_id: 1 }`
      //     /// Will remove the `foreignKey` from map because it's already exists on [association] object
      //     /// `Dog{ name: 'Hamzah' }`
      //     item.remove(foreignKey.parent);

      //     /// assign association to parent
      //     /// `Dog{ name: 'Hamzah' }`
      //     /// Will became
      //     /// `Dog{ name: 'Hamzah', person: Person{ id: 1, name: 'Sam' } }`
      //     item['${include.type}'.toCamelCase()] = association;
      //   }
      // }

      /// Prepare unique foreign keys to query them from database
      // final associationIds =
      //     items.map((item) => item[foreignKey.parent]).toSet().toList();

      // /// load associations based on foreign keys for example:
      // /// `[Person{ id: 1, name: 'Sam' }, ... ]`
      // if (associationIds.isNotEmpty) {
      //   final associations = await include
      //       .where({
      //         '${include.schema.primaryKey} IN (${List.filled(associationIds.length, '?').join(',')})':
      //             associationIds
      //       })
      //       .limit(associationIds.length)
      //       .toMap();

      //   /// add all associations to object for example:
      //   /// `Dog{ name: 'Hamzah', person_id: 1 }`
      //   /// we need to remove `foreginKey` and add object for example:
      //   /// `Dog{ name: 'Hamzah', person: Person{ id: 1, name: 'Sam' } }`
      //   for (final item in items) {
      //     final association = associations.find(
      //       (association) {
      //         final primaryKey = association[include.schema.primaryKey];

      //         /// search for `primaryKey` that matches item `foreignKey` for example:
      //         /// `Person{ id: 1 } == Item{ personId: 1 }`
      //         return primaryKey == item[foreignKey.parent];
      //       },
      //     );

      //     /// remove foreignKey from item for example:
      //     /// `Dog{ name: 'Hamzah', person_id: 1 }`
      //     /// Will remove the `foreignKey` from map because it's already exists on [association] object
      //     /// `Dog{ name: 'Hamzah' }`
      //     item.remove(foreignKey.parent);

      //     /// assign association to parent
      //     /// `Dog{ name: 'Hamzah' }`
      //     /// Will became
      //     /// `Dog{ name: 'Hamzah', person: Person{ id: 1, name: 'Sam' } }`
      //     item['${include.type}'.toCamelCase()] = association;
      //   }
      // }
    }

    clear();

    return items;
  }

  Future<List<T>> get all => toList();
  Future<bool> get isEmpty async => await count() > 0;
  Future<bool> get isNotEmpty async => !await isEmpty;

  SqlBuilder _copyQueryWith({
    bool distinct,
    List<String> columns,
    String where,
    List<dynamic> whereArgs,
    String groupBy,
    String having,
    String orderBy,
    int limit,
    int offset,
  }) {
    return SqlBuilder.query(
      [schema.table, ..._select].join(' '),
      distinct: distinct ?? _distinct,
      columns: columns ?? ['${schema.table}.*', ..._columns],
      where: where ?? _whereQuery,
      whereArgs: whereArgs ?? _whereArgs,
      groupBy: groupBy ?? _group.isEmpty ? null : _group.join(', '),
      having: having ?? _having.isEmpty ? null : _having.join(', '),
      orderBy: orderBy ?? _order.isEmpty ? null : _order.join(', '),
      limit: limit ?? _limit,
      offset: offset ?? _offset,
    );
  }

  void clear() {
    /// Queries
    _select.clear();
    _distinct = null;
    _columns.clear();
    _where.clear();
    _or.clear();
    _group.clear();
    _having.clear();
    _order.clear();
    _limit = null;
    _offset = null;

    /// Associations
    _includes.clear();
    _joins.clear();
  }
}
