import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqfly/sqfly.dart';

class MockDatabaseExecutor extends Mock implements DatabaseExecutor {}

class MockDatabaseBatch extends Mock implements Batch {}

class MockSqfliteDatabase extends Mock implements Database {}

class Person {
  final int id;
  final String name;

  Person({this.id, this.name});

  Person.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'Person{id: $id, name: $name}';
  }
}

class PersonDao extends Dao<Person> {
  PersonDao()
      : super(
          '''
          CREATE TABLE people (
            id   INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name TEXT    NOT NULL
          )
          ''',
          converter: Converter(
            encode: (person) => Person.fromMap(person),
            decode: (person) => person.toMap(),
          ),
        );
}

final sqfly = Sqfly(
  version: 1,
  daos: [PersonDao()],
);
