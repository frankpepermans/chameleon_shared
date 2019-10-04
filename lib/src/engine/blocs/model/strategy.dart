import 'dart:async';

import 'package:xml/xml.dart' as xml;

import 'package:chameleon_shared/src/engine/blocs/model/model_state.dart';
import 'package:chameleon_shared/src/engine/blocs/model/session.dart';
import 'package:chameleon_shared/src/engine/utils/utils.dart';

abstract class ParserStrategy {
  Future<Element> apply(
      xml.XmlElement element, Element parent, ParserSession session);
}

class BindingParserStrategy implements ParserStrategy {
  const BindingParserStrategy();

  Future<Element> apply(
      xml.XmlElement element, Element parent, ParserSession session) {
    final id = attributeValue(element, 'id');

    return session
        .findMatch(id, element)
        .timeout(const Duration(milliseconds: 20))
        .then((parent) {
      if (parent == null) return null;

      parent.bindings.add(Binding(element.name.local, id, element,
          element.name.prefix == 'bound', session.getNextId()));

      return asyncEvery(notOmitted(element.children),
              (xml.XmlElement element) => session.next(element, parent: parent))
          .then((_) => parent);
    }, onError: (e, s) {
      print(e);

      return parent;
    });
  }
}

class CoreParserStrategy implements ParserStrategy {
  const CoreParserStrategy();

  Future<Element> apply(
      xml.XmlElement element, Element parent, ParserSession session) {
    final entry = Element(
        element.name.local,
        attributeValue(element, 'id'),
        element,
        <Element>[],
        <Binding>[],
        element.name.prefix == 'mounted',
        session.getNextId());

    parent.children.add(entry);

    session.registerParsed(entry);

    return asyncEvery(notOmitted(element.children),
            (xml.XmlElement element) => session.next(element, parent: entry))
        .then((_) => entry);
  }
}

class DefaultParserStrategy implements ParserStrategy {
  const DefaultParserStrategy();

  Future<Element> apply(
          xml.XmlElement element, Element parent, ParserSession session) =>
      asyncEvery(notOmitted(element.children),
              (xml.XmlElement element) => session.next(element, parent: parent))
          .then((_) => parent);
}
