import 'package:flutter/material.dart';

Future<void> mostrarDialogNome(
  BuildContext context, {
  required String titulo,
  required String rotulo,
  String inicial = '',
  int minimo = 2,
  int maximo = 60,
  required Future<String?> Function(String nome) onSalvar,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DialogNome(
      titulo: titulo,
      rotulo: rotulo,
      inicial: inicial,
      minimo: minimo,
      maximo: maximo,
      onSalvar: onSalvar,
    ),
  );
}

class _DialogNome extends StatefulWidget {
  final String titulo;
  final String rotulo;
  final String inicial;
  final int minimo;
  final int maximo;
  final Future<String?> Function(String nome) onSalvar;

  const _DialogNome({
    required this.titulo,
    required this.rotulo,
    required this.inicial,
    required this.minimo,
    required this.maximo,
    required this.onSalvar,
  });

  @override
  State<_DialogNome> createState() => _DialogNomeState();
}

class _DialogNomeState extends State<_DialogNome> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.inicial,
  );
  String? _erro;
  bool _salvando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _controller.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (nome.length < widget.minimo) {
      setState(() => _erro = 'Digite pelo menos ${widget.minimo} caracteres');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    String? erro;
    try {
      erro = await widget.onSalvar(nome);
    } catch (e) {
      erro = 'Erro ao salvar: $e';
    }

    if (!mounted) return;
    if (erro == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _salvando = false;
        _erro = erro;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maximo,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: widget.rotulo, errorText: _erro),
        onSubmitted: (_) => _salvar(),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
          onPressed: _salvando ? null : _salvar,
          child: const Text('Salvar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
