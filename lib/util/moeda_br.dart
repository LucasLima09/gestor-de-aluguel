class MoedaBr {
  MoedaBr._();

  static String formatar(double valor) {
    final negativo = valor < 0;
    final cents = (valor.abs() * 100).round();
    final inteiro = (cents ~/ 100).toString();
    final decimal = (cents % 100).toString().padLeft(2, '0');
    final buffer = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(inteiro[i]);
    }
    return '${negativo ? '-' : ''}$buffer,$decimal';
  }

  static String reais(double valor) => 'R\$ ${formatar(valor)}';

  static double? parse(String? raw) {
    if (raw == null) return null;
    var texto = raw.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (texto.isEmpty) return null;
    if (texto.contains(',') && texto.contains('.')) {
      texto = texto.replaceAll('.', '').replaceAll(',', '.');
    } else if (texto.contains(',')) {
      texto = texto.replaceAll(',', '.');
    }
    return double.tryParse(texto);
  }
}
