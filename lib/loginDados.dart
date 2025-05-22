class DadosL {
  String login = "";
  String senha = "";

  DadosL(this.login, this.senha);

  String get getNome => login;

  set setNome(String nome) => login = login;

  get getSenha => senha;

  set setSenha(senha) => this.senha = senha;
}
