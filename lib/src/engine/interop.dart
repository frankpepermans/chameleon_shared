@JS('plugins')
library plugins;

import 'dart:html';

import 'package:js/js.dart';

import 'package:chameleon_shared/src/engine/core_js.dart';

@JS()
class Plugin {
  external String get id;
  external int get uid;
  external String get value;
  external bool get hasState;
  external Element get element;

  external Promise<Plugin> get onValue;

  external String mount();
  external void setValue(String value);
}

@JS()
class Container {
  external Plugin get plugin;
  external Promise<Container> get onValue;

  external factory Container(String resolvedName, String id, Element node,
      bool isMounted, bool isBinding, int uid);
  external void append(Container other);
  external Plugin findPlugin(String uid);
  external Plugin findRecursively(String uid, [dynamic indices]);

  Future<Container> onAnyValue;
}
