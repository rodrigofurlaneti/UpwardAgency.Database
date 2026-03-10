# 🏢 Agência de Publicidade e Marketing — Documentação do Banco de Dados

> Modelagem relacional completa em MySQL para gestão de agências de comunicação, publicidade e marketing. Cobre desde a estrutura organizacional até o controle financeiro, campanhas de mídia e produção criativa.

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Tecnologias e Requisitos](#tecnologias-e-requisitos)
3. [Como Executar](#como-executar)
4. [Diagrama de Entidade-Relacionamento (MER)](#diagrama-de-entidade-relacionamento-mer)
5. [Módulos e Tabelas](#módulos-e-tabelas)
   - [01 · Estrutura Organizacional](#01--estrutura-organizacional)
   - [02 · Clientes](#02--clientes)
   - [03 · Fornecedores e Parceiros](#03--fornecedores-e-parceiros)
   - [04 · Catálogo de Serviços](#04--catálogo-de-serviços)
   - [05 · Contratos](#05--contratos)
   - [06 · Briefings e Projetos](#06--briefings-e-projetos)
   - [07 · Tarefas e Workflow](#07--tarefas-e-workflow)
   - [08 · Campanhas de Mídia](#08--campanhas-de-mídia)
   - [09 · Orçamentos e Propostas](#09--orçamentos-e-propostas)
   - [10 · Financeiro](#10--financeiro)
   - [11 · Aprovações](#11--aprovações)
   - [12 · Reuniões](#12--reuniões)
   - [13 · Produção Criativa](#13--produção-criativa)
   - [14 · Avaliações e NPS](#14--avaliações-e-nps)
   - [15 · Configurações e Auditoria](#15--configurações-e-auditoria)
6. [Regras de Negócio — Triggers](#regras-de-negócio--triggers)
7. [Views Gerenciais](#views-gerenciais)
8. [Stored Procedures](#stored-procedures)
9. [Índices de Performance](#índices-de-performance)
10. [Dados Iniciais (Seed)](#dados-iniciais-seed)
11. [Fluxos Principais do Sistema](#fluxos-principais-do-sistema)
12. [Convenções de Nomenclatura](#convenções-de-nomenclatura)

---

## Visão Geral

Este banco de dados foi modelado para atender ao ciclo completo de operação de uma agência de publicidade e marketing, cobrindo os seguintes domínios funcionais:

| Domínio | Descrição |
|---|---|
| **Pessoas** | Funcionários, hierarquia, cargos e departamentos |
| **Comercial** | Clientes, briefings, orçamentos, contratos e propostas |
| **Produção** | Projetos, tarefas, workflow, peças criativas e apontamento de horas |
| **Mídia** | Campanhas, veiculações por canal e métricas de performance |
| **Financeiro** | Contas a receber/pagar, notas fiscais, plano de contas |
| **Gestão** | Reuniões, aprovações, NPS, auditoria e configurações |

**Estatísticas do modelo:**

| Item | Quantidade |
|---|---|
| Tabelas | 47 |
| Triggers | 8 |
| Views | 5 |
| Stored Procedures | 3 |
| Índices adicionais | 12+ |
| Constraints (FK, UK, CHK) | 90+ |
| Dados iniciais (seed) | 6 domínios |

---

## Tecnologias e Requisitos

- **MySQL** 8.0 ou superior (necessário para colunas geradas `GENERATED ALWAYS AS`)
- **Engine**: InnoDB em todas as tabelas (suporte a transações e chaves estrangeiras)
- **Charset**: `utf8mb4` com collation `utf8mb4_unicode_ci` (suporte completo a Unicode e emojis)
- **SQL Mode**: `STRICT_TRANS_TABLES` habilitado para garantir integridade dos dados

---

## Como Executar

```bash
# Via linha de comando MySQL
mysql -u root -p < agencia_publicidade_marketing.sql

# Via MySQL Workbench
# File > Open SQL Script > Execute (Ctrl+Shift+Enter)

# Verificar criação
mysql -u root -p -e "USE agencia_marketing; SHOW TABLES;"
```

> ⚠️ O script cria e seleciona automaticamente o banco `agencia_marketing`. Não é necessário criar o banco manualmente.

---

## Diagrama de Entidade-Relacionamento (MER)

### Mapa Geral dos Módulos e seus Relacionamentos

```
┌─────────────────────────────────────────────────────────────────────┐
│                      ESTRUTURA ORGANIZACIONAL                        │
│   departamentos ──── funcionarios ──── cargos                       │
│                          │  └──────────────┐ (gestor_id — hierarquia)│
└──────────────────────────┼────────────────────────────────────────── ┘
                           │ (responsavel, gerente, executivo...)
┌──────────────────────────▼──────────────────────────────────────────┐
│                           CLIENTES                                   │
│   segmentos_mercado ──── clientes ──── clientes_contatos            │
│                              └──────── clientes_enderecos           │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
        ┌──────────────────┼────────────────────┐
        ▼                  ▼                    ▼
   ┌─────────┐       ┌──────────┐        ┌──────────────┐
   │briefings│       │contratos │        │  orcamentos  │
   └────┬────┘       └────┬─────┘        └──────┬───────┘
        │                 │                     │
        └────────┬────────┘                     │
                 ▼                               │
          ┌──────────┐  ◄─────────────── converte em projeto
          │ projetos │
          └─────┬────┘
       ┌────────┼────────┐
       ▼        ▼        ▼
  ┌────────┐  ┌────────┐  ┌──────────────┐
  │tarefas │  │equipe  │  │campanhas_midia│
  └───┬────┘  └────────┘  └──────┬───────┘
      │                          │
  ┌───▼──────────┐        ┌──────▼──────────────┐
  │apontamentos  │        │campanhas_veiculacoes │
  │_horas        │        └──────┬──────────────┘
  └──────────────┘               │
                          ┌──────▼──────────┐
                          │campanhas_metricas│
                          └─────────────────┘

          ┌──────────────────────────────────────┐
          │             FINANCEIRO               │
          │  notas_fiscais                       │
          │  contas_receber ◄── clientes         │
          │  contas_pagar   ◄── fornecedores     │
          │  plano_contas (hierárquico)          │
          │  centros_custo  ◄── projetos         │
          └──────────────────────────────────────┘
```

### Cardinalidades Principais

| Relacionamento | Cardinalidade | Descrição |
|---|---|---|
| `departamentos` → `funcionarios` | 1:N | Um departamento possui vários funcionários |
| `funcionarios` → `funcionarios` | 1:N (self) | Hierarquia gerencial (gestor → subordinados) |
| `clientes` → `projetos` | 1:N | Um cliente possui vários projetos |
| `projetos` → `tarefas` | 1:N | Um projeto contém várias tarefas |
| `tarefas` → `tarefas` | 1:N (self) | Sub-tarefas hierárquicas |
| `projetos` → `projetos_equipe` | N:M (via tabela) | Funcionários alocados por projeto |
| `contratos` → `contratos_servicos` | 1:N | Serviços incluídos no contrato |
| `campanhas_midia` → `campanhas_veiculacoes` | 1:N | Veiculações por canal |
| `campanhas_veiculacoes` → `campanhas_metricas` | 1:N | Métricas diárias por veiculação |
| `orcamentos` → `orcamentos_itens` | 1:N | Itens do orçamento |
| `pecas_criativas` → `pecas_versoes` | 1:N | Histórico de versões das peças |
| `plano_contas` → `plano_contas` | 1:N (self) | Hierarquia de contas (pai → filho) |

---

## Módulos e Tabelas

---

### 01 · Estrutura Organizacional

Gerencia a hierarquia interna da agência: departamentos, cargos e colaboradores.

#### `departamentos`

Representa as áreas funcionais da agência (Criação, Atendimento, Mídia, Financeiro, etc.).

| Coluna | Tipo | Descrição |
|---|---|---|
| `id` | INT PK | Identificador único |
| `nome` | VARCHAR(100) UNIQUE | Nome do departamento |
| `descricao` | TEXT | Detalhamento das atividades |
| `ativo` | TINYINT(1) | Indica se o departamento está ativo |

---

#### `cargos`

Catálogo de funções com nível hierárquico e salário-base de referência.

| Coluna | Tipo | Descrição |
|---|---|---|
| `id` | INT PK | Identificador único |
| `nome` | VARCHAR(100) | Nome do cargo (ex: "Designer Sênior") |
| `nivel` | ENUM | ESTAGIARIO / JUNIOR / PLENO / SENIOR / ESPECIALISTA / GERENTE / DIRETOR / SOCIO |
| `salario_base` | DECIMAL(10,2) | Salário-base de referência para o cargo |
| `descricao` | TEXT | Responsabilidades do cargo |

---

#### `funcionarios`

Colaboradores da agência. Suporta hierarquia gerencial via auto-referência (`gestor_id`).

| Coluna | Tipo | Descrição |
|---|---|---|
| `id` | INT PK | Identificador único |
| `departamento_id` | FK | Departamento ao qual pertence |
| `cargo_id` | FK | Cargo atual |
| `gestor_id` | FK (self) | ID do gestor direto (nulo para a diretoria) |
| `nome`, `sobrenome` | VARCHAR | Nome completo |
| `cpf` | CHAR(11) UNIQUE | CPF sem formatação |
| `email_corporativo` | VARCHAR UNIQUE | E-mail institucional |
| `data_admissao` | DATE | Data de entrada na agência |
| `data_demissao` | DATE | Data de saída (NULL = ativo) |
| `salario` | DECIMAL(10,2) | Salário atual |
| `carga_horaria` | INT | Horas semanais contratadas |
| `status` | ENUM | ATIVO / FERIAS / AFASTADO / DEMITIDO |

> **Regra:** Um funcionário não pode ser seu próprio gestor. A constraint de FK para `gestor_id` permite NULL, tornando-a adequada para a diretoria.

---

### 02 · Clientes

Gerencia as empresas contratantes, seus contatos e endereços.

#### `segmentos_mercado`

Tabela de domínio com os segmentos de atuação dos clientes (Varejo, Tecnologia, Saúde, etc.). Utilizada para segmentação de carteira e relatórios comerciais.

---

#### `clientes`

Empresa contratante da agência. Cada cliente tem um executivo de contas responsável e é classificado por tier de faturamento.

| Coluna | Tipo | Descrição |
|---|---|---|
| `id` | INT PK | Identificador único |
| `segmento_id` | FK | Segmento de mercado |
| `responsavel_id` | FK | Funcionário responsável pela conta |
| `razao_social` | VARCHAR(200) | Razão social da empresa |
| `cnpj` | CHAR(14) UNIQUE | CNPJ sem formatação |
| `data_inicio` | DATE | Início do relacionamento comercial |
| `data_fim` | DATE | Encerramento do relacionamento (NULL = ativo) |
| `classificacao` | ENUM | BRONZE / PRATA / OURO / PLATINA / DIAMANTE |
| `limite_credito` | DECIMAL(14,2) | Limite de crédito aprovado |

> **Regra (Trigger RN08):** A classificação é atualizada automaticamente com base no faturamento acumulado pago: Diamante ≥ R$ 500k, Platina ≥ R$ 200k, Ouro ≥ R$ 50k, Prata ≥ R$ 10k, Bronze < R$ 10k.

> **Regra (Trigger RN03):** Clientes com projetos ou contratos ativos não podem ser excluídos.

---

#### `clientes_enderecos`

Múltiplos endereços por cliente, classificados por tipo: Faturamento, Entrega ou Comercial. Um endereço pode ser marcado como principal (`principal = 1`).

---

#### `clientes_contatos`

Pessoas de contato dentro da empresa cliente. O campo `decisor` identifica quem tem poder de aprovação (útil para envio de orçamentos e aprovação de peças).

---

### 03 · Fornecedores e Parceiros

#### `fornecedores`

Parceiros externos que prestam serviços à agência: gráficas, produtoras, fotógrafos, estúdios de vídeo, etc. Suporta tanto Pessoa Física quanto Jurídica.

| Coluna | Tipo | Descrição |
|---|---|---|
| `categoria` | ENUM | GRAFICA / PRODUCAO / MIDIA / FOTOGRAFIA / VIDEO / TI / OUTRO |
| `avaliacao` | TINYINT(1) | Nota de 1 a 5 estrelas |

---

### 04 · Catálogo de Serviços

Define o portfólio de serviços que a agência oferece, com precificação padrão e possibilidade de preços negociados por cliente.

#### `categorias_servico`

Agrupamento dos serviços (ex: Identidade Visual, Campanha, Marketing Digital).

---

#### `servicos`

Catálogo completo de serviços com código único, unidade de medida e valor-padrão.

| Coluna | Tipo | Descrição |
|---|---|---|
| `codigo` | VARCHAR(20) UNIQUE | Código interno (ex: `RS001`, `VD002`) |
| `unidade` | ENUM | HORA / DIA / SEMANA / MES / UNIDADE / PACOTE / CAMPANHA |
| `valor_padrao` | DECIMAL(10,2) | Preço de tabela padrão |

---

#### `servicos_precos_cliente`

Permite definir preços negociados individualmente por cliente, com período de vigência (`valido_de` / `valido_ate`). Caso exista um preço específico para o cliente no período, ele sobrepõe o valor-padrão do catálogo.

---

### 05 · Contratos

Formaliza os acordos comerciais entre a agência e seus clientes.

#### `contratos`

| Coluna | Tipo | Descrição |
|---|---|---|
| `tipo` | ENUM | RETAINER (mensal recorrente) / PROJETO / AVULSO / LICENCA |
| `valor_mensal` | DECIMAL | Preenchido apenas para contratos do tipo RETAINER |
| `renovacao_automatica` | TINYINT(1) | Se o contrato renova automaticamente ao vencer |
| `prazo_aviso_dias` | INT | Dias de antecedência para notificar o vencimento |
| `status` | ENUM | RASCUNHO → AGUARDANDO_ASSINATURA → ATIVO → SUSPENSO / ENCERRADO / CANCELADO |

> **Constraint:** `data_fim` deve ser posterior a `data_inicio`.

---

#### `contratos_servicos`

Itens do contrato: lista de serviços acordados com quantidade, valor unitário e desconto. O `valor_total` de cada item é calculado automaticamente como coluna gerada:

```sql
valor_total = quantidade * valor_unitario * (1 - desconto_pct / 100)
```

---

#### `contratos_historico`

Toda alteração de status do contrato é registrada automaticamente pelo **Trigger RN04**, preservando o histórico completo de negociação.

---

### 06 · Briefings e Projetos

Gerencia o ciclo de vida completo dos projetos, desde o recebimento do briefing até a entrega.

#### `briefings`

Registro inicial das demandas dos clientes, com informações estratégicas como objetivo, público-alvo, concorrentes e orçamento máximo.

| Coluna | Tipo | Descrição |
|---|---|---|
| `status` | ENUM | RECEBIDO → EM_ANALISE → APROVADO / REPROVADO → CONVERTIDO |
| `convertido_em` | DATETIME | Data em que o briefing gerou um projeto (preenchido pelo Trigger RN01) |

---

#### `briefings_anexos`

Documentos, referências e arquivos enviados junto ao briefing (PDFs, imagens de referência, planilhas de concorrentes, etc.).

---

#### `projetos`

Unidade central de trabalho da agência. Um projeto pode originar de um briefing aprovado e estar vinculado a um contrato.

| Coluna | Tipo | Descrição |
|---|---|---|
| `codigo` | VARCHAR(30) UNIQUE | Código único do projeto (ex: `PRJ-2024-042`) |
| `tipo` | ENUM | CAMPANHA / IDENTIDADE_VISUAL / WEBSITE / MIDIA_SOCIAL / VIDEO / EVENTO / CONSULTORIA / OUTRO |
| `prioridade` | ENUM | BAIXA / MEDIA / ALTA / CRITICA |
| `status` | ENUM | BACKLOG → PLANEJAMENTO → EM_ANDAMENTO → PAUSADO → REVISAO → CONCLUIDO / CANCELADO |
| `percentual_conclusao` | TINYINT (0–100) | Calculado automaticamente com base nas tarefas concluídas |
| `orcamento_aprovado` | DECIMAL(14,2) | Verba aprovada para o projeto |
| `custo_real` | DECIMAL(14,2) | Custo real acumulado (atualizado pelo Trigger RN05) |

---

#### `projetos_equipe`

Tabela de associação N:M que define quais funcionários estão alocados em cada projeto, qual o papel de cada um e quantas horas foram estimadas para sua participação.

---

### 07 · Tarefas e Workflow

#### `etapas_workflow`

Define as etapas padrão do fluxo de trabalho da agência (Briefing → Planejamento → Conceito → Criação → Revisão Interna → Aprovação Cliente → Ajustes → Produção Final → Entrega → Pós-venda), permitindo padronizar o processo produtivo.

---

#### `tarefas`

Unidade mínima de trabalho. Suporta hierarquia de sub-tarefas via `tarefa_pai_id`.

| Coluna | Tipo | Descrição |
|---|---|---|
| `tipo` | ENUM | CRIACAO / REVISAO / APROVACAO / PRODUCAO / ENTREGA / REUNIAO / OUTRO |
| `status` | ENUM | ABERTA → EM_ANDAMENTO → AGUARDANDO_APROVACAO → APROVADA → REVISAO → CONCLUIDA / CANCELADA |
| `horas_estimadas` | DECIMAL(6,2) | Estimativa de horas para concluir |
| `horas_realizadas` | DECIMAL(6,2) | Horas efetivamente apontadas |

> **Regra (Trigger RN02):** Ao concluir uma tarefa, o campo `percentual_conclusao` do projeto pai é recalculado automaticamente.

---

#### `tarefas_comentarios`

Histórico de interações e feedbacks nas tarefas, diferenciando comentários simples de ações formais de revisão, aprovação ou reprovação.

---

#### `tarefas_anexos`

Arquivos vinculados às tarefas (layouts, criações, mockups). Cada arquivo possui controle de versão (`versao`) para rastrear evoluções.

---

#### `apontamentos_horas`

Registro das horas trabalhadas por funcionário em cada tarefa. Essencial para:
- Controle de produtividade e capacidade
- Faturamento de horas ao cliente (campo `faturavel`)
- Cálculo de custo real dos projetos

> **Regra (Trigger RN06):** O total de horas apontadas por um funcionário em um único dia não pode ultrapassar 24 horas.

---

### 08 · Campanhas de Mídia

Gerencia o planejamento, execução e mensuração de campanhas publicitárias.

#### `canais_midia`

Catálogo dos canais de veiculação disponíveis (Google Ads, Meta Ads, TV, Rádio, OOH, etc.), classificados como Digital, Offline ou Híbrido.

---

#### `campanhas_midia`

Campanha publicitária vinculada a um projeto. Controla a distribuição orçamentária entre verba de investimento (mídia pura) e verba de produção.

| Coluna | Tipo | Descrição |
|---|---|---|
| `objetivo` | ENUM | AWARENESS / CONSIDERACAO / CONVERSAO / RETENCAO / FIDELIZACAO |
| `taxa_agencia_pct` | DECIMAL(5,2) | Comissão de agência sobre a verba de mídia (padrão: 20%) |
| `verba_investimento` | DECIMAL | Valor destinado à veiculação (compra de mídia) |
| `verba_producao` | DECIMAL | Valor destinado à produção dos materiais |

---

#### `campanhas_veiculacoes`

Detalhamento da campanha por canal e por período. Cada linha representa uma compra de espaço em um veículo/plataforma específico.

---

#### `campanhas_metricas`

Resultado diário de cada veiculação. As métricas **CPM** (custo por mil impressões), **CPC** (custo por clique) e **CPA** (custo por aquisição) são calculadas automaticamente como colunas geradas:

```sql
cpm = (custo_real / impressoes) * 1000
cpc = custo_real / cliques
cpa = custo_real / conversoes
```

---

### 09 · Orçamentos e Propostas

#### `orcamentos`

Proposta comercial formal enviada ao cliente. Suporta versionamento (`versao` + `orcamento_pai_id`) para controlar revisões de preço e escopo.

| Coluna | Tipo | Descrição |
|---|---|---|
| `status` | ENUM | RASCUNHO → ENVIADO → EM_NEGOCIACAO → APROVADO / REPROVADO / EXPIRADO / CANCELADO |
| `validade_dias` | INT | Prazo de validade da proposta em dias |
| `desconto_geral_pct` | DECIMAL(5,2) | Desconto global aplicado sobre o subtotal |
| `versao` | INT | Número da versão (1, 2, 3...) |

> **Regra (Trigger RN01):** Ao aprovar um orçamento, o briefing vinculado é automaticamente marcado como `CONVERTIDO`.

---

#### `orcamentos_itens`

Itens detalhados da proposta com cálculo automático de `valor_total` por linha (coluna gerada). Permite vincular cada item a um serviço do catálogo ou descrever um item personalizado.

---

### 10 · Financeiro

Módulo completo de controle financeiro da agência.

#### `plano_contas`

Estrutura hierárquica de contas contábeis (auto-referência via `pai_id`). Classifica receitas, despesas, ativos, passivos e resultados.

---

#### `centros_custo`

Permite alocar receitas e despesas a departamentos ou projetos específicos, possibilitando análise de rentabilidade por unidade de negócio.

---

#### `contas_bancarias`

Contas bancárias da agência para controle de movimentações financeiras. O campo `saldo_atual` é atualizado conforme os pagamentos são registrados.

---

#### `notas_fiscais`

Notas Fiscais de Serviço (NFS-e) emitidas para os clientes. Cálculo automático do ISS como coluna gerada:

```sql
valor_iss = valor_servicos * aliquota_iss / 100
```

Controla também PIS, COFINS, IR e CSLL. O cancelamento é rastreado com data e motivo.

---

#### `contas_receber`

Títulos a receber de clientes. Suporta controle de parcelas (`parcela = "2/3"`), registro de pagamento parcial, multa, juros e desconto por pontualidade.

| `status` | Descrição |
|---|---|
| ABERTA | Dentro do prazo, sem pagamento |
| PARCIAL | Pago parcialmente |
| PAGA | Quitada integralmente |
| VENCIDA | Passou da data sem pagamento (inadimplência) |
| NEGOCIADA | Em processo de renegociação |

> **Regra (Trigger RN08):** O pagamento de contas atualiza automaticamente a classificação (tier) do cliente.

---

#### `contas_pagar`

Despesas e obrigações da agência com fornecedores e reembolsos a funcionários. Suporta aprovação prévia (`aprovado_por`) para controle de gastos.

---

### 11 · Aprovações

#### `aprovacoes`

Fluxo centralizado de aprovações internas para diferentes tipos de documentos e ações. O campo `tipo` identifica o que está sendo aprovado, e `referencia_id` aponta para o ID do registro específico na tabela correspondente.

| Tipo | Tabela Referenciada |
|---|---|
| ORCAMENTO | `orcamentos` |
| CAMPANHA | `campanhas_midia` |
| CRIACAO | `pecas_criativas` |
| COMPRA | `contas_pagar` |
| NOTA_FISCAL | `notas_fiscais` |
| HORAS | `apontamentos_horas` |

---

### 12 · Reuniões

#### `reunioes`

Agendamento e registro de reuniões internas e com clientes, com controle de pauta, ata e modalidade (presencial, virtual ou híbrida).

---

#### `reunioes_participantes`

Lista de presença das reuniões, incluindo tanto funcionários da agência quanto contatos externos dos clientes. Controla confirmação prévia e presença efetiva.

---

#### `reunioes_acoes`

Ações definidas na ata da reunião, com responsável e prazo. Permite o acompanhamento do follow-up das decisões tomadas.

---

### 13 · Produção Criativa

#### `pecas_criativas`

Registro de cada peça publicitária ou material criativo produzido. Controla o fluxo de aprovação desde a criação até a entrega final.

| `status` | Significado |
|---|---|
| CRIACAO | Em desenvolvimento pela equipe criativa |
| INTERNO_APROVACAO | Aguardando aprovação interna (diretor de arte, CD) |
| CLIENTE_REVISAO | Enviado ao cliente para revisão |
| CLIENTE_APROVADO | Aprovado pelo cliente |
| PRODUCAO | Em arte-final / produção técnica |
| FINALIZADO | Entregue |
| ARQUIVADO | Arquivado sem uso |

---

#### `pecas_versoes`

Histórico completo de versões de cada peça. Cada novo arquivo enviado gera uma nova versão, e o campo `versao_atual` em `pecas_criativas` é atualizado automaticamente pelo **Trigger RN07**.

---

### 14 · Avaliações e NPS

#### `avaliacoes_cliente`

Coleta de feedback dos clientes em diferentes momentos do relacionamento. Suporta metodologias NPS (Net Promoter Score), CSAT (Customer Satisfaction), avaliação de projeto e avaliação de atendimento — todas com nota de 0 a 10.

---

### 15 · Configurações e Auditoria

#### `configuracoes`

Tabela chave-valor para parâmetros globais do sistema (taxa de agência padrão, prazo de validade de orçamentos, alíquota de ISS, etc.). Permite ajustar comportamentos do sistema sem alteração de código.

---

#### `auditoria_log`

Log de todas as operações críticas no banco de dados (INSERT, UPDATE, DELETE). Armazena o estado anterior (`dados_antes` em JSON) e o estado posterior (`dados_depois` em JSON) para rastreabilidade completa.

---

## Regras de Negócio — Triggers

| # | Trigger | Evento | Regra Implementada |
|---|---|---|---|
| RN01 | `trg_orcamento_aprovado` | AFTER UPDATE em `orcamentos` | Ao aprovar um orçamento, registra `aprovado_em` e marca o briefing vinculado como `CONVERTIDO` |
| RN02 | `trg_tarefa_concluida` | AFTER UPDATE em `tarefas` | Ao concluir uma tarefa, recalcula automaticamente o `percentual_conclusao` do projeto |
| RN03 | `trg_bloquear_exclusao_cliente` | BEFORE DELETE em `clientes` | Impede a exclusão de clientes com projetos ou contratos ativos |
| RN04 | `trg_contrato_status_historico` | AFTER UPDATE em `contratos` | Registra automaticamente toda mudança de status no histórico do contrato |
| RN05 | `trg_atualizar_custo_projeto` | AFTER UPDATE em `contas_pagar` | Ao quitar uma conta a pagar, recalcula o `custo_real` do projeto vinculado |
| RN06 | `trg_validar_horas_diarias` | BEFORE INSERT em `apontamentos_horas` | Valida que o total de horas apontadas por um funcionário em um dia não ultrapasse 24h |
| RN07 | `trg_incrementar_versao_peca` | AFTER INSERT em `pecas_versoes` | Ao adicionar uma nova versão de arquivo, atualiza `versao_atual` na peça criativa |
| RN08 | `trg_classificar_cliente` | AFTER UPDATE em `contas_receber` | Ao registrar um pagamento, recalcula e atualiza a classificação (tier) do cliente |

---

## Views Gerenciais

| View | Descrição |
|---|---|
| `vw_projetos_resumo` | Consolidado de todos os projetos com dados financeiros, progresso, horas apontadas e contagem de tarefas por status |
| `vw_fluxo_caixa` | União de contas a receber e contas a pagar ordenadas por data, para análise de fluxo de caixa |
| `vw_campanhas_performance` | Performance consolidada das campanhas de mídia com CPM, CPC e CPA médios calculados |
| `vw_ocupacao_funcionarios` | Mapa de ocupação dos colaboradores: projetos ativos, horas alocadas vs. horas contratadas |
| `vw_inadimplencia` | Listagem de títulos vencidos e não pagos, com número de dias em atraso — ordenada dos mais antigos para os mais recentes |

**Exemplo de uso:**

```sql
-- Projetos em andamento com orçamento comprometido acima de 80%
SELECT projeto, cliente, orcamento_aprovado, custo_real,
       ROUND((custo_real / orcamento_aprovado) * 100, 1) AS comprometimento_pct
FROM vw_projetos_resumo
WHERE status = 'EM_ANDAMENTO'
  AND custo_real / orcamento_aprovado >= 0.8
ORDER BY comprometimento_pct DESC;

-- Clientes inadimplentes há mais de 30 dias
SELECT cliente, classificacao, saldo_devedor, dias_atraso
FROM vw_inadimplencia
WHERE dias_atraso > 30
ORDER BY saldo_devedor DESC;
```

---

## Stored Procedures

### `sp_gerar_parcelas_contrato`

Gera automaticamente as parcelas a receber de um contrato parcelado.

```sql
CALL sp_gerar_parcelas_contrato(
    p_contrato_id    => 1,    -- ID do contrato
    p_num_parcelas   => 12,   -- Quantidade de parcelas
    p_dia_vencimento => 10    -- Dia de vencimento (ex: todo dia 10)
);
```

**Comportamento:** Calcula o valor de cada parcela (`valor_total / num_parcelas`), determina a data de vencimento respeitando o último dia do mês (ex: fevereiro não gera dia 31), e insere os registros em `contas_receber` com o label de parcela (`1/12`, `2/12`, etc.).

---

### `sp_clonar_projeto`

Cria um novo projeto com a mesma estrutura de um projeto existente (descrição, tipo, orçamento e duração), útil para projetos recorrentes ou campanhas similares.

```sql
CALL sp_clonar_projeto(
    p_projeto_origem_id => 5,
    p_novo_codigo       => 'PRJ-2024-088',
    p_novo_nome         => 'Campanha Verão 2025',
    p_cliente_id        => 3,
    p_gerente_id        => 12,
    p_data_inicio       => '2024-11-01',
    @novo_id            -- OUT: retorna o ID do novo projeto
);
```

---

### `sp_rentabilidade_cliente`

Relatório de rentabilidade por cliente em um determinado ano, calculando receita total, custo total, lucro bruto e margem percentual.

```sql
CALL sp_rentabilidade_cliente(2024);
```

**Retorna:** `id`, `razao_social`, `classificacao`, `total_projetos`, `receita_total`, `custo_total`, `lucro_bruto`, `margem_pct` — ordenado por receita decrescente.

---

## Índices de Performance

Além das chaves primárias e estrangeiras (que geram índices automaticamente), foram criados índices adicionais para as consultas mais frequentes:

| Índice | Tabela | Coluna(s) | Justificativa |
|---|---|---|---|
| `idx_func_status` | `funcionarios` | `status` | Filtrar funcionários ativos |
| `idx_func_departamento` | `funcionarios` | `departamento_id` | Consultas por departamento |
| `idx_cli_status` | `clientes` | `ativo` | Filtrar carteira ativa |
| `idx_cli_classificacao` | `clientes` | `classificacao` | Segmentar por tier |
| `idx_proj_status` | `projetos` | `status` | Dashboard de projetos |
| `idx_proj_cliente` | `projetos` | `cliente_id` | Projetos por cliente |
| `idx_proj_datas` | `projetos` | `data_inicio`, `data_prazo` | Filtros de período |
| `idx_tar_status` | `tarefas` | `status` | Kanban / board de tarefas |
| `idx_tar_responsavel` | `tarefas` | `responsavel_id` | "Minhas tarefas" do colaborador |
| `idx_tar_prazo` | `tarefas` | `data_prazo` | Alertas de prazo |
| `idx_cr_status` | `contas_receber` | `status` | Filtro financeiro |
| `idx_cr_vencimento` | `contas_receber` | `data_vencimento` | Alertas de vencimento |
| `idx_ah_func_data` | `apontamentos_horas` | `funcionario_id`, `data` | Timesheet por dia |

---

## Dados Iniciais (Seed)

O script inclui dados de domínio prontos para uso em produção:

| Tabela | Registros | Conteúdo |
|---|---|---|
| `departamentos` | 10 | Atendimento, Criação, Mídia, Planejamento, Produção, Financeiro, TI, Comercial, RH, Direção |
| `cargos` | 16 | Do Estagiário ao Sócio, com salários-base de referência |
| `segmentos_mercado` | 12 | Varejo, Tecnologia, Saúde, Educação, entre outros |
| `categorias_servico` | 12 | Identidade Visual, Campanha, Redes Sociais, Vídeo, etc. |
| `servicos` | 20 | Serviços completos com código, unidade e valor-padrão |
| `canais_midia` | 14 | Google, Meta, YouTube, LinkedIn, TikTok, TV, Rádio, OOH, etc. |
| `etapas_workflow` | 10 | Fluxo completo: Briefing → Pós-venda |
| `configuracoes` | 7 | Parâmetros operacionais do sistema |

---

## Fluxos Principais do Sistema

### Fluxo Comercial Completo

```
Contato do Cliente
       │
       ▼
  [briefings] ──► status: RECEBIDO
       │
       ▼
  Análise interna
       │
       ▼
  [orcamentos] ──► status: RASCUNHO → ENVIADO → EM_NEGOCIACAO
       │
       ├── Reprovado ──► fim
       │
       └── Aprovado ──► (Trigger RN01 atualiza briefing para CONVERTIDO)
               │
               ▼
          [contratos] ──► status: ATIVO
               │
               ▼
          [projetos] ──► status: PLANEJAMENTO → EM_ANDAMENTO → CONCLUIDO
```

---

### Fluxo de Produção de uma Peça

```
[projetos]
    │
    ▼
[tarefas] ──► tipo: CRIACAO ──► status: EM_ANDAMENTO
    │               │
    │          [apontamentos_horas] (colaborador registra horas)
    │               │
    ▼               │
[pecas_criativas] ◄─┘
    │
    ├── versão 1 ──► [pecas_versoes] (Trigger RN07 atualiza versao_atual)
    │
    ├── status: INTERNO_APROVACAO ──► [aprovacoes] (aprovador interno)
    │
    ├── status: CLIENTE_REVISAO ──► cliente avalia
    │
    ├── Reprovado ──► status: CRIACAO (nova iteração + nova versão)
    │
    └── Aprovado ──► status: CLIENTE_APROVADO → PRODUCAO → FINALIZADO
```

---

### Fluxo Financeiro

```
Projeto concluído / marco atingido
       │
       ▼
  [notas_fiscais] ──► status: EMITIDA
       │
       ▼
  [contas_receber] ──► status: ABERTA
       │
       ├── Pagamento recebido ──► status: PAGA
       │        │
       │        └── (Trigger RN08 atualiza classificação do cliente)
       │
       └── Data vencida sem pagamento ──► status: VENCIDA
                │                          (aparece na vw_inadimplencia)
                └── Negociação ──► status: NEGOCIADA
```

---

## Convenções de Nomenclatura

| Elemento | Convenção | Exemplo |
|---|---|---|
| Tabelas | `snake_case`, plural | `projetos_equipe` |
| Colunas | `snake_case` | `data_vencimento` |
| Chaves primárias | `id` | `id` |
| Chaves estrangeiras | `{tabela_ref}_id` | `cliente_id` |
| Constraints FK | `fk_{tabela_origem}_{referencia}` | `fk_proj_cliente` |
| Constraints UNIQUE | `uq_{tabela}_{campo}` | `uq_cliente_cnpj` |
| Constraints CHECK | `chk_{tabela}_{descricao}` | `chk_proj_datas` |
| Triggers | `trg_{descricao_acao}` | `trg_tarefa_concluida` |
| Views | `vw_{descricao}` | `vw_fluxo_caixa` |
| Stored Procedures | `sp_{descricao}` | `sp_gerar_parcelas_contrato` |
| Índices adicionais | `idx_{tabela}_{campo}` | `idx_tar_prazo` |
| ENUMs | `MAIUSCULO_UNDERSCORE` | `'EM_ANDAMENTO'` |

---

> **Autor:** Modelagem gerada para sistema de gestão de Agência de Publicidade e Marketing  
> **Engine:** MySQL 8.0+ com InnoDB  
> **Versão:** 1.0.0
