enum AccessSpecifier {
  readWrite('ReadWrite'),
  readOnly('ReadOnly'),
  writeOnly('WriteOnly');

  const AccessSpecifier(this.value);

  final String value;
}
