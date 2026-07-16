import 'package:flutter/material.dart';
import '../models/mensalidade_model.dart';

class CobrancasPendentesScreen extends StatelessWidget {
  final List<MensalidadeModel> pendencias;

  const CobrancasPendentesScreen({super.key, required this.pendencias});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    final agrupadas = <String, List<MensalidadeModel>>{};
    for (final p in pendencias) {
      final chave = p.nomeImovel ?? 'Sem imóvel';
      agrupadas.putIfAbsent(chave, () => []).add(p);
    }

    final totalValor = pendencias.fold<double>(0, (soma, m) => soma + m.valor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobranças Pendentes'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Text(
                  '${pendencias.length} pendente(s) • R\$ ${totalValor.toStringAsFixed(2)}',
                  style: tema.textTheme.titleMedium?.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: agrupadas.keys.length,
              itemBuilder: (context, index) {
                final nomeImovel = agrupadas.keys.elementAt(index);
                final itens = agrupadas[nomeImovel]!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tema.colorScheme.primary.withValues(alpha: 0.05),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.home_outlined,
                                  color: tema.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                nomeImovel,
                                style: tema.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...itens.map((m) => _buildItem(context, m, tema)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
      BuildContext context, MensalidadeModel m, ThemeData tema) {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final vencimento = m.dataVencimento!;
    final vencimentoSemHora = DateTime(vencimento.year, vencimento.month, vencimento.day);
    final diasAtraso = vencimentoSemHora.isBefore(hojeSemHora)
        ? hojeSemHora.difference(vencimentoSemHora).inDays
        : 0;
    final diasParaVencer = vencimentoSemHora.isAfter(hojeSemHora)
        ? vencimentoSemHora.difference(hojeSemHora).inDays
        : 0;

    final String status;
    final Color cor;

    if (diasAtraso > 0) {
      status = 'Atrasado $diasAtraso ${diasAtraso == 1 ? 'dia' : 'dias'}';
      cor = Colors.red.shade700;
    } else if (diasParaVencer == 0) {
      status = 'Vence hoje';
      cor = Colors.orange.shade700;
    } else if (diasParaVencer == 1) {
      status = 'Vence amanhã';
      cor = Colors.orange.shade700;
    } else {
      status = 'Vence em $diasParaVencer dias';
      cor = Colors.orange.shade600;
    }

    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${m.mesReferencia.toString().padLeft(2, '0')}/${m.anoReferencia}',
                    style: tema.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.nomeInquilino ?? '',
                    style: tema.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${m.valor.toStringAsFixed(2)}',
                  style: tema.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: cor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
