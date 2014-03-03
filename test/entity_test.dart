library entity_test;

import 'package:persist/persist.dart';
import 'package:sqljocky/sqljocky.dart';
import 'package:options_file/options_file.dart';
import 'package:sqljocky/utils.dart';
import 'package:logging/logging.dart';
import 'package:unittest/unittest.dart';
import 'dart:async';

@Entity(table: "thing")
class Thing {
  @Attribute(primaryKey: true)
  String userId;
  @Attribute()
  String name;
  @Attribute()
  int age;
  
  String toString() {
    return "Thing, userId=${userId}, name=${name}, age=${age}";
  }
  
  Thing(this.userId, this.name, this.age);
  Thing.empty();
}

@Entity(autoInc: true)
class SomethingElse {
  @Attribute(primaryKey: true)
  int id;
  @Attribute()
  int bobId;
  @Attribute()
  String wibble;
  
  SomethingElse(this.id, this.bobId, this.wibble);
  SomethingElse.empty();
}

class ThingDao extends EntityDao<Thing> {
  ThingDao(ConnectionPool pool) : super(Thing, pool);
}

class ConnectionDetails {
  String user;
  String password;
  String host;
  String db;
  int port;
}

ConnectionDetails getConnectionDetails() {
  OptionsFile options = new OptionsFile('connection.options');
  var connectionDetails = new ConnectionDetails();
  connectionDetails.user = options.getString('user');
  connectionDetails.password = options.getString('password');
  connectionDetails.port = options.getInt('port', 3306);
  connectionDetails.db = options.getString('db');
  connectionDetails.host = options.getString('host', 'localhost');
  print("got connection details");
  return connectionDetails;
}

Future setup(ConnectionPool pool) {
  Completer completer = new Completer();
  
  var dropper = new TableDropper(pool, ['thing', 'SomethingElse']);
  dropper.dropTables().then((_) {
    var creator = new QueryRunner(pool, ['''create table thing (
                                                name varchar(255), 
                                                userId varchar(255),
                                                age integer, 
                                                primary key (userId)
                                                )''',
                                                
                                                '''create table SomethingElse (
                                                id integer not null auto_increment, 
                                                bobId integer,
                                                wibble varchar(255), 
                                                primary key (id)
                                                )''']);
    creator.executeQueries().then((_) {
      completer.complete(null);
    });
  });
  
  return completer.future;
}

void main() {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.OFF;
  Logger.root.onRecord.listen((LogRecord r) {
    print("${r.time}: ${r.loggerName}: ${r.message}");
  });

  var connectionDetails = getConnectionDetails();
  var pool = new ConnectionPool(user:connectionDetails.user, password:connectionDetails.password, 
      port:connectionDetails.port, db:connectionDetails.db, 
      host:connectionDetails.host, max: 5);

  var thingDao = new ThingDao(pool);
  var somethingElseDao = new EntityDao<SomethingElse>(SomethingElse, pool);

  test('setup', () {
    return setup(pool);
  });
  
  test('can insert thing', () {
    var c = new Completer();
    var thing = new Thing("jamesots", "James", 36);
    thingDao.insertNew(thing).then((_) {
      return pool.query("select * from thing");
    }).then((result) {
      return result.toList();
    }).then((list) {
      expect(list.length, equals(1));
      expect(list[0], equals(["James", "jamesots", 36]));
      c.complete();
    });
    return c.future;
  });

  test('update thing', () {
    var c = new Completer();
    var thing = new Thing("jamesots", "Bill", 100);
    thingDao.update(thing).then((_) {
      return pool.query("select * from thing");
    }).then((result) {
      return result.toList();
    }).then((list) {
      expect(list.length, equals(1));
      expect(list[0], equals(["Bill", "jamesots", 100]));
      c.complete();
    });
    return c.future;
  });

  test('insert it1', () {
    var c = new Completer();
    var it1 = new SomethingElse(null, 123, "blah");
    somethingElseDao.insertNew(it1).then((_) {
      return pool.query("select * from SomethingElse");
    }).then((result) {
      return result.toList();
    }).then((list) {
      expect(list.length, equals(1));
      expect(list[0], equals([1, 123, 'blah']));
      c.complete();
    });
    return c.future;
  });

  test('insert it2', () {
    var c = new Completer();
    var it2 = new SomethingElse(null, -3, "what?");
    somethingElseDao.insertNew(it2).then((_) {
      return pool.query("select * from SomethingElse order by id");
    }).then((result) {
      return result.toList();
    }).then((list) {
      expect(list.length, equals(2));
      expect(list[1], equals([2, -3, 'what?']));
      c.complete();
    });
    return c.future;
  });

  test('insert thing2', () {
    var c = new Completer();
    var thing2 = thingDao.fromJson('{"userId":"jonny", "name":"Jon","age":5}');
    thingDao.insertNew(thing2).then((_) {
      return pool.query("select * from thing where userId = 'jonny'");
    }).then((result) {
      return result.toList();
    }).then((list) {
      expect(list.length, equals(1));
      expect(list[0], equals(["Jon", "jonny", 5]));
      c.complete();
    });
    return c.future;
  });

  test('delete thing2', () {
    var c = new Completer();
    var thing2 = thingDao.fromJson('{"userId":"jonny", "name":"Jon","age":5}');
    thingDao.delete(thing2).then((_) {
      return pool.query("select * from thing where userId = 'jonny'");
    }).then((result) {
      return result.toList();
    }).then((list) {
      expect(list.length, equals(0));
      c.complete();
    });
    return c.future;
  });

  test('read all things', () {
    var c = new Completer();
    thingDao.readAll().then((list) {
      expect(list.length, equals(1));
      expect(list[0].userId, equals('jamesots'));
      expect(list[0].name, equals('Bill'));
      expect(list[0].age, equals(100));
      c.complete();
    });
    return c.future;
  });

  test('read all something elses', () {
    var c = new Completer();
    somethingElseDao.readAll().then((list) {
      expect(list.length, equals(2));
      expect(list[0].id, equals(1));
      expect(list[0].bobId, equals(123));
      expect(list[0].wibble, equals('blah'));
      expect(list[1].id, equals(2));
      expect(list[1].bobId, equals(-3));
      expect(list[1].wibble, equals('what?'));
      c.complete();
    });
    return c.future;
  });

  test('read thing', () {
    var c = new Completer();
    thingDao.read("jamesots").then((list) {
      expect(list.length, equals(1)); // maybe read should throw error if more than one returned?
      expect(list[0].userId, equals('jamesots'));
      expect(list[0].name, equals('Bill'));
      expect(list[0].age, equals(100));
      c.complete();
    });
    return c.future;
  });
  
  test('transaction', () {
    var c = new Completer();
    thingDao.startTransaction().then((_) {
      var thing = new Thing("bert", "Bert", 100);
      return thingDao.insertNew(thing);
    })
    .then((_) {
      var thing = new Thing("sam", "Sam", 101);
      return thingDao.insertNew(thing);
    })
    .then((_) {
      return thingDao.rollback();
    })
    .then((_) {
      return pool.query("select * from thing where userId = 'bert' or userId = 'sam'");
    }).then((result) {
      return result.stream.toList();
    }).then((list) {
      expect(list.length, equals(0));
      c.complete();
    });
    return c.future;
  });
  
  test('cannot start two transactions', () {
    return thingDao.startTransaction().then((_) {
      expect(() {
        thingDao.startTransaction();
      }, throws);
      return thingDao.rollback();
    });
  });
  
  test('cannot rollback outside transaction', () {
    expect(() {
      thingDao.rollback();
    }, throws);
  });
  
  test('close', () {
    pool.close();
  });
}
