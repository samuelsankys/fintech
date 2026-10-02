# ADR-001: Documentação de contexto por serviço (architecture, code_style, testing, security, patterns)

- **Data**: 2026-10-01
- **Status**: Accepted
- **Deciders**: Samuel Santana
- **Tags**: harness, documentação, agentes, arquitetura

## Contexto e problema

Este repositório não é um produto — é um testbed para avaliar um harness de
agente de IA (ver `CLAUDE.md`, seção "Project purpose"). A pergunta central
que o projeto mede é: *um agente consegue alterar um serviço sem quebrar
contratos, invariantes ou convenções dos seus vizinhos, usando apenas o
contexto que o harness fornece?*

Hoje cada um dos 8 serviços (`ledger-service`, `accounts-service`,
`identity-service`, `payments-service`, `fraud-service`, `bff-gateway`,
`statements-service`, `notification-service`) tem um `AGENTS.md` enxuto —
responsabilidade, stack/versão, comandos de build/test, layout de pacotes,
eventos produzidos/consumidos e "o que não tocar". Isso é suficiente para
orientação operacional rápida, mas não cobre o racional mais profundo que
um agente precisa para tomar decisões corretas em quatro frentes
recorrentes: arquitetura (papel no sistema, fronteiras de dados,
camadas), estilo de código (convenções por stack), testes (o que e como
testar, incluindo os sensores de guardrail já listados em `CLAUDE.md`),
segurança (PII, segredos, superfície de ataque) e padrões (outbox, CQRS,
saga, consumidor idempotente) aplicados àquele serviço específico.

Sem esse contexto estruturado, um agente tende a inferir essas respostas a
partir do código (hoje, scaffolds quase vazios) ou do documento de
planejamento em português, nenhum dos dois adequado para consulta rápida
por serviço durante uma tarefa.

## Decision Drivers

- O harness deve fornecer contexto específico por serviço, não só global
  (root `AGENTS.md`) — ver camadas de contexto descritas em `CLAUDE.md`,
  seção "Harness design".
- Cada serviço usa uma stack diferente (Java/Spring Boot, Go, Node/NestJS)
  com convenções de código e teste distintas — um documento genérico único
  não serve às três.
- O racional de segurança varia muito por serviço (ex.: `identity-service`
  concentra PII; `ledger-service` concentra o invariante financeiro) e
  merece um documento dedicado, não uma seção perdida dentro de outro
  arquivo.
- Os pares guardrail → sensor já listados em `CLAUDE.md` (ledger
  append-only, eventos compatíveis, sem import cross-service, sem PII em
  log, consumidores idempotentes, API síncrona segue contrato) precisam de
  um lugar natural, por serviço, para apontar como contexto acionável.
- Manter `AGENTS.md` enxuto (uso rápido, "o que rodar agora") separado do
  racional mais extenso evita que o arquivo operacional vire um documento
  longo demais para ser lido a cada tarefa.

## Opções consideradas

- Expandir cada `AGENTS.md` para incluir tudo inline (arquitetura, estilo,
  testes, segurança, padrões).
- Criar `services/<nome>/docs/{ARCHITECTURE,CODE_STYLE,TESTING,SECURITY,
  PATTERNS}.md` por serviço, complementando o `AGENTS.md` existente.
- Um único `ARCHITECTURE.md` por serviço cobrindo todas as cinco frentes.
- Centralizar toda a orientação em `harness/skills/` e
  `harness/guardrails/` apenas, sem documentação por serviço.

## Decision Outcome

Opção escolhida: **criar `services/<nome>/docs/{ARCHITECTURE,CODE_STYLE,
TESTING,SECURITY,PATTERNS}.md` por serviço**, porque separa contexto
operacional rápido (`AGENTS.md`) de racional mais profundo por frente
(arquitetura/estilo/teste/segurança/padrões), permite que cada stack
(Java/Go/Node) tenha convenções próprias sem poluir as demais, e dá um
lugar natural para ancorar os pares guardrail → sensor já previstos em
`CLAUDE.md` antes que `harness/guardrails/` e `harness/sensors/` existam
de fato.

### Consequências positivas

- Agente consegue carregar só o documento relevante à tarefa (ex.: só
  `SECURITY.md` de `identity-service` ao mexer em PII), em vez de um
  `AGENTS.md` monolítico.
- Convenções de stack (Google Java Format, `go vet`, ESLint/Jest) ficam
  isoladas por serviço, evitando contradição entre stacks.
- Documentos de segurança tornam explícito o invariante crítico de cada
  serviço (append-only em `ledger-service`, PII em `identity-service`,
  rate limit/JWT em `bff-gateway`, idempotência em
  `notification-service`), alinhado à tabela de guardrails de
  `CLAUDE.md`.
- Estrutura replicável: qualquer serviço novo (ex.: `cards-service` na
  fase 2) ganha o mesmo conjunto de 5 arquivos sem redesenho.

### Consequências negativas

- 40 arquivos (8 serviços × 5 documentos) para manter; risco de
  desatualização conforme os serviços saem do estágio de scaffold.
- Duplicação de boilerplate entre serviços da mesma stack (ex.: as três
  docs Java repetem convenção de formatação/camadas) — aceito porque
  cada um ainda carrega particularidades específicas do serviço.
- Nenhum sensor automatizado hoje garante que os documentos continuem
  batendo com o código real; a validação é manual até `harness/sensors/`
  existir.
- `AGENTS.md` e `docs/*.md` podem divergir se um for atualizado sem o
  outro — mitigar linkando um ao outro quando ambos existirem.

## Links

- `CLAUDE.md` — seções "Project purpose" e "Harness design"
- `AGENTS.md` (raiz) — mapa de serviços/stacks e regra de não-import
  cross-service
- `services/*/AGENTS.md` — contexto operacional complementar a estes
  documentos
- `services/*/docs/{ARCHITECTURE,CODE_STYLE,TESTING,SECURITY,
  PATTERNS}.md` — artefatos gerados por esta decisão
