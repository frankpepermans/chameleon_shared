import 'package:xml/xml.dart' as xml;

abstract class XmlState {}

class InitialState implements XmlState {}

class DocumentState implements XmlState {
  final xml.XmlDocument document;

  DocumentState(this.document);
}

class ErrorState implements XmlState {
  final xml.XmlException exception;

  ErrorState(this.exception);
}
