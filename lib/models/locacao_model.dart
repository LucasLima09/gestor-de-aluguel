// lib/models/locacao_model.dart

class LocacaoModel {
  final String id;
  final String userId;
  final String imovelId;
  final String nomeInquilino;
  final String? whatsappInquilino;
  final int diaVencimento;
  final DateTime dataInicio;
  final bool ativo;
  final DateTime criadoEm;

  LocacaoModel({
    required this.id,
    required this.userId,
    required this.imovelId,
    required this.nomeInquilino,
    this.whatsappInquilino,
    required this.diaVencimento,
    required this.dataInicio,
    required this.ativo,
    required this.criadoEm,
  });

  // Converte o JSON vindo do Supabase para o objeto Dart
  factory LocacaoModel.fromJson(Map<String, dynamic> json) {
    return LocacaoModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imovelId: json['imovel_id'] as String,
      nomeInquilino: json['nome_inquilino'] as String,
      whatsappInquilino: json['whatsapp_inquilino'] as String?,
      diaVencimento: json['dia_vencimento'] as int,
      dataInicio: DateTime.parse(json['data_inicio'] as String),
      ativo: json['ativo'] as bool,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'imovel_id': imovelId,
      'nome_inquilino': nomeInquilino,
      'whatsapp_inquilino': whatsappInquilino,
      'dia_vencimento': diaVencimento,
      'data_inicio': dataInicio.toIso8601String().substring(0, 10),
      'ativo': ativo,
    };
  }
}