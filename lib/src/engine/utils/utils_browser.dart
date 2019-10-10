import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js_util';

import 'package:chameleon_shared/src/engine/utils/utils.dart';
import 'package:xml/xml.dart' as xml;

final Map<String, bool> _matchingIndexCache = <String, bool>{};

Map<String, int> indexMapHtml(Element htmlElement) => htmlElement.attributes
        .containsKey('data-index')
    ? Map<String, int>.from(json.decode(htmlElement.attributes['data-index']))
    : const <String, int>{};

dynamic getCombinedIndex(xml.XmlElement element, {bool asJsObject = true}) {
  final indices = <String, int>{};
  xml.XmlNode current = element;

  while (current != null && current is! XmlDocument) {
    if (current is xml.XmlElement) {
      final json = attributeValue(current, 'data-index');

      if (json != null) {
        indices
            .addAll(Map<String, int>.from(const JsonDecoder().convert(json)));
      }
    }

    current = current.parent;
  }

  return asJsObject ? toJsObject(indices) : indices;
}

dynamic toJsObject(Map<String, int> indices) {
  final obj = newObject();

  indices.forEach((k, v) => setProperty(obj, k, v));

  return obj;
}
