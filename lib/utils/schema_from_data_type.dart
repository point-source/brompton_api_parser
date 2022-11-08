import 'package:brompton_parser/models/data_type.dart';
import 'package:open_api_forked/v3.dart';

APISchemaObject schemaFromDataType(DataType? type) {
  switch (type) {
    case DataType.array:
    case DataType.bytearray:
      return APISchemaObject.array(ofType: APIType.string);
    case DataType.boolean:
      return APISchemaObject.boolean();
    case DataType.enumerator:
      return APISchemaObject.freeForm();
    case DataType.float:
      return APISchemaObject.number();
    case DataType.integer:
      return APISchemaObject.integer();
    default:
      return APISchemaObject.string();
  }
}
