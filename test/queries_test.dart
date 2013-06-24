library queries_test;

import 'package:persist/persist.dart';
import 'package:unittest/unittest.dart';
import 'dart:async';

@Entity(table: "thing", autoInc: true)
class Thing {
  @Attribute(primaryKey: true)
  String userId;
  @Attribute()
  String name;
  @Attribute(column: "number")
  int age;
  
  Thing.empty();
}

main() {
  test('should create correct queries', () {
    EntityInfo info = new EntityInfo(Thing);
    var queries = new Queries(info);
    
    expect(queries.insert, 'insert into thing (name, number) values (?, ?)');
    expect(queries.readAll, 'select userId, name, number from thing');
    expect(queries.readWhere, 'userId = ?');
    expect(queries.update, 'update thing set name=?, number=? where userId=?');
    expect(queries.delete, 'delete from thing where userId=?');
  });
}