import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/drawernav.dart';

class FolhaRespostaScreen extends StatelessWidget {
  final String nomeAluno;
  final String matricula;
  final String turma;

  const FolhaRespostaScreen({
    super.key,
    required this.nomeAluno,
    required this.matricula,
    required this.turma,
  });

  @override
  Widget build(BuildContext context) {
    final String qrCodeData = '{"matricula":"$matricula","turma":"$turma","prova":"MAT_01"}';

    return Scaffold(
      drawer: const DrawerNav(), 
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Header(),
      ),
      bottomNavigationBar: Navegar(
        onVoltar: () => Navigator.pop(context),
        onAvancar: () {},
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Imprimir'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Simulando envio para impressora...')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 350,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AVALIAÇÃO OFICIAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 12),
                              Text('Nome: $nomeAluno', style: const TextStyle(fontSize: 14)),
                              Text('Turma: $turma', style: const TextStyle(fontSize: 14)),
                              Text('Matrícula: $matricula', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        QrImageView(
                          data: qrCodeData,
                          version: QrVersions.auto,
                          size: 90.0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(thickness: 2, color: Colors.black),
                    const SizedBox(height: 8),
                    const Text('FOLHA DE RESPOSTAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    ...List.generate(10, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            _buildBolinha('A'),
                            _buildBolinha('B'),
                            _buildBolinha('C'),
                            _buildBolinha('D'),
                            _buildBolinha('E'),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    const Text('Preencha a bolinha completamente.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBolinha(String letra) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Center(
        child: Text(letra, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}