# TEST FAST

**TEST FAST** é um aplicativo desenvolvido para facilitar a criação, correção e análise de provas, ajudando professores a economizar tempo e organizar melhor suas avaliações.

## Objetivo

O objetivo principal do projeto é **automatizar a correção de provas**. O professor poderá realizar a leitura da folha de respostas pelo aplicativo e receber a nota automaticamente.

O sistema também permite criar provas utilizando um **banco de questões**, selecionar perguntas, embaralhar questões e alternativas e gerar diferentes versões de uma mesma prova.

Além disso, o professor poderá visualizar **relatórios e estatísticas** sobre as avaliações e exportar as notas dos alunos para uma planilha.

## Público-alvo

O sistema é destinado principalmente a **professores que precisam criar, corrigir e analisar provas**, especialmente aqueles que possuem um grande volume de avaliações para corrigir.

## Principais funcionalidades

* Leitura de QR Code da prova;
* Cálculo automático da nota;
* Criação de provas;
* Banco de questões;
* Embaralhamento de questões e alternativas;
* Criação de diferentes versões de uma prova;
* Gerenciamento de turmas;
* Relatórios de desempenho;
* Estatísticas das respostas;
* Personalização do layout da prova;
* Login e gerenciamento dos dados do professor.

## Estrutura do projeto

O projeto está organizado em **Routes, Screens e Widgets**, facilitando a organização e manutenção do código.
lib/
│
├── routes/
│
├── screens/
│   ├── home/
│   ├── turma/
│   ├── relatorios/
│   ├── banco_de_questoes/
│   ├── correcao_de_provas/
│   ├── entrar/
│   └── criar_prova/
│
└── widgets/
    ├── header/
    ├── blocos_de_navegacao/
    └── menu_de_pesquisa/
    
## Benefícios

### Para os professores

* Redução do tempo gasto com correções;
* Organização das questões;
* Criação de provas de forma mais rápida;
* Correção automática;
* Geração de notas e relatórios;
* Análise das questões com maior número de erros.

### Para os alunos

* Correção mais rápida;
* Menor tempo de espera para saber o resultado;
* Possibilidade de levar a prova para casa enquanto o professor realiza a correção.

  ## Principais Requisitos Funcionais

* **RF01 – Leitura de QR Code:** identificar a prova e o aluno através do QR Code presente na folha de respostas.
* **RF02 – Correção automática:** comparar as respostas do aluno com o gabarito da prova.
* **RF03 – Cálculo da nota:** calcular automaticamente a nota após a correção.
* **RF04 – Criação de provas:** permitir que o professor crie e configure suas avaliações.
* **RF05 – Banco de questões:** permitir cadastrar, editar, armazenar e reutilizar questões.
* **RF06 – Randomização:** permitir embaralhar questões e alternativas.
* **RF07 – Diferentes versões:** permitir gerar a mesma prova para todos os alunos ou versões diferentes.
* **RF08 – Gerenciamento de alunos:** permitir cadastrar ou importar alunos e associá-los às provas e turmas.
* **RF09 – Relatórios:** gerar estatísticas sobre o desempenho dos alunos e as respostas de cada questão.
* **RF10 – Exportação:** permitir exportar notas e resultados em formato compatível com Excel.
* **RF11 – Autenticação:** exigir login para salvar e gerenciar os dados do professor.
* **RF12 – Correção mobile:** disponibilizar o processo de correção em dispositivos móveis.

## Principais Requisitos Não Funcionais

* **RNF01 – Desempenho:** o sistema deverá realizar as correções de forma rápida e eficiente, tendo como meta corrigir aproximadamente 50 provas em até 30 minutos.
* **RNF02 – Segurança:** os dados de provas, alunos e notas deverão ser protegidos e acessíveis somente ao professor responsável.
* **RNF03 – Escalabilidade:** a arquitetura deverá suportar o crescimento da quantidade de provas, alunos, questões e resultados.
* **RNF04 – Organização:** o código deverá ser organizado de forma modular, facilitando a manutenção e o trabalho da equipe.
* **RNF05 – Controle de versão:** o projeto deverá utilizar Git, com branches para funcionalidades e Pull Requests para revisão do código.
* **RNF06 – Testes:** o sistema deverá possuir testes automatizados básicos utilizando dados simulados (*mocks*).
* **RNF07 – Usabilidade:** a interface deverá ser clara e intuitiva, facilitando a utilização pelo professor.
* **RNF08 – Design:** a aplicação deverá utilizar um design minimalista, priorizando legibilidade e facilidade de uso.
* **RNF09 – Responsividade:** a interface deverá se adaptar a diferentes tamanhos de tela e dispositivos.


