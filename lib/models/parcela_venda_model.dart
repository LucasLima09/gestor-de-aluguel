class ParcelaVendaModel {
  final String id;
  final String userId;
  final String imovelId;
  final int mesReferencia;
  final int anoReferencia;
  final double valor;
  final bool pago;
  final DateTime? dataPagamento;
  final DateTime criadoEm;
  String? nomeImovel;

  ParcelaVendaModel({
    required this.id,
    required this.userId,
    required this.imovelId,
    required this.mesReferencia,
    required this.anoReferencia,
    required this.valor,
    required this.pago,
    this.dataPagamento,
    required this.criadoEm,
    this.nomeImovel,
  });

  factory ParcelaVendaModel.fromJson(Map<String, dynamic> json) {
    return ParcelaVendaModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imovelId: json['imovel_id'] as String,
      mesReferencia: json['mes_referencia'] as int,
      anoReferencia: json['ano_referencia'] as int,
      valor: (json['valor'] as num).toDouble(),
      pago: json['pago'] as bool,
      dataPagamento: json['data_pagamento'] != null
          ? DateTime.parse(json['data_pagamento'] as String)
          : null,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'imovel_id': imovelId,
      'mes_referencia': mesReferencia,
      'ano_referencia': anoReferencia,
      'valor': valor,
      'pago': pago,
      'data_pagamento': dataPagamento?.toIso8601String().substring(0, 10),
    };
  }

  bool get atrasada {
    if (pago) return false;
    final agora = DateTime.now();
    if (anoReferencia < agora.year) return true;
    if (anoReferencia == agora.year && mesReferencia < agora.month) {
      return true;
    }
    return false;
  }

  bool get pendenteNoMesOuAtrasada {
    if (pago) return false;
    final agora = DateTime.now();
    if (anoReferencia < agora.year) return true;
    if (anoReferencia == agora.year && mesReferencia <= agora.month) {
      return true;
    }
    return false;
  }
}
