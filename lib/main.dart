import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:gql_entity_gen/dart_entity.dart';
import 'package:gql_entity_gen/introspection_query.dart';
import 'package:http/http.dart' as http;

/// Flag
const String helpFlag = 'help';

/// Flag
const String entityFlag = 'entities';

/// Flag
const String addressFlag = 'address';

/// Flag
const String outputFlag = 'output';

/// Entry point
Future<void> createModelsFromArguments(List<String> arguments) async {
  final ArgParser parser = ArgParser(allowTrailingOptions: true);
  parser
    ..addFlag(helpFlag, abbr: 'h', help: 'Usage help', negatable: false)
    ..addOption(
      addressFlag,
      abbr: 'a',
      help: 'GraphQL address',
      defaultsTo: 'http://localhost:4000/graphql',
    )
    ..addOption(
      outputFlag,
      abbr: 'o',
      help: 'Generates model output path',
      defaultsTo: 'lib/app_models.dart',
    )
    ..addOption(
      entityFlag,
      abbr: 'e',
      help: 'Entities. Separeted by , Example: -e "User,Posts,Comments"',
    );

  final ArgResults argResults = parser.parse(arguments);

  if (argResults[helpFlag]) {
    print('Generates entity from GraphQL');
    print(parser.usage);
    exit(0);
  }

  if (argResults[entityFlag] == null) {
    print('Entities flag is required');
    print(parser.usage);
    exit(0);
  }

  final res = await http.post(
    Uri.parse(argResults[addressFlag]),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'query': introspectionQuery}),
  );

  final List<dynamic> allTypes = jsonDecode(res.body)['data']['__schema']['types'];

  List<String> needEntities = (argResults[entityFlag] as String).split(',');

  final List<DartEntity> entities = [];

  while (true) {
    final List<dynamic> filteredTypes = allTypes.where((dynamic e) {
      return needEntities.contains(e['name']);
    }).map((dynamic e) {
      return <String, dynamic>{'name': e['name'], 'fields': e['fields']};
    }).toList();

    entities.addAll(filteredTypes.map((dynamic e) => DartEntity.parse(e)));

    final List<String> needToExtract = [];
    for (final entity in entities) {
      for (final type in entity.needToExtractEntities) {
        String extractedType = type;

        if (type.startsWith('List<')) {
          extractedType = type.split('<')[1].split('>')[0];
        }

        if (!needToExtract.contains(extractedType) && !entities.map((e) => e.name).contains(extractedType)) {
          needToExtract.add(extractedType);
        }
      }
    }

    if (needToExtract.isEmpty) {
      break;
    }

    needEntities = needToExtract;
  }

  String exportFile = '// AUTO GENERATED CODE';

  for (final entity in entities) {
    exportFile += '\n\n// ' + entity.name + '.dart' + '\n' + entity.toDart();
  }

  File(argResults[outputFlag]).writeAsStringSync(exportFile);

  print('✅ Success saved to ' + argResults[outputFlag]);
}
