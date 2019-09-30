import 'package:xml/xml.dart' as xml;

abstract class XmlEvent {}

class RawEvent implements XmlEvent {
  final String raw;

  RawEvent(this.raw);
}

class DocumentEvent implements XmlEvent {
  final xml.XmlDocument document;

  DocumentEvent(this.document);
}

class ErrorEvent implements XmlEvent {
  final xml.XmlException exception;

  ErrorEvent(this.exception);
}
