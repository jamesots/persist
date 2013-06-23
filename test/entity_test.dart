library entity_test;

import 'package:persist/persist.dart';
import 'package:sqljocky/sqljocky.dart';
import 'package:options_file/options_file.dart';
import 'package:sqljocky/utils.dart';
import 'package:logging/logging.dart';
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
  dropper.dropTables().then((x) {
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
    creator.executeQueries().then((y) {
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

  
  var thingDao;
  var somethingElseDao;
  var thing = new Thing("jamesots", "James", 36);
  var it1 = new SomethingElse(null, 123, "blah");
  var it2 = new SomethingElse(null, -3, "what?");
  var thing2;
  print("starting");
  var connectionDetails = getConnectionDetails();
  var pool = new ConnectionPool(user:connectionDetails.user, password:connectionDetails.password, 
      port:connectionDetails.port, db:connectionDetails.db, 
      host:connectionDetails.host, max: 5);

  thingDao = new ThingDao(pool);
  somethingElseDao = new EntityDao<SomethingElse>(SomethingElse, pool);
  setup(pool).then((_) {
    return thingDao.insertNew(thing);
  }).then((_) {
    return somethingElseDao.insertNew(it1);
  }).then((_) {
    return somethingElseDao.insertNew(it2);
  }).then((_) {
    print("inserted");
    return thingDao.update(thing);
  }).then((_) {
    print("updated");
    thing2 = thingDao.fromJson('{"userId":"jonny", "name":"Jon","age":5}');
    return thingDao.insertNew(thing2);
  }).then((_) {
    print("inserted");
    return thingDao.delete(thing2);
  }).then((_) {
    print("deleted");
    return thingDao.readAll();
  }).then((list) {
    print("read all");
    list.forEach((item) {
      print(thingDao.toJson(item));
    });
    return somethingElseDao.readAll();
  }).then((list) {
    print("read all something elses:");
    list.forEach((item) {
      print(somethingElseDao.toJson(item));
    });
    return thingDao.read("jamesots");
  }).then((list) {
    print("read item");
    list.forEach((item) {
      print(thingDao.toJson(item));
    });
    pool.close();
    print("finished");
  });
}
