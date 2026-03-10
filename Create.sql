-- =============================================================================
-- SISTEMA DE AGÊNCIA DE PUBLICIDADE E MARKETING
-- Modelagem Completa MySQL com Todas as Regras de Negócio
-- Versão: 1.0
-- =============================================================================

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DROP DATABASE IF EXISTS agencia_marketing;
CREATE DATABASE agencia_marketing CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE agencia_marketing;

-- =============================================================================
-- 1. ESTRUTURA ORGANIZACIONAL
-- =============================================================================

-- Departamentos da agência
CREATE TABLE departamentos (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(100) NOT NULL,
    descricao       TEXT,
    ativo           TINYINT(1) NOT NULL DEFAULT 1,
    criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_departamento_nome UNIQUE (nome)
) ENGINE=InnoDB COMMENT='Departamentos da agência';

-- Cargos / Funções
CREATE TABLE cargos (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(100) NOT NULL,
    nivel           ENUM('ESTAGIARIO','JUNIOR','PLENO','SENIOR','ESPECIALISTA','GERENTE','DIRETOR','SOCIO') NOT NULL,
    salario_base    DECIMAL(10,2) NOT NULL CHECK (salario_base >= 0),
    descricao       TEXT,
    ativo           TINYINT(1) NOT NULL DEFAULT 1,
    criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Cargos e níveis da agência';

-- Funcionários
CREATE TABLE funcionarios (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    departamento_id     INT UNSIGNED NOT NULL,
    cargo_id            INT UNSIGNED NOT NULL,
    gestor_id           INT UNSIGNED NULL COMMENT 'Auto-referência para hierarquia',
    nome                VARCHAR(150) NOT NULL,
    sobrenome           VARCHAR(150) NOT NULL,
    cpf                 CHAR(11) NOT NULL,
    email               VARCHAR(150) NOT NULL,
    email_corporativo   VARCHAR(150) NOT NULL,
    telefone            VARCHAR(20),
    data_nascimento     DATE NOT NULL,
    data_admissao       DATE NOT NULL,
    data_demissao       DATE NULL,
    salario             DECIMAL(10,2) NOT NULL CHECK (salario >= 0),
    carga_horaria       INT NOT NULL DEFAULT 40 COMMENT 'Horas semanais',
    status              ENUM('ATIVO','FERIAS','AFASTADO','DEMITIDO') NOT NULL DEFAULT 'ATIVO',
    foto_url            VARCHAR(500),
    criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_funcionario_cpf   UNIQUE (cpf),
    CONSTRAINT uq_funcionario_email UNIQUE (email_corporativo),
    CONSTRAINT fk_func_departamento FOREIGN KEY (departamento_id) REFERENCES departamentos(id),
    CONSTRAINT fk_func_cargo        FOREIGN KEY (cargo_id)        REFERENCES cargos(id),
    CONSTRAINT fk_func_gestor       FOREIGN KEY (gestor_id)       REFERENCES funcionarios(id)
) ENGINE=InnoDB COMMENT='Colaboradores da agência';

-- =============================================================================
-- 2. CLIENTES
-- =============================================================================

-- Segmentos de mercado
CREATE TABLE segmentos_mercado (
    id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome    VARCHAR(100) NOT NULL,
    CONSTRAINT uq_segmento UNIQUE (nome)
) ENGINE=InnoDB;

-- Clientes (empresas contratantes)
CREATE TABLE clientes (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    segmento_id         INT UNSIGNED NOT NULL,
    responsavel_id      INT UNSIGNED NOT NULL COMMENT 'Executivo de conta responsável',
    razao_social        VARCHAR(200) NOT NULL,
    nome_fantasia       VARCHAR(200),
    cnpj                CHAR(14) NOT NULL,
    inscricao_estadual  VARCHAR(30),
    email               VARCHAR(150) NOT NULL,
    telefone            VARCHAR(20),
    website             VARCHAR(300),
    logo_url            VARCHAR(500),
    data_inicio         DATE NOT NULL COMMENT 'Início do relacionamento',
    data_fim            DATE NULL    COMMENT 'Encerramento (NULL = ativo)',
    classificacao       ENUM('BRONZE','PRATA','OURO','PLATINA','DIAMANTE') NOT NULL DEFAULT 'BRONZE' COMMENT 'Tier do cliente por faturamento/potencial',
    limite_credito      DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    observacoes         TEXT,
    ativo               TINYINT(1) NOT NULL DEFAULT 1,
    criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_cliente_cnpj  UNIQUE (cnpj),
    CONSTRAINT fk_cli_segmento  FOREIGN KEY (segmento_id)    REFERENCES segmentos_mercado(id),
    CONSTRAINT fk_cli_resp      FOREIGN KEY (responsavel_id) REFERENCES funcionarios(id)
) ENGINE=InnoDB COMMENT='Empresas clientes da agência';

-- Endereços dos clientes
CREATE TABLE clientes_enderecos (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cliente_id  INT UNSIGNED NOT NULL,
    tipo        ENUM('FATURAMENTO','ENTREGA','COMERCIAL') NOT NULL DEFAULT 'COMERCIAL',
    logradouro  VARCHAR(200) NOT NULL,
    numero      VARCHAR(20),
    complemento VARCHAR(100),
    bairro      VARCHAR(100),
    cidade      VARCHAR(100) NOT NULL,
    estado      CHAR(2) NOT NULL,
    cep         CHAR(8) NOT NULL,
    pais        CHAR(2) NOT NULL DEFAULT 'BR',
    principal   TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_end_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Contatos dos clientes
CREATE TABLE clientes_contatos (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cliente_id  INT UNSIGNED NOT NULL,
    nome        VARCHAR(150) NOT NULL,
    cargo       VARCHAR(100),
    email       VARCHAR(150),
    telefone    VARCHAR(20),
    whatsapp    VARCHAR(20),
    decisor     TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'É tomador de decisão?',
    ativo       TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_contato_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Pessoas de contato nos clientes';

-- =============================================================================
-- 3. FORNECEDORES E PARCEIROS
-- =============================================================================

CREATE TABLE fornecedores (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    razao_social    VARCHAR(200) NOT NULL,
    nome_fantasia   VARCHAR(200),
    cnpj_cpf        VARCHAR(14) NOT NULL,
    tipo_pessoa     ENUM('FISICA','JURIDICA') NOT NULL DEFAULT 'JURIDICA',
    categoria       ENUM('GRAFICA','PRODUCAO','MIDIA','FOTOGRAFIA','VIDEO','TI','OUTRO') NOT NULL,
    email           VARCHAR(150),
    telefone        VARCHAR(20),
    website         VARCHAR(300),
    avaliacao       TINYINT(1) DEFAULT NULL CHECK (avaliacao BETWEEN 1 AND 5),
    ativo           TINYINT(1) NOT NULL DEFAULT 1,
    criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_fornecedor_doc UNIQUE (cnpj_cpf)
) ENGINE=InnoDB COMMENT='Fornecedores e parceiros externos';

-- =============================================================================
-- 4. SERVIÇOS DA AGÊNCIA
-- =============================================================================

CREATE TABLE categorias_servico (
    id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome    VARCHAR(100) NOT NULL,
    CONSTRAINT uq_cat_servico UNIQUE (nome)
) ENGINE=InnoDB;

CREATE TABLE servicos (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    categoria_id    INT UNSIGNED NOT NULL,
    codigo          VARCHAR(20) NOT NULL,
    nome            VARCHAR(150) NOT NULL,
    descricao       TEXT,
    unidade         ENUM('HORA','DIA','SEMANA','MES','UNIDADE','PACOTE','CAMPANHA') NOT NULL DEFAULT 'HORA',
    valor_padrao    DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (valor_padrao >= 0),
    ativo           TINYINT(1) NOT NULL DEFAULT 1,
    criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_servico_codigo UNIQUE (codigo),
    CONSTRAINT fk_serv_categoria FOREIGN KEY (categoria_id) REFERENCES categorias_servico(id)
) ENGINE=InnoDB COMMENT='Catálogo de serviços oferecidos pela agência';

-- Tabela de preços por cliente (permite preço negociado)
CREATE TABLE servicos_precos_cliente (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    servico_id  INT UNSIGNED NOT NULL,
    cliente_id  INT UNSIGNED NOT NULL,
    valor       DECIMAL(10,2) NOT NULL CHECK (valor >= 0),
    valido_de   DATE NOT NULL,
    valido_ate  DATE NULL,
    CONSTRAINT uq_preco_servico_cliente UNIQUE (servico_id, cliente_id, valido_de),
    CONSTRAINT fk_preco_servico FOREIGN KEY (servico_id) REFERENCES servicos(id),
    CONSTRAINT fk_preco_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id)
) ENGINE=InnoDB COMMENT='Preços negociados por cliente';

-- =============================================================================
-- 5. CONTRATOS
-- =============================================================================

CREATE TABLE contratos (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cliente_id          INT UNSIGNED NOT NULL,
    executivo_conta_id  INT UNSIGNED NOT NULL,
    numero              VARCHAR(30) NOT NULL,
    tipo                ENUM('RETAINER','PROJETO','AVULSO','LICENCA') NOT NULL,
    descricao           TEXT,
    valor_total         DECIMAL(14,2) NOT NULL CHECK (valor_total >= 0),
    valor_mensal        DECIMAL(14,2) NULL COMMENT 'Para contratos retainer',
    data_inicio         DATE NOT NULL,
    data_fim            DATE NULL,
    renovacao_automatica TINYINT(1) NOT NULL DEFAULT 0,
    prazo_aviso_dias    INT DEFAULT 30 COMMENT 'Dias de aviso antes do vencimento',
    status              ENUM('RASCUNHO','AGUARDANDO_ASSINATURA','ATIVO','SUSPENSO','ENCERRADO','CANCELADO') NOT NULL DEFAULT 'RASCUNHO',
    assinado_em         DATETIME NULL,
    arquivo_url         VARCHAR(500),
    observacoes         TEXT,
    criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_contrato_numero UNIQUE (numero),
    CONSTRAINT fk_cont_cliente  FOREIGN KEY (cliente_id)         REFERENCES clientes(id),
    CONSTRAINT fk_cont_exec     FOREIGN KEY (executivo_conta_id) REFERENCES funcionarios(id),
    CONSTRAINT chk_contrato_datas CHECK (data_fim IS NULL OR data_fim > data_inicio)
) ENGINE=InnoDB COMMENT='Contratos com clientes';

-- Serviços incluídos em cada contrato
CREATE TABLE contratos_servicos (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    contrato_id     INT UNSIGNED NOT NULL,
    servico_id      INT UNSIGNED NOT NULL,
    quantidade      DECIMAL(10,2) NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    valor_unitario  DECIMAL(10,2) NOT NULL CHECK (valor_unitario >= 0),
    desconto_pct    DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (desconto_pct BETWEEN 0 AND 100),
    valor_total     DECIMAL(14,2) GENERATED ALWAYS AS (quantidade * valor_unitario * (1 - desconto_pct/100)) STORED,
    CONSTRAINT uq_cont_serv UNIQUE (contrato_id, servico_id),
    CONSTRAINT fk_cs_contrato FOREIGN KEY (contrato_id) REFERENCES contratos(id) ON DELETE CASCADE,
    CONSTRAINT fk_cs_servico  FOREIGN KEY (servico_id)  REFERENCES servicos(id)
) ENGINE=InnoDB;

-- Histórico de alterações de status do contrato
CREATE TABLE contratos_historico (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    contrato_id     INT UNSIGNED NOT NULL,
    funcionario_id  INT UNSIGNED NOT NULL,
    status_anterior ENUM('RASCUNHO','AGUARDANDO_ASSINATURA','ATIVO','SUSPENSO','ENCERRADO','CANCELADO'),
    status_novo     ENUM('RASCUNHO','AGUARDANDO_ASSINATURA','ATIVO','SUSPENSO','ENCERRADO','CANCELADO') NOT NULL,
    motivo          TEXT,
    registrado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ch_contrato    FOREIGN KEY (contrato_id)    REFERENCES contratos(id),
    CONSTRAINT fk_ch_funcionario FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id)
) ENGINE=InnoDB;

-- =============================================================================
-- 6. BRIEFINGS E PROJETOS
-- =============================================================================

CREATE TABLE briefings (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cliente_id      INT UNSIGNED NOT NULL,
    contato_id      INT UNSIGNED NULL,
    criado_por      INT UNSIGNED NOT NULL COMMENT 'Funcionário que registrou',
    titulo          VARCHAR(200) NOT NULL,
    descricao       TEXT NOT NULL,
    objetivo        TEXT COMMENT 'Objetivo de marketing/comunicação',
    publico_alvo    TEXT,
    concorrentes    TEXT,
    orcamento_max   DECIMAL(14,2) NULL,
    prazo_desejado  DATE NULL,
    status          ENUM('RECEBIDO','EM_ANALISE','APROVADO','REPROVADO','CONVERTIDO') NOT NULL DEFAULT 'RECEBIDO',
    convertido_em   DATETIME NULL COMMENT 'Data de conversão em projeto',
    criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_brief_cliente  FOREIGN KEY (cliente_id)  REFERENCES clientes(id),
    CONSTRAINT fk_brief_contato  FOREIGN KEY (contato_id)  REFERENCES clientes_contatos(id),
    CONSTRAINT fk_brief_criador  FOREIGN KEY (criado_por)  REFERENCES funcionarios(id)
) ENGINE=InnoDB COMMENT='Briefings recebidos dos clientes';

-- Anexos do briefing
CREATE TABLE briefings_anexos (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    briefing_id INT UNSIGNED NOT NULL,
    nome        VARCHAR(200) NOT NULL,
    url         VARCHAR(500) NOT NULL,
    tipo_mime   VARCHAR(100),
    tamanho_kb  INT,
    criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ba_briefing FOREIGN KEY (briefing_id) REFERENCES briefings(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Projetos
CREATE TABLE projetos (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cliente_id          INT UNSIGNED NOT NULL,
    contrato_id         INT UNSIGNED NULL,
    briefing_id         INT UNSIGNED NULL,
    gerente_projeto_id  INT UNSIGNED NOT NULL,
    codigo              VARCHAR(30) NOT NULL,
    nome                VARCHAR(200) NOT NULL,
    descricao           TEXT,
    tipo                ENUM('CAMPANHA','IDENTIDADE_VISUAL','WEBSITE','MIDIA_SOCIAL','VIDEO','EVENTO','CONSULTORIA','OUTRO') NOT NULL,
    data_inicio         DATE NOT NULL,
    data_prazo          DATE NOT NULL,
    data_conclusao      DATE NULL,
    orcamento_aprovado  DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    custo_real          DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    prioridade          ENUM('BAIXA','MEDIA','ALTA','CRITICA') NOT NULL DEFAULT 'MEDIA',
    status              ENUM('BACKLOG','PLANEJAMENTO','EM_ANDAMENTO','PAUSADO','REVISAO','CONCLUIDO','CANCELADO') NOT NULL DEFAULT 'BACKLOG',
    percentual_conclusao TINYINT UNSIGNED NOT NULL DEFAULT 0 CHECK (percentual_conclusao <= 100),
    observacoes         TEXT,
    criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_projeto_codigo    UNIQUE (codigo),
    CONSTRAINT fk_proj_cliente      FOREIGN KEY (cliente_id)         REFERENCES clientes(id),
    CONSTRAINT fk_proj_contrato     FOREIGN KEY (contrato_id)        REFERENCES contratos(id),
    CONSTRAINT fk_proj_briefing     FOREIGN KEY (briefing_id)        REFERENCES briefings(id),
    CONSTRAINT fk_proj_gerente      FOREIGN KEY (gerente_projeto_id) REFERENCES funcionarios(id),
    CONSTRAINT chk_proj_datas       CHECK (data_prazo >= data_inicio)
) ENGINE=InnoDB COMMENT='Projetos em execução';

-- Equipe do projeto (membros alocados)
CREATE TABLE projetos_equipe (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    projeto_id      INT UNSIGNED NOT NULL,
    funcionario_id  INT UNSIGNED NOT NULL,
    papel           VARCHAR(100) NOT NULL COMMENT 'Ex: Diretor de Arte, Redator, Desenvolvedor',
    horas_alocadas  DECIMAL(8,2) NOT NULL DEFAULT 0.00 CHECK (horas_alocadas >= 0),
    data_entrada    DATE NOT NULL,
    data_saida      DATE NULL,
    CONSTRAINT uq_proj_func UNIQUE (projeto_id, funcionario_id),
    CONSTRAINT fk_pe_projeto     FOREIGN KEY (projeto_id)     REFERENCES projetos(id) ON DELETE CASCADE,
    CONSTRAINT fk_pe_funcionario FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id)
) ENGINE=InnoDB COMMENT='Equipe alocada em cada projeto';

-- =============================================================================
-- 7. TAREFAS E WORKFLOW
-- =============================================================================

CREATE TABLE etapas_workflow (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    descricao   TEXT,
    ordem       INT NOT NULL,
    CONSTRAINT uq_etapa_ordem UNIQUE (ordem)
) ENGINE=InnoDB COMMENT='Etapas padrão do fluxo de trabalho';

CREATE TABLE tarefas (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    projeto_id          INT UNSIGNED NOT NULL,
    etapa_id            INT UNSIGNED NULL,
    tarefa_pai_id       INT UNSIGNED NULL COMMENT 'Sub-tarefas',
    responsavel_id      INT UNSIGNED NOT NULL,
    titulo              VARCHAR(300) NOT NULL,
    descricao           TEXT,
    tipo                ENUM('CRIACAO','REVISAO','APROVACAO','PRODUCAO','ENTREGA','REUNIAO','OUTRO') NOT NULL DEFAULT 'CRIACAO',
    prioridade          ENUM('BAIXA','MEDIA','ALTA','CRITICA') NOT NULL DEFAULT 'MEDIA',
    status              ENUM('ABERTA','EM_ANDAMENTO','AGUARDANDO_APROVACAO','APROVADA','REVISAO','CONCLUIDA','CANCELADA') NOT NULL DEFAULT 'ABERTA',
    horas_estimadas     DECIMAL(6,2) NOT NULL DEFAULT 0.00 CHECK (horas_estimadas >= 0),
    horas_realizadas    DECIMAL(6,2) NOT NULL DEFAULT 0.00 CHECK (horas_realizadas >= 0),
    data_inicio         DATE,
    data_prazo          DATE NOT NULL,
    data_conclusao      DATE NULL,
    criado_por          INT UNSIGNED NOT NULL,
    criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_tar_projeto     FOREIGN KEY (projeto_id)     REFERENCES projetos(id) ON DELETE CASCADE,
    CONSTRAINT fk_tar_etapa       FOREIGN KEY (etapa_id)       REFERENCES etapas_workflow(id),
    CONSTRAINT fk_tar_pai         FOREIGN KEY (tarefa_pai_id)  REFERENCES tarefas(id),
    CONSTRAINT fk_tar_resp        FOREIGN KEY (responsavel_id) REFERENCES funcionarios(id),
    CONSTRAINT fk_tar_criador     FOREIGN KEY (criado_por)     REFERENCES funcionarios(id)
) ENGINE=InnoDB COMMENT='Tarefas dos projetos';

-- Comentários e revisões nas tarefas
CREATE TABLE tarefas_comentarios (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tarefa_id       INT UNSIGNED NOT NULL,
    funcionario_id  INT UNSIGNED NOT NULL,
    comentario      TEXT NOT NULL,
    tipo            ENUM('COMENTARIO','REVISAO','APROVACAO','REPROVACAO') NOT NULL DEFAULT 'COMENTARIO',
    criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tc_tarefa      FOREIGN KEY (tarefa_id)      REFERENCES tarefas(id) ON DELETE CASCADE,
    CONSTRAINT fk_tc_funcionario FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id)
) ENGINE=InnoDB;

-- Anexos das tarefas (criações, layouts, arquivos)
CREATE TABLE tarefas_anexos (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tarefa_id   INT UNSIGNED NOT NULL,
    nome        VARCHAR(200) NOT NULL,
    url         VARCHAR(500) NOT NULL,
    tipo_mime   VARCHAR(100),
    tamanho_kb  INT,
    versao      VARCHAR(20) NOT NULL DEFAULT 'v1',
    criado_por  INT UNSIGNED NOT NULL,
    criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ta_tarefa   FOREIGN KEY (tarefa_id)  REFERENCES tarefas(id) ON DELETE CASCADE,
    CONSTRAINT fk_ta_criador  FOREIGN KEY (criado_por) REFERENCES funcionarios(id)
) ENGINE=InnoDB;

-- Apontamento de horas
CREATE TABLE apontamentos_horas (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tarefa_id       INT UNSIGNED NOT NULL,
    funcionario_id  INT UNSIGNED NOT NULL,
    data            DATE NOT NULL,
    horas           DECIMAL(5,2) NOT NULL CHECK (horas > 0 AND horas <= 24),
    descricao       TEXT,
    faturavel       TINYINT(1) NOT NULL DEFAULT 1,
    aprovado        TINYINT(1) NOT NULL DEFAULT 0,
    aprovado_por    INT UNSIGNED NULL,
    criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ah_tarefa      FOREIGN KEY (tarefa_id)      REFERENCES tarefas(id),
    CONSTRAINT fk_ah_funcionario FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id),
    CONSTRAINT fk_ah_aprovador   FOREIGN KEY (aprovado_por)   REFERENCES funcionarios(id)
) ENGINE=InnoDB COMMENT='Controle de horas trabalhadas por tarefa';

-- =============================================================================
-- 8. CAMPANHAS DE MÍDIA
-- =============================================================================

CREATE TABLE canais_midia (
    id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome    VARCHAR(100) NOT NULL COMMENT 'Ex: Google Ads, Meta Ads, TV, Rádio, OOH',
    tipo    ENUM('DIGITAL','OFFLINE','HIBRIDO') NOT NULL DEFAULT 'DIGITAL',
    ativo   TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT uq_canal_nome UNIQUE (nome)
) ENGINE=InnoDB;

CREATE TABLE campanhas_midia (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    projeto_id          INT UNSIGNED NOT NULL,
    responsavel_id      INT UNSIGNED NOT NULL COMMENT 'Gestor de mídia',
    nome                VARCHAR(200) NOT NULL,
    objetivo            ENUM('AWARENESS','CONSIDERACAO','CONVERSAO','RETENCAO','FIDELIZACAO') NOT NULL,
    publico_alvo        TEXT,
    orcamento_total     DECIMAL(14,2) NOT NULL CHECK (orcamento_total >= 0),
    verba_investimento  DECIMAL(14,2) NOT NULL DEFAULT 0.00 COMMENT 'Verba pura para veiculação',
    verba_producao      DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    taxa_agencia_pct    DECIMAL(5,2) NOT NULL DEFAULT 20.00 COMMENT 'Comissão padrão de agência (%)',
    data_inicio         DATE NOT NULL,
    data_fim            DATE NOT NULL,
    status              ENUM('PLANEJAMENTO','APROVADA','ATIVA','PAUSADA','ENCERRADA','CANCELADA') NOT NULL DEFAULT 'PLANEJAMENTO',
    criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_cm_projeto     FOREIGN KEY (projeto_id)     REFERENCES projetos(id),
    CONSTRAINT fk_cm_responsavel FOREIGN KEY (responsavel_id) REFERENCES funcionarios(id),
    CONSTRAINT chk_camp_datas    CHECK (data_fim > data_inicio)
) ENGINE=InnoDB COMMENT='Campanhas de mídia vinculadas a projetos';

-- Veiculação por canal
CREATE TABLE campanhas_veiculacoes (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    campanha_id     INT UNSIGNED NOT NULL,
    canal_id        INT UNSIGNED NOT NULL,
    fornecedor_id   INT UNSIGNED NULL COMMENT 'Veículo/plataforma',
    descricao       VARCHAR(300),
    investimento    DECIMAL(12,2) NOT NULL CHECK (investimento >= 0),
    impressoes_meta BIGINT DEFAULT NULL,
    cliques_meta    INT DEFAULT NULL,
    data_inicio     DATE NOT NULL,
    data_fim        DATE NOT NULL,
    status          ENUM('PLANEJADO','ATIVO','PAUSADO','CONCLUIDO','CANCELADO') NOT NULL DEFAULT 'PLANEJADO',
    CONSTRAINT fk_cv_campanha   FOREIGN KEY (campanha_id)  REFERENCES campanhas_midia(id) ON DELETE CASCADE,
    CONSTRAINT fk_cv_canal      FOREIGN KEY (canal_id)     REFERENCES canais_midia(id),
    CONSTRAINT fk_cv_fornecedor FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id)
) ENGINE=InnoDB;

-- Métricas/resultados de campanhas
CREATE TABLE campanhas_metricas (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    veiculacao_id   INT UNSIGNED NOT NULL,
    data_referencia DATE NOT NULL,
    impressoes      BIGINT NOT NULL DEFAULT 0,
    alcance         BIGINT NOT NULL DEFAULT 0,
    cliques         INT NOT NULL DEFAULT 0,
    conversoes      INT NOT NULL DEFAULT 0,
    custo_real      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    cpm             DECIMAL(8,4) GENERATED ALWAYS AS (IF(impressoes > 0, (custo_real / impressoes) * 1000, 0)) STORED COMMENT 'Custo por mil impressões',
    cpc             DECIMAL(8,4) GENERATED ALWAYS AS (IF(cliques > 0, custo_real / cliques, 0)) STORED COMMENT 'Custo por clique',
    cpa             DECIMAL(10,4) GENERATED ALWAYS AS (IF(conversoes > 0, custo_real / conversoes, 0)) STORED COMMENT 'Custo por aquisição',
    criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_metrica_veic_data UNIQUE (veiculacao_id, data_referencia),
    CONSTRAINT fk_met_veiculacao FOREIGN KEY (veiculacao_id) REFERENCES campanhas_veiculacoes(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Métricas de performance de campanhas';

-- =============================================================================
-- 9. ORÇAMENTOS E PROPOSTAS COMERCIAIS
-- =============================================================================

CREATE TABLE orcamentos (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cliente_id          INT UNSIGNED NOT NULL,
    briefing_id         INT UNSIGNED NULL,
    criado_por          INT UNSIGNED NOT NULL,
    numero              VARCHAR(30) NOT NULL,
    titulo              VARCHAR(200) NOT NULL,
    descricao           TEXT,
    validade_dias       INT NOT NULL DEFAULT 30,
    desconto_geral_pct  DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (desconto_geral_pct BETWEEN 0 AND 100),
    valor_subtotal      DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    valor_desconto      DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    valor_impostos      DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    valor_total         DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    status              ENUM('RASCUNHO','ENVIADO','EM_NEGOCIACAO','APROVADO','REPROVADO','EXPIRADO','CANCELADO') NOT NULL DEFAULT 'RASCUNHO',
    aprovado_em         DATETIME NULL,
    aprovado_por_contato INT UNSIGNED NULL,
    motivo_reprovacao   TEXT,
    versao              INT NOT NULL DEFAULT 1,
    orcamento_pai_id    INT UNSIGNED NULL COMMENT 'Para revisões/versões',
    observacoes         TEXT,
    criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_orcamento_numero UNIQUE (numero),
    CONSTRAINT fk_orc_cliente    FOREIGN KEY (cliente_id)         REFERENCES clientes(id),
    CONSTRAINT fk_orc_briefing   FOREIGN KEY (briefing_id)        REFERENCES briefings(id),
    CONSTRAINT fk_orc_criador    FOREIGN KEY (criado_por)         REFERENCES funcionarios(id),
    CONSTRAINT fk_orc_contato    FOREIGN KEY (aprovado_por_contato) REFERENCES clientes_contatos(id),
    CONSTRAINT fk_orc_pai        FOREIGN KEY (orcamento_pai_id)   REFERENCES orcamentos(id)
) ENGINE=InnoDB COMMENT='Orçamentos e propostas comerciais';

CREATE TABLE orcamentos_itens (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    orcamento_id    INT UNSIGNED NOT NULL,
    servico_id      INT UNSIGNED NULL,
    descricao       VARCHAR(300) NOT NULL,
    quantidade      DECIMAL(10,2) NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    valor_unitario  DECIMAL(10,2) NOT NULL CHECK (valor_unitario >= 0),
    desconto_pct    DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (desconto_pct BETWEEN 0 AND 100),
    valor_total     DECIMAL(14,2) GENERATED ALWAYS AS (quantidade * valor_unitario * (1 - desconto_pct/100)) STORED,
    ordem           INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_oi_orcamento FOREIGN KEY (orcamento_id) REFERENCES orcamentos(id) ON DELETE CASCADE,
    CONSTRAINT fk_oi_servico   FOREIGN KEY (servico_id)   REFERENCES servicos(id)
) ENGINE=InnoDB COMMENT='Itens dos orçamentos';

-- =============================================================================
-- 10. FINANCEIRO
-- =============================================================================

-- Plano de contas
CREATE TABLE plano_contas (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pai_id      INT UNSIGNED NULL,
    codigo      VARCHAR(20) NOT NULL,
    descricao   VARCHAR(200) NOT NULL,
    tipo        ENUM('RECEITA','DESPESA','ATIVO','PASSIVO','RESULTADO') NOT NULL,
    CONSTRAINT uq_plano_codigo UNIQUE (codigo),
    CONSTRAINT fk_pc_pai FOREIGN KEY (pai_id) REFERENCES plano_contas(id)
) ENGINE=InnoDB COMMENT='Plano de contas financeiro';

-- Centros de custo
CREATE TABLE centros_custo (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    departamento_id INT UNSIGNED NULL,
    projeto_id      INT UNSIGNED NULL,
    codigo          VARCHAR(20) NOT NULL,
    descricao       VARCHAR(200) NOT NULL,
    ativo           TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT uq_cc_codigo UNIQUE (codigo),
    CONSTRAINT fk_cc_departamento FOREIGN KEY (departamento_id) REFERENCES departamentos(id),
    CONSTRAINT fk_cc_projeto      FOREIGN KEY (projeto_id)      REFERENCES projetos(id)
) ENGINE=InnoDB;

-- Contas bancárias da agência
CREATE TABLE contas_bancarias (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    banco       VARCHAR(100) NOT NULL,
    agencia     VARCHAR(10) NOT NULL,
    conta       VARCHAR(20) NOT NULL,
    tipo        ENUM('CORRENTE','POUPANCA','PAGAMENTO') NOT NULL DEFAULT 'CORRENTE',
    descricao   VARCHAR(200),
    principal   TINYINT(1) NOT NULL DEFAULT 0,
    saldo_atual DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    ativo       TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- Notas fiscais de serviço
CREATE TABLE notas_fiscais (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cliente_id      INT UNSIGNED NOT NULL,
    projeto_id      INT UNSIGNED NULL,
    numero          VARCHAR(30) NOT NULL,
    serie           VARCHAR(5) NOT NULL DEFAULT '1',
    data_emissao    DATE NOT NULL,
    data_vencimento DATE NOT NULL,
    valor_servicos  DECIMAL(14,2) NOT NULL CHECK (valor_servicos >= 0),
    aliquota_iss    DECIMAL(5,2) NOT NULL DEFAULT 5.00 CHECK (aliquota_iss BETWEEN 0 AND 100),
    valor_iss       DECIMAL(14,2) GENERATED ALWAYS AS (valor_servicos * aliquota_iss / 100) STORED,
    valor_pis       DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    valor_cofins    DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    valor_ir        DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    valor_csll      DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    valor_liquido   DECIMAL(14,2) NOT NULL,
    descricao       TEXT,
    status          ENUM('RASCUNHO','EMITIDA','CANCELADA') NOT NULL DEFAULT 'RASCUNHO',
    cancelada_em    DATETIME NULL,
    motivo_cancel   TEXT NULL,
    criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_nf_numero_serie UNIQUE (numero, serie),
    CONSTRAINT fk_nf_cliente  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    CONSTRAINT fk_nf_projeto  FOREIGN KEY (projeto_id) REFERENCES projetos(id),
    CONSTRAINT chk_nf_datas   CHECK (data_vencimento >= data_emissao)
) ENGINE=InnoDB COMMENT='Notas fiscais de serviço emitidas';

-- Contas a receber
CREATE TABLE contas_receber (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cliente_id          INT UNSIGNED NOT NULL,
    nota_fiscal_id      INT UNSIGNED NULL,
    projeto_id          INT UNSIGNED NULL,
    conta_id            INT UNSIGNED NULL COMMENT 'Plano de contas',
    centro_custo_id     INT UNSIGNED NULL,
    descricao           VARCHAR(300) NOT NULL,
    valor               DECIMAL(14,2) NOT NULL CHECK (valor > 0),
    valor_pago          DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    data_emissao        DATE NOT NULL,
    data_vencimento     DATE NOT NULL,
    data_pagamento      DATE NULL,
    parcela             VARCHAR(10) NULL COMMENT 'Ex: 1/3',
    status              ENUM('ABERTA','PARCIAL','PAGA','VENCIDA','CANCELADA','NEGOCIADA') NOT NULL DEFAULT 'ABERTA',
    forma_pagamento     ENUM('BOLETO','PIX','TRANSFERENCIA','CARTAO','CHEQUE','DINHEIRO','OUTRO') NULL,
    conta_bancaria_id   INT UNSIGNED NULL,
    juros               DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    multa               DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    desconto            DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    observacoes         TEXT,
    criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_cr_cliente       FOREIGN KEY (cliente_id)       REFERENCES clientes(id),
    CONSTRAINT fk_cr_nf            FOREIGN KEY (nota_fiscal_id)   REFERENCES notas_fiscais(id),
    CONSTRAINT fk_cr_projeto       FOREIGN KEY (projeto_id)       REFERENCES projetos(id),
    CONSTRAINT fk_cr_conta         FOREIGN KEY (conta_id)         REFERENCES plano_contas(id),
    CONSTRAINT fk_cr_cc            FOREIGN KEY (centro_custo_id)  REFERENCES centros_custo(id),
    CONSTRAINT fk_cr_banco         FOREIGN KEY (conta_bancaria_id) REFERENCES contas_bancarias(id)
) ENGINE=InnoDB COMMENT='Contas a receber dos clientes';

-- Contas a pagar
CREATE TABLE contas_pagar (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fornecedor_id       INT UNSIGNED NULL,
    funcionario_id      INT UNSIGNED NULL COMMENT 'Para reembolsos',
    projeto_id          INT UNSIGNED NULL,
    conta_id            INT UNSIGNED NULL,
    centro_custo_id     INT UNSIGNED NULL,
    descricao           VARCHAR(300) NOT NULL,
    valor               DECIMAL(14,2) NOT NULL CHECK (valor > 0),
    valor_pago          DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    data_emissao        DATE NOT NULL,
    data_vencimento     DATE NOT NULL,
    data_pagamento      DATE NULL,
    status              ENUM('ABERTA','PARCIAL','PAGA','VENCIDA','CANCELADA') NOT NULL DEFAULT 'ABERTA',
    forma_pagamento     ENUM('BOLETO','PIX','TRANSFERENCIA','CARTAO','CHEQUE','DINHEIRO','OUTRO') NULL,
    conta_bancaria_id   INT UNSIGNED NULL,
    comprovante_url     VARCHAR(500),
    observacoes         TEXT,
    aprovado_por        INT UNSIGNED NULL,
    criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cp_fornecedor FOREIGN KEY (fornecedor_id)    REFERENCES fornecedores(id),
    CONSTRAINT fk_cp_funcionario FOREIGN KEY (funcionario_id)  REFERENCES funcionarios(id),
    CONSTRAINT fk_cp_projeto    FOREIGN KEY (projeto_id)       REFERENCES projetos(id),
    CONSTRAINT fk_cp_conta      FOREIGN KEY (conta_id)         REFERENCES plano_contas(id),
    CONSTRAINT fk_cp_cc         FOREIGN KEY (centro_custo_id)  REFERENCES centros_custo(id),
    CONSTRAINT fk_cp_banco      FOREIGN KEY (conta_bancaria_id) REFERENCES contas_bancarias(id),
    CONSTRAINT fk_cp_aprovador  FOREIGN KEY (aprovado_por)     REFERENCES funcionarios(id)
) ENGINE=InnoDB COMMENT='Contas a pagar (fornecedores, despesas)';

-- =============================================================================
-- 11. APROVAÇÕES (WORKFLOW DE APROVAÇÃO INTERNA)
-- =============================================================================

CREATE TABLE aprovacoes (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tipo                ENUM('ORCAMENTO','CAMPANHA','CRIACAO','COMPRA','NOTA_FISCAL','HORAS') NOT NULL,
    referencia_id       INT UNSIGNED NOT NULL COMMENT 'ID do registro a ser aprovado',
    solicitante_id      INT UNSIGNED NOT NULL,
    aprovador_id        INT UNSIGNED NOT NULL,
    status              ENUM('PENDENTE','APROVADO','REPROVADO','CANCELADO') NOT NULL DEFAULT 'PENDENTE',
    comentario          TEXT,
    prazo               DATE,
    respondido_em       DATETIME NULL,
    criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_apr_solicitante FOREIGN KEY (solicitante_id) REFERENCES funcionarios(id),
    CONSTRAINT fk_apr_aprovador   FOREIGN KEY (aprovador_id)   REFERENCES funcionarios(id)
) ENGINE=InnoDB COMMENT='Fluxo de aprovações internas';

-- =============================================================================
-- 12. COMUNICAÇÃO E REUNIÕES
-- =============================================================================

CREATE TABLE reunioes (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    projeto_id      INT UNSIGNED NULL,
    cliente_id      INT UNSIGNED NULL,
    organizador_id  INT UNSIGNED NOT NULL,
    titulo          VARCHAR(200) NOT NULL,
    pauta           TEXT,
    tipo            ENUM('KICKOFF','ALINHAMENTO','APRESENTACAO','REVISAO','STATUS','INTERNA','OUTRO') NOT NULL,
    data_hora       DATETIME NOT NULL,
    duracao_min     INT NOT NULL DEFAULT 60 CHECK (duracao_min > 0),
    local           VARCHAR(300) COMMENT 'Sala, endereço ou link',
    modalidade      ENUM('PRESENCIAL','VIRTUAL','HIBRIDA') NOT NULL DEFAULT 'PRESENCIAL',
    ata             TEXT,
    status          ENUM('AGENDADA','REALIZADA','CANCELADA','REAGENDADA') NOT NULL DEFAULT 'AGENDADA',
    criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reu_projeto     FOREIGN KEY (projeto_id)     REFERENCES projetos(id),
    CONSTRAINT fk_reu_cliente     FOREIGN KEY (cliente_id)     REFERENCES clientes(id),
    CONSTRAINT fk_reu_organizador FOREIGN KEY (organizador_id) REFERENCES funcionarios(id)
) ENGINE=InnoDB COMMENT='Reuniões internas e com clientes';

CREATE TABLE reunioes_participantes (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reuniao_id      INT UNSIGNED NOT NULL,
    funcionario_id  INT UNSIGNED NULL,
    contato_id      INT UNSIGNED NULL COMMENT 'Participante externo (cliente)',
    confirmado      TINYINT(1) NOT NULL DEFAULT 0,
    presente        TINYINT(1) NULL,
    CONSTRAINT fk_rp_reuniao     FOREIGN KEY (reuniao_id)    REFERENCES reunioes(id) ON DELETE CASCADE,
    CONSTRAINT fk_rp_funcionario FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id),
    CONSTRAINT fk_rp_contato     FOREIGN KEY (contato_id)    REFERENCES clientes_contatos(id)
) ENGINE=InnoDB;

-- Ações da ata de reunião
CREATE TABLE reunioes_acoes (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reuniao_id      INT UNSIGNED NOT NULL,
    responsavel_id  INT UNSIGNED NOT NULL,
    descricao       TEXT NOT NULL,
    prazo           DATE,
    status          ENUM('PENDENTE','EM_ANDAMENTO','CONCLUIDA') NOT NULL DEFAULT 'PENDENTE',
    CONSTRAINT fk_ra_reuniao     FOREIGN KEY (reuniao_id)    REFERENCES reunioes(id) ON DELETE CASCADE,
    CONSTRAINT fk_ra_responsavel FOREIGN KEY (responsavel_id) REFERENCES funcionarios(id)
) ENGINE=InnoDB;

-- =============================================================================
-- 13. PRODUÇÃO DE CONTEÚDO E CRIAÇÃO
-- =============================================================================

CREATE TABLE pecas_criativas (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    projeto_id      INT UNSIGNED NOT NULL,
    tarefa_id       INT UNSIGNED NULL,
    criado_por      INT UNSIGNED NOT NULL,
    nome            VARCHAR(200) NOT NULL,
    formato         VARCHAR(100) COMMENT 'Ex: Post 1080x1080, Banner 728x90, Folder A4',
    canal           VARCHAR(100) COMMENT 'Destino final: Instagram, Site, Impressão',
    descricao       TEXT,
    versao_atual    INT NOT NULL DEFAULT 1,
    status          ENUM('CRIACAO','INTERNO_APROVACAO','CLIENTE_REVISAO','CLIENTE_APROVADO','PRODUCAO','FINALIZADO','ARQUIVADO') NOT NULL DEFAULT 'CRIACAO',
    aprovado_em     DATETIME NULL,
    criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_pc_projeto  FOREIGN KEY (projeto_id) REFERENCES projetos(id),
    CONSTRAINT fk_pc_tarefa   FOREIGN KEY (tarefa_id)  REFERENCES tarefas(id),
    CONSTRAINT fk_pc_criador  FOREIGN KEY (criado_por) REFERENCES funcionarios(id)
) ENGINE=InnoDB COMMENT='Peças criativas produzidas';

-- Versões dos arquivos criativos
CREATE TABLE pecas_versoes (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    peca_id     INT UNSIGNED NOT NULL,
    numero      INT NOT NULL DEFAULT 1,
    url         VARCHAR(500) NOT NULL,
    url_preview VARCHAR(500),
    tipo_mime   VARCHAR(100),
    tamanho_kb  INT,
    comentario  VARCHAR(500),
    criado_por  INT UNSIGNED NOT NULL,
    criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_peca_versao UNIQUE (peca_id, numero),
    CONSTRAINT fk_pv_peca    FOREIGN KEY (peca_id)    REFERENCES pecas_criativas(id) ON DELETE CASCADE,
    CONSTRAINT fk_pv_criador FOREIGN KEY (criado_por) REFERENCES funcionarios(id)
) ENGINE=InnoDB COMMENT='Versões/histórico das peças criativas';

-- =============================================================================
-- 14. AVALIAÇÕES E NPS
-- =============================================================================

CREATE TABLE avaliacoes_cliente (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cliente_id      INT UNSIGNED NOT NULL,
    projeto_id      INT UNSIGNED NULL,
    contato_id      INT UNSIGNED NULL,
    tipo            ENUM('NPS','CSAT','PROJETO','ATENDIMENTO') NOT NULL,
    nota            TINYINT NOT NULL CHECK (nota BETWEEN 0 AND 10),
    comentario      TEXT,
    respondido_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_av_cliente  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    CONSTRAINT fk_av_projeto  FOREIGN KEY (projeto_id) REFERENCES projetos(id),
    CONSTRAINT fk_av_contato  FOREIGN KEY (contato_id) REFERENCES clientes_contatos(id)
) ENGINE=InnoDB COMMENT='Avaliações e NPS dos clientes';

-- =============================================================================
-- 15. CONFIGURAÇÕES E AUDITORIA
-- =============================================================================

CREATE TABLE configuracoes (
    chave       VARCHAR(100) PRIMARY KEY,
    valor       TEXT NOT NULL,
    descricao   TEXT,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Configurações gerais do sistema';

CREATE TABLE auditoria_log (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tabela          VARCHAR(100) NOT NULL,
    operacao        ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    registro_id     INT UNSIGNED NOT NULL,
    funcionario_id  INT UNSIGNED NULL,
    dados_antes     JSON NULL,
    dados_depois    JSON NULL,
    ip              VARCHAR(45),
    user_agent      VARCHAR(500),
    executado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_tabela (tabela, registro_id),
    INDEX idx_audit_data   (executado_em)
) ENGINE=InnoDB COMMENT='Log de auditoria de operações críticas';

-- =============================================================================
-- ÍNDICES DE PERFORMANCE
-- =============================================================================

-- Funcionários
CREATE INDEX idx_func_status         ON funcionarios (status);
CREATE INDEX idx_func_departamento   ON funcionarios (departamento_id);

-- Clientes
CREATE INDEX idx_cli_status          ON clientes (ativo);
CREATE INDEX idx_cli_classificacao   ON clientes (classificacao);

-- Projetos
CREATE INDEX idx_proj_status         ON projetos (status);
CREATE INDEX idx_proj_cliente        ON projetos (cliente_id);
CREATE INDEX idx_proj_datas          ON projetos (data_inicio, data_prazo);

-- Tarefas
CREATE INDEX idx_tar_status          ON tarefas (status);
CREATE INDEX idx_tar_responsavel     ON tarefas (responsavel_id);
CREATE INDEX idx_tar_projeto         ON tarefas (projeto_id);
CREATE INDEX idx_tar_prazo           ON tarefas (data_prazo);

-- Financeiro
CREATE INDEX idx_cr_status           ON contas_receber (status);
CREATE INDEX idx_cr_vencimento       ON contas_receber (data_vencimento);
CREATE INDEX idx_cr_cliente          ON contas_receber (cliente_id);
CREATE INDEX idx_cp_status           ON contas_pagar (status);
CREATE INDEX idx_cp_vencimento       ON contas_pagar (data_vencimento);

-- Campanhas
CREATE INDEX idx_camp_status         ON campanhas_midia (status);
CREATE INDEX idx_camp_datas          ON campanhas_midia (data_inicio, data_fim);

-- Apontamentos
CREATE INDEX idx_ah_func_data        ON apontamentos_horas (funcionario_id, data);
CREATE INDEX idx_ah_tarefa           ON apontamentos_horas (tarefa_id);

-- =============================================================================
-- TRIGGERS - REGRAS DE NEGÓCIO AUTOMATIZADAS
-- =============================================================================

DELIMITER //

-- RN01: Ao aprovar orçamento, registrar data e mover briefing para "CONVERTIDO"
CREATE TRIGGER trg_orcamento_aprovado
AFTER UPDATE ON orcamentos
FOR EACH ROW
BEGIN
    IF NEW.status = 'APROVADO' AND OLD.status != 'APROVADO' THEN
        -- Marca a data de aprovação
        UPDATE orcamentos SET aprovado_em = NOW() WHERE id = NEW.id;
        -- Atualiza o briefing vinculado
        IF NEW.briefing_id IS NOT NULL THEN
            UPDATE briefings
               SET status = 'CONVERTIDO', convertido_em = NOW()
             WHERE id = NEW.briefing_id AND status != 'CONVERTIDO';
        END IF;
    END IF;
END//

-- RN02: Ao concluir tarefa, recalcular % de conclusão do projeto
CREATE TRIGGER trg_tarefa_concluida
AFTER UPDATE ON tarefas
FOR EACH ROW
BEGIN
    DECLARE v_total INT;
    DECLARE v_concluidas INT;
    DECLARE v_percentual TINYINT;

    IF NEW.status = 'CONCLUIDA' AND OLD.status != 'CONCLUIDA' THEN
        SELECT COUNT(*) INTO v_total     FROM tarefas WHERE projeto_id = NEW.projeto_id AND status != 'CANCELADA';
        SELECT COUNT(*) INTO v_concluidas FROM tarefas WHERE projeto_id = NEW.projeto_id AND status = 'CONCLUIDA';
        IF v_total > 0 THEN
            SET v_percentual = ROUND((v_concluidas / v_total) * 100);
            UPDATE projetos SET percentual_conclusao = v_percentual WHERE id = NEW.projeto_id;
        END IF;
    END IF;
END//

-- RN03: Impedir exclusão de cliente com projetos ou contratos ativos
CREATE TRIGGER trg_bloquear_exclusao_cliente
BEFORE DELETE ON clientes
FOR EACH ROW
BEGIN
    DECLARE v_projetos INT;
    DECLARE v_contratos INT;
    SELECT COUNT(*) INTO v_projetos  FROM projetos  WHERE cliente_id = OLD.id AND status NOT IN ('CONCLUIDO','CANCELADO');
    SELECT COUNT(*) INTO v_contratos FROM contratos WHERE cliente_id = OLD.id AND status NOT IN ('ENCERRADO','CANCELADO');
    IF v_projetos > 0 OR v_contratos > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Não é possível excluir cliente com projetos ou contratos ativos.';
    END IF;
END//

-- RN04: Registrar histórico de mudança de status do contrato
CREATE TRIGGER trg_contrato_status_historico
AFTER UPDATE ON contratos
FOR EACH ROW
BEGIN
    IF NEW.status != OLD.status THEN
        INSERT INTO contratos_historico (contrato_id, funcionario_id, status_anterior, status_novo)
        VALUES (NEW.id, NEW.executivo_conta_id, OLD.status, NEW.status);
    END IF;
END//

-- RN05: Atualizar custo_real do projeto quando conta a pagar é quitada
CREATE TRIGGER trg_atualizar_custo_projeto
AFTER UPDATE ON contas_pagar
FOR EACH ROW
BEGIN
    IF NEW.status = 'PAGA' AND OLD.status != 'PAGA' AND NEW.projeto_id IS NOT NULL THEN
        UPDATE projetos
           SET custo_real = (
               SELECT COALESCE(SUM(valor_pago), 0)
                 FROM contas_pagar
                WHERE projeto_id = NEW.projeto_id AND status = 'PAGA'
           )
         WHERE id = NEW.projeto_id;
    END IF;
END//

-- RN06: Validar que horas apontadas não excedam 24h/dia por funcionário
CREATE TRIGGER trg_validar_horas_diarias
BEFORE INSERT ON apontamentos_horas
FOR EACH ROW
BEGIN
    DECLARE v_total_dia DECIMAL(5,2);
    SELECT COALESCE(SUM(horas), 0) INTO v_total_dia
      FROM apontamentos_horas
     WHERE funcionario_id = NEW.funcionario_id AND data = NEW.data;
    IF (v_total_dia + NEW.horas) > 24 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Total de horas apontadas no dia não pode exceder 24 horas.';
    END IF;
END//

-- RN07: Ao criar nova versão de peça, incrementar versao_atual automaticamente
CREATE TRIGGER trg_incrementar_versao_peca
AFTER INSERT ON pecas_versoes
FOR EACH ROW
BEGIN
    UPDATE pecas_criativas SET versao_atual = NEW.numero WHERE id = NEW.peca_id;
END//

-- RN08: Atualizar classificação do cliente baseado no faturamento acumulado
CREATE TRIGGER trg_classificar_cliente
AFTER UPDATE ON contas_receber
FOR EACH ROW
BEGIN
    DECLARE v_faturamento DECIMAL(14,2);
    IF NEW.status = 'PAGA' AND OLD.status != 'PAGA' THEN
        SELECT COALESCE(SUM(valor_pago), 0) INTO v_faturamento
          FROM contas_receber
         WHERE cliente_id = NEW.cliente_id AND status = 'PAGA';
        UPDATE clientes
           SET classificacao = CASE
               WHEN v_faturamento >= 500000 THEN 'DIAMANTE'
               WHEN v_faturamento >= 200000 THEN 'PLATINA'
               WHEN v_faturamento >= 50000  THEN 'OURO'
               WHEN v_faturamento >= 10000  THEN 'PRATA'
               ELSE 'BRONZE'
           END
         WHERE id = NEW.cliente_id;
    END IF;
END//

DELIMITER ;

-- =============================================================================
-- VIEWS GERENCIAIS
-- =============================================================================

-- View: Projetos com resumo financeiro e de progresso
CREATE VIEW vw_projetos_resumo AS
SELECT
    p.id,
    p.codigo,
    p.nome                                          AS projeto,
    p.tipo,
    p.status,
    p.prioridade,
    c.razao_social                                  AS cliente,
    CONCAT(f.nome, ' ', f.sobrenome)                AS gerente,
    p.data_inicio,
    p.data_prazo,
    p.data_conclusao,
    p.percentual_conclusao,
    p.orcamento_aprovado,
    p.custo_real,
    (p.orcamento_aprovado - p.custo_real)           AS saldo_orcamento,
    COUNT(DISTINCT t.id)                            AS total_tarefas,
    SUM(t.status = 'CONCLUIDA')                     AS tarefas_concluidas,
    SUM(t.status = 'EM_ANDAMENTO')                  AS tarefas_andamento,
    COALESCE(SUM(ah.horas), 0)                      AS horas_apontadas
FROM projetos p
JOIN clientes    c  ON c.id = p.cliente_id
JOIN funcionarios f  ON f.id = p.gerente_projeto_id
LEFT JOIN tarefas t  ON t.projeto_id = p.id
LEFT JOIN apontamentos_horas ah ON ah.tarefa_id = t.id
GROUP BY p.id;

-- View: Fluxo de caixa simplificado
CREATE VIEW vw_fluxo_caixa AS
SELECT
    data_vencimento     AS data,
    'RECEITA'           AS tipo,
    descricao,
    valor,
    status
FROM contas_receber
UNION ALL
SELECT
    data_vencimento,
    'DESPESA',
    descricao,
    valor * -1,
    status
FROM contas_pagar
ORDER BY data;

-- View: Desempenho de campanhas
CREATE VIEW vw_campanhas_performance AS
SELECT
    cm.id,
    cm.nome                                             AS campanha,
    p.nome                                              AS projeto,
    c.razao_social                                      AS cliente,
    cm.orcamento_total,
    cm.verba_investimento,
    COALESCE(SUM(met.impressoes), 0)                    AS total_impressoes,
    COALESCE(SUM(met.cliques), 0)                       AS total_cliques,
    COALESCE(SUM(met.conversoes), 0)                    AS total_conversoes,
    COALESCE(SUM(met.custo_real), 0)                    AS custo_realizado,
    IF(SUM(met.impressoes) > 0,
       (SUM(met.custo_real) / SUM(met.impressoes)) * 1000, 0) AS cpm_medio,
    IF(SUM(met.cliques) > 0,
       SUM(met.custo_real) / SUM(met.cliques), 0)       AS cpc_medio,
    cm.status
FROM campanhas_midia cm
JOIN projetos  p   ON p.id = cm.projeto_id
JOIN clientes  c   ON c.id = p.cliente_id
LEFT JOIN campanhas_veiculacoes cv  ON cv.campanha_id = cm.id
LEFT JOIN campanhas_metricas    met ON met.veiculacao_id = cv.id
GROUP BY cm.id;

-- View: Ocupação dos funcionários
CREATE VIEW vw_ocupacao_funcionarios AS
SELECT
    f.id,
    CONCAT(f.nome, ' ', f.sobrenome)    AS funcionario,
    d.nome                              AS departamento,
    cg.nome                             AS cargo,
    COUNT(DISTINCT pe.projeto_id)       AS projetos_ativos,
    COALESCE(SUM(pe.horas_alocadas), 0) AS horas_alocadas,
    f.carga_horaria * 4                 AS horas_mensais_contratadas,
    f.status
FROM funcionarios f
JOIN departamentos d  ON d.id = f.departamento_id
JOIN cargos       cg ON cg.id = f.cargo_id
LEFT JOIN projetos_equipe pe ON pe.funcionario_id = f.id
    AND pe.data_saida IS NULL
    AND EXISTS (
        SELECT 1 FROM projetos pr
         WHERE pr.id = pe.projeto_id
           AND pr.status = 'EM_ANDAMENTO'
    )
GROUP BY f.id;

-- View: Contas vencidas (inadimplência)
CREATE VIEW vw_inadimplencia AS
SELECT
    cr.id,
    c.razao_social      AS cliente,
    c.classificacao,
    cr.descricao,
    cr.valor,
    cr.valor_pago,
    (cr.valor - cr.valor_pago)  AS saldo_devedor,
    cr.data_vencimento,
    DATEDIFF(CURDATE(), cr.data_vencimento) AS dias_atraso,
    cr.status
FROM contas_receber cr
JOIN clientes c ON c.id = cr.cliente_id
WHERE cr.status IN ('ABERTA','PARCIAL')
  AND cr.data_vencimento < CURDATE()
ORDER BY dias_atraso DESC;

-- =============================================================================
-- STORED PROCEDURES
-- =============================================================================

DELIMITER //

-- SP: Gerar parcelas de contrato a receber
CREATE PROCEDURE sp_gerar_parcelas_contrato(
    IN p_contrato_id INT UNSIGNED,
    IN p_num_parcelas INT,
    IN p_dia_vencimento INT
)
BEGIN
    DECLARE v_valor_parcela DECIMAL(14,2);
    DECLARE v_cliente_id INT UNSIGNED;
    DECLARE v_descricao VARCHAR(300);
    DECLARE i INT DEFAULT 1;
    DECLARE v_data_vcto DATE;

    SELECT valor_total / p_num_parcelas, cliente_id, CONCAT('Parcela contrato nº ', numero)
      INTO v_valor_parcela, v_cliente_id, v_descricao
      FROM contratos WHERE id = p_contrato_id;

    WHILE i <= p_num_parcelas DO
        SET v_data_vcto = DATE(CONCAT(
            YEAR(DATE_ADD(CURDATE(), INTERVAL i MONTH)), '-',
            LPAD(MONTH(DATE_ADD(CURDATE(), INTERVAL i MONTH)), 2, '0'), '-',
            LPAD(LEAST(p_dia_vencimento, DAY(LAST_DAY(DATE_ADD(CURDATE(), INTERVAL i MONTH)))), 2, '0')
        ));
        INSERT INTO contas_receber (cliente_id, projeto_id, descricao, valor, data_emissao, data_vencimento, parcela)
        VALUES (v_cliente_id, NULL, v_descricao, v_valor_parcela, CURDATE(), v_data_vcto, CONCAT(i, '/', p_num_parcelas));
        SET i = i + 1;
    END WHILE;
END//

-- SP: Clonar projeto como novo projeto (reutilizar estrutura)
CREATE PROCEDURE sp_clonar_projeto(
    IN p_projeto_origem_id INT UNSIGNED,
    IN p_novo_codigo VARCHAR(30),
    IN p_novo_nome VARCHAR(200),
    IN p_cliente_id INT UNSIGNED,
    IN p_gerente_id INT UNSIGNED,
    IN p_data_inicio DATE,
    OUT p_novo_projeto_id INT UNSIGNED
)
BEGIN
    INSERT INTO projetos (cliente_id, gerente_projeto_id, codigo, nome, descricao, tipo,
                          data_inicio, data_prazo, orcamento_aprovado, prioridade, status)
    SELECT p_cliente_id, p_gerente_id, p_novo_codigo, p_novo_nome, descricao, tipo,
           p_data_inicio,
           DATE_ADD(p_data_inicio, INTERVAL DATEDIFF(data_prazo, data_inicio) DAY),
           orcamento_aprovado, prioridade, 'PLANEJAMENTO'
      FROM projetos WHERE id = p_projeto_origem_id;

    SET p_novo_projeto_id = LAST_INSERT_ID();
END//

-- SP: Relatório de rentabilidade por cliente
CREATE PROCEDURE sp_rentabilidade_cliente(IN p_ano INT)
BEGIN
    SELECT
        c.id,
        c.razao_social,
        c.classificacao,
        COUNT(DISTINCT p.id)                            AS total_projetos,
        COALESCE(SUM(cr.valor_pago), 0)                 AS receita_total,
        COALESCE(SUM(cp.valor_pago), 0)                 AS custo_total,
        COALESCE(SUM(cr.valor_pago),0) - COALESCE(SUM(cp.valor_pago),0) AS lucro_bruto,
        IF(SUM(cr.valor_pago) > 0,
           ROUND(((SUM(cr.valor_pago) - COALESCE(SUM(cp.valor_pago),0)) / SUM(cr.valor_pago)) * 100, 2),
           0)                                           AS margem_pct
    FROM clientes c
    LEFT JOIN projetos       p   ON p.cliente_id = c.id
    LEFT JOIN contas_receber cr  ON cr.cliente_id = c.id AND YEAR(cr.data_pagamento) = p_ano AND cr.status = 'PAGA'
    LEFT JOIN contas_pagar   cp  ON cp.projeto_id = p.id AND YEAR(cp.data_pagamento) = p_ano  AND cp.status = 'PAGA'
    GROUP BY c.id
    ORDER BY receita_total DESC;
END//

DELIMITER ;

-- =============================================================================
-- DADOS INICIAIS (SEED)
-- =============================================================================

INSERT INTO departamentos (nome) VALUES
    ('Atendimento'),
    ('Criação'),
    ('Mídia'),
    ('Planejamento'),
    ('Produção'),
    ('Financeiro'),
    ('Tecnologia'),
    ('Comercial'),
    ('RH e Administrativo'),
    ('Direção');

INSERT INTO cargos (nome, nivel, salario_base) VALUES
    ('Estagiário de Criação',         'ESTAGIARIO',    1200.00),
    ('Assistente de Atendimento',     'JUNIOR',        2800.00),
    ('Designer Jr.',                  'JUNIOR',        3200.00),
    ('Redator Jr.',                   'JUNIOR',        3000.00),
    ('Designer Pleno',                'PLENO',         5500.00),
    ('Redator Pleno',                 'PLENO',         5200.00),
    ('Analista de Mídia',             'PLENO',         5800.00),
    ('Executivo de Contas',           'PLENO',         6500.00),
    ('Designer Sênior',               'SENIOR',        8500.00),
    ('Diretor de Arte',               'ESPECIALISTA', 12000.00),
    ('Diretor de Criação',            'DIRETOR',      18000.00),
    ('Gerente de Projetos',           'GERENTE',      11000.00),
    ('Gerente Financeiro',            'GERENTE',      12000.00),
    ('Diretor de Atendimento',        'DIRETOR',      16000.00),
    ('Diretor Geral',                 'DIRETOR',      25000.00),
    ('Sócio',                         'SOCIO',        35000.00);

INSERT INTO segmentos_mercado (nome) VALUES
    ('Varejo'),('Indústria'),('Serviços'),('Tecnologia'),('Saúde'),
    ('Educação'),('Alimentos e Bebidas'),('Moda e Beleza'),('Imobiliário'),
    ('Financeiro'),('Entretenimento'),('ONG / Terceiro Setor');

INSERT INTO categorias_servico (nome) VALUES
    ('Identidade Visual'),('Campanha Publicitária'),('Marketing Digital'),
    ('Gestão de Redes Sociais'),('Produção de Vídeo'),('Fotografia'),
    ('Design Gráfico'),('Desenvolvimento Web'),('Planejamento Estratégico'),
    ('Media Planning'),('Eventos'),('Assessoria de Imprensa');

INSERT INTO servicos (categoria_id, codigo, nome, unidade, valor_padrao) VALUES
    (1, 'ID001', 'Criação de Logotipo',             'PACOTE',   2500.00),
    (1, 'ID002', 'Manual de Marca Completo',        'PACOTE',   6000.00),
    (2, 'CA001', 'Campanha 360° Completa',          'CAMPANHA', 25000.00),
    (2, 'CA002', 'Conceito Criativo de Campanha',   'PACOTE',   8000.00),
    (3, 'MD001', 'Gestão Google Ads',               'MES',      2500.00),
    (3, 'MD002', 'Gestão Meta Ads (FB+Instagram)',  'MES',      2500.00),
    (3, 'MD003', 'Relatório de Performance Mensal', 'MES',       800.00),
    (4, 'RS001', 'Gestão de Redes Sociais – Básico','MES',      3500.00),
    (4, 'RS002', 'Gestão de Redes Sociais – Pro',   'MES',      7000.00),
    (4, 'RS003', 'Produção de Post Estático',       'UNIDADE',   180.00),
    (4, 'RS004', 'Produção de Reels/Stories',       'UNIDADE',   350.00),
    (5, 'VD001', 'Produção de Vídeo Institucional', 'PACOTE',  15000.00),
    (5, 'VD002', 'Roteiro e Storyboard',            'PACOTE',   3500.00),
    (6, 'FT001', 'Ensaio Fotográfico de Produtos',  'DIA',      4000.00),
    (7, 'GD001', 'Design de Material Impresso',     'HORA',      150.00),
    (8, 'WB001', 'Desenvolvimento de Website',      'PACOTE',  18000.00),
    (8, 'WB002', 'Manutenção de Website',           'MES',      1200.00),
    (9, 'PL001', 'Planejamento de Marketing Anual', 'PACOTE',  12000.00),
    (10,'MI001', 'Media Planning e Buying',         'CAMPANHA', 5000.00),
    (11,'EV001', 'Organização de Evento Corporativo','PACOTE', 20000.00);

INSERT INTO canais_midia (nome, tipo) VALUES
    ('Google Search Ads',   'DIGITAL'),
    ('Google Display',      'DIGITAL'),
    ('YouTube Ads',         'DIGITAL'),
    ('Meta Ads (Facebook)', 'DIGITAL'),
    ('Instagram Ads',       'DIGITAL'),
    ('LinkedIn Ads',        'DIGITAL'),
    ('TikTok Ads',          'DIGITAL'),
    ('Programática',        'DIGITAL'),
    ('E-mail Marketing',    'DIGITAL'),
    ('TV Aberta',           'OFFLINE'),
    ('Rádio',               'OFFLINE'),
    ('OOH (Out of Home)',   'OFFLINE'),
    ('Jornal / Revista',    'OFFLINE'),
    ('Patrocínio',          'HIBRIDO');

INSERT INTO etapas_workflow (nome, descricao, ordem) VALUES
    ('Briefing',            'Recebimento e análise do briefing',                1),
    ('Planejamento',        'Definição de estratégia e plano de ação',          2),
    ('Conceito Criativo',   'Desenvolvimento do conceito e referências',        3),
    ('Criação',             'Produção das peças e materiais',                   4),
    ('Revisão Interna',     'Aprovação interna pela equipe',                    5),
    ('Aprovação Cliente',   'Apresentação e aprovação pelo cliente',            6),
    ('Ajustes',             'Revisões solicitadas pelo cliente',                7),
    ('Produção Final',      'Arte-final, exportação e preparação de entrega',   8),
    ('Entrega',             'Entrega dos arquivos / veiculação',                9),
    ('Pós-venda',           'Acompanhamento de resultados e relatório final',  10);

INSERT INTO configuracoes (chave, valor, descricao) VALUES
    ('taxa_agencia_padrao',       '20',    'Percentual padrão de comissão de agência (%)'),
    ('prazo_orcamento_dias',      '30',    'Validade padrão de orçamentos em dias'),
    ('limite_horas_dia',          '12',    'Máximo de horas apontáveis por dia por funcionário'),
    ('aliquota_iss_padrao',       '5',     'Alíquota de ISS padrão (%)'),
    ('notif_vencimento_dias',     '5',     'Dias de antecedência para notificar vencimentos'),
    ('versao_sistema',            '1.0.0', 'Versão atual do sistema'),
    ('moeda',                     'BRL',   'Moeda padrão do sistema');

-- =============================================================================
-- RESTAURAR CONFIGURAÇÕES
-- =============================================================================

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- =============================================================================
-- FIM DO SCRIPT
-- Agência de Publicidade e Marketing — Banco de Dados Completo
-- Tabelas: 47 | Triggers: 8 | Views: 5 | Procedures: 3 | Índices: 12+
-- =============================================================================
