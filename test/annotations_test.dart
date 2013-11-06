library annotations_test;

import 'package:persist/persist.dart';
import 'package:unittest/unittest.dart';

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

@Entity()
class Bob {
  @Attribute()
  String aField;
  
  String notAField;
}

class Bobble extends Bob {}

@Entity()
class TooPrimary {
  @Attribute(primaryKey: true)
  String aField;
  @Attribute(primaryKey: true)  
  String anotherField;
}

main() {
  test('it should create info for Thing', () {
    var info = new EntityInfo(Thing);
    expect(info, isNotNull);
    expect(info.tableName, equals("thing"));
    expect(info.fields, hasLength(3));
    expect(info.fields, contains("userId"));
    expect(info.fields, contains("name"));
    expect(info.fields, contains("number"));
    expect(info.autoInc, isTrue);
    expect(info.primaryKey, equals("userId"));
  });
  
  test('it should fail to create info for int', () {
    expect(() {
      var info = new EntityInfo(int);
    }, throws);
  });
  
  test('it should fail to create info for Bobble', () {
    expect(() {
      var info = new EntityInfo(Bobble);
    }, throws);
  });
  
  test('it should default table name to class name', () {
    var info = new EntityInfo(Bob);
    expect(info.tableName, equals("Bob"));
    expect(info.fields, hasLength(1));
    expect(info.fields, contains("aField"));
    expect(info.autoInc, isFalse);
  });
  
  test('it should not allow multiple primary keys', () {
    expect(() {
      var info = new EntityInfo(TooPrimary);
    }, throws);
  });
}

