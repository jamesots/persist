library queries_test;

import 'package:persist/persist.dart';
import 'package:unittest/unittest.dart';

@Entity(table: "thing", autoInc: true)
class Thing {
  @Attribute()
  String name;
  @Attribute(column: "number")
  int age;
  @Attribute(primaryKey: true)
  int userId;
  
  Thing.empty();
}

main() {
  test('should create correct queries', () {
    EntityInfo info = new EntityInfo(Thing);
    var queries = new Queries(info);
    
    expect(queries.insert, 'insert into thing (name, number) values (?, ?)');
    expect(queries.readAll, 'select name, number, userId from thing');
    expect(queries.readWhere, 'userId = ?');
    expect(queries.update, 'update thing set name=?, number=? where userId=?');
    expect(queries.delete, 'delete from thing where userId=?');
  });
}
