/// Utilitários de validação para formulários
class Validators {
  
  /// Valida CPF
  static bool isValidCPF(String cpf) {
    // Remove caracteres não numéricos
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Verifica se tem 11 dígitos
    if (cpf.length != 11) return false;
    
    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;
    
    // Calcula primeiro dígito verificador
    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }
    int resto = soma % 11;
    int digito1 = resto < 2 ? 0 : 11 - resto;
    
    // Verifica primeiro dígito
    if (int.parse(cpf[9]) != digito1) return false;
    
    // Calcula segundo dígito verificador
    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }
    resto = soma % 11;
    int digito2 = resto < 2 ? 0 : 11 - resto;
    
    // Verifica segundo dígito
    return int.parse(cpf[10]) == digito2;
  }
  
  /// Valida CNPJ
  static bool isValidCNPJ(String cnpj) {
    // Remove caracteres não numéricos
    cnpj = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Verifica se tem 14 dígitos
    if (cnpj.length != 14) return false;
    
    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(cnpj)) return false;
    
    // Calcula primeiro dígito verificador
    List<int> pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    int soma = 0;
    for (int i = 0; i < 12; i++) {
      soma += int.parse(cnpj[i]) * pesos1[i];
    }
    int resto = soma % 11;
    int digito1 = resto < 2 ? 0 : 11 - resto;
    
    // Verifica primeiro dígito
    if (int.parse(cnpj[12]) != digito1) return false;
    
    // Calcula segundo dígito verificador
    List<int> pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    soma = 0;
    for (int i = 0; i < 13; i++) {
      soma += int.parse(cnpj[i]) * pesos2[i];
    }
    resto = soma % 11;
    int digito2 = resto < 2 ? 0 : 11 - resto;
    
    // Verifica segundo dígito
    return int.parse(cnpj[13]) == digito2;
  }
  
  /// Valida CEP (formato brasileiro)
  static bool isValidCEP(String cep) {
    // Remove caracteres não numéricos
    cep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Verifica se tem 8 dígitos
    if (cep.length != 8) return false;
    
    // Verifica se não é um CEP inválido conhecido
    List<String> cepsInvalidos = ['00000000', '11111111', '22222222', '33333333', 
                                  '44444444', '55555555', '66666666', '77777777', 
                                  '88888888', '99999999'];
    
    return !cepsInvalidos.contains(cep);
  }
  
  /// Valida email
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
  
  /// Valida telefone brasileiro
  static bool isValidPhone(String phone) {
    // Remove caracteres não numéricos
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Verifica se tem 10 ou 11 dígitos (com DDD)
    if (phone.length < 10 || phone.length > 11) return false;
    
    // Verifica se o DDD é válido (11-99)
    int ddd = int.parse(phone.substring(0, 2));
    if (ddd < 11 || ddd > 99) return false;
    
    return true;
  }
  
  /// Formata CPF
  static String formatCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
  }
  
  /// Formata CNPJ
  static String formatCNPJ(String cnpj) {
    cnpj = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
    if (cnpj.length != 14) return cnpj;
    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12, 14)}';
  }
  
  /// Formata CEP
  static String formatCEP(String cep) {
    cep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return cep;
    return '${cep.substring(0, 5)}-${cep.substring(5, 8)}';
  }
  
  /// Formata telefone
  static String formatPhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length == 10) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 6)}-${phone.substring(6, 10)}';
    } else if (phone.length == 11) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 7)}-${phone.substring(7, 11)}';
    }
    return phone;
  }
  
  /// Valida senha robusta
  static bool isValidPassword(String password) {
    // Mínimo 8 caracteres
    if (password.length < 8) return false;
    
    // Pelo menos uma letra minúscula
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    
    // Pelo menos uma letra maiúscula
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    
    // Pelo menos um número
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    
    return true;
  }
  
  /// Retorna mensagem de erro para senha
  static String? getPasswordError(String password) {
    if (password.isEmpty) return 'Senha é obrigatória';
    if (password.length < 8) return 'Senha deve ter pelo menos 8 caracteres';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'Senha deve conter pelo menos uma letra minúscula';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Senha deve conter pelo menos uma letra maiúscula';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Senha deve conter pelo menos um número';
    return null;
  }
}
