import 'dog.dart';

class Person {
  final int id;
  final String name;
  // final List<Dog> dogs;
  final Dog dog;

  const Person({this.id, this.name, this.dog});

  Person.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        // dogs = map.containsKey('dogs')
        //     ? (map['dogs'] as List).map((dog) => Dog.fromMap(dog)).toList()
        //     : <Dog>[];
        dog = map.containsKey('dog') ? Dog.fromMap(map['dog']) : null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        // 'dogs': dogs?.map((dog) => dog.toMap())?.toList(),
        'dog': dog?.toMap(),
      };
}
