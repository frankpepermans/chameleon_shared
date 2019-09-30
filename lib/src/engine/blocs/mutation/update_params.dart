class UpdateParameters {
  final int uid;
  final String replacement, state;
  final Map<String, int> indices;

  UpdateParameters(this.uid, this.replacement, this.state, this.indices);
}
