import 'dart:convert';

import 'package:xml/xml.dart';

import 'package:chameleon_shared/src/engine/utils/utils.dart';

abstract class ModelEntry {
  String get id;
  String get type;
  bool get isMounted;
  XmlElement get element;

  Map<String, dynamic> toMap();
}

class Element implements ModelEntry {
  final String type, id;
  final Map<String, int> path;
  final bool isMounted;
  final XmlElement element;
  final List<Element> children;
  final List<Binding> bindings;

  const Element(this.type, this.id, this.element, this.children, this.bindings,
      this.isMounted, this.path);

  Map<String, dynamic> toMap() {
    /*if (id == null || id.isEmpty) {
      return const <String, dynamic>{};
    }*/

    final state = attributeValue(element, 'data-state');
    final stateMap = state != null ? json.decode(state) : null;

    if (children.isEmpty) {
      return <String, dynamic>{'id': id, 'value': stateMap};
    }

    return <String, dynamic>{
      'id': id,
      'value': stateMap,
      'children': children
          /*.where((child) => child.id != null && child.id.isNotEmpty)*/
          .map((child) => child.toMap())
          .toList(growable: false)
    };
  }
}

class Binding implements ModelEntry {
  final String type, id;
  final bool isMounted;
  final XmlElement element;

  const Binding(this.type, this.id, this.element, this.isMounted);

  Map<String, dynamic> toMap() => null;
}

class ModelState {
  final Element element;
  final List<String> currentIds;

  const ModelState(this.element, this.currentIds);
}
