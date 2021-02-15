import 'package:example/daos/dog_dao.dart';
import 'package:example/models/person.dart';
import 'package:sqfly/sqfly.dart';

class PersonDao extends Dao<Person> {
  PersonDao()
      : super(
          '''
          CREATE TABLE people (
            id     INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name   TEXT    NOT NULL
          )
          ''',
          relations: [
            HasOne<DogDao>(),
          ],
          converter: Converter(
            encode: (person) => Person.fromMap(person),
            decode: (person) => person.toMap(),
          ),
        );
}
