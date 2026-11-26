//Tela inicial das provas: criar nova e ver as já criadas
import 'package:flutter/material.dart';

import '../../models/provas.dart';
import '../../service/prova_service.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../BancoQuestoes/elem_comuns.dart';
import 'criar_prova.dart';
import 'detalhe_prova.dart';

class Prova extends StatefulWidget {
  const Prova({super.key});

  @override
  State<Prova> createState() => _ProvaState();
}

class _ProvaState extends State<Prova> {
  final _service = ProvaService();
  late final Stream<List<ProvaSalva>> _stream = _service.observarMinhas();

  void _nova() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CriarProvaPage()),
    );
  }

  void _abrir(ProvaSalva p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalheProvaPage(provaId: p.id)),
    );
  }

  String _data(DateTime? d) {
    if (d == null) return '';
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: StreamBuilder<List<ProvaSalva>>(
          stream: _stream,
          builder: (context, snap) {
            final provas = snap.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MenuTitle(title: 'Provas', fontSize: 28),
                  const SizedBox(height: 4),
                  Text(
                    'Monte uma prova com questões do banco e aplique à sua turma.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: kCard,
                    borderRadius: BorderRadius.circular(24),
                    elevation: 2,
                    shadowColor: Colors.black26,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _nova,
                      child: const SizedBox(
                        height: 110,
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 40,
                              color: kGreen,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Nova prova',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: kGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Text(
                        'Minhas provas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${provas.length}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (snap.hasError)
                    Text('Erro ao carregar: ${snap.error}')
                  else if (snap.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (provas.isEmpty)
                    Text(
                      'Você ainda não criou nenhuma prova.',
                      style: TextStyle(color: Colors.grey.shade700),
                    )
                  else
                    ...provas.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: kListCard,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _abrir(p),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.description_outlined,
                                    color: kGreen,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.titulo,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          [
                                            '${p.questoes.length} questões',
                                            '${p.versoes.length} versões',
                                            if (_data(p.criadoEm).isNotEmpty)
                                              _data(p.criadoEm),
                                          ].join(' · '),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
