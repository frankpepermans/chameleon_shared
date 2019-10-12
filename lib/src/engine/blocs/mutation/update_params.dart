import 'package:chameleon_shared/src/engine/blocs/model/model_state.dart';

class UpdateParameters {
  final ModelEntry entry;
  final String replacement, state;
  final Map<String, int> indices;

  UpdateParameters(this.entry, this.replacement, this.state, this.indices);
}
