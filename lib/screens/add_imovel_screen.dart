import 'package:flutter/material.dart';
import '../repositories/imovel_repository.dart';
import '../widgets/app_buttons.dart';

class AddImovelScreen extends StatefulWidget {
  const AddImovelScreen({super.key});

  @override
  State<AddImovelScreen> createState() => _AddImovelScreenState();
}

class _AddImovelScreenState extends State<AddImovelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apelidoController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _valorController = TextEditingController();

  final _imovelRepository = ImovelRepository();
  bool _carregando = false;

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final apelido = _apelidoController.text.trim();
      final endereco = _enderecoController.text.trim().isEmpty
          ? null
          : _enderecoController.text.trim();

      final valor = double.parse(_valorController.text.replaceAll(',', '.').trim());

      await _imovelRepository.registerImovel(apelido, endereco, valor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imóvel cadastrado com sucesso!')),
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
    _apelidoController.dispose();
    _enderecoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Imóvel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _apelidoController,
                  decoration: const InputDecoration(
                    labelText: 'Identificação / Apelido',
                    hintText: 'Ex: Casa da Esquina, Ap 202',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira uma identificação para o imóvel.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _enderecoController,
                  decoration: const InputDecoration(
                    labelText: 'Endereço (Opcional)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorController,
                  decoration: const InputDecoration(
                    labelText: 'Valor Base do Aluguel (R\$)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira o valor do aluguel.';
                    }
                    final valor = double.tryParse(value.replaceAll(',', '.'));
                    if (valor == null || valor <= 0) {
                      return 'Insira um valor numérico válido maior que zero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _carregando
                    ? const Center(child: CircularProgressIndicator())
                    : AppPrimaryButton(
                        label: 'Salvar Imóvel',
                        onPressed: _salvar,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
