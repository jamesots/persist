part of persist;

//TODO what about auto-increment ids?

class Attribute {
  final String column;
  final bool primaryKey;
  const Attribute({this.column: null, this.primaryKey: false});
}

class Entity {
  final String table;
  final bool autoInc;
  const Entity({this.table: null, this.autoInc: false});
}

class EntityInfo {
  String _tableName; // the table to store this entity in
  String _primaryKey; // the primary key field name
  String _primaryKeyColumn; // the primary key db column
  final List<String> fields; // all fields, including primary key
  final List<String> columns; // the column names, used by the db
  final ClassMirror classMirror; // a class mirror
  bool _autoInc = false; // is the primary key auto incremented?
  
  String get primaryKey => _primaryKey;
  String get primaryKeyColumn => _primaryKeyColumn;
  String get tableName => _tableName;
  bool get autoInc => _autoInc;
  
  // autoincrement field?
  
  /**
   * This defines how an entity is stored and loaded.
   */
  EntityInfo(Type classType) :
    fields = [],
    columns = [],
    classMirror = reflectClass(classType) {
    
    for (var member in classMirror.declarations.values.where((m) => m is VariableMirror)) {
      for (var metadata in member.metadata.where((m) => m is InstanceMirror)) {
        if (metadata.type.qualifiedName == const Symbol("persist.Attribute")) {
          var attribute = metadata.reflectee as Attribute;
          
          var fieldName = MirrorSystem.getName(member.simpleName);
          var columnName = fieldName;
          if (attribute.column != null) {
            columnName = attribute.column;
          }
          
          fields.add(fieldName);
          columns.add(columnName);
          
          if (attribute.primaryKey) {
            if (_primaryKey != null) {
              throw "Must not have more than one primary key";
            }
            _primaryKey = fieldName;
            _primaryKeyColumn = columnName;
          }
        }
      }
    }

    var ok = false;
    for (var metadata in classMirror.metadata.where((m) => m is InstanceMirror)) {
      if (metadata.type.qualifiedName == const Symbol("persist.Entity")) {
        var entity = metadata.reflectee as Entity;
        this._tableName = entity.table;
        this._autoInc = entity.autoInc;
        ok = true;
      }
    }
    if (!ok) {
      throw "class must have Entity annotation";
    }
    
    if (_tableName == null) {
      _tableName = MirrorSystem.getName(classMirror.simpleName);
    }
  }
  
  InstanceMirror newInstance() {
    return classMirror.newInstance(const Symbol('empty'), []);
  }
  
  getPrimaryKey(entity) {
    return reflect(entity).getField(new Symbol(primaryKey)).reflectee;
  }
}

