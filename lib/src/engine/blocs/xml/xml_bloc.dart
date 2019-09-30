import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:xml/xml.dart' as xml;

import 'package:chameleon_shared/src/engine/blocs/xml/xml_event.dart';
import 'package:chameleon_shared/src/engine/blocs/xml/xml_state.dart';

class XmlBloc extends Bloc<XmlEvent, XmlState> {
  XmlBloc();

  @override
  XmlState get initialState => InitialState();

  @override
  Stream<XmlState> mapEventToState(XmlEvent event) async* {
    if (event is RawEvent) {
      xml.XmlDocument document;

      try {
        document = xml.parse(event.raw);

        yield DocumentState(document);
      } on xml.XmlException catch (e) {
        yield ErrorState(e);
      }
    } else if (event is DocumentEvent) {
      yield DocumentState(event.document);
    } else if (event is ErrorEvent) {
      yield ErrorState(event.exception);
    }
  }

  @override
  Stream<XmlState> transformEvents(events, next) =>
      Observable(events).switchMap(next);
}
