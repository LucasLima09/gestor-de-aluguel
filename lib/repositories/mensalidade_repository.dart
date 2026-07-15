import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mensalidade_model.dart';
import '../services/cobranca_pdf_service.dart';

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

  Future<void> excluirMensalidade(String mensalidadeId) async {
    try {
      await _supabase.from('mensalidades').delete().eq('id', mensalidadeId);
    } catch (e) {
      throw Exception('Erro ao excluir mensalidade: $e');
    }
  }

  Future<List<MensalidadeModel>> buscarMensalidadesPendentes(String userId) async {
    try {
      final response = await _supabase
          .from('mensalidades')
          .select('''
            *,
            locacoes!inner(
              dia_vencimento,
              nome_inquilino,
              imoveis!inner(
                apelido
              )
            )
          ''')
          .eq('user_id', userId)
          .eq('pago', false);

      final mensalidades = (response as List).map((json) {
        final data = json as Map<String, dynamic>;
        final m = MensalidadeModel.fromJson(data);

        final locacao = data['locacoes'] as Map<String, dynamic>;
        final imovel = locacao['imoveis'] as Map<String, dynamic>;
        final diaVencimento = locacao['dia_vencimento'] as int;

        m.nomeInquilino = locacao['nome_inquilino'] as String;
        m.nomeImovel = imovel['apelido'] as String;
        m.dataVencimento = CobrancaPdfService.calcularVencimento(
          m.mesReferencia,
          m.anoReferencia,
          diaVencimento,
        );

        return m;
      }).toList();

      final limite = DateTime.now().add(const Duration(days: 7));
      return mensalidades
          .where((m) => m.dataVencimento!.isBefore(limite))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar pendências: $e');
    }
  }
}