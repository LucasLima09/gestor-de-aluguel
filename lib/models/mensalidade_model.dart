class MensalidadeModel {
  final String id;
  final String userId;
  final String locacaoId;
  final int mesReferencia;
  final int anoReferencia;
  final double valor;
  final bool pago;
  final DateTime? dataPagamento;
  final String? nomeInquilino;
  final DateTime criadoEm;

  MensalidadeModel({
    required this.id,
    required this.userId,
    required this.locacaoId,
    required this.mesReferencia,
    required this.anoReferencia,
    required this.valor,
    required this.pago,
    this.dataPagamento,
    this.nomeInquilino,
    required this.criadoEm,
  });

  factory MensalidadeModel.fromJson(Map<String, dynamic> json) {
    return MensalidadeModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      locacaoId: json['locacao_id'] as String,
      mesReferencia: json['mes_referencia'] as int,
      anoReferencia: json['ano_referencia'] as int,
      valor: (json['valor'] as num).toDouble(),
      pago: json['pago'] as bool,
      dataPagamento: json['data_pagamento'] != null
          ? DateTime.parse(json['data_pagamento'] as String)
          : null,
      nomeInquilino: json['nome_inquilino'] as String?,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'locacao_id': locacaoId,
      'mes_referencia': mesReferencia,
      'ano_referencia': anoReferencia,
      'valor': valor,
      'pago': pago,
      'data_pagamento': dataPagamento?.toIso8601String().substring(0, 10),
      'nome_inquilino': nomeInquilino,
    };
  }
}