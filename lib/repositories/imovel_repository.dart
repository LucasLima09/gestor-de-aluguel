import 'package:alugala/models/imovel_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImovelRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ImovelModel>> getImoveis() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuário não autenticado");

      final response = await _supabase
          .from('imoveis')
          .select()
          .eq('user_id', userId)
          .order('apelido', ascending: true);
      return (response as List)
          .map((json) => ImovelModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Erro ao buscar imóveis: $e");
    }
  }

  Future<ImovelModel> buscarImovelPorId(String imovelId) async {
    try {
      final response = await _supabase
          .from('imoveis')
          .select()
          .eq('id', imovelId)
          .single();
      return ImovelModel.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao buscar imóvel: $e');
    }
  }

  Future<void> atualizarImovel({
    required String imovelId,
    required String apelido,
    required String? endereco,
    required ImovelTipo tipo,
    required double valorBaseAluguel,
    required double? valorVenda,
    required double? valorMensalVenda,
  }) async {
    try {
      await _supabase
          .from('imoveis')
          .update({
            'apelido': apelido,
            'endereco': endereco,
            'tipo': tipo.dbValue,
            'valor_base_aluguel': valorBaseAluguel,
            'valor_venda': valorVenda,
            'valor_mensal_venda': valorMensalVenda,
          })
          .eq('id', imovelId);
    } catch (e) {
      throw Exception('Erro ao atualizar imóvel: $e');
    }
  }

  Future<void> deletarImovel(String imovelId) async {
    try {
      await _supabase.from('imoveis').delete().eq('id', imovelId);
    } catch (e) {
      throw Exception('Erro ao excluir imóvel: $e');
    }
  }

  Future<void> registerImovel({
    required String apelido,
    required String? endereco,
    required ImovelTipo tipo,
    required double valorBaseAluguel,
    required double? valorVenda,
    required double? valorMensalVenda,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuário não autenticado");

      await _supabase.from('imoveis').insert({
        'user_id': userId,
        'apelido': apelido,
        'endereco': endereco,
        'tipo': tipo.dbValue,
        'valor_base_aluguel': valorBaseAluguel,
        'valor_venda': valorVenda,
        'valor_mensal_venda': valorMensalVenda,
      });
    } catch (e) {
      throw Exception('Erro ao salvar imóvel: $e');
    }
  }
}
