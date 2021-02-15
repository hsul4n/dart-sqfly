import 'package:example/daos/person_dao.dart';
import 'package:example/models/dog.dart';
import 'package:sqfly/sqfly.dart';

class DogDao extends Dao<Dog> {
  DogDao()
      : super(
          '''
          CREATE TABLE dogs (
            id        INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            person_id INTEGER NOT NULL,
            name      TEXT    NOT NULL,

            FOREIGN KEY (person_id) REFERENCES people (id)
          )
          ''',
          relations: [
            BelongsTo<PersonDao>(),
          ],
          converter: Converter(
            encode: (todo) => Dog.fromMap(todo),
            decode: (todo) => todo.toMap(),
          ),
        );
}
