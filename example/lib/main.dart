import 'package:example/daos/dog_dao.dart';
import 'package:example/daos/person_dao.dart';
import 'package:example/models/dog.dart';
import 'package:example/models/person.dart';
import 'package:flutter/material.dart';
import 'package:sqfly/sqfly.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sqfly = await Sqfly.initialize(
    inMemory: true,
    version: 1,
    daos: [
      PersonDao(),
      DogDao(),
    ],
  );

  /// [belongs-to]
  await sqfly<DogDao>().create(
    Dog(
      name: 'Dog-1',
      person: Person(name: 'Person-1'),
    ),
  );

  // print(Sqfly.instance<DogDao>().where({'name': 'ALI'}).toSql());

  /// [has-one]
  // await Sqfly.instance<PersonDao>().create(
  //   Person(
  //     name: 'Person-1',
  //     dog: Dog(name: 'Dog-1'),
  //   ),
  // );

  /// [has-many]
  // await Sqfly.instance<PersonDao>().create(
  //   Person(
  //     name: 'Person-1',
  //     dogs: List.generate(
  //       3,
  //       (i) => Dog(
  //         name: 'Dog-$i',
  //       ),
  //     ),
  //   ),
  // );

  // await Sqfly.instance<DogDao>().destroyAll();
  // await Sqfly.instance<DogDao>().updateAll({'name': 'Steven'});

  // await Sqfly.instance<PersonDao>().update(Person(id: 1, name: 'Steve'));
  // await Sqfly.instance<PersonDao>().delete(Person(id: 1));
  // await Sqfly.instance<PersonDao>().create(Person(id: 1, name: 'Huthaifah', dogs: []));

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyListPage(),
    );
  }
}

class MyListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MyList'),
      ),
      body: FutureBuilder<List>(
        // future: Sqfly.instance<DogDao>().includes([PersonDao]).toList(),
        future: Sqfly.instance<PersonDao>().includes([DogDao]).toList(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, i) {
                final item = snapshot.data[i];

                if (item is Dog) {
                  return ListTile(
                    title: Text(item?.name ?? ''),
                    subtitle: Text('Belongs to person: ${item.person?.name}'),
                  );
                } else if (item is Person) {
                  return ListTile(
                    title: Text(item?.name ?? ''),
                    subtitle: Text('Has one dog: ${item.dog?.name}'),
                  );

                  // return ExpansionTile(
                  //   title: Text(
                  //       '${item?.name ?? ''} has ${item?.dogs?.length} dogs'),
                  //   children: item.dogs
                  //       ?.map((dog) => ListTile(title: Text(dog?.name)))
                  //       ?.toList(),
                  // );
                } else {
                  return Text('Unsupported');
                }
              },
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
