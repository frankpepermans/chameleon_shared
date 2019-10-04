import 'dart:async';

import 'package:xml/xml.dart' as xml;

import 'package:chameleon_shared/src/engine/blocs/model/model_state.dart';
import 'package:chameleon_shared/src/engine/blocs/model/session.dart';
import 'package:chameleon_shared/src/engine/utils/utils.dart';

abstract class ParserStrategy {
  Future<Element> apply(xml.XmlElement element, Element parent,
      ParserSession session, OpenCloseNodes openCloseNodes);
}

class BindingParserStrategy implements ParserStrategy {
  const BindingParserStrategy();

  Future<Element> apply(xml.XmlElement element, Element parent,
      ParserSession session, OpenCloseNodes openCloseNodes) {
    final id = attributeValue(element, 'id');

    openCloseNodes.incrementOpen();

    return session
        .findMatch(id, element, openCloseNodes.completer)
        .then((parent) {
      if (parent == null) return null;

      parent.bindings.add(Binding(element.name.local, id, element,
          element.name.prefix == 'bound', session.getNextId()));

      return asyncEvery(
          notOmitted(element.children),
          (xml.XmlElement element) => session.next(element,
              parent: parent,
              openCloseNodes: openCloseNodes)).then((_) => parent);
    });
  }
}

class CoreParserStrategy implements ParserStrategy {
  const CoreParserStrategy();

  Future<Element> apply(xml.XmlElement element, Element parent,
      ParserSession session, OpenCloseNodes openCloseNodes) {
    final entry = Element(
        element.name.local,
        attributeValue(element, 'id'),
        element,
        <Element>[],
        <Binding>[],
        element.name.prefix == 'mounted',
        session.getNextId());

    openCloseNodes.incrementOpen();

    parent.children.add(entry);

    session.registerParsed(entry);

    return asyncEvery(
        notOmitted(element.children),
        (xml.XmlElement element) => session.next(element,
            parent: entry, openCloseNodes: openCloseNodes)).then((_) => entry);
  }
}

class DefaultParserStrategy implements ParserStrategy {
  const DefaultParserStrategy();

  Future<Element> apply(xml.XmlElement element, Element parent,
      ParserSession session, OpenCloseNodes openCloseNodes) {
    openCloseNodes.incrementOpen();

    return asyncEvery(
        notOmitted(element.children),
        (xml.XmlElement element) => session.next(element,
            parent: parent,
            openCloseNodes: openCloseNodes)).then((_) => parent);
  }
}

class OpenCloseNodes {
  final Completer<bool> completer = Completer<bool>();
  int _openNodes = 0, _closedNodes = 0;

  OpenCloseNodes();

  void incrementOpen() => _openNodes++;

  void incrementClosed() => _closedNodes++;

  void tryResolve() {
    if (_openNodes > 0 && _closedNodes > 0 && _openNodes == _closedNodes) {
      completer.complete(true);
    }
  }
}
