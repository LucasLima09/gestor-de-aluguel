import 'package:flutter/material.dart';
import '../models/imovel_model.dart';
import '../models/locacao_model.dart';
import '../models/mensalidade_model.dart';
import '../repositories/imovel_repository.dart';
import '../repositories/locacao_repository.dart';
import '../repositories/mensalidade_repository.dart';
import '../services/cobranca_pdf_service.dart';
import '../util/app_button_styles.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_dialog.dart';
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
  final _cobrancaPdfService = CobrancaPdfService();

  bool _carregando = true;
  LocacaoModel? _locacaoAtiva;
  List<MensalidadeModel> _mensalidades = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final locacao = await _locacaoRepository.buscarLocacaoAtivaPorImovel(
        widget.imovel.id,
      );

      List<MensalidadeModel> mensalidadesTemp = [];
      if (locacao != null) {
        mensalidadesTemp = await _mensalidadeRepository
            .buscarMensalidadesPorLocacao(locacao.id);
      }

      setState(() {
        _locacaoAtiva = locacao;
        _mensalidades = mensalidadesTemp;
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
    final valorController = TextEditingController(
      text: widget.imovel.valorBaseAluguel.toStringAsFixed(2),
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
                  final novaMensalidade = MensalidadeModel(
                    id: '',
                    userId: _locacaoAtiva!.userId,
                    locacaoId: _locacaoAtiva!.id,
                    mesReferencia: int.parse(mesController.text),
                    anoReferencia: int.parse(anoController.text),
                    valor: double.parse(
                      valorController.text.replaceAll(',', '.'),
                    ),
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

                  if (!mounted) return;
                  try {
                    await _compartilharPdfCobranca(novaMensalidade);
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Não foi possível abrir o compartilhamento: $e',
                          ),
                        ),
                      );
                    }
                  }
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
      imovel: widget.imovel.apelido,
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
          'R\$ ${mensalidade.valor.toStringAsFixed(2)}? '
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
        title: Text(widget.imovel.apelido),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmarExcluirImovel,
            tooltip: 'Excluir imóvel',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                  if (_locacaoAtiva != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mensalidades',
                          style: theme.textTheme.titleMedium,
                        ),
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
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          (pago ? Colors.green : Colors.orange)
                                              .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      pago ? Icons.check_circle : Icons.pending,
                                      color: pago
                                          ? Colors.green
                                          : Colors.orange,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${m.mesReferencia.toString().padLeft(2, '0')}/${m.anoReferencia}',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'R\$ ${m.valor.toStringAsFixed(2)}',
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
                                          final messenger =
                                              ScaffoldMessenger.of(context);

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
                                        icon: const Icon(
                                          Icons.picture_as_pdf_outlined,
                                        ),
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
                                        Text(
                                          'PAGO',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      else
                                        AppCompactButton(
                                          label: 'Receber',
                                          onPressed: () =>
                                              _quitarMensalidade(m.id),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
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
            _infoRow('Endereço', widget.imovel.endereco ?? 'Não informado'),
            const SizedBox(height: 8),
            _infoRow(
              'Aluguel Sugerido',
              'R\$ ${widget.imovel.valorBaseAluguel.toStringAsFixed(2)}',
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
      await _imovelRepository.deletarImovel(widget.imovel.id);
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
              'Registre um contrato para começar a gerenciar as cobranças.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Alugar Imóvel',
              icon: Icons.vpn_key,
              onPressed: () async {
                final contratoIniciado = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AddLocacaoScreen(imovel: widget.imovel),
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
                Text(
                  'Inquilino Ativo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade300,
                  ),
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
}
