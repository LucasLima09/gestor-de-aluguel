import 'package:flutter/material.dart';
import '../models/imovel_model.dart';
import '../models/locacao_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/locacao_repository.dart';
import '../widgets/app_buttons.dart';

class AddLocacaoScreen extends StatefulWidget {
  final ImovelModel imovel;

  const AddLocacaoScreen({super.key, required this.imovel});

  @override
  State<AddLocacaoScreen> createState() => _AddLocacaoScreenState();
}

class _AddLocacaoScreenState extends State<AddLocacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _vencimentoController = TextEditingController();

  final _locacaoRepository = LocacaoRepository();
  final _authRepository = AuthRepository();
  bool _carregando = false;
  DateTime _dataInicioSelected = DateTime.now();

  Future<void> _selecionarDataInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataInicioSelected,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dataInicioSelected) {
      setState(() {
        _dataInicioSelected = picked;
      });
    }
  }

  Future<void> _salvarContrato() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final userId = _authRepository.currentUser();
      if (userId == null) throw Exception('Usuário não autenticado');

      final novaLocacao = LocacaoModel(
        id: '',
        userId: userId,
        imovelId: widget.imovel.id,
        nomeInquilino: _nomeController.text.trim(),
        whatsappInquilino: _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        diaVencimento: int.parse(_vencimentoController.text.trim()),
        dataInicio: _dataInicioSelected,
        ativo: true,
        criadoEm: DateTime.now(),
      );

      await _locacaoRepository.cadastrarLocacao(novaLocacao);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrato de aluguel iniciado!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _whatsappController.dispose();
    _vencimentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Contrato'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Alugando: ${widget.imovel.apelido}',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Inquilino',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Insira o nome do inquilino.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _whatsappController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp do Inquilino (Opcional)',
                    prefixIcon: Icon(Icons.phone),
                    hintText: 'Ex: 54999999999',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vencimentoController,
                  decoration: const InputDecoration(
                    labelText: 'Dia do Vencimento (1 a 31)',
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Insira o dia do vencimento.';
                    }
                    final dia = int.tryParse(value);
                    if (dia == null || dia < 1 || dia > 31) {
                      return 'Insira um dia válido entre 1 e 31.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.date_range, color: theme.colorScheme.primary),
                    title: const Text('Data de Início do Contrato'),
                    subtitle: Text(
                      '${_dataInicioSelected.day}/${_dataInicioSelected.month}/${_dataInicioSelected.year}',
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _selecionarDataInicio(context),
                  ),
                ),
                const SizedBox(height: 32),
                _carregando
                    ? const Center(child: CircularProgressIndicator())
                    : AppPrimaryButton(
                        label: 'Confirmar Contrato',
                        onPressed: _salvarContrato,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
