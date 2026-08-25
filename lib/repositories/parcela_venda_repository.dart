import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parcela_venda_model.dart';

class ParcelaVendaRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ParcelaVendaModel>> buscarPorImovel(String imovelId) async {
    try {
      final response = await _supabase
          .from('parcelas_venda')
          .select()
          .eq('imovel_id', imovelId)
          .order('ano_referencia', ascending: false)
          .order('mes_referencia', ascending: false);

      return (response as List)
          .map(
            (json) => ParcelaVendaModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar parcelas: $e');
    }
  }

  Future<List<ParcelaVendaModel>> buscarTodasDoUsuario() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final response = await _supabase
          .from('parcelas_venda')
          .select('*, imoveis!inner(apelido)')
          .eq('user_id', userId);

      return (response as List).map((json) {
        final data = json as Map<String, dynamic>;
        final parcela = ParcelaVendaModel.fromJson(data);
        final imovel = data['imoveis'] as Map<String, dynamic>?;
        parcela.nomeImovel = imovel?['apelido'] as String?;
        return parcela;
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar parcelas: $e');
    }
  }

  Future<List<ParcelaVendaModel>> buscarPendentes() async {
    final todas = await buscarTodasDoUsuario();
    return todas.where((p) => p.pendenteNoMesOuAtrasada).toList();
  }

  Future<void> gerarParcela(ParcelaVendaModel parcela) async {
    try {
      await _supabase.from('parcelas_venda').insert(parcela.toJson());
    } catch (e) {
      throw Exception('Erro ao gerar parcela: $e');
    }
  }

  Future<void> marcarComoPaga(String parcelaId) async {
    try {
      await _supabase
          .from('parcelas_venda')
          .update({
            'pago': true,
            'data_pagamento': DateTime.now().toIso8601String().substring(0, 10),
          })
          .eq('id', parcelaId);
    } catch (e) {
      throw Exception('Erro ao confirmar pagamento: $e');
    }
  }

  Future<void> excluirParcela(String parcelaId) async {
    try {
      await _supabase.from('parcelas_venda').delete().eq('id', parcelaId);
    } catch (e) {
      throw Exception('Erro ao excluir parcela: $e');
    }
  }
}
