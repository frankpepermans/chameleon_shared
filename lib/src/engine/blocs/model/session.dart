import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:xml/xml.dart' as xml;

import 'package:chameleon_shared/src/engine/blocs/model/model_state.dart';
import 'package:chameleon_shared/src/engine/utils/utils.dart';

class ParserSession {
  final Future<Element> Function(xml.XmlElement element, {Element parent}) next;

  int _nextId = 0;

  final BehaviorSubject<List<Element>> _onParsed =
      BehaviorSubject<List<Element>>.seeded(const <Element>[]);
  final List<_ElementCompleter> _completers = <_ElementCompleter>[];

  Stream<List<Element>> get parsed => _onParsed.stream;

  Sink<List<Element>> get onParsed => _onParsed.sink;

  List<Element> get currentlyParsed => _onParsed.value;

  int getNextId() => ++_nextId;

  ParserSession(this.next);

  Future<Element> findMatch(String id, xml.XmlElement origin) {
    final completer = _ElementCompleter(id, origin);

    _onParsed.value.firstWhere(completer.test, orElse: () {
      _completers.add(completer);

      return null;
    });

    return completer.completer.future;
  }

  void registerParsed(Element element) {
    _completers.removeWhere((completer) => completer.test(element));

    _onParsed.add(List<Element>.unmodifiable(
        List<Element>.from(_onParsed.value)..add(element)));
  }
}

class _ElementCompleter {
  final String id;
  final xml.XmlElement origin;
  final Completer<Element> completer;

  _ElementCompleter(this.id, this.origin) : completer = Completer<Element>();

  bool test(Element other) {
    if (other.id == id && samePath(other.element, origin)) {
      completer.complete(other);

      return true;
    }

    return false;
  }
}
