import 'dart:io';

import 'package:brompton_parser/models/access_specifier.dart';
import 'package:brompton_parser/models/brompton_endpoint.dart';
import 'package:brompton_parser/models/data_type.dart';
import 'package:brompton_parser/utils/capitalize_extension.dart';
import 'package:brompton_parser/utils/schema_from_data_type.dart';
import 'package:json2yaml/json2yaml.dart';
import 'package:open_api_forked/v3.dart';

// ignore: long-method
void main(List<String> arguments) {
  // Open the input file (dangerously)
  final file = File(arguments.first);

  // Create new openapi object
  final api = APIDocument();
  api.version = '3.1.0';
  api.info = APIInfo('Brompton Tessera Control API', '3.4.3');
  api.paths = {};

  // Declare variables to hold parsed but yet-to-be-converted (formatted) data
  List<String> endpointName = [];
  BromptonEndpoint? endpoint;

  // Begin the loop
  for (final line in file.readAsLinesSync()) {
    // Found a new path block
    if (line.startsWith('Path: ')) {
      // Set current path and initialize the new path object
      final path = line.replaceFirst('Path: ', '').trim();
      final parts = path.split('/');
      endpoint = BromptonEndpoint(
        path: path,
        category: parts.first,
        valueName: path.substring(path.lastIndexOf('/') + 1),
        parameters: parts
            .where((e) => e.startsWith('{') && e.endsWith('}'))
            .map((e) => e.substring(1, e.length - 1))
            .toList(),
      );
      // Description line (with possible data type appended)
    } else if (line.startsWith('Description: ')) {
      final parts = line
          .replaceFirst('Description: ', '')
          .split(' Data type: ')
          .map((e) => e.trim())
          .toList();
      endpoint!.description = parts.first;
      if (parts.length > 1) {
        endpoint.dataType =
            DataType.values.firstWhere((e) => e.value == parts.last);
      }
      // Data type line
    } else if (line.startsWith('Data type: ')) {
      endpoint!.dataType = DataType.values.firstWhere(
        (e) => e.value == line.replaceAll('Data type: ', '').trim(),
      );
      // Access specifier
    } else if (line.startsWith('Access Specifier: ')) {
      endpoint!.accessSpecifier = AccessSpecifier.values.firstWhere(
        (e) => e.value == line.replaceAll('Access Specifier: ', '').trim(),
      );
      // Range (sometimes missing spaces)
    } else if (line.startsWith('Range:')) {
      final parts =
          line.replaceAll('Range:', '').split('-').map((e) => e.trim());
      endpoint!.min = int.tryParse(parts.first);
      endpoint.max = int.tryParse(parts.last);
      // Decimal places
      // TODO: Handle these
    } else if (line.startsWith('Decimal places: ')) {
      print('WARN: Handle decimal place specifier');
      // Supported values (enum)
      // TODO: Handle these
    } else if (line.startsWith('Supported values: ')) {
      print('WARN: Handle enums');
      // Skip empty lines
    } else if (line.isEmpty) {
      continue;
      // Naively assume that failing all previous cases means we have a new title line
    } else {
      if (endpoint != null) {
        // Attempt to make a shiny new operation ID + description
        final opId = [endpoint.category, ...endpointName]
            .map((e) => e.capitalize())
            .join();
        final opDescription =
            endpointName.map((e) => e.toLowerCase()).join(' ');

        Map<String, APIOperation> operations = {};

        // If the access specifier suggests we can read this, add a Get op
        if ([AccessSpecifier.readOnly, AccessSpecifier.readWrite]
            .contains(endpoint.accessSpecifier)) {
          operations.addAll({
            'get': APIOperation(
              'get$opId',
              description: 'Gets $opDescription',
              {
                '200': APIResponse('HTTP/1.1 200 OK', content: {
                  'application/json': APIMediaType(
                    schema: APISchemaObject.object({
                      endpoint.valueName: schemaFromDataType(endpoint.dataType),
                    }),
                  ),
                }),
              },
            ),
          });
        }

        // If the access specifier suggests we can write this, add a Set op
        if ([AccessSpecifier.writeOnly, AccessSpecifier.readWrite]
            .contains(endpoint.accessSpecifier)) {
          operations.addAll({
            'put': APIOperation(
              'set$opId',
              description: 'Sets $opDescription',
              {
                '200': APIResponse('HTTP/1.1 200 OK', content: {
                  'application/json': APIMediaType(
                    schema: APISchemaObject.object({
                      endpoint.valueName: schemaFromDataType(endpoint.dataType),
                    }),
                  ),
                }),
              },
              requestBody: APIRequestBody({
                'data':
                    APIMediaType(schema: schemaFromDataType(endpoint.dataType)),
              }),
            ),
          });
        }

        // Add the new APIPath object to the api object
        api.paths?.addAll({
          endpoint.path: APIPath(
            description: endpoint.description,
            parameters: endpoint.parameters
                .map((name) => APIParameter(
                      name,
                      description: name,
                      APIParameterLocation.path,
                      isRequired: true,
                    ))
                .toList(),
            operations: operations,
          ),
        });
      }

      // Clear the current endpoint and name containers
      endpoint = null;
      endpointName = line.split(' ');
    }
  }

  // Save the file to the output path (dangerously)
  File(arguments.last).writeAsStringSync(json2yaml(api.asMap()));
}
