import 'package:flutter/material.dart';
import '../models/imovel_model.dart';
import '../repositories/imovel_repository.dart';
import '../widgets/app_buttons.dart';
import '../widgets/tipo_imovel_picker.dart';
import '../util/moeda_br.dart';

class AddImovelScreen extends StatefulWidget {
  const AddImovelScreen({super.key, this.imovel});

  final ImovelModel? imovel;

  @override
  State<AddImovelScreen> createState() => _AddImovelScreenState();
}

class _AddImovelScreenState extends State<AddImovelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apelidoController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _valorAluguelController = TextEditingController();
  final _valorTotalController = TextEditingController();
  final _valorMensalController = TextEditingController();

  final _imovelRepository = ImovelRepository();
  bool _carregando = false;
  ImovelTipo _tipo = ImovelTipo.aluguel;

  bool get _isEditing => widget.imovel != null;
  bool get _isVenda => _tipo == ImovelTipo.venda;

  @override
  void initState() {
    super.initState();
    final imovel = widget.imovel;
    if (imovel != null) {
      _tipo = imovel.tipo;
      _apelidoController.text = imovel.apelido;
      _enderecoController.text = imovel.endereco ?? '';
      _valorAluguelController.text = MoedaBr.formatar(imovel.valorBaseAluguel);
      _valorTotalController.text = MoedaBr.formatar(imovel.valorVenda ?? 0);
      _valorMensalController.text =
          MoedaBr.formatar(imovel.valorMensalVenda ?? 0);
    }
  }

  double? _parseValor(String raw) => MoedaBr.parse(raw);

  String? _validarValor(String? value, String mensagemVazio) {
    if (value == null || value.trim().isEmpty) return mensagemVazio;
    final valor = _parseValor(value);
    if (valor == null || valor <= 0) {
      return 'Insira um valor numérico válido maior que zero.';
    }
    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final apelido = _apelidoController.text.trim();
      final endereco = _enderecoController.text.trim().isEmpty
          ? null
          : _enderecoController.text.trim();

      final valorBaseAluguel = _isVenda
          ? 0.0
          : _parseValor(_valorAluguelController.text)!;
      final valorVenda =
          _isVenda ? _parseValor(_valorTotalController.text) : null;
      final valorMensalVenda =
          _isVenda ? _parseValor(_valorMensalController.text) : null;

      if (_isEditing) {
        await _imovelRepository.atualizarImovel(
          imovelId: widget.imovel!.id,
          apelido: apelido,
          endereco: endereco,
          tipo: _tipo,
          valorBaseAluguel: valorBaseAluguel,
          valorVenda: valorVenda,
          valorMensalVenda: valorMensalVenda,
        );
      } else {
        await _imovelRepository.registerImovel(
          apelido: apelido,
          endereco: endereco,
          tipo: _tipo,
          valorBaseAluguel: valorBaseAluguel,
          valorVenda: valorVenda,
          valorMensalVenda: valorMensalVenda,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Imóvel atualizado com sucesso!'
                  : 'Imóvel cadastrado com sucesso!',
            ),
          ),
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
    _valorAluguelController.dispose();
    _valorTotalController.dispose();
    _valorMensalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Alterar Imóvel' : 'Novo Imóvel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Como você vai gerenciar este imóvel?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TipoImovelPicker(
                  selected: _tipo,
                  onChanged: (tipo) => setState(() => _tipo = tipo),
                ),
                const SizedBox(height: 24),
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
                if (_isVenda) ...[
                  TextFormField(
                    controller: _valorTotalController,
                    decoration: const InputDecoration(
                      labelText: 'Valor total do imóvel (R\$)',
                      prefixIcon: Icon(Icons.home_work_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => _validarValor(
                      value,
                      'Informe o valor total do imóvel.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _valorMensalController,
                    decoration: const InputDecoration(
                      labelText: 'Valor por mês (R\$)',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => _validarValor(
                      value,
                      'Informe o valor que será pago por mês.',
                    ),
                  ),
                ] else
                  TextFormField(
                    controller: _valorAluguelController,
                    decoration: const InputDecoration(
                      labelText: 'Valor Base do Aluguel (R\$)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => _validarValor(
                      value,
                      'Por favor, insira o valor do aluguel.',
                    ),
                  ),
                const SizedBox(height: 32),
                _carregando
                    ? const Center(child: CircularProgressIndicator())
                    : AppPrimaryButton(
                        label: _isEditing
                            ? 'Salvar Alterações'
                            : 'Salvar Imóvel',
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
