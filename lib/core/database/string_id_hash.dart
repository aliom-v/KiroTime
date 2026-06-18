int stableStringIdHash(String value) {
  const mask = 0x7fffffffffffffff;
  const prime = 0x100000001b3;
  var hash = 0xcbf29ce484222325;

  for (var index = 0; index < value.length; index++) {
    final codeUnit = value.codeUnitAt(index);
    hash = ((hash ^ (codeUnit >> 8)) * prime) & mask;
    hash = ((hash ^ (codeUnit & 0xff)) * prime) & mask;
  }

  return hash & mask;
}
