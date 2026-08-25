import 'package:alugala/screens/add_imovel_screen.dart';
import 'package:alugala/screens/imovel_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/imovel_model.dart';
import '../models/parcela_venda_model.dart';
import '../repositories/imovel_repository.dart';
import '../repositories/parcela_venda_repository.dart';
import '../widgets/app_dialog.dart';
import '../widgets/filter_pills.dart';
import '../util/moeda_br.dart';

enum _FiltroImovel { todos, alugados, vendidos }

class ImoveisScreen extends StatefulWidget {
  const ImoveisScreen({super.key});

  @override
  State<ImoveisScreen> createState() => _ImoveisScreenState();
}

class _ImoveisScreenState extends State<ImoveisScreen> {
  final _imovelRepository = ImovelRepository();
  final _parcelaVendaRepository = ParcelaVendaRepository();
  late Future<_ImoveisListaData> _futureDados;
  _FiltroImovel _filtro = _FiltroImovel.todos;

  @override
  void initState() {
    super.initState();
    _futureDados = _carregarDados();
  }

  Future<_ImoveisListaData> _carregarDados() async {
    final results = await Future.wait([
      _imovelRepository.getImoveis(),
      _parcelaVendaRepository.buscarTodasDoUsuario(),
    ]);

    final imoveis = results[0] as List<ImovelModel>;
    final parcelas = results[1] as List<ParcelaVendaModel>;
    final parcelasPorImovel = <String, List<ParcelaVendaModel>>{};
    for (final parcela in parcelas) {
      parcelasPorImovel.putIfAbsent(parcela.imovelId, () => []).add(parcela);
    }

    return _ImoveisListaData(
      imoveis: imoveis,
      parcelasPorImovel: parcelasPorImovel,
    );
  }

  void _recarregar() {
    setState(() {
      _futureDados = _carregarDados();
    });
  }

  Future<void> _alterarImovel(ImovelModel imovel) async {
    final atualizou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddImovelScreen(imovel: imovel)),
    );

    if (atualizou == true) {
      _recarregar();
    }
  }

  Future<void> _excluirImovel(ImovelModel imovel) async {
    final confirmou = await showAppConfirmDialog(
      context: context,
      title: 'Excluir Imóvel',
      message:
          'Excluir "${imovel.apelido}"? Esta ação irá excluir o imóvel e todos os '
          'dados relacionados (contratos, mensalidades e parcelas).',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );

    if (confirmou != true) return;

    try {
      await _imovelRepository.deletarImovel(imovel.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imóvel excluído com sucesso!')),
      );
      _recarregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    }
  }

  List<ImovelModel> _filtrar(List<ImovelModel> imoveis) {
    switch (_filtro) {
      case _FiltroImovel.alugados:
        return imoveis.where((imovel) => imovel.isAluguel).toList();
      case _FiltroImovel.vendidos:
        return imoveis.where((imovel) => imovel.isVenda).toList();
      case _FiltroImovel.todos:
        return imoveis;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Imóveis')),
      body: FutureBuilder<_ImoveisListaData>(
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
          final imoveis = dados.imoveis;

          if (imoveis.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_outlined,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum imóvel cadastrado',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toque no botão + para adicionar seu primeiro imóvel',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final filtrados = _filtrar(imoveis);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilterPills<_FiltroImovel>(
                  selected: _filtro,
                  onSelected: (filtro) => setState(() => _filtro = filtro),
                  options: const [
                    FilterPillOption(
                      value: _FiltroImovel.todos,
                      label: 'Todos',
                    ),
                    FilterPillOption(
                      value: _FiltroImovel.alugados,
                      label: 'Alugados',
                    ),
                    FilterPillOption(
                      value: _FiltroImovel.vendidos,
                      label: 'Vendidos',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtrados.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum imóvel neste filtro',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          _recarregar();
                          await _futureDados;
                        },
                        child: SlidableAutoCloseBehavior(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final imovel = filtrados[index];
                              return _buildImovelCard(
                                theme,
                                imovel,
                                dados.parcelasPorImovel[imovel.id] ?? const [],
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final cadastrou = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddImovelScreen()),
          );

          if (cadastrou == true) {
            _recarregar();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildImovelCard(
    ThemeData theme,
    ImovelModel imovel,
    List<ParcelaVendaModel> parcelas,
  ) {
    final pago = parcelas
        .where((parcela) => parcela.pago)
        .fold<double>(0, (soma, parcela) => soma + parcela.valor);
    final valorVenda = imovel.valorVenda ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Slidable(
        key: ValueKey(imovel.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.52,
          children: [
            SlidableAction(
              onPressed: (_) => _alterarImovel(imovel),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.edit_outlined,
              label: 'Alterar',
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
            SlidableAction(
              onPressed: (_) => _excluirImovel(imovel),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Excluir',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetalhesImovelScreen(imovel: imovel),
                ),
              );
              _recarregar();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      imovel.isVenda
                          ? Icons.sell_outlined
                          : Icons.home_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          imovel.apelido,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          imovel.endereco ?? 'Sem endereço cadastrado',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (imovel.isVenda
                                        ? theme.colorScheme.secondary
                                        : theme.colorScheme.primary)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            imovel.tipo.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: imovel.isVenda
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (imovel.isVenda) ...[
                        Text(
                          '${MoedaBr.reais(imovel.valorMensalVenda ?? 0)}/mês',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          MoedaBr.reais(valorVenda),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ] else
                        Text(
                          MoedaBr.reais(imovel.valorBaseAluguel),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImoveisListaData {
  const _ImoveisListaData({
    required this.imoveis,
    required this.parcelasPorImovel,
  });

  final List<ImovelModel> imoveis;
  final Map<String, List<ParcelaVendaModel>> parcelasPorImovel;
}
