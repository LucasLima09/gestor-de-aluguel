enum ImovelTipo {
  aluguel,
  venda;

  static ImovelTipo fromString(String? value) {
    if (value == 'venda') return ImovelTipo.venda;
    return ImovelTipo.aluguel;
  }

  String get dbValue => name;

  String get label => this == ImovelTipo.venda ? 'Venda' : 'Aluguel';
}

class ImovelModel {
  final String id;
  final String userId;
  final String apelido;
  final String? endereco;
  final ImovelTipo tipo;
  final double valorBaseAluguel;
  final double? valorVenda;
  final double? valorMensalVenda;
  final DateTime criadoEm;

  ImovelModel({
    required this.id,
    required this.userId,
    required this.apelido,
    this.endereco,
    this.tipo = ImovelTipo.aluguel,
    required this.valorBaseAluguel,
    this.valorVenda,
    this.valorMensalVenda,
    required this.criadoEm,
  });

  bool get isVenda => tipo == ImovelTipo.venda;
  bool get isAluguel => tipo == ImovelTipo.aluguel;

  factory ImovelModel.fromJson(Map<String, dynamic> json) {
    return ImovelModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      apelido: json['apelido'] as String,
      endereco: json['endereco'] as String?,
      tipo: ImovelTipo.fromString(json['tipo'] as String?),
      valorBaseAluguel: (json['valor_base_aluguel'] as num?)?.toDouble() ?? 0,
      valorVenda: (json['valor_venda'] as num?)?.toDouble(),
      valorMensalVenda: (json['valor_mensal_venda'] as num?)?.toDouble(),
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apelido': apelido,
      'endereco': endereco,
      'tipo': tipo.dbValue,
      'valor_base_aluguel': valorBaseAluguel,
      'valor_venda': valorVenda,
      'valor_mensal_venda': valorMensalVenda,
      'user_id': userId,
    };
  }
}
