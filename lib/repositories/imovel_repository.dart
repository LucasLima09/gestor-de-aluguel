import 'package:alugaai/models/imovel_model.dart';
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

  Future<void> registerImovel(
    String apelido,
    String? endereco,
    double valorBase,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuário não autenticado");

      await _supabase.from('imoveis').insert({
        'user_id': userId,
        'apelido': apelido,
        'endereco': endereco,
        'valor_base_aluguel': valorBase,
      });
    } catch (e) {
      throw Exception('Erro ao salvar imóvel: $e');
    }
  }
}
