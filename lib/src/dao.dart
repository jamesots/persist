part of persist;

class EntityDao<E> {
  Queries _queries;
  final EntityInfo info;
  final ConnectionPool pool;
  QueriableConnection _queriableConnection;
  
  EntityDao(Type entityType, this.pool) :
      info = new EntityInfo(entityType) {
      _queriableConnection = this.pool;
      _queries = new Queries(info);
  }

  Future startTransaction({bool consistent: false}) {
    if (_queriableConnection is Transaction) {
      throw "already in a transaction";
    }
    var c = new Completer();
    pool.startTransaction(consistent: consistent).then((transaction) {
      _queriableConnection = transaction;
      c.complete();
    });
    return c.future;
  }
  
  Future rollback() {
    if (!(_queriableConnection is Transaction)) {
      throw "not in a transaction";
    }
    var c = new Completer();
    (_queriableConnection as Transaction).rollback().then((_) {
      _queriableConnection = pool;
      c.complete();
    });
    return c.future;
  }
  
  Future commit() {
    if (!(_queriableConnection is Transaction)) {
      throw "not in a transaction";
    }
    var c = new Completer();
    (_queriableConnection as Transaction).commit().then((_) {
      _queriableConnection = pool;
      c.complete();
    });
    return c.future;
  }
  
  Future delete(E entity) {
    return _queriableConnection.prepare(_queries.delete)
      .then((query) {
        return query.execute([info.getPrimaryKey(entity)]);
      });
  }

  Future update(E entity) {
    return _queriableConnection.prepare(_queries.update)
      .then((query) {
        InstanceMirror mirror = reflect(entity);
        var values = new List();
        var primaryKeyValue;
        info.fields.forEach((name) {
          if (name == info.primaryKey) {
            primaryKeyValue = mirror.getField(new Symbol(name)).reflectee;
          } else {
            values.add(mirror.getField(new Symbol(name)).reflectee);
          }
        });
        values.add(primaryKeyValue);
        return query.execute(values);
      });
  }
  
  Future<num> insertNew(E entity) {
    var completer = new Completer<num>();
    InstanceMirror mirror = reflect(entity);
    _queriableConnection.prepare(_queries.insert)
      .then((query) {
        var values = new List();
        var i = 0;
        info.fields.forEach((name) {
          if (!info.autoInc || name != info.primaryKey) { 
            values.add(mirror.getField(new Symbol(name)).reflectee);
          }
          i++;
        });
        return query.execute(values);
      })
      .then((results) {
        if (info.autoInc) {
          mirror.setField(new Symbol(info.primaryKey), results.insertId);
        }
        completer.complete(results.insertId);
      })
      .catchError((e) {
        completer.completeError(e);
        return;
      });
    return completer.future;
  }
  
  Future<List<E>> readAll([String where, List values]) {
    var completer = new Completer<List<E>>();
    String whereString = "";
    if (where != null) {
      whereString = " where ${where}";
    }
    _queriableConnection.prepare("${_queries.readAll}$whereString")
      .then((query) {
        if (values != null) {
          return query.execute(values);
        }
        return query.execute([]);
      })
      .then((Results results) {
        var entities = [];
        results.forEach((List<dynamic> row) {
          try {
            var instanceMirror = info.newInstance();
            E entity = instanceMirror.reflectee;
            entities.add(entity);
            var i = 0;
            info.fields.forEach((name) {
              //TODO when this fails, system halts with no errors
              try {
                instanceMirror.setField(new Symbol(name), row[i]);
              } catch (e) {
                print("Error setting field: $e");
              }
              i++;
            });
          } catch (e) {
            print("Error instantiating entity: $e");
          }
        }).then((_) {
          completer.complete(entities);
        });
      })
      .catchError((e) {
        completer.completeError(e);
        return;
      });
    return completer.future;
  }
  
  Future<List<E>> read(dynamic value) {
    return readAll(_queries.readWhere, [value]);
  }
  
  String toJson(E entity) {
    return JSON.encode(toMap(entity));
  }
  
  Map toMap(E entity) {
    InstanceMirror mirror = reflect(entity);
    var map = {};
    var futures = new FutureList();
    info.fields.forEach((name) {
      map[name] = mirror.getField(new Symbol(name)).reflectee;
    });
    return map;
  }
  
  E fromJson(String json) {
    return fromMap(JSON.decode(json));
  }
  
  E fromMap(Map map) {
    var instanceMirror = info.newInstance();
    info.fields.forEach((name) {
      instanceMirror.setField(new Symbol(name), map[name]);
    });
    return instanceMirror.reflectee;
  }
}

