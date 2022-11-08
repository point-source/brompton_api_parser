import 'access_specifier.dart';
import 'data_type.dart';

class BromptonEndpoint {
  BromptonEndpoint({
    required this.path,
    this.description = '',
    this.category = '',
    this.dataType,
    this.accessSpecifier,
    required this.valueName,
    this.parameters = const [],
    this.min,
    this.max,
  });

  final String path;
  String description;
  String category;
  DataType? dataType;
  AccessSpecifier? accessSpecifier;
  String valueName;
  List<String> parameters;
  int? min;
  int? max;
}
