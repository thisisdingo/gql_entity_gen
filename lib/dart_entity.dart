/// All primitives
const primitiveTypes = ['String', 'DateTime', 'Int', 'Boolean'];

/// Convert from GraphQL to Dart primitive
String convertGraphQLToDart(String input) {
  if (input == 'Int') {
    return 'int';
  }
  if (input == 'Boolean') {
    return 'bool';
  }

  return input;
}

/// Model structure
class DartEntity {
  /// Entity name
  String name = '';

  /// Entity fields array
  List<Field> fields = [];

  /// Need to parse linked entities
  List<String> needToExtractEntities = [];

  /// Parsing
  DartEntity.parse(dynamic json) {
    name = json['name'];

    for (final field in json['fields'] as Iterable) {
      // Ignore system types
      if ((field['name'] as String).startsWith('_')) {
        continue;
      }

      final dynamic typeObject = field['type'];

      String? type = _getTypeRecursive(typeObject);
      final bool isPrimitive = primitiveTypes.contains(type);
      if (isPrimitive) {
        type = convertGraphQLToDart(type);
      } else {
        needToExtractEntities.add(type);
      }

      fields.add(Field(field['name'], type));
    }
  }

  String _getTypeRecursive(dynamic input) {
    dynamic typeObject = input;
    String? type;

    bool isList = false;

    int index = 1;
    while (true) {
      for (var i = 0; i < index; i++) {
        if (typeObject['kind'] == 'LIST') {
          isList = true;
        }
        if (typeObject['name'] != null) {
          type = typeObject['name'];
        } else {
          typeObject = typeObject['ofType'];
        }
      }

      if (type != null) {
        break;
      }
      index++;
    }

    if (isList) {
      return 'List<' + type + '>';
    }

    return type;
  }

  /// Final convert to Dart entitiy
  String toDart() {
    return """class $name {
${fields.map((e) => '  ${e.type}? ${e.name};').join('\n')}

  $name({${fields.where((e) => !e.name.startsWith("_")).map((e) => 'this.${e.name}').join(', ')}});

  $name.parse(Map<String, dynamic> data) {
${fields.map((e) {
      if (e.type.startsWith("List")) {
        return "    ${e.name} = (data['${e.name}'] as Iterable).map((dynamic e) => ${e.type.split("<")[1].split(">")[0]}.parse(e)).toList();";
      } else if (e.type == "DateTime") {
        return "    ${e.name} = DateTime.parse(data['${e.name}']);";
      } else {
        return "    ${e.name} = data['${e.name}'];";
      }
    }).join('\n')}
  }

}""";
  }
}

/// Model fields
class Field {
  /// Name of field
  final String name;

  /// Type of field
  final String type;

  /// Initialize
  const Field(this.name, this.type);

  String toField() {
    return '  $type? $name;';
  }
}
