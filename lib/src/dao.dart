part of persist;

class EntityDao<E> {
  Query _insertQuery;
  Query _readAllQuery;
  String _readQuery;
  Query _updateQuery;
  Query _deleteQuery;
  final EntityInfo info;
  final ConnectionPool pool;
  
  EntityDao(Type entityType, this.pool) :
      info = new EntityInfo(entityType);
  
  Future delete(E entity) {
    var completer = new Completer();
    _buildDeleteQuery()
      .then((_) {
        _deleteQuery[0] = info.getPrimaryKey(entity);
        _deleteQuery.execute().then((results) {
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

  Future _buildDeleteQuery() {
    var completer = new Completer();
    if (_deleteQuery == null) {
      //TODO escape the table and field names
      var queryString = "delete from ${info.tableName} where ${info.fields[0]}=?";
      pool.prepare(queryString)
        .then((Query query) {
          _deleteQuery = query;
          completer.complete();
        })
        .catchError((e) {
          completer.completeError(e);
          return;
        });
    } else {
      completer.complete();
    }
    return completer.future;
  }
  
  Future update(E entity) {
    var completer = new Completer();
    _buildUpdateQuery()
      .then((_) {
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
          _updateQuery[i] = values[i];
        }
        _updateQuery.execute()
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
  
  Future _buildUpdateQuery() {
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
      var queryString = "update ${info.tableName} set $fieldNames where ${info.fields[0]}=?";
      pool.prepare(queryString)
        .then((Query query) {
          _updateQuery = query;
          completer.complete(null);
        })
        .catchError((e) {
          completer.completeError(e);
          return;
        });
    } else {
      completer.complete(null);
    }
    return completer.future;
  }
  
  Future<num> insertNew(E entity) {
    var completer = new Completer<num>();
    _buildInsertQuery()
      .then((_) {
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
          _insertQuery[i] = values[i];
        }
        _insertQuery.execute()
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
  
  Future _buildInsertQuery() {
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
      var queryString = 'insert into ${info.tableName} ($fieldNames) values ($placeholders)';
      pool.prepare(queryString)
        .then((Query query) {
          _insertQuery = query;
          completer.complete(null);
        })
        .catchError((e) {
          completer.completeError(e);
          return;
        });
    } else {
      completer.complete(null);
    }
    return completer.future;
  }
  
  Future<List<E>> readAll([String where, List values]) {
    var completer = new Completer<List<E>>();
    String whereString = "";
    if (where != null) {
      whereString = " where ${where}";
    }
    _buildReadAllQuery(whereString)
      .then((_) {
        if (values != null) {
          for (var i = 0; i < values.length; i++) {
            _readAllQuery[i] = values[i];
          }
        }
        _readAllQuery.execute()
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
  
  Future _buildReadAllQuery(String where) {
    var completer = new Completer();
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
      var queryString = 'select $fieldNames from ${info.tableName}$where';
      pool.prepare(queryString)
        .then((Query query) {
          _readAllQuery = query;
          completer.complete(null);
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

