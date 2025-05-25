class MessageKey {
  final String? _value;

  const MessageKey._(this._value);

  factory MessageKey.create(String value) => MessageKey._(value);
  factory MessageKey.none() => const MessageKey._(null);

  String? get value => _value;
  bool get hasValue => _value != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageKey && runtimeType == other.runtimeType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => hasValue ? 'MessageKey($_value)' : 'MessageKey(NONE)';
}