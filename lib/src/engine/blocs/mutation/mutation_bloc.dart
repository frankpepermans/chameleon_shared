import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:chameleon_shared/src/engine/utils/utils.dart';
import 'package:rxdart/rxdart.dart';
import 'package:xml/xml.dart' as xml;

import 'package:chameleon_shared/src/engine/blocs/model/model_state.dart';
import 'package:chameleon_shared/src/engine/blocs/mutation/update_params.dart';
import 'package:chameleon_shared/src/engine/blocs/xml/bloc.dart';

class MutationBloc extends Bloc<Element, XmlEvent> {
  final String raw;
  final Stream<UpdateParameters> update;

  MutationBloc(this.raw, this.update);

  @override
  XmlEvent get initialState => RawEvent(raw);

  @override
  Stream<XmlEvent> mapEventToState(Element event) async* {
    yield* update
        .map(
            (params) => _update(params.entry, params.replacement, params.state))
        .where((doc) => doc != null);
  }

  @override
  Stream<XmlEvent> transformEvents(events, next) {
    return Observable(events).switchMap(next);
  }

  XmlEvent _update(ModelEntry original, String replacement, String state) {
    if (original == null) return null;

    final xml.XmlElement parent = original.element.parent;
    xml.XmlDocument doc;

    try {
      doc = xml.parse(replacement);

      _replaceNodes(original.element, original is Binding,
          doc.children.first.children, state);

      return DocumentEvent(parent.root);
    } on xml.XmlException catch (e) {
      return ErrorEvent(e);
    }
  }

  ModelEntry _findElementByUid(
      Element current, int uid, Map<String, int> indices) {
    for (var i = 0, len = current.children.length; i < len; i++) {
      final child = current.children[i];

      if (child.uid == uid) {
        final localIndices = indexMapXml(child.element);
        final mismatch = localIndices.keys.firstWhere(
            (key) => indices[key] != localIndices[key],
            orElse: () => null);

        if (mismatch == null) return child;
      }

      final recursive = _findElementByUid(child, uid, indices);

      if (recursive != null) return recursive;
    }

    return current.bindings
        .firstWhere((binding) => binding.uid == uid, orElse: () => null);
  }

  void _replaceNodes(xml.XmlElement original, bool isBinding,
      List<xml.XmlNode> nodes, String state) {
    final mounted = _asTransformedElement(
        original, isBinding ? 'bound' : 'mounted',
        state: state);
    final parent = original.parent;
    final list = nodes.toList(growable: false);
    final index = parent.children.indexOf(original);

    nodes.clear();

    parent.children.removeAt(index);
    mounted.children.addAll(list);
    parent.children.insert(index, mounted);
  }

  xml.XmlElement _asTransformedElement(xml.XmlElement element, String prefix,
      {String state}) {
    final name = xml.XmlName(element.name.local, prefix);
    final xml.XmlAttribute Function(xml.XmlAttribute) copyAttr =
        (xml.XmlAttribute attr) => attr.copy();
    final attributes = element.attributes.map(copyAttr).toList();

    if (state != null) {
      attributes.removeWhere((attr) => attr.name.local == 'data-state');
      attributes.add(xml.XmlAttribute(
          xml.XmlName('data-state'), const JsonEncoder().convert(state)));
    }

    return xml.XmlElement(name, attributes);
  }
}
