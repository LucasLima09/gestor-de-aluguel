import 'package:flutter/material.dart';
import '../models/imovel_model.dart';

class TipoImovelPicker extends StatelessWidget {
  const TipoImovelPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ImovelTipo selected;
  final ValueChanged<ImovelTipo> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TipoCard(
            icon: Icons.vpn_key_outlined,
            title: 'Aluguel',
            subtitle: 'Cobrança mensal de aluguel',
            selected: selected == ImovelTipo.aluguel,
            onTap: () => onChanged(ImovelTipo.aluguel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TipoCard(
            icon: Icons.sell_outlined,
            title: 'Venda',
            subtitle: 'Parcelas até quitar o imóvel',
            selected: selected == ImovelTipo.venda,
            onTap: () => onChanged(ImovelTipo.venda),
          ),
        ),
      ],
    );
  }
}

class _TipoCard extends StatelessWidget {
  const _TipoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Material(
      color: selected ? color.withValues(alpha: 0.1) : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : const Color(0xFFDDE1E6),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? color : const Color(0xFF6B7280)),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? color : const Color(0xFF1A1D21),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
