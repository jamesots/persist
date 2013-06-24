part of persist;

class EntityDao<E> {
  Queries queries;
  final EntityInfo info;
  final ConnectionPool pool;
  
  EntityDao(Type entityType, this.pool) :
      info = new EntityInfo(entityType) {
      queries = new Queries(info);
  }
  
  Future delete(E entity) {
    var completer = new Completer();
    pool.prepare(queries.delete)
      .then((query) {
        query[0] = info.getPrimaryKey(entity);
        query.execute().then((results) {
          // should we do something with the results?
          completer.complete();
        });
      })
      .catchError((e) {
        completer.completeError(e);
        return;
      });
    return completer.future;
  }

  Future update(E entity) {
    var completer = new Completer();
    pool.prepare(queries.update)
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
        for (var i = 0; i < values.length; i++) {
          query[i] = values[i];
        }
        query.execute()
          .then((results) {
            // should we do something with the results?
            completer.complete(1);
          })
          .catchError((e) {
            completer.completeError(e);
            return;
          });
      })
      .catchError((e) {
        completer.completeError(e);
        return;
      });
    return completer.future;
  }
  
  Future<num> insertNew(E entity) {
    var completer = new Completer<num>();
    pool.prepare(queries.insert)
      .then((query) {
        InstanceMirror mirror = reflect(entity);
        var values = new List();
        var i = 0;
        info.fields.forEach((name) {
          if (!info.autoInc || name != info.primaryKey) { 
            values.add(mirror.getField(new Symbol(name)).reflectee);
          }
          i++;
        });
        for (var i = 0; i < values.length; i++) {
          query[i] = values[i];
        }
        query.execute()
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
    pool.prepare("${queries.readAll}$whereString")
      .then((query) {
        if (values != null) {
          for (var i = 0; i < values.length; i++) {
            query[i] = values[i];
          }
        }
        query.execute()
          .then((Results results) {
            print("got all");
            var entities = [];
            results.stream.forEach((List<dynamic> row) {
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
      })
      .catchError((e) {
        completer.completeError(e);
        return;
      });
    return completer.future;
  }
  
  Future<List<E>> read(dynamic value) {
    return readAll(queries.read, [value]);
  }
  
  String toJson(E entity) {
    return stringify(toMap(entity));
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
    return fromMap(parse(json));
  }
  
  E fromMap(Map map) {
    var instanceMirror = info.newInstance();
    info.fields.forEach((name) {
      instanceMirror.setField(new Symbol(name), map[name]);
    });
    return instanceMirror.reflectee;
  }
}

