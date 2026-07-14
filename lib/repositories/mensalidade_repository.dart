import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mensalidade_model.dart';

class MensalidadeRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MensalidadeModel>> buscarMensalidadesPorLocacao(String locacaoId) async {
    try {
      final response = await _supabase
          .from('mensalidades')
          .select()
          .eq('locacao_id', locacaoId)
          .order('ano_referencia', ascending: false)
          .order('mes_referencia', ascending: false);

      return (response as List)
          .map((json) => MensalidadeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar mensalidades: $e');
    }
  }

  Future<void> gerarMensalidade(MensalidadeModel mensalidade) async {
    try {
      await _supabase.from('mensalidades').insert(mensalidade.toJson());
    } catch (e) {
      throw Exception('Erro ao gerar mensalidade: $e');
    }
  }

  Future<void> marcarComoPaga(String mensalidadeId) async {
    try {
      await _supabase.from('mensalidades').update({
        'pago': true,
        'data_pagamento': DateTime.now().toIso8601String().substring(0, 10),
      }).eq('id', mensalidadeId);
    } catch (e) {
      throw Exception('Erro ao confirmar pagamento: $e');
    }
  }
}