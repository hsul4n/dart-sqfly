// library sqfly;

// class _SqflyImpl implements Sqfly {
//   // your database name
//   final String name;

//   // your db version
//   final int version;

//   /// use to import database localy from `assets` folder default `false`
//   /// if `true` make sure to locate db file at `assets/database.db`
//   final bool import;

//   /// list of migrations
//   // final List<Migration> migrations;

//   /// list of your daos `Data Access Object`
//   // static final List<Dao> _daos = [];
//   static final Map<Type, Dao> _daos = {};
//   static Map<Type, Dao> get daos => _daos;

//   static bool logger;

//   _SqflyImpl({
//     final String name,
//     final this.version,
//     final List<Dao> daos,
//     // final this.migrations = const [],
//     final bool import,
//     final bool logger,
//     final bool memory,
//   })  :
//         // set null name when in-memory
//         name = (memory != null && memory) ? null : name,
//         assert(version != null && version > 0),
//         assert(daos != null && daos.isNotEmpty),
//         import = import ?? false

//   // /// make sure that can't use memory with import
//   // assert(name != null && !import)
//   {
//     _SqflyImpl.logger = logger ?? kDebugMode;
//     for (final dao in daos) _daos[dao.runtimeType] = dao;
//   }

//   // static Dao<T> call2<T>(type) => _daos.firstWhere(
//   //       (i) => i.runtimeType == type,
//   //       orElse: () => null,
//   //     );
//   // static Dao get(type) => _daos.firstWhere(
//   //       (i) => i.runtimeType == type,
//   //       orElse: () => null,
//   //     );

//   // T call<T>() => _daos[T] as T;
//   T call<T>() => _daos.values.whereType<T>().first;
//   T get<T>() => this.call<T>();

//   static Database _database;
//   static Database get database => _database;

//   Future<Sqfly> init() async {
//     if (_database != null) return this;

//     final path = name != null
//         ? '${await getDatabasesPath()}/flutter_$name.db'
//         : inMemoryDatabasePath;

//     if (import) {
//       final isExists = await databaseExists(path);

//       if (!isExists) {
//         // Should happen only the first time you launch your application
//         if (logger) print("Creating new copy from assets.database.db");

//         // Make sure the parent directory isExists
//         try {
//           final dir = path.split('/');
//           dir.removeLast();

//           await Directory(dir.join('/')).create(recursive: true);
//         } catch (_) {}

//         final data = await rootBundle.load('assets/database.db');

//         // Convert to bytes
//         final List<int> bytes = data.buffer.asUint8List(
//           data.offsetInBytes,
//           data.lengthInBytes,
//         );

//         // Write and flush the bytes written
//         await File(path).writeAsBytes(bytes, flush: true);
//       }
//     }

//     await openDatabase(
//       path,
//       version: version,
//       onConfigure: (Database database) => _database = database,
//       onCreate: (_, __) async {
//         await Future.forEach(
//             _daos.values.map((dao) => dao.schema.sql), database.execute);

//         // await Future.forEach(
//         //   migrations.where((migration) =>
//         //       migration.isUpgrade && migration.to <= version),
//         //   (Migration migration) async {
//         //     await migration.change(database);
//         //   },
//         // );
//       },
//       onUpgrade: (_, int from, int to) async {
//         if (logger) print('Upgrading from $from to $to');
//         await Future.forEach(daos.values, Migration.force);

//         // await Future.forEach(
//         //   migrations.where((migration) =>
//         //       migration.isUpgrade &&
//         //       migration.from >= from &&
//         //       migration.to <= to),
//         //   (Migration migration) async {
//         //     await migration.change(database);
//         //   },
//         // );
//       },
//       onDowngrade: (_, int from, int to) async {
//         if (logger) print('Downgrading from $from to $to');
//         await Future.forEach(daos.values, Migration.force);
//         // await Future.forEach(
//         //   migrations.where((migration) =>
//         //       !migration.isUpgrade &&
//         //       migration.from <= from &&
//         //       migration.to >= to),
//         //   (Migration migration) async {
//         //     await migration.change(database);
//         //   },
//         // );
//       },
//     );

//     return this;
//   }
// }
