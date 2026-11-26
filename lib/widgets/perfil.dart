//Tela de perfil: dados do usuário logado, turmas e provas cadastradas
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/provas.dart';
import '../../models/turma.dart';
import '../../models/usuario.dart';
import '../../service/prova_service.dart';
import '../../service/turma_service.dart';
import '../../service/usuario_service.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../screens/BancoQuestoes/elem_comuns.dart';
import '../screens/CriarProva/detalhe_prova.dart';
import '../screens/Turmas/lista_alunos.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;

  // Os streams são criados uma vez só, para não recarregar a cada rebuild
  late final Stream<Usuario?> _usuario = _user == null
      ? Stream.value(null)
      : UsuarioService().observar(_user.uid);
  late final Stream<List<Turma>> _turmas = TurmaService().getTurmas();
  late final Stream<List<ProvaSalva>> _provas = ProvaService().observarMinhas();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerNav(),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Header(),
      ),
      bottomNavigationBar: const Navegar(semAvancar: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MenuTitle(title: 'Meu perfil', fontSize: 28),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dadosUsuario(),
                        const Divider(height: 32),
                        const Text(
                          'Meu espaço',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _secaoTurmas(),
                        const SizedBox(height: 12),
                        _secaoProvas(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dadosUsuario() {
    return StreamBuilder<Usuario?>(
      stream: _usuario,
      builder: (context, snap) {
        final nome = snap.data?.nome ?? '';
        // Se o perfil não tiver e-mail salvo, usa o da conta do Firebase
        final emailPerfil = snap.data?.email ?? '';
        final email = emailPerfil.isNotEmpty
            ? emailPerfil
            : (_user?.email ?? '');
        final base = nome.trim().isNotEmpty ? nome.trim() : email;
        final inicial = base.isEmpty
            ? '?'
            : base.characters.first.toUpperCase();

        String titulo = nome;
        if (snap.connectionState == ConnectionState.waiting) {
          titulo = 'Carregando...';
        } else if (snap.hasError) {
          titulo = 'Erro ao carregar o nome';
        } else if (nome.isEmpty) {
          titulo = 'Usuário sem nome';
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF4C6B5E),
              child: Text(
                inicial,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Conta conectada',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _secaoTurmas() {
    return StreamBuilder<List<Turma>>(
      stream: _turmas,
      builder: (context, snap) {
        return _SecaoExpansivel(
          icone: Icons.groups_outlined,
          titulo: 'Minhas turmas',
          subtitulo: 'Toque para ver as turmas cadastradas.',
          vazio: 'Nenhuma turma cadastrada.',
          carregando: snap.connectionState == ConnectionState.waiting,
          erro: snap.error,
          itens: [
            for (final turma in snap.data ?? <Turma>[])
              ListTile(
                title: Text(turma.nome),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListaAlunosScreen(
                      turmaId: turma.id,
                      turmaNome: turma.nome,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _secaoProvas() {
    return StreamBuilder<List<ProvaSalva>>(
      stream: _provas,
      builder: (context, snap) {
        return _SecaoExpansivel(
          icone: Icons.description_outlined,
          titulo: 'Provas cadastradas',
          subtitulo: 'Toque para ver as provas, questões e versões.',
          vazio: 'Nenhuma prova cadastrada.',
          carregando: snap.connectionState == ConnectionState.waiting,
          erro: snap.error,
          itens: [
            for (final prova in snap.data ?? <ProvaSalva>[])
              ListTile(
                title: Text(prova.titulo),
                subtitle: Text(
                  [
                    _plural(prova.questoes.length, 'questão', 'questões'),
                    _plural(prova.versoes.length, 'versão', 'versões'),
                    if (prova.criadoEm != null) formatarData(prova.criadoEm),
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalheProvaPage(provaId: prova.id),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _plural(int n, String um, String varios) =>
      '$n ${n == 1 ? um : varios}';
}

/// Bloco que abre e fecha, com a quantidade de itens ao lado do título.
class _SecaoExpansivel extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final String vazio;
  final bool carregando;
  final Object? erro;
  final List<Widget> itens;

  const _SecaoExpansivel({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.vazio,
    required this.carregando,
    required this.erro,
    required this.itens,
  });

  Widget _mensagem(String texto) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(texto, style: TextStyle(color: Colors.grey.shade700)),
  );

  @override
  Widget build(BuildContext context) {
    final contagem = carregando || erro != null
        ? '...'
        : '${itens.length} ${itens.length == 1 ? 'item' : 'itens'}';

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(icone, color: const Color(0xFF4C6B5E)),
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitulo,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kListCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(contagem, style: const TextStyle(fontSize: 12)),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          if (erro != null)
            _mensagem('Erro ao carregar: $erro')
          else if (carregando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (itens.isEmpty)
            _mensagem(vazio)
          else
            ...itens,
        ],
      ),
    );
  }
}
