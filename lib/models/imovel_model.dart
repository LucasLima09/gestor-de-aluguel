class ImovelModel {
  final String id;
  final String userId;
  final String apelido;
  final String? endereco;
  final double valorBaseAluguel;
  final DateTime criadoEm;

  ImovelModel({
    required this.id,
    required this.userId,
    required this.apelido,
    this.endereco,
    required this.valorBaseAluguel,
    required this.criadoEm,
  });

  factory ImovelModel.fromJson(Map<String, dynamic> json) {
    return ImovelModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      apelido: json['apelido'] as String,
      endereco: json['endereco'] as String?,
      valorBaseAluguel: (json['valor_base_aluguel'] as num).toDouble(),
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apelido': apelido,
      'endereco': endereco,
      'valor_base_aluguel': valorBaseAluguel,
      'user_id': userId,
    };
  }
}