import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks.dart';

void main() {
  // setUpAll(() async {});

  // test('average', () async {
  //   //
  // });

  test('count', () async {
    final instance = await sqfly;
    await instance<PersonDao>().create(Person(name: 'Mike'));
    expect(await instance<PersonDao>().count(), 1);
  });

  // /// #method-i-average
  // Future<int> average(String column);

  // /// #method-i-count
  // Future<int> count([String column = '*']);

  // /// #method-i-ids
  // Future<List<dynamic>> get ids;

  // /// #method-i-maximum
  // Future<dynamic> maximum(String column);

  // /// #method-i-minimum
  // Future<dynamic> minimum(String column);

  // /// #method-i-pick
  // Future<List<dynamic>> pick(List<String> columns);

  // /// #method-i-pluck
  // Future<List<dynamic>> pluck(List<String> columns);

  // /// #method-i-sum
  // Future<int> sum(String column);
}
