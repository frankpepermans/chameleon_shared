import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js';

import 'package:xml/xml.dart' as xml;

import 'package:chameleon_shared/src/engine/blocs/model/model_state.dart';
import 'package:chameleon_shared/src/engine/interop.dart';
import 'package:chameleon_shared/src/engine/utils/utils.dart';

class WebGlue {
  static final plugins = context['plugins'] as JsObject;

  final List<String> availablePlugins;
  final Map<int, html.Element> _parserCache = <int, html.Element>{};
  final Map<int, Object> _stateCache = <int, Object>{};

  WebGlue() : availablePlugins = _listPlugins();

  static List<String> _listPlugins() {
    final obj = context['Object'] as JsObject;
    final list = obj.callMethod('keys', [plugins]) as JsArray;

    return List.unmodifiable(list.cast<String>());
  }

  Container toJsModel(ModelEntry element,
      {Container model, List<Future<Container>> futures, bool isRoot}) {
    final container = model ?? Container(null, 'root', null, true, false, -1);
    final list = futures ?? <Future<Container>>[];

    final box = (bool isBinding) => (ModelEntry child) {
          final match = child.type.toLowerCase();
          final model = Container(
              availablePlugins.firstWhere(
                  (entry) => entry.toLowerCase() == match, orElse: () {
                print('No plugin found for ${child.type}');

                return null;
              }),
              child.id,
              _asNode(child.element),
              child.isMounted,
              isBinding,
              child.uid);
          final completer = Completer<Container>();

          model.onValue.then(allowInterop(completer.complete),
              allowInterop(completer.completeError));

          if (isBinding && container.plugin.hasState) {
            final rawValue = attributeValue(element.element, 'data-state');
            final value = rawValue != null
                ? _stateCache.putIfAbsent(rawValue.hashCode,
                    () => const JsonDecoder().convert(rawValue))
                : null;
            final maybeTransform = (String value) {
              final transform = attributeValue(child.element, 'data-transform');
              final onHandler = Completer<String>();
              final attempt = (JsFunction method) {
                dynamic temp;

                try {
                  temp = method.apply([value]);
                } catch (e, s) {
                  onHandler.completeError(e, s);
                }

                return temp;
              };
              final maybeAwait = (dynamic temp) {
                if (temp is JsObject) {
                  // Promise
                  temp.callMethod('then', [
                    allowInterop(onHandler.complete),
                    allowInterop(onHandler.completeError)
                  ]);
                } else {
                  onHandler.complete(temp);
                }
              };

              if (transform != null) {
                final method = _transformerFromPath(transform);

                if (method == null) {
                  completer.completeError(ArgumentError(
                      'binding transform method $transform could not be found'));
                } else {
                  maybeAwait(attempt(method));
                }
              } else {
                onHandler.complete(value);
              }

              return onHandler.future;
            };

            maybeTransform(value).then((value) => model.plugin.setValue(value),
                onError: completer.completeError);
          }

          container.append(
              toJsModel(child, model: model, futures: list, isRoot: false));

          return completer.future;
        };

    if (element is Element) {
      list
        ..addAll(element.children.map(box(false)).toList(growable: false))
        ..addAll(element.bindings.map(box(true)).toList(growable: false));
    }

    if (isRoot) {
      // First plugin to set a value
      container.onAnyValue = Future.any(list);
    }

    return container;
  }

  html.Element _asNode(xml.XmlElement element) =>
      _parserCache.putIfAbsent(element.toXmlString().hashCode, () {
        final wrapper = element.document.rootElement;
        final parent = xml.XmlElement(
            xml.XmlName(wrapper.name.local, wrapper.name.prefix),
            wrapper.attributes.map((attr) => attr.copy()));

        parent.children.add(element.copy());

        return html.DomParser()
            .parseFromString(parent.toXmlString(), 'application/xml')
            .firstChild
            .firstChild;
      });

  JsFunction _transformerFromPath(String path) {
    final split = path.split('.');

    if (split.length == 1) return context[split.first];

    var object = context;

    for (var i = 0, len = split.length - 1; i < len; i++) {
      object = object[split[i]];
    }

    return object[split.last];
  }
}
