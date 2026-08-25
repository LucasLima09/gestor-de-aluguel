import 'package:flutter/material.dart';
import '../models/parcela_venda_model.dart';
import '../util/moeda_br.dart';

class PendenciasVendaBanner extends StatelessWidget {
  const PendenciasVendaBanner({super.key, required this.parcelas});

  final List<ParcelaVendaModel> parcelas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final totalValor = parcelas.fold<double>(0, (soma, p) => soma + p.valor);
    final atrasadas = parcelas.where((p) => p.atrasada).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color: Colors.orange.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sell_outlined,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${parcelas.length} ${parcelas.length == 1 ? 'parcela de venda pendente' : 'parcelas de venda pendentes'}',
                      style: tema.textTheme.titleMedium?.copyWith(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MoedaBr.reais(totalValor),
                      style: tema.textTheme.bodyLarge?.copyWith(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (atrasadas > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$atrasadas ${atrasadas == 1 ? 'atrasada' : 'atrasadas'}',
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
