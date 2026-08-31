# Sistema para Correção e Criação Automatizada de Provas

## Objetivo
O objetivo do app é criar um sistema automatizado de correção de provas para que os professores consigam corrigir várias provas otimizando tempo. O app também traz benefícios para os alunos, uma vez que eles podem levar a prova para casa e os professores ficam com a folha de respostas para corrigi-las no app — o que evita que os alunos fiquem esperando o professor devolver a prova para saber se acertaram ou erraram as questões.

Outro objetivo do app é a criação de provas: os professores podem cadastrar suas próprias perguntas no banco de questões do app e, com apenas alguns cliques, selecionar as perguntas que querem colocar em suas provas, além de poder embaralhar as questões.

Por último, o app também traz o benefício de gerar relatórios de correção para cada prova. Os professores podem gerar um relatório em Excel com o nome do aluno e sua respectiva nota, para lançar no sistema acadêmico da instituição, além de um relatório de estatística indicando qual alternativa foi a mais marcada em cada questão da prova.

O projeto é desenvolvido em Flutter, com uma interface Web voltada à criação de provas e uma interface Mobile voltada à correção.

## Usuário final e problema resolvido

O usuário final é o professor, que precisa corrigir, montar e avaliar relatórios de suas provas no menor tempo possível — garantindo, ao mesmo tempo, que o aluno consiga saber quais questões errou antes mesmo de o professor devolver a correção.

O app resolve a questão principal, que é a correção das provas: muitos professores levam horas corrigindo manualmente, e o sistema garante que essa correção seja feita em poucos minutos. Além disso, ele resolve a organização das questões e a montagem de provas aleatórias, ajuda os professores a identificar quais questões estão sendo mais erradas para reforçar o assunto em aula, e elimina o trabalho manual de organizar notas, já que gera automaticamente um relatório pronto para lançar no sistema acadêmico.

## Requisitos Funcionais (RF)

RF01 Cadastro de questões em um banco de questões reutilizável, próprio de cada professor
RF02 Geração de prova a partir do banco de questões
RF03 Opção de randomização das questões e das alternativas
RF04 Opção de gerar a mesma prova para todos ou provas totalmente diferentes por aluno
RF05 Leitura de QR code para identificação e correção da folha de respostas
RF06 Cálculo automático da nota do aluno após a leitura da folha de resposta
RF07 Interface Mobile com fluxo de correção: abrir → ler QR code → ler gabarito → ler prova → nota automática
RF08 Interface Web para criação de provas
RF09 Importação de lista de alunos para o sistema
RF10 Geração de relatório de estatísticas por questão (qual alternativa foi mais marcada)
RF11 Exportação dos resultados/notas em planilha (Excel)
RF12 Opção de editar o layout da prova gerada, sem deixar a mesma questão dividida entre duas páginas diferentes
RF13 Navegação livre pelo app sem necessidade de login; o login só é exigido no momento de salvar dados
Requisitos Não Funcionais (RNF)

## Requisitos Não Funcionais (RNF)

RNF01 Usabilidade Design minimalista, com cores claras e objetivas; botões lógicos e responsivos, para que o professor não tenha dúvidas de como usar o app
RNF02 Desempenho Correção rápida, com meta de corrigir 50 provas em até 30 minutos
RNF03 Disponibilidade multiplataforma Web para criação de provas e Mobile para correção de provas
RNF04 Segurança Dados de notas de alunos e provas corrigidas protegidos, com controle de acesso somente pelo professor responsável pela conta
RNF05 Escalabilidade Suporte a grandes volumes de dados para correção, exportação e salvamento
RNF06 Portabilidade Layout responsivo, usando LayoutBuilder/MediaQuery, adaptando a interface entre telas largas (web) e estreitas (mobile)
RNF07 Manutenibilidade Arquitetura modular por features, com código organizado entre as pessoas da equipe; controle de versão organizado (uma branch por feature/pessoa, com Pull Request e revisão antes do merge); testes automatizados básicos com dados mock
Navegação do Sistema
A navegação é centralizada em um único ponto de configuração (lib/Routes/routes.dart), onde cada tela do app recebe um nome de rota. O app abre sempre pela tela inicial (Home), que funciona como um painel de atalhos para as demais áreas do sistema.

A partir da Home, o professor navega para grandes áreas:

Home
├── Banco de Questões
├── Criação de Prova
├── Turmas e Alunos
├── Correção de Provas (Mobile)
└── Relatórios
├── Provas corrigidas (histórico)
├── Relatório de notas por turma
└── Estatística por questão
|__Cadastro do professor. 

Cada uma dessas telas é acessada através de botões que chamam Navigator.pushNamed(context, <nome_da_rota>), empilhando a nova tela sobre a atual — o que já disponibiliza automaticamente o botão de voltar no topo da tela. A navegação entre Web e Mobile segue a mesma lógica de rotas; o que muda entre as duas plataformas é apenas quais telas fazem sentido em cada uma (ex: a correção via câmera só é acessada pelo Mobile).

Está sujeito a alterações caso seja necessário.
