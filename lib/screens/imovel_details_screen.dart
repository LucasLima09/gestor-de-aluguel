import 'package:flutter/material.dart';
import '../models/imovel_model.dart';
import '../models/locacao_model.dart';
import '../models/mensalidade_model.dart';
import '../models/parcela_venda_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/imovel_repository.dart';
import '../repositories/locacao_repository.dart';
import '../repositories/mensalidade_repository.dart';
import '../repositories/parcela_venda_repository.dart';
import '../services/cobranca_pdf_service.dart';
import '../services/parcela_venda_pdf_service.dart';
import '../util/app_button_styles.dart';
import '../util/moeda_br.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_dialog.dart';
import 'add_imovel_screen.dart';
import 'add_locacao_screen.dart';

class DetalhesImovelScreen extends StatefulWidget {
  final ImovelModel imovel;

  const DetalhesImovelScreen({super.key, required this.imovel});

  @override
  State<DetalhesImovelScreen> createState() => _DetalhesImovelScreenState();
}

class _DetalhesImovelScreenState extends State<DetalhesImovelScreen> {
  final _imovelRepository = ImovelRepository();
  final _locacaoRepository = LocacaoRepository();
  final _mensalidadeRepository = MensalidadeRepository();
  final _parcelaVendaRepository = ParcelaVendaRepository();
  final _authRepository = AuthRepository();
  final _cobrancaPdfService = CobrancaPdfService();
  final _parcelaVendaPdfService = ParcelaVendaPdfService();

  late ImovelModel _imovel;
  bool _carregando = true;
  LocacaoModel? _locacaoAtiva;
  List<MensalidadeModel> _mensalidades = [];
  List<ParcelaVendaModel> _parcelasVenda = [];

  @override
  void initState() {
    super.initState();
    _imovel = widget.imovel;
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final results = await Future.wait([
        _locacaoRepository.buscarLocacaoAtivaPorImovel(_imovel.id),
        _mensalidadeRepository.buscarMensalidadesPorImovel(_imovel.id),
        if (_imovel.isVenda)
          _parcelaVendaRepository.buscarPorImovel(_imovel.id)
        else
          Future.value(<ParcelaVendaModel>[]),
      ]);

      setState(() {
        _locacaoAtiva = results[0] as LocacaoModel?;
        _mensalidades = results[1] as List<MensalidadeModel>;
        _parcelasVenda = results[2] as List<ParcelaVendaModel>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _dialogGerarMensalidade() async {
    if (_locacaoAtiva == null) return;

    final mesController = TextEditingController(
      text: DateTime.now().month.toString(),
    );
    final anoController = TextEditingController(
      text: DateTime.now().year.toString(),
    );
    final valorPadrao = _imovel.isVenda
        ? (_imovel.valorMensalVenda ?? 0)
        : _imovel.valorBaseAluguel;
    final valorController = TextEditingController(
      text: MoedaBr.formatar(valorPadrao),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cobrar Mensalidade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: mesController,
                    decoration: const InputDecoration(labelText: 'Mês (1-12)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: anoController,
                    decoration: const InputDecoration(labelText: 'Ano'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valorController,
              decoration: const InputDecoration(
                labelText: 'Valor da Cobrança (R\$)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 24),
            AppDialogActions(
              cancelLabel: 'Cancelar',
              confirmLabel: 'Gerar',
              onCancel: () => Navigator.pop(context),
              onConfirm: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                try {
                  final valor = MoedaBr.parse(valorController.text);
                  if (valor == null || valor <= 0) {
                    throw Exception('Informe um valor válido');
                  }

                  final novaMensalidade = MensalidadeModel(
                    id: '',
                    userId: _locacaoAtiva!.userId,
                    locacaoId: _locacaoAtiva!.id,
                    mesReferencia: int.parse(mesController.text),
                    anoReferencia: int.parse(anoController.text),
                    valor: valor,
                    pago: false,
                    nomeInquilino: _locacaoAtiva!.nomeInquilino,
                    criadoEm: DateTime.now(),
                  );

                  await _mensalidadeRepository.gerarMensalidade(
                    novaMensalidade,
                  );

                  if (!context.mounted) return;
                  navigator.pop();
                  await _carregarDados();
                } catch (e) {
                  if (context.mounted) {
                    messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _compartilharPdfCobranca(MensalidadeModel mensalidade) async {
    if (_locacaoAtiva == null) return;

    await _cobrancaPdfService.compartilhar(
      nomeInquilino: mensalidade.nomeInquilino ?? _locacaoAtiva!.nomeInquilino,
      valor: mensalidade.valor,
      mesReferencia: mensalidade.mesReferencia,
      anoReferencia: mensalidade.anoReferencia,
      diaVencimento: _locacaoAtiva!.diaVencimento,
      imovel: _imovel.apelido,
    );
  }

  Future<void> _compartilharPdfParcela(ParcelaVendaModel parcela) async {
    final parcelasPagas = _parcelasVenda.where((p) => p.pago).toList();
    await _parcelaVendaPdfService.compartilhar(
      nomeInquilino: _locacaoAtiva?.nomeInquilino ?? 'Não informado',
      imovel: _imovel.apelido,
      valorParcela: parcela.valor,
      valorTotal: _imovel.valorVenda ?? 0,
      mesReferencia: parcela.mesReferencia,
      anoReferencia: parcela.anoReferencia,
      parcelasPagas: parcelasPagas,
    );
  }

  Future<void> _confirmarExcluirMensalidade(
    MensalidadeModel mensalidade,
  ) async {
    if (mensalidade.pago) return;

    final referencia =
        '${mensalidade.mesReferencia.toString().padLeft(2, '0')}/${mensalidade.anoReferencia}';
    final confirmou = await showAppConfirmDialog(
      context: context,
      title: 'Excluir Cobrança',
      message:
          'Excluir a cobrança de $referencia no valor de '
          '${MoedaBr.reais(mensalidade.valor)}? '
          'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );

    if (confirmou != true) return;

    try {
      await _mensalidadeRepository.excluirMensalidade(mensalidade.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cobrança excluída com sucesso!')),
      );
      _carregarDados();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _quitarMensalidade(String id) async {
    final confirmou = await showAppConfirmDialog(
      context: context,
      title: 'Confirmar Pagamento',
      message: 'Confirmar que esta mensalidade foi paga?',
      confirmLabel: 'Confirmar',
    );

    if (confirmou != true) return;

    try {
      await _mensalidadeRepository.marcarComoPaga(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento confirmado com sucesso!')),
      );
      _carregarDados();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_imovel.apelido),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _alterarImovel,
            tooltip: 'Alterar imóvel',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmarExcluirImovel,
            tooltip: 'Excluir imóvel',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(theme),
                    const SizedBox(height: 16),
                    _locacaoAtiva == null
                        ? _buildCardImovelVago(theme)
                        : _buildCardInquilinoAtivo(theme, _locacaoAtiva!),
                    const SizedBox(height: 16),
                    if (_imovel.isVenda) ...[
                      ..._buildVendaContent(theme),
                      const SizedBox(height: 16),
                    ],
                    if (_locacaoAtiva != null || _mensalidades.isNotEmpty)
                      _buildMensalidadesSection(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMensalidadesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mensalidades', style: theme.textTheme.titleMedium),
            if (_locacaoAtiva != null)
              OutlinedButton.icon(
                onPressed: _dialogGerarMensalidade,
                style: AppButtonStyles.outlinedCompact(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Gerar Cobrança'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_mensalidades.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Nenhuma cobrança gerada para este contrato.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mensalidades.length,
            itemBuilder: (context, index) {
              final m = _mensalidades[index];
              final pago = m.pago;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: pago ? Colors.green : Colors.orange,
                        width: 4,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (pago ? Colors.green : Colors.orange)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            pago ? Icons.check_circle : Icons.pending,
                            color: pago ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${m.mesReferencia.toString().padLeft(2, '0')}/${m.anoReferencia}',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                MoedaBr.reais(m.valor),
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (m.nomeInquilino != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  m.nomeInquilino!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);

                                try {
                                  await _compartilharPdfCobranca(m);
                                } catch (e) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Não foi possível abrir o compartilhamento: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              tooltip: 'Compartilhar PDF',
                            ),
                            if (!pago)
                              IconButton(
                                onPressed: () =>
                                    _confirmarExcluirMensalidade(m),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade400,
                                ),
                                tooltip: 'Excluir cobrança',
                              ),
                            if (pago)
                              const Text(
                                'PAGO',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              AppCompactButton(
                                label: 'Receber',
                                onPressed: () => _quitarMensalidade(m.id),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.home_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Dados do Imóvel', style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(height: 28),
            _infoRow('Tipo', _imovel.tipo.label),
            const SizedBox(height: 8),
            _infoRow('Endereço', _imovel.endereco ?? 'Não informado'),
            const SizedBox(height: 8),
            if (_imovel.isVenda) ...[
              _infoRow(
                'Valor total',
                MoedaBr.reais(_imovel.valorVenda ?? 0),
                valueColor: theme.colorScheme.secondary,
              ),
              const SizedBox(height: 8),
              _infoRow(
                'Valor por mês',
                MoedaBr.reais(_imovel.valorMensalVenda ?? 0),
                valueColor: theme.colorScheme.primary,
              ),
            ] else
              _infoRow(
                'Aluguel Sugerido',
                MoedaBr.reais(_imovel.valorBaseAluguel),
                valueColor: theme.colorScheme.secondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: valueColor ?? const Color(0xFF1A1D21),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _alterarImovel() async {
    final atualizou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddImovelScreen(imovel: _imovel)),
    );

    if (atualizou != true || !mounted) return;

    try {
      final atualizado = await _imovelRepository.buscarImovelPorId(_imovel.id);
      if (mounted) {
        setState(() => _imovel = atualizado);
        await _carregarDados();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao atualizar dados: $e')));
    }
  }

  Future<void> _confirmarExcluirImovel() async {
    final confirmou = await showAppConfirmDialog(
      context: context,
      title: 'Excluir Imóvel',
      message:
          'Tem certeza? Esta ação irá excluir o imóvel e todos os '
          'dados relacionados (contratos e mensalidades).',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );

    if (confirmou != true) return;

    try {
      await _imovelRepository.deletarImovel(_imovel.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imóvel excluído com sucesso!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
  }

  Widget _buildCardImovelVago(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline,
                size: 40,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Imóvel Vago',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _imovel.isVenda
                  ? 'Cadastre o inquilino para acompanhar as parcelas da venda.'
                  : 'Registre um contrato para começar a gerenciar as cobranças.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: _imovel.isVenda ? 'Cadastrar inquilino' : 'Alugar Imóvel',
              icon: Icons.vpn_key,
              onPressed: () async {
                final contratoIniciado = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AddLocacaoScreen(imovel: _imovel),
                  ),
                );
                if (contratoIniciado == true) {
                  _carregarDados();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInquilinoAtivo(ThemeData theme, LocacaoModel locacao) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Inquilino Ativo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade300,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _alterarInquilino(locacao),
                  icon: Icon(
                    Icons.edit_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Alterar inquilino',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 28),
            _infoRow('Nome', locacao.nomeInquilino),
            const SizedBox(height: 8),
            _infoRow('WhatsApp', locacao.whatsappInquilino ?? 'Não cadastrado'),
            const SizedBox(height: 8),
            _infoRow('Vencimento', 'Dia ${locacao.diaVencimento}'),
            const SizedBox(height: 8),
            _infoRow(
              'Alugado em',
              '${locacao.dataInicio.day}/${locacao.dataInicio.month}/${locacao.dataInicio.year}',
            ),
            const SizedBox(height: 20),
            AppOutlinedDangerButton(
              label: 'Encerrar Contrato',
              onPressed: () => _confirmarEncerrarContrato(locacao.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _alterarInquilino(LocacaoModel locacao) async {
    final atualizou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddLocacaoScreen(imovel: _imovel, locacao: locacao),
      ),
    );

    if (atualizou == true) {
      _carregarDados();
    }
  }

  Future<void> _confirmarEncerrarContrato(String locacaoId) async {
    final confirmou = await showAppConfirmDialog(
      context: context,
      title: 'Encerrar Contrato',
      message:
          'Tem certeza? O contrato será encerrado e o imóvel ficará vago. '
          'As mensalidades serão mantidas no histórico.',
      confirmLabel: 'Encerrar',
      isDestructive: true,
    );

    if (confirmou != true) return;

    try {
      await _locacaoRepository.encerrarLocacao(locacaoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrato encerrado com sucesso!')),
        );
        _carregarDados();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao encerrar: $e')));
      }
    }
  }

  List<Widget> _buildVendaContent(ThemeData theme) {
    final valorVenda = _imovel.valorVenda ?? 0;
    final totalParcelasPagas = _parcelasVenda
        .where((parcela) => parcela.pago)
        .fold<double>(0, (soma, parcela) => soma + parcela.valor);
    final totalMensalidadesPagas = _mensalidades
        .where((mensalidade) => mensalidade.pago)
        .fold<double>(0, (soma, mensalidade) => soma + mensalidade.valor);
    final totalPago = totalParcelasPagas + totalMensalidadesPagas;
    final restante = valorVenda - totalPago;

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acompanhamento da venda',
                style: theme.textTheme.titleMedium,
              ),
              const Divider(height: 28),
              _infoRow(
                'Total pago',
                MoedaBr.reais(totalPago),
                valueColor: Colors.green.shade700,
              ),
              if (totalMensalidadesPagas > 0) ...[
                const SizedBox(height: 8),
                _infoRow(
                  'Parcelas da venda',
                  MoedaBr.reais(totalParcelasPagas),
                ),
                const SizedBox(height: 8),
                _infoRow(
                  'Mensalidades pagas',
                  MoedaBr.reais(totalMensalidadesPagas),
                ),
              ],
              const SizedBox(height: 8),
              _infoRow(
                'Restante',
                MoedaBr.reais(restante),
                valueColor: restante > 0
                    ? Colors.orange.shade800
                    : Colors.green.shade700,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Parcelas', style: theme.textTheme.titleMedium),
          OutlinedButton.icon(
            onPressed: _dialogGerarParcelaVenda,
            style: AppButtonStyles.outlinedCompact(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Gerar Parcela'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (_parcelasVenda.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Nenhuma parcela gerada para esta venda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        )
      else
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _parcelasVenda.length,
          itemBuilder: (context, index) {
            final parcela = _parcelasVenda[index];
            final pago = parcela.pago;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide.none,
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: pago ? Colors.green : Colors.orange,
                      width: 4,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (pago ? Colors.green : Colors.orange)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          pago ? Icons.check_circle : Icons.pending,
                          color: pago ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${parcela.mesReferencia.toString().padLeft(2, '0')}/${parcela.anoReferencia}',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              MoedaBr.reais(parcela.valor),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _compartilharPdfParcela(parcela);
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Não foi possível abrir o compartilhamento: $e',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        tooltip: 'Compartilhar PDF',
                      ),
                      if (!pago)
                        IconButton(
                          onPressed: () => _confirmarExcluirParcela(parcela),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade400,
                          ),
                          tooltip: 'Excluir parcela',
                        ),
                      if (pago)
                        const Text(
                          'PAGO',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        AppCompactButton(
                          label: 'Receber',
                          onPressed: () => _quitarParcela(parcela.id),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
    ];
  }

  Future<void> _dialogGerarParcelaVenda() async {
    final valorMensal = _imovel.valorMensalVenda ?? 0.0;
    final valorTotal = _imovel.valorVenda ?? 0.0;
    final valorPadrao = valorMensal > 0
        ? valorMensal
        : (valorTotal > 0 ? valorTotal : 0.0);

    final mesController = TextEditingController(
      text: DateTime.now().month.toString(),
    );
    final anoController = TextEditingController(
      text: DateTime.now().year.toString(),
    );
    final valorController = TextEditingController(
      text: MoedaBr.formatar(valorPadrao),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gerar Parcela'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: mesController,
                    decoration: const InputDecoration(labelText: 'Mês (1-12)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: anoController,
                    decoration: const InputDecoration(labelText: 'Ano'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valorController,
              decoration: const InputDecoration(
                labelText: 'Valor da parcela (R\$)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 24),
            AppDialogActions(
              cancelLabel: 'Cancelar',
              confirmLabel: 'Gerar',
              onCancel: () => Navigator.pop(context),
              onConfirm: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                try {
                  final userId = _authRepository.currentUser();
                  if (userId == null) {
                    throw Exception('Usuário não autenticado');
                  }

                  final valor = MoedaBr.parse(valorController.text);
                  if (valor == null || valor <= 0) {
                    throw Exception('Informe um valor válido');
                  }

                  final novaParcela = ParcelaVendaModel(
                    id: '',
                    userId: userId,
                    imovelId: _imovel.id,
                    mesReferencia: int.parse(mesController.text),
                    anoReferencia: int.parse(anoController.text),
                    valor: valor,
                    pago: false,
                    criadoEm: DateTime.now(),
                  );

                  await _parcelaVendaRepository.gerarParcela(novaParcela);

                  if (!context.mounted) return;
                  navigator.pop();
                  await _carregarDados();
                } catch (e) {
                  if (context.mounted) {
                    messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExcluirParcela(ParcelaVendaModel parcela) async {
    if (parcela.pago) return;

    final referencia =
        '${parcela.mesReferencia.toString().padLeft(2, '0')}/${parcela.anoReferencia}';
    final confirmou = await showAppConfirmDialog(
      context: context,
      title: 'Excluir Parcela',
      message:
          'Excluir a parcela de $referencia no valor de '
          '${MoedaBr.reais(parcela.valor)}? '
          'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );

    if (confirmou != true) return;

    try {
      await _parcelaVendaRepository.excluirParcela(parcela.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parcela excluída com sucesso!')),
      );
      _carregarDados();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _quitarParcela(String id) async {
    final confirmou = await showAppConfirmDialog(
      context: context,
      title: 'Confirmar Pagamento',
      message: 'Confirmar que esta parcela foi paga?',
      confirmLabel: 'Confirmar',
    );

    if (confirmou != true) return;

    try {
      await _parcelaVendaRepository.marcarComoPaga(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento confirmado com sucesso!')),
      );
      _carregarDados();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
