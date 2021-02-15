import 'package:sqfly/src/definitions/schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Adding different column position
  /// Remove column

  _migrate(Schema oldSchema, Schema newSchema) {
    final sql = List<String>();

    /// Turn off `foreign_keys` to avoid errors
    sql.add('PRAGMA foreign_keys=OFF;');

    /// Suffex table with `_old`
    sql.add(
      'ALTER TABLE ${oldSchema.table} RENAME TO ${oldSchema.table}_old;',
    );

    /// Creating the new table on its new format `no redundant columns`
    sql.add('${newSchema.sql};');

    final oldColumns = oldSchema.columns.map((column) => column.name).toList();
    final newColumns = newSchema.columns.map((column) => column.name).toList();

    /// Remove any new column not exists in previous sql
    oldColumns.removeWhere((oldColumn) => !newColumns.contains(oldColumn));

    // final different = newColumns.length - oldColumns.length;

    // if (different < 0)
    //   oldColumns.removeWhere(());

    // if (oldColumns.length > newColumns.length) {}

    /// Remove any default value column that's not exists in old-column for example:
    /// ```
    /// CREATE TABLE old_example (
    ///   a TEXT NOT NULL,
    ///   b TEXT NOT NULL,
    ///   c TEXT NOT NULL,
    ///   d TEXT NOT NULL DEFAULT z
    /// )
    ///
    /// CREATE TABLE new_example (
    ///   a TEXT NOT NULL,
    ///   b TEXT NOT NULL,
    ///   c TEXT NOT NULL DEFAULT x,
    ///   d TEXT NOT NULL DEFAULT y
    /// )
    /// ```
    /// for above example will remove `new_example.c`
    /// `INSERT INTO new_example (a, b, c, d) SELECT (a, b, c, d) FROM old_example`
    /// and with this the default value will be emitted
    // newColumns.removeWhere(
    //   (newColumn) =>
    //       newColumn.defaultValue != null && !oldColumns.contains(newColumn),
    // );

    // if (oldColumns.length > newColumns.length) {
    //   for (int i = 0; i < newColumns.length; i++) {
    //     if (newColumns[i].name != oldColumns[i].name) {
    //       oldColumns.add(Column(name: 'NULL'));
    //     }
    //   }
    // } else {
    //   for (int i = 0; i < oldColumns.length; i++) {
    //     if (oldColumns[i].name != newColumns[i].name) {
    //       newColumns.remove(oldColumns[i]);
    //     }
    //   }
    // }

    // final different = newColumns.length - oldColumns.length;

    /// new columns added (might be upgrade) `INSERT INTO new_table (col-a, col-b, col-c) SELECT (col-a, col-b, NULL)`
    // if (newColumns.length > oldColumns.length)
    //   oldColumns.addAll(List.filled(different, 'NULL'));
    // newColumns.removeWhere((newColumn) => !oldColumns.contains(newColumn));
    // for (int i = 0; i < newColumns.length; i++)

    //   /// check if newColumn has default value then remove else add null
    //   newSchema.columns[i].defaultValue != null
    //       ? newColumns.remove(newColumns[i])
    //       : newColumns.add('NULL');

    /// remove columns (might be downgrade) `INSERT INTO new_table (col-a, col-b) SELECT (col-a, col-b)`
    // else
    //   oldColumns.removeWhere((oldColumn) => !newColumns.contains(oldColumn));

    // newColumns.sort((colA, colB) => colA.compareTo(colB));
    // oldColumns.sort((colA, colB) => colA.compareTo(colB));

    // expect(newColumns.length, equals(oldColumns.length));

    // Populating the table with the data
    sql.add(
      'INSERT INTO ${newSchema.table} (${oldColumns.join(', ')}) SELECT (${oldColumns.join(', ')}) FROM ${oldSchema.table}_old;',
    );

    // Drop old table
    sql.add('DROP TABLE ${oldSchema.table}_old;');

    /// Re enable forign_keys
    sql.add('PRAGMA foreign_keys=ON;');

    return sql.join('\n');
  }

  test('add new column on last position', () {
    final oldSchema = Schema('''
CREATE TABLE example (
  a TEXT NOT NULL,
  b TEXT NOT NULL,
  c TEXT NOT NULL
)
      ''');

    final newSchema = Schema('''
CREATE TABLE example (
  a TEXT NOT NULL, 
  b TEXT NOT NULL, 
  c TEXT NOT NULL, 
  d TEXT
)
      ''');

    expect(_migrate(oldSchema, newSchema), equals('''
PRAGMA foreign_keys=OFF;
ALTER TABLE example RENAME TO example_old;
${newSchema.sql};
INSERT INTO example (a, b, c) SELECT (a, b, c) FROM example_old;
DROP TABLE example_old;
PRAGMA foreign_keys=ON;'''));
  });

  test('add new column on different position', () {
    final oldSchema = Schema('''
CREATE TABLE example (
  a TEXT NOT NULL,
  b TEXT NOT NULL,
  c TEXT NOT NULL
)
      ''');

    final newSchema = Schema('''
CREATE TABLE example (
  a TEXT NOT NULL, 
  b TEXT NOT NULL, 
  d TEXT,
  c TEXT NOT NULL
)
      ''');

    expect(_migrate(oldSchema, newSchema), equals('''
PRAGMA foreign_keys=OFF;
ALTER TABLE example RENAME TO example_old;
${newSchema.sql};
INSERT INTO example (a, b, c) SELECT (a, b, c) FROM example_old;
DROP TABLE example_old;
PRAGMA foreign_keys=ON;'''));
  });

  test('change column type with the exact name', () {
    final oldSchema = Schema('''
CREATE TABLE example (
  a TEXT NOT NULL,
  b TEXT NOT NULL,
  c TEXT NOT NULL
)
      ''');

    final newSchema = Schema('''
CREATE TABLE example (
  a TEXT NOT NULL, 
  b TEXT NOT NULL, 
  c TEXT NOT NULL,
  d INTEGER
)
      ''');

    expect(_migrate(oldSchema, newSchema), equals('''
PRAGMA foreign_keys=OFF;
ALTER TABLE example RENAME TO example_old;
${newSchema.sql};
INSERT INTO example (a, b, c) SELECT (a, b, c) FROM example_old;
DROP TABLE example_old;
PRAGMA foreign_keys=ON;'''));
  });

  test('remove column', () {
    final oldSchema = Schema('''
CREATE TABLE example (
  a TEXT NOT NULL,
  b TEXT NOT NULL,
  c TEXT NOT NULL
)
      ''');

    final newSchema = Schema('''
CREATE TABLE example (
  a TEXT NOT NULL,
  b TEXT NOT NULL
)
      ''');

    expect(_migrate(oldSchema, newSchema), equals('''
PRAGMA foreign_keys=OFF;
ALTER TABLE example RENAME TO example_old;
${newSchema.sql};
INSERT INTO example (a, b) SELECT (a, b) FROM example_old;
DROP TABLE example_old;
PRAGMA foreign_keys=ON;'''));
  });
}
