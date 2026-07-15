import 'package:flutter/material.dart';
import '../models/mensalidade_model.dart';

class PendenciasBanner extends StatelessWidget {
  final List<MensalidadeModel> pendencias;
  final VoidCallback onTap;

  const PendenciasBanner({
    super.key,
    required this.pendencias,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final totalValor = pendencias.fold<double>(0, (soma, m) => soma + m.valor);
    final atrasadas = pendencias
        .where((m) => m.dataVencimento!.isBefore(DateTime.now()))
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color: Colors.orange.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade300),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
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
                    Icons.warning_amber_rounded,
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
                        '${pendencias.length} ${pendencias.length == 1 ? 'cobrança pendente' : 'cobranças pendentes'}',
                        style: tema.textTheme.titleMedium?.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'R\$ ${totalValor.toStringAsFixed(2)}',
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
                Icon(
                  Icons.chevron_right,
                  color: Colors.orange.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
