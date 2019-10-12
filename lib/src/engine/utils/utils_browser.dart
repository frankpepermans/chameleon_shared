import 'dart:convert';
import 'dart:html';
import 'dart:js_util';

final Map<String, bool> _matchingIndexCache = <String, bool>{};

Map<String, int> indexMapHtml(Element htmlElement) => htmlElement.attributes
        .containsKey('data-index')
    ? Map<String, int>.from(json.decode(htmlElement.attributes['data-index']))
    : const <String, int>{};

dynamic toJsObject(Map<String, int> indices) {
  final obj = newObject();

  indices.forEach((k, v) => setProperty(obj, k, v));

  return obj;
}
