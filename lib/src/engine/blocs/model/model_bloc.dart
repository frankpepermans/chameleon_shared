import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:xml/xml.dart' as xml;

import 'package:chameleon_shared/src/engine/blocs/model/model_state.dart';
import 'package:chameleon_shared/src/engine/blocs/model/session.dart';
import 'package:chameleon_shared/src/engine/blocs/model/strategy.dart';
import 'package:chameleon_shared/src/engine/blocs/xml/bloc.dart';
import 'package:chameleon_shared/src/engine/blocs/xml/xml_state.dart';

enum _ElementType { binding, core, plain }

class ModelBloc extends Bloc<XmlState, ModelState> {
  ParserSession _session;

  ModelBloc() {
    _session = ParserSession(_parse);
  }

  @override
  ModelState get initialState => const ModelState(
      Element('', '', null, <Element>[], <Binding>[], false, -1), <String>[]);

  @override
  Stream<ModelState> mapEventToState(XmlState event) async* {
    _session.onParsed.add(const <Element>[]);

    yield ModelState(
        await _toModel(event),
        _session.currentlyParsed
            .map((element) => element.id)
            .toList(growable: false));
  }

  @override
  Stream<ModelState> transformEvents(events, next) =>
      Observable(events).whereType<DocumentState>().switchMap(next);

  Future<Element> _toModel(DocumentState state) => _parse(
      state.document.rootElement,
      parent:
          Element('root', 'root', null, <Element>[], <Binding>[], false, -1));

  Future<Element> _parse(xml.XmlElement element, {Element parent}) =>
      _resolveStrategy(element.name.prefix).apply(element, parent, _session);

  ParserStrategy _resolveStrategy(String fromPrefix) {
    switch (_resolveElementType(fromPrefix)) {
      case _ElementType.core:
        return const CoreParserStrategy();
      case _ElementType.binding:
        return const BindingParserStrategy();
      default:
        return const DefaultParserStrategy();
    }
  }

  _ElementType _resolveElementType(String fromPrefix) {
    if (fromPrefix == 'core' || fromPrefix == 'mounted') {
      return _ElementType.core;
    } else if (fromPrefix == 'binding' || fromPrefix == 'bound') {
      return _ElementType.binding;
    }

    return _ElementType.plain;
  }
}
