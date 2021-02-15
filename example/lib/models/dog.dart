import 'package:example/models/person.dart';

import 'person.dart';

class Dog {
  final int id;
  final String name;

  final Person person;

  const Dog({
    this.id,
    this.person,
    this.name,
  });

  Dog.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        person = Person.fromMap(map['person']);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'person': person?.toMap(),
      };
}
