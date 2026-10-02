# ADR-006: Saga de transferência orquestrada por payments-service

- **Data**: 2026-10-01
- **Status**: Accepted
- **Deciders**: Samuel Santana
- **Tags**: saga, payments, orquestração

## Contexto e problema

Uma transferência atravessa fraud, ledger, accounts, statements e
notification, sem transação distribuída. É preciso coordenar os passos e
compensar quando um deles falha (ex.: `ledger.post-rejected`). Precisamos
decidir quem detém o fluxo.

## Decision Drivers

- Fluxo explícito, em um só lugar, mais fácil de ensinar ao agente.
- Estados e compensações verificáveis.
- Idempotência e retry controlados.

## Considered Options

- Saga orquestrada (payments-service como orquestrador)
- Saga coreografada (cada serviço reage a eventos dos outros)

## Decision Outcome

Opção escolhida: **saga orquestrada**, com `payments-service` (Go) como
orquestrador. Fluxo:

`transfer.requested` → fraud → `fraud.assessed` → `ledger.post-requested`
→ ledger → `ledger.entries-posted` ou `ledger.post-rejected` →
`transfer.completed` ou `transfer.failed` (compensado).

Payments mantém estado da saga, idempotência e compensação, publicando via
outbox ([ADR-005](005-outbox-pattern-para-publicacao-de-eventos.md)).

### Consequências positivas

- Lógica do fluxo concentrada; novo passo da saga é mudança em um serviço
  mais contratos.
- Estados e compensações testáveis em um lugar.

### Consequências negativas

- `payments-service` vira ponto de acoplamento e de risco (complexidade 5);
  exige revisão humana linha a linha.
- Ledger e fraud dependem do contrato definido pelo orquestrador.

## Pros and Cons of the Options

### Orquestrada ✅ Chosen

- ✅ Fluxo visível, compensação centralizada, simples para o agente
- ❌ Orquestrador concentra conhecimento

### Coreografada

- ✅ Menor acoplamento ao centro
- ❌ Fluxo espalhado e difícil de raciocinar; compensação difusa

## Diagrama (sequência da saga)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#e0e7ff', 'primaryTextColor': '#1e293b', 'primaryBorderColor': '#4f46e5', 'lineColor': '#94a3b8', 'noteBkgColor': '#fef3c7', 'noteTextColor': '#1e293b', 'actorBkg': '#e0e7ff', 'actorBorder': '#4f46e5', 'textColor': '#334155'}}}%%
sequenceDiagram
    autonumber
    participant P as payments-service<br/>(orquestrador)
    participant F as fraud-service
    participant L as ledger-service
    participant N as notification / statements

    P->>F: transfer.requested
    F-->>P: fraud.assessed
    alt fraude bloqueou
        P->>N: transfer.failed
    else fraude aprovou
        P->>L: ledger.post-requested
        alt lançamentos gravados
            L-->>P: ledger.entries-posted
            P->>N: transfer.completed
        else invariante violada (saldo / limite)
            L-->>P: ledger.post-rejected
            Note over P: compensação
            P->>N: transfer.failed
        end
    end
```

## Links

- Documento inicial — seção "Saga de transferência e seus eventos" e
  tabela de decisões em aberto
- [ADR-004](004-comunicacao-assincrona-via-kafka-e-sincrona-apenas-na-borda.md)
