import 'dart:async';
import 'dart:convert';

import 'package:xml/xml.dart' as xml;

final Map<String, bool> _matchingIndexCache = <String, bool>{};

Map<String, int> indexMapXml(xml.XmlElement xmlElement) {
  final data = attributeValue(xmlElement, 'data-index');

  if (data != null) {
    return Map<String, int>.from(json.decode(data));
  }

  return const <String, int>{};
}

String attributeValue(xml.XmlElement element, String name) {
  if (element == null) return null;

  final attr = element.attributes
      .firstWhere((attr) => attr.name.local == name, orElse: () => null);

  return attr?.value;
}

bool samePath(xml.XmlElement origin, String right, Map rMap) {
  final left = attributeValue(origin, 'data-index');
  final hash = '${left.hashCode}_${right.hashCode}';

  return _matchingIndexCache.putIfAbsent(hash, () {
    if (left == right) return true;
    if (left == null || right == null) return false;

    final lMap = const JsonDecoder().convert(left) as Map;

    final unionKeys =
        lMap.keys.where((key) => rMap.containsKey(key)).toList(growable: false);

    if (unionKeys.isEmpty) return false;

    for (var i = 0, len = unionKeys.length; i < len; i++) {
      final key = unionKeys[i];

      if (lMap[key] != rMap[key]) return false;
    }

    return true;
  });
}

Future<dynamic> asyncEvery<T>(
        Iterable<T> list, Future<dynamic> fn(T current)) =>
    Stream.fromIterable(list).asyncMap(fn).drain();

List<xml.XmlElement> notOmitted(Iterable<xml.XmlNode> list) => list
    .whereType<xml.XmlElement>()
    .where((element) => element.name.local != 'omit')
    .toList(growable: false);
