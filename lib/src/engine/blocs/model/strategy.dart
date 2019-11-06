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

      final isBound =
          element.name.prefix == 'bound' || element.name.prefix == 'mounted';

      parent.bindings.add(Binding(element.name.local, id, element, isBound));

      if (isBound) {
        final handler =
            (xml.XmlElement element) => session.next(element, parent: parent);

        return asyncEvery(notOmitted(element.children), handler)
            .then((_) => parent);
      }

      return parent;
    }, onError: (e, s) {
      print(
          'Unable to match binding: "${element.name.local}" with core id: $id');

      return parent;
    });
  }
}

class CoreParserStrategy implements ParserStrategy {
  const CoreParserStrategy();

  Future<Element> apply(
      xml.XmlElement element, Element parent, ParserSession session) {
    final isMounted = element.name.prefix == 'mounted';
    final id = attributeValue(element, 'id');
    final entry = Element(
        element.name.local,
        id,
        element,
        <Element>[],
        <Binding>[],
        isMounted,
        id != null ? getCombinedIndex(element) : const {});

    if (entry.id != null && session.isRegistered(entry)) {
      /// Treat a core node as a binding node if the same id/path is encountered
      /// This can occur for example when loading external templates,
      /// where we cannot control the ID's used
      return const BindingParserStrategy().apply(element, parent, session);
    }

    parent.children.add(entry);

    session.registerParsed(entry);

    if (isMounted) {
      final handler =
          (xml.XmlElement element) => session.next(element, parent: entry);

      return asyncEvery(notOmitted(element.children), handler)
          .then((_) => entry);
    }

    return Future.value(entry);
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
