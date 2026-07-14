import 'package:alugaai/models/locacao_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocacaoRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> cadastrarLocacao(LocacaoModel locacao) async {
    try {
      final existente = await _supabase
          .from('locacoes')
          .select()
          .eq('imovel_id', locacao.imovelId)
          .maybeSingle();

      if (existente != null) {
        await _supabase
            .from('locacoes')
            .update({
              'nome_inquilino': locacao.nomeInquilino,
              'whatsapp_inquilino': locacao.whatsappInquilino,
              'dia_vencimento': locacao.diaVencimento,
              'data_inicio': locacao.dataInicio.toIso8601String().substring(0, 10),
              'ativo': true,
            })
            .eq('id', existente['id']);
      } else {
        await _supabase.from('locacoes').insert(locacao.toJson());
      }
    } catch (e) {
      throw Exception('Erro ao cadastrar contrato: $e');
    }
  }

  Future<LocacaoModel?> buscarLocacaoAtivaPorImovel(String imovelId) async {
    try {
      final response = await _supabase
          .from('locacoes')
          .select()
          .eq('imovel_id', imovelId)
          .eq('ativo', true)
          .maybeSingle();

      if (response == null) return null;
      return LocacaoModel.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao buscar locação ativa: $e');
    }
  }

  Future<void> encerrarLocacao(String locacaoId) async {
    try {
      await _supabase
          .from('locacoes')
          .update({'ativo': false})
          .eq('id', locacaoId);
    } catch (e) {
      throw Exception('Erro ao encerrar contrato: $e');
    }
  }
}