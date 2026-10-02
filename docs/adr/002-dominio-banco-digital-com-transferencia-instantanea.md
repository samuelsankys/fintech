# ADR-002: Adotar banco digital com transferência instantânea (estilo Pix) como domínio

- **Data**: 2026-10-01
- **Status**: Accepted
- **Deciders**: Samuel Santana
- **Tags**: domínio, harness

## Contexto e problema

O projeto é um testbed para avaliar um harness de agente de IA, não um
produto. O domínio precisa ter invariantes que um agente possa violar de
forma verificável, fluxos que cruzem serviços e ser conhecido o bastante
por LLMs para que o scaffolding seja rápido.

## Decision Drivers

- Invariantes de negócio fortes (saldo, idempotência, ordem de eventos).
- Fluxos cross-service com compensação (sagas).
- Domínio que LLMs já conhecem bem.
- Complexidade de negócio maior que a de infraestrutura.
- Sobe local com `docker compose`, para sensores em loop curto.

## Considered Options

- Chat (estilo Slack/Discord)
- Banco digital / fintech com transferência instantânea
- E-commerce / marketplace
- Logística / ride-hailing

## Decision Outcome

Opção escolhida: **banco digital com transferência instantânea**, porque
tem as invariantes mais duras (ledger de partidas dobradas, idempotência,
ordem por conta) e o harness ganha um trabalho claro: proteger o ledger.

### Consequências positivas

- Guardrails e sensores ficam concretos e testáveis (property-based tests
  no ledger, contract tests, reentrega de `eventId`).
- Encaixe natural em Java, Go e Node + Kafka.

### Consequências negativas

- Ledger e payments exigem revisão humana linha a linha; não saem direto
  de template.
- Parte assíncrona de chat/tempo real fica de fora; coberta só em parte
  pelo `notification-service` (retry + DLQ).

## Pros and Cons of the Options

### Banco digital ✅ Chosen

- ✅ Invariantes fortes, velocidade de geração alta, valor alto para o harness
- ❌ Exige rigor em ledger e saga

### Chat

- ✅ Estressa tempo real e fan-out
- ❌ Invariantes fracas; esforço vai para infra e performance

### E-commerce / marketplace

- ✅ Fluxo previsível e muito repetido
- ❌ Invariantes médias; valor para o harness menor

### Logística / ride-hailing

- ✅ Problemas ricos de matching e ETA
- ❌ Geo e tempo real roubam o foco; geração lenta

## Links

- `Harness-first sistema distribuído poliglota — documento inicial.md`
  — seções "Objetivo e critérios de escolha" e "Comparação de domínios"
- [ADR-001](001-documentacao-de-contexto-por-servico.md)
