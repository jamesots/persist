part of persist;

class EntityDao<E> {
  String _insertQuery;
  String _readAllQuery;
  String _readQuery;
  String _updateQuery;
  String _deleteQuery;
  final EntityInfo info;
  final ConnectionPool pool;
  
  EntityDao(Type entityType, this.pool) :
      info = new EntityInfo(entityType);
  
  Future delete(E entity) {
    var completer = new Completer();
    _buildDeleteQuery()
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

  Future<Query> _buildDeleteQuery() {
    var completer = new Completer();
    if (_deleteQuery == null) {
      //TODO escape the table and field names
      _deleteQuery = "delete from ${info.tableName} where ${info.fields[0]}=?";
    }
    pool.prepare(_deleteQuery)
      .then((Query query) {
        completer.complete(query);
      })
      .catchError((e) {
        completer.completeError(e);
        return;
      });
    return completer.future;
  }
  
  Future update(E entity) {
    var completer = new Completer();
    _buildUpdateQuery()
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
  
  Future<Query> _buildUpdateQuery() {
    var completer = new Completer();
    if (_updateQuery == null) {
      var fieldNameBuffer = new StringBuffer();
      var i = 0;
      var first = true;
      info.fields.forEach((name) {
        if (name != info.fields[0]) {
          if (!first) {
            fieldNameBuffer.write(", ");
          }
          first = false;
          fieldNameBuffer.write(name);
          fieldNameBuffer.write("=?");
        }
        i++;
      });
      var fieldNames = fieldNameBuffer.toString();
      _updateQuery = "update ${info.tableName} set $fieldNames where ${info.fields[0]}=?";
    }
    pool.prepare(_updateQuery)
      .then((Query query) {
        completer.complete(query);
      })
      .catchError((e) {
        completer.completeError(e);
        return;
      });
    return completer.future;
  }
  
  Future<num> insertNew(E entity) {
    var completer = new Completer<num>();
    _buildInsertQuery()
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
  
  Future<Query> _buildInsertQuery() {
    var completer = new Completer();
    if (_insertQuery == null) {
      var fieldNameBuffer = new StringBuffer();
      var placeholderBuffer = new StringBuffer();
      var i = 0;
      info.fields.forEach((name) {
        if (!info.autoInc || name != info.primaryKey) {
          if (fieldNameBuffer.length > 0) {
            fieldNameBuffer.write(", ");
            placeholderBuffer.write(", ");
          }
          fieldNameBuffer.write(name);
          placeholderBuffer.write("?");
        }
        i++;
      });
      var fieldNames = fieldNameBuffer.toString();
      var placeholders = placeholderBuffer.toString();
      _insertQuery = 'insert into ${info.tableName} ($fieldNames) values ($placeholders)';
    }
    pool.prepare(_insertQuery)
      .then((Query query) {
        completer.complete(query);
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
    _buildReadAllQuery(whereString)
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
  
  Future<Query> _buildReadAllQuery(String where) {
    var completer = new Completer();
    if (_readAllQuery == null) {
      var fieldNameBuffer = new StringBuffer();
      var i = 0;
      info.fields.forEach((name) {
        if (i > 0) {
          fieldNameBuffer.write(", ");
        }
        fieldNameBuffer.write(name);
        i++;
      });
      var fieldNames = fieldNameBuffer.toString();
      _readAllQuery = 'select $fieldNames from ${info.tableName}';
    }
    pool.prepare("$_readAllQuery$where")
      .then((Query query) {
        completer.complete(query);
      })
      .catchError((e) {
        completer.completeError(e);
        return;
      });
    return completer.future;
  }
  
  Future<List<E>> read(dynamic value) {
    _buildReadQuery();
    return readAll(_readQuery, [value]);
  }
  
  void _buildReadQuery() {
    if (_readQuery == null) {
      _readQuery = "${info.fields[0]} = ?";
    }
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

