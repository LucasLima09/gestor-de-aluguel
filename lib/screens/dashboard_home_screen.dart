import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/imovel_model.dart';
import '../models/locacao_model.dart';
import '../models/mensalidade_model.dart';
import '../models/parcela_venda_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/imovel_repository.dart';
import '../repositories/locacao_repository.dart';
import '../repositories/mensalidade_repository.dart';
import '../repositories/parcela_venda_repository.dart';
import '../widgets/dashboard_metric_card.dart';
import '../widgets/pendencias_banner.dart';
import '../widgets/pendencias_venda_banner.dart';
import '../util/moeda_br.dart';
import 'cobrancas_pendentes_screen.dart';
import 'login_screen.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => DashboardHomeScreenState();
}

class DashboardHomeScreenState extends State<DashboardHomeScreen> {
  final _imovelRepository = ImovelRepository();
  final _locacaoRepository = LocacaoRepository();
  final _mensalidadeRepository = MensalidadeRepository();
  final _parcelaVendaRepository = ParcelaVendaRepository();
  final _authRepository = AuthRepository();
  late Future<_DashboardData> _futureDados;

  @override
  void initState() {
    super.initState();
    _futureDados = _carregarDados();
  }

  Future<_DashboardData> _carregarDados() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    final results = await Future.wait([
      _imovelRepository.getImoveis(),
      _locacaoRepository.buscarLocacoesAtivas(),
      _mensalidadeRepository.buscarMensalidadesPendentes(userId),
      _parcelaVendaRepository.buscarTodasDoUsuario(),
    ]);

    return _DashboardData(
      imoveis: results[0] as List<ImovelModel>,
      locacoesAtivas: results[1] as List<LocacaoModel>,
      pendencias: results[2] as List<MensalidadeModel>,
      parcelasVenda: results[3] as List<ParcelaVendaModel>,
    );
  }

  void recarregar() {
    setState(() {
      _futureDados = _carregarDados();
    });
  }

  Future<void> _logout() async {
    await _authRepository.logout();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair do App',
          ),
        ],
      ),
      body: FutureBuilder<_DashboardData>(
        future: _futureDados,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar dados',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final dados = snapshot.data!;
          final alugadosIds = dados.locacoesAtivas
              .map((locacao) => locacao.imovelId)
              .toSet();
          final imoveisAluguel = dados.imoveis
              .where((imovel) => imovel.isAluguel)
              .toList();
          final imoveisVenda = dados.imoveis
              .where((imovel) => imovel.isVenda)
              .toList();
          final rendimentoAluguel = imoveisAluguel
              .where((imovel) => alugadosIds.contains(imovel.id))
              .fold<double>(
                0,
                (soma, imovel) => soma + imovel.valorBaseAluguel,
              );
          final vendasMes = imoveisVenda
              .where((imovel) => alugadosIds.contains(imovel.id))
              .fold<double>(
                0,
                (soma, imovel) => soma + (imovel.valorMensalVenda ?? 0),
              );
          final bruto = rendimentoAluguel + vendasMes;
          final alugados = imoveisAluguel
              .where((imovel) => alugadosIds.contains(imovel.id))
              .length;
          final vagos = imoveisAluguel.length - alugados;
          final pendenciasVenda = dados.parcelasVenda
              .where((parcela) => parcela.pendenteNoMesOuAtrasada)
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              recarregar();
              await _futureDados;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: DashboardMetricCard(
                    icon: Icons.payments_outlined,
                    label: 'Entrada bruta / mês',
                    value: MoedaBr.reais(bruto),
                    color: theme.colorScheme.secondary,
                    subtitle: 'Aluguel previsto + mensal de vendas ativas',
                    large: true,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DashboardMetricCard(
                          icon: Icons.vpn_key_outlined,
                          label: 'Aluguel / mês',
                          value: MoedaBr.reais(rendimentoAluguel),
                          color: theme.colorScheme.primary,
                          subtitle: 'Imóveis com inquilino ativo',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DashboardMetricCard(
                          icon: Icons.sell_outlined,
                          label: 'Vendas / mês',
                          value: MoedaBr.reais(vendasMes),
                          color: Colors.teal.shade700,
                          subtitle: 'Com inquilino ativo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DashboardMetricCard(
                          icon: Icons.home_work_outlined,
                          label: 'Imóveis',
                          value: '${dados.imoveis.length}',
                          color: theme.colorScheme.primary,
                          subtitle: dados.imoveis.length == 1
                              ? 'cadastrado'
                              : 'cadastrados',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DashboardMetricCard(
                          icon: Icons.vpn_key_outlined,
                          label: 'Ocupação',
                          value: '$alugados / $vagos',
                          color: Colors.green.shade600,
                          subtitle: 'só imóveis de aluguel',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (dados.pendencias.isNotEmpty)
                  PendenciasBanner(
                    pendencias: dados.pendencias,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CobrancasPendentesScreen(
                            pendencias: dados.pendencias,
                          ),
                        ),
                      );
                      recarregar();
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_circle_outline,
                                color: Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Nenhuma cobrança de aluguel pendente',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (pendenciasVenda.isNotEmpty)
                  PendenciasVendaBanner(parcelas: pendenciasVenda),
                if (dados.imoveis.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 56,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum imóvel cadastrado',
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vá até a aba Imóveis e toque em + para começar.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.imoveis,
    required this.locacoesAtivas,
    required this.pendencias,
    required this.parcelasVenda,
  });

  final List<ImovelModel> imoveis;
  final List<LocacaoModel> locacoesAtivas;
  final List<MensalidadeModel> pendencias;
  final List<ParcelaVendaModel> parcelasVenda;
}
