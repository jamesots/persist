part of persist;

class Queries {
  String _insertQuery;
  String _readAllQuery;
  String _readWhereQuery;
  String _updateQuery;
  String _deleteQuery;
  
  final EntityInfo info;
  
  Queries(this.info) {
    buildInsertQuery();
    buildReadAllQuery();
    buildReadWhereQuery();
    buildUpdateQuery();
    buildDeleteQuery();
  }
  
  buildInsertQuery() {
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
  
  buildReadAllQuery() {
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
  
  buildReadWhereQuery() {
    _readWhereQuery = "${info.primaryKey} = ?";
  }
  
  buildUpdateQuery() {
    var fieldNameBuffer = new StringBuffer();
    var i = 0;
    var first = true;
    info.fields.forEach((name) {
      if (name != info.primaryKey) {
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
    _updateQuery = "update ${info.tableName} set $fieldNames where ${info.primaryKey}=?";
  }
  
  buildDeleteQuery() {
    _deleteQuery = "delete from ${info.tableName} where ${info.primaryKey}=?";
  }

  String get insert => _insertQuery;
  String get readAll => _readAllQuery;
  String get readWhere => _readWhereQuery;
  String get update => _updateQuery;
  String get delete => _deleteQuery;
}
