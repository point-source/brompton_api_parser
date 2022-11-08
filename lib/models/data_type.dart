enum DataType {
  string('string'),
  boolean('bool'),
  integer('int'),
  float('float'),
  bytearray('bytearray'),
  enumerator('enum'),
  array('array');

  const DataType(this.value);

  final String value;
}
