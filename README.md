

# Test Fast

**Aplicativo que automatiza a criação e a correção de provas, feito para professores com grande volume de avaliações.**

## Equipe

| Nome completo |
|---|
| Amanda Specht |
| Giovanni Micheluzzi |
| João Santana |
| Júlia Paz |

## 1. Visão Geral

O objetivo principal do projeto é **automatizar a correção de provas**. O professor realiza a leitura da folha de respostas pelo aplicativo e recebe a nota automaticamente.

O sistema também permite **criar provas** a partir de um banco de questões: o professor seleciona as perguntas, embaralha questões e alternativas e gera diferentes versões de uma mesma prova. Além disso, é possível visualizar relatórios e estatísticas sobre as avaliações e exportar as notas dos alunos para uma planilha.

### Público-alvo

O sistema é destinado principalmente a **professores** que precisam criar, corrigir e analisar provas, especialmente aqueles que possuem um grande volume de avaliações para corrigir.

### Principais funcionalidades

- Leitura de QR Code da prova;
- Cálculo automático da nota;
- Criação de provas;
- Banco de questões;
- Embaralhamento de questões e alternativas;
- Criação de diferentes versões de uma prova;
- Gerenciamento de turmas;
- Relatórios de desempenho;
- Estatísticas das respostas;
- Personalização do layout da prova;
- Login e gerenciamento dos dados do professor.

### Benefícios para os professores

- Redução do tempo gasto com correções;
- Organização das questões;
- Criação de provas de forma mais rápida;
- Correção automática;
- Geração de notas e relatórios;
- Análise das questões com maior número de erros.

## 2. Requisitos

### 2.1 Funcionais (RF)

| Código | Requisito |
|---|---|
| RF01 | **Leitura do QR Code:** o sistema deverá realizar a leitura do QR Code presente na folha de respostas para identificar a prova e o aluno, permitindo o correto processamento das respostas. |
| RF02 | **Correção automatizada:** o sistema deverá realizar a leitura da folha de respostas e comparar as respostas do aluno com o gabarito da prova, efetuando a correção automaticamente. |
| RF03 | **Cálculo automático da nota:** o sistema deverá calcular automaticamente a nota do aluno após a conclusão da leitura e correção da folha de respostas. |
| RF04 | **Criação de provas:** o sistema deverá disponibilizar uma interface web para que o professor possa criar e configurar provas. |
| RF05 | **Banco de questões:** o sistema deverá permitir o cadastro, edição e armazenamento de questões em um banco de questões reutilizável pelo professor. |
| RF06 | **Geração de provas:** o sistema deverá permitir a geração de provas a partir das questões armazenadas no banco de questões. |
| RF07 | **Randomização de questões e alternativas:** o sistema deverá permitir a randomização da ordem das questões e das alternativas durante a geração das provas. |
| RF08 | **Geração de diferentes versões de prova:** o sistema deverá permitir ao professor gerar a mesma versão de prova para todos os alunos ou versões diferentes para cada aluno. |
| RF09 | **Organização das questões nas páginas:** o sistema deverá organizar automaticamente as questões de modo que uma mesma questão não seja dividida entre duas páginas diferentes. |
| RF10 | **Importação de alunos:** o sistema deverá permitir a importação de uma lista de alunos para facilitar o cadastro e a associação dos alunos às respectivas provas. |
| RF11 | **Relatórios estatísticos:** o sistema deverá gerar relatórios estatísticos relacionados ao desempenho dos alunos e à distribuição das respostas em cada questão. |
| RF12 | **Exportação de resultados:** o sistema deverá permitir a exportação dos resultados e das notas dos alunos em formato de planilha compatível com o Microsoft Excel. |
| RF13 | **Autenticação e gerenciamento de dados:** o sistema deverá permitir que o professor navegue e utilize as funcionalidades disponíveis sem autenticação, porém deverá exigir login para salvar, acessar e gerenciar seus dados. |
| RF14 | **Edição do layout da prova:** o sistema deverá permitir ao professor editar e personalizar o layout da prova antes de sua geração. |
| RF15 | **Aplicação mobile para correção:** o sistema deverá disponibilizar uma interface mobile destinada ao processo de correção, permitindo ao professor seguir o fluxo de leitura do QR Code, gabarito e folha de respostas até a obtenção da nota automática. |
| RF16 | **Interface mobile para criação:** o sistema deverá disponibilizar uma interface mobile destinada à criação, configuração e gerenciamento das provas e do banco de questões. |

### 2.2 Não Funcionais (RNF)

| Código | Requisito |
|---|---|
| RNF01 | O sistema deverá realizar a correção das folhas de respostas de forma rápida e eficiente, tendo como meta possibilitar a correção de aproximadamente 50 provas em até 30 minutos. |
| RNF02 | O sistema deverá estar disponível em ambiente mobile para criação e gerenciamento de provas e em dispositivos móveis para realização do processo de correção. |
| RNF03 | Os dados referentes às provas, alunos e notas deverão ser protegidos, garantindo que o acesso às informações seja restrito ao professor responsável pela respectiva conta. |
| RNF04 | A arquitetura do sistema deverá ser preparada para suportar o crescimento do volume de provas, alunos, questões, resultados e demais dados armazenados. |
| RNF05 | O sistema deverá utilizar uma arquitetura modular organizada por funcionalidades (*features*), facilitando a manutenção da aplicação. |
| RNF06 | O código-fonte deverá seguir uma estrutura padronizada e organizada, permitindo que diferentes integrantes da equipe trabalhem no projeto de forma independente e integrada. |
| RNF07 | O desenvolvimento deverá utilizar um sistema de controle de versão, adotando uma branch específica para cada funcionalidade ou integrante da equipe e Pull Requests com revisão de código antes da realização do merge. |
| RNF08 | O sistema deverá possuir testes automatizados básicos, utilizando dados simulados (*mocks*). |
| RNF10 | A interface deverá apresentar botões, menus e elementos de navegação de forma clara e intuitiva, permitindo que o usuário compreenda facilmente como utilizar o sistema. |
| RNF11 | A interface deverá utilizar um design minimalista, com cores claras, objetivas e elementos visuais que favoreçam a legibilidade e a facilidade de uso. |
| RNF12 | A aplicação deverá adaptar sua interface de acordo com o dispositivo utilizado. |

## 3. Telas do Sistema

As telas do aplicativo ficam em `lib/screens/`, organizadas em uma pasta por funcionalidade:

| Módulo | Arquivo(s) | O que a tela faz |
|---|---|---|
| **Entrar** | `entrar.dart`, `login.dart`, `cadastro.dart` | Autenticação do professor (login) e criação de conta (cadastro). |
| **Home** | `home.dart` | Tela inicial, com acesso às principais funcionalidades do app. |
| **Turmas** | `turmas.dart`, `lista_alunos.dart`, `folha_resposta.dart` | Gerenciamento de turmas, lista de alunos de cada turma e folha de respostas. |
| **Banco de Questões** | `questoes.dart`, `criar_questao.dart`, `pesquisar_questao.dart` | Listagem, criação e busca de questões reutilizáveis. |
| **Criar Prova** | `prova.dart` | Montagem e configuração da prova a partir do banco de questões. |
| **Corrigir Provas** | `corrigir.dart` | Leitura do QR Code e da folha de respostas, com cálculo automático da nota. |
| **Relatórios** | `relatorios.dart`, `relatorio_aluno.dart`, `relatorio_prova.dart`, `relatorio_turma.dart` | Relatórios de desempenho por aluno, por prova e por turma. |

### As imagens das telas estão na documentação entregue separada do readme. 

## 4. Modelo de Dados

Os dados são armazenados no **Firebase Firestore** (NoSQL), em coleções de documentos. As coleções do projeto são: `usuarios`, `turmas`, `alunos`, `questoes`, `provas` e `correcoes`.

### Coleção: `usuarios`

```json
// Coleção: usuarios
{
  "cpf": "0999999999",
  "email": "pazesilvajulia@gmail.com",
  "nome": "Julia",
  "sobrenome": "Paz"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| cpf | String | CPF do professor |
| email | String | E-mail do professor (usado no login) |
| nome | String | Nome do professor |
| sobrenome | String | Sobrenome do professor |

### Coleção: `turmas`

```json
// Coleção: turmas
{
  "criadoPor": "BN3w1H9eAibLWcyQIIL84PmDU322",
  "nome": "Turma da Julia"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| criadoPor | String | UID do professor que criou a turma |
| nome | String | Nome da turma |

### Coleção: `alunos`

```json
// Coleção: alunos
{
  "email": "oliviapazzschornack@gmail.com",
  "nome": "Olívia Paz",
  "turmaID": "5JwwoGmxSXVi8rnMCiaz"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| email | String | E-mail do aluno |
| nome | String | Nome do aluno |
| turmaID | String | ID do documento da turma à qual o aluno pertence |

### Coleção: `questoes`

```json
// Coleção: questoes
{
  "alternativas": ["R$20.000", "R$15.000", "R$19.000", "R$12.000"],
  "assunto": "Porcentagem",
  "corretas": [1],
  "criadoEm": "27 de outubro de 2026 às 22:08:06 UTC-3",
  "enunciado": "Se um carro tem o valor de R$60.000,00. ...",
  "materia": "Matemática"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| alternativas | Array (String) | Alternativas da questão |
| assunto | String | Assunto da questão (ex.: Porcentagem) |
| corretas | Array (int) | Índice(s) da(s) alternativa(s) correta(s) |
| criadoEm | Timestamp | Data e hora de criação da questão |
| enunciado | String | Texto da questão |
| materia | String | Matéria/disciplina da questão |

### Coleção: `provas`

```json
// Coleção: provas
{
  "codigoQr": "WDzNhR3XHEMF9oGTGhxs",
  "criadoEm": "28 de outubro de 2026 às 19:51:14 UTC-3",
  "disciplina": "Matemática",
  "gabarito": {
    "Udkj0F17Nhlk3IaY7tQZ": "A"
  },
  "professorId": "pjo4FO0xefXfuqdpHOKixT8XW0l2",
  "questoesIds": ["Udkj0F17Nhlk3IaY7tQZ"],
  "titulo": "teste",
  "turma": "103",
  "ultimaCorrecaoEm": "29 de outubro de 2026 às 20:18:27 UTC-3"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| codigoQr | String | Código lido no QR Code da folha de respostas para identificar a prova |
| criadoEm | Timestamp | Data e hora de criação da prova |
| disciplina | String | Disciplina da prova |
| gabarito | Map | Mapa com o ID de cada questão e a alternativa correta (ex.: `"A"`) |
| professorId | String | UID do professor dono da prova |
| questoesIds | Array (String) | IDs das questões que compõem a prova |
| titulo | String | Título da prova |
| turma | String | Turma para a qual a prova foi aplicada |
| ultimaCorrecaoEm | Timestamp | Data e hora da última correção realizada |

### Coleção: `correcoes`

```json
// Coleção: correcoes
{
  "acertos": 1,
  "alunoNome": "Giovani",
  "aproveitamento": 1,
  "dataCorrecao": "28 de outubro de 2026 às 19:52:10 UTC-3",
  "disciplina": "Matemática",
  "emBranco": 0,
  "erros": 0,
  "matricula": "",
  "nota": 10,
  "professorId": "pjo4FO0xefXfuqdpHOKixT8XW0l2",
  "provaId": "WDzNhR3XHEMF9oGTGhxs",
  "respostas": [
    {
      "correta": true,
      "gabarito": "A",
      "marcada": "A",
      "numero": 1,
      "questaoId": "Udkj0F17Nhlk3IaY7tQZ"
    }
  ],
  "tituloProva": "teste",
  "totalQuestoes": 1,
  "turma": "103"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| acertos | int64 | Quantidade de questões acertadas |
| alunoNome | String | Nome do aluno |
| aproveitamento | int64 | Aproveitamento do aluno na prova |
| dataCorrecao | Timestamp | Data e hora da correção |
| disciplina | String | Disciplina da prova |
| emBranco | int64 | Quantidade de questões deixadas em branco |
| erros | int64 | Quantidade de questões erradas |
| matricula | String | Matrícula do aluno |
| nota | int64 | Nota final calculada automaticamente |
| professorId | String | UID do professor que realizou a correção |
| provaId | String | ID do documento da prova corrigida |
| respostas | Array (Map) | Lista com o resultado de cada questão (campos abaixo) |
| respostas[].correta | Boolean | Indica se o aluno acertou a questão |
| respostas[].gabarito | String | Alternativa correta segundo o gabarito |
| respostas[].marcada | String | Alternativa marcada pelo aluno |
| respostas[].numero | int64 | Número da questão na prova |
| respostas[].questaoId | String | ID do documento da questão |
| tituloProva | String | Título da prova |
| totalQuestoes | int64 | Total de questões da prova |
| turma | String | Turma do aluno |

## 5. Stack Tecnológica

- **Flutter**: framework usado para construir a interface e a navegação do app mobile. Com uma única base de código, o app roda em Android e na web, o que atende ao requisito de adaptação ao dispositivo (RNF12).
- **Dart**: linguagem de programação usada no Flutter.
- **Firebase Firestore**: banco de dados em nuvem (NoSQL) usado para armazenar e consultar os dados do app (usuários, turmas, alunos, questões, provas e correções). Escala conforme o volume de dados cresce (RNF04).
- **Firebase Authentication (`firebase_auth`)**: serviço de autenticação usado para o cadastro e o login dos professores com e-mail e senha.
  - **Por que usamos:** é seguro e já pronto, então a equipe não precisa implementar do zero o armazenamento de senhas, a criptografia e o controle de sessão. Além disso, cada usuário recebe um **UID único**, que usamos como identificador do professor (`professorId` / `criadoPor`) e dos alunos nas coleções. Isso permite isolar os dados de cada professor, de modo que ele acesse apenas as próprias turmas, provas e notas (RNF03), e se integra diretamente às Regras de Segurança do Firestore.
- **`firebase_core`**: pacote que inicializa a conexão do app com o Firebase.
- **`cloud_firestore`**: pacote que permite ler e gravar dados no Firestore pelo Flutter.
- **Git e GitHub**: controle de versão e trabalho em equipe, com branches por integrante e Pull Requests com revisão (RNF07).

## 6. Estrutura de Pastas

```
lib/
  Routes/            # definição das rotas e da navegação entre telas
  data/              # dados e fontes de dados do app
  models/            # representação das entidades usadas no app
    aluno.dart
    relatorio.dart
    turma.dart
    usuario.dart
  respostaErro/      # tratamento e padronização de respostas de erro
  screens/           # telas do aplicativo, organizadas por funcionalidade
    BancoQuestoes/   # banco de questões
      criar_questao.dart
      elem_comuns.dart
      pesquisar_questao.dart
      questoes.dart
    CorrigirProvas/  # correção das provas
      corrigir.dart
    CriarProva/      # criação das provas
      prova.dart
    Entrar/          # autenticação do professor
      breakpoint.dart
      cadastro.dart
      entrar.dart
      login.dart
    Home/            # tela inicial
      home.dart
    Relatorios/      # relatórios e estatísticas
      relatorio_aluno.dart
      relatorio_prova.dart
      relatorio_turma.dart
      relatorios.dart
    Turmas/          # turmas e alunos
      folha_resposta.dart
      lista_alunos.dart
      turmas.dart
  service/           # comunicação com o Firebase e regras do app
    aluno_service.dart
    questao_service.dart
    turma_service.dart
    usuario_service.dart
  widgets/           # componentes de interface reutilizáveis entre telas
  firebase_options.dart  # configuração de conexão com o Firebase (gerada pelo FlutterFire)
  main.dart          # ponto de entrada do aplicativo
docs/
  telas/
  modelo-dados/
  backlog/
```

## 7. Como Executar o Projeto

### Pré-requisitos

Antes de executar o projeto, certifique-se de ter instalado:

- [Flutter](https://docs.flutter.dev/get-started/install)
- [Dart](https://dart.dev/get-dart)
- Android Studio (caso utilize um emulador Android)
- Git
- Node.js e o [Firebase CLI](https://firebase.google.com/docs/cli) (para configurar o Firebase)
- Uma conta Google com acesso ao projeto Firebase da equipe

Para verificar se o Flutter está configurado corretamente:

```
flutter doctor
```

### Passo a passo

**1. Clone o repositório**

```
git clone URL_DO_REPOSITORIO
```

**2. Entre na pasta do projeto**

```
cd app-flutter-criador-de-provas
```

**3. Instale as dependências** (pacotes, fontes, imagens etc.)

```
flutter pub get
```

**4. Configure o Firebase** (veja a seção abaixo)

**5. Verifique os dispositivos disponíveis**

```
flutter devices
```

**6. Execute o projeto**

```
flutter run -d chrome
```

ou, para um dispositivo/emulador Android:

```
flutter run -d <id-do-dispositivo>
```

### Configuração do Firebase

O app usa **Firebase Authentication** e **Cloud Firestore**. Para rodar, é preciso conectar o projeto ao Firebase.

**1. Ter acesso ao projeto Firebase da equipe**

Peça à Amanda (responsável pela configuração) para adicionar seu e-mail como membro do projeto no [Console do Firebase](https://console.firebase.google.com/) (*Configurações do projeto → Usuários e permissões*).

**2. Instalar as ferramentas de linha de comando**

```
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

**3. Conectar o app ao projeto Firebase**

Na raiz do projeto, execute e escolha o projeto da equipe e as plataformas (Android e Web):

```
flutterfire configure
```

**4. Ativar a autenticação** 

No Console do Firebase: *Authentication → Sign-in method → E-mail/senha → Ativar*.

**5. Criar o banco Firestore** (apenas uma vez)

No Console do Firebase: *Firestore Database → Criar banco de dados*. As coleções (`usuarios`, `turmas`, `alunos`, `questoes`, `provas` e `correcoes`) são criadas automaticamente pelo app conforme os dados são salvos.

**6. Regras de segurança do Firestore**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**7. Criar uma conta de teste**

Ao abrir o app, use a tela de **Cadastro** para criar um professor (e-mail e senha) e depois faça **Login**.

## 8. Backlog de Atividades da N2

### Amanda Specht

| Tarefa | Prazo | Status |
|---|---|---|
| Criação e configuração do Firebase Auth para cadastro e login | 29/10/26 | Finalizado |
| Configuração do banco de dados para o banco de questões | 29/10/26 | Finalizado |
| Compartilhamento do Firebase com os outros membros da equipe | 29/10/26 | Finalizado |
| Criação da tela de banco de questões (pendente da N1) | 29/10/26 | Finalizado |
| Escrita do README da N2 | 29/10/26 | Finalizado |

### Giovanni Micheluzzi

| Tarefa | Prazo | Status |
|---|---|---|
| Habilitar a correção das provas por aluno | 29/10/26 | Finalizado |
| Exibir o resultado final para o professor | 29/10/26 | Finalizado |
| Importar os resultados para os relatórios | 29/10/26 | Finalizado |

### João Santana

| Tarefa | Prazo | Status |
|---|---|---|
| Criação da tela de criação de prova | 29/10/26 | Finalizado |
| Conexão com o banco de dados para criação de prova | 29/10/26 | Finalizado |
| Conexão com o banco de dados para relatórios | 29/10/26 | Finalizado |
| Envio de todos os documentos (APK, código e README) | 29/10/26 | Finalizado |

### Júlia Paz

| Tarefa | Prazo | Status |
|---|---|---|
| Conexão com o banco de dados das turmas | 29/10/26 | Finalizado |
| Cadastro de alunos com UID próprio por professor e aluno | 29/10/26 | Finalizado |

---
