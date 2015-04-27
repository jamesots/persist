part of persist;

class Queries {
  String _insertQuery;
  String _readAllQuery;
  String _readWhereQuery;
  String _updateQuery;
  String _deleteQuery;
  
  final EntityInfo info;
  
  Queries(this.info) {
    _buildInsertQuery();
    _buildReadAllQuery();
    _buildReadWhereQuery();
    _buildUpdateQuery();
    _buildDeleteQuery();
  }
  
  _buildInsertQuery() {
    var fieldNameBuffer = new StringBuffer();
    var placeholderBuffer = new StringBuffer();
    var i = 0;
    info.fields.forEach((name) {
      if (!info.autoInc || name != info.primaryKey) {
        if (fieldNameBuffer.length > 0) {
          fieldNameBuffer.write(", ");
          placeholderBuffer.write(", ");
        }
        fieldNameBuffer.write(info.columns[i]);
        placeholderBuffer.write("?");
      }
      i++;
    });
    var fieldNames = fieldNameBuffer.toString();
    var placeholders = placeholderBuffer.toString();
    _insertQuery = 'insert into ${info.tableName} ($fieldNames) values ($placeholders)';
  }
  
  _buildReadAllQuery() {
    var fieldNameBuffer = new StringBuffer();
    var i = 0;
    info.columns.forEach((name) {
      if (i > 0) {
        fieldNameBuffer.write(", ");
      }
      fieldNameBuffer.write(name);
      i++;
    });
    var fieldNames = fieldNameBuffer.toString();
    _readAllQuery = 'select $fieldNames from ${info.tableName}';
  }
  
  _buildReadWhereQuery() {
    _readWhereQuery = "${info.primaryKeyColumn} = ?";
  }
  
  _buildUpdateQuery() {
    var fieldNameBuffer = new StringBuffer();
    var i = 0;
    var first = true;
    info.fields.forEach((name) {
      if (name != info.primaryKey) {
        if (!first) {
          fieldNameBuffer.write(", ");
        }
        first = false;
        fieldNameBuffer.write(info.columns[i]);
        fieldNameBuffer.write("=?");
      }
      i++;
    });
    var fieldNames = fieldNameBuffer.toString();
    _updateQuery = "update ${info.tableName} set $fieldNames where ${info.primaryKeyColumn}=?";
  }
  
  _buildDeleteQuery() {
    _deleteQuery = "delete from ${info.tableName} where ${info.primaryKeyColumn}=?";
  }

  String get insert => _insertQuery;
  String get readAll => _readAllQuery;
  String get readWhere => _readWhereQuery;
  String get update => _updateQuery;
  String get delete => _deleteQuery;
}
