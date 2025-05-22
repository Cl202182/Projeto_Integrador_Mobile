class Cliente {
  String _nome = "";
  String _email = "";

  Cliente(this._email, this._nome);
  String get nome => _nome;

  set nome(String value) => _nome = value;

  String get email => _email;

  set email(String value) => _email = value;
}
