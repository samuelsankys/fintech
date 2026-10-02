# Harness-first: sistema distribuído poliglota — documento inicial

Sep 30, 2026 · @samuel santana

## Objetivo e critérios de escolha

O projeto existe para testar o harness, não para entregar um produto: os serviços são o terreno de teste. Precisam ser complexos o bastante para expor um harness fraco e simples o bastante para serem gerados rápido.

Pergunta central: um agente de IA consegue alterar um serviço sem quebrar contratos, invariantes e convenções dos vizinhos, usando só o contexto que o harness entrega?

| Critério do domínio                                        | Por que importa para o harness                                                        |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Invariantes de negócio fortes (saldo, idempotência, ordem) | Dá ao agente algo concreto para violar; guardrails e testes passam a ser verificáveis |
| Fluxos que cruzam serviços (sagas, compensações)           | Testa se o contexto cross-service chega ao agente                                     |
| Domínio que LLMs já conhecem bem                           | Scaffolding rápido, sem gastar tempo explicando o negócio                             |
| Encaixe natural em Java, Node e Go + Kafka                 | Poliglota por motivo real, não forçado                                                |
| Complexidade de negócio maior que a de infra               | O esforço vai para o harness, não para escalar WebSocket                              |
| Sobe local com docker compose                              | Sensores (testes, lint, contract tests) rodam em loop curto                           |

## Comparação de domínios

A recomendação é um banco digital com transferência instantânea (estilo Pix): é o domínio com as regras mais duras para o agente respeitar, e o harness passa a ter um trabalho claro, que é proteger o ledger.

| Domínio                     | Onde está a complexidade                              | Invariantes verificáveis | Velocidade para gerar | Valor para o harness                                                          |
| --------------------------- | ----------------------------------------------------- | ------------------------ | --------------------- | ----------------------------------------------------------------------------- |
| Chat (tipo Slack/Discord)   | Tempo real, fan-out, presença, ordenação de mensagens | Fracas                   | Média                 | Médio: o esforço vai para infra e performance, com poucas regras para quebrar |
| **Banco digital / fintech** | Ledger, transferências, limites, antifraude           | Fortes                   | Alta                  | **Alto**                                                                      |
| E-commerce / marketplace    | Pedido, estoque, preço, pagamento                     | Médias                   | Alta                  | Médio-alto: fluxo previsível e já muito repetido                              |
| Logística / ride-hailing    | Matching, geolocalização, ETA                         | Médias                   | Baixa                 | Médio: geo e tempo real roubam o foco                                         |

O lado chat não precisa ser descartado: um serviço de notificações com retry e DLQ cobre a parte assíncrona sem trazer WebSocket e escala de conexões para o centro do projeto.

## Catálogo de microserviços

Oito serviços no MVP, em três stacks, mais dois opcionais para a fase 2. Se quiser o menor núcleo que ainda exercita tudo, fique com bff-gateway, accounts, ledger, payments e notification (cinco serviços, três stacks).

Escala de complexidade: 1 = CRUD · 2 = consumidor com retry · 3 = regras + integrações · 4 = estado, projeção ou concorrência · 5 = invariantes distribuídas.

| Serviço                           | Stack            | Responsabilidade                                                        | Dados               | Compl. (1–5) | O que estressa no harness                                       |
| --------------------------------- | ---------------- | ----------------------------------------------------------------------- | ------------------- | ------------ | --------------------------------------------------------------- |
| ledger-service                    | Java Spring Boot | Livro-razão de partidas dobradas, imutável; fonte da verdade do saldo   | PostgreSQL          | 5            | Invariante central: débitos = créditos, só append, nunca update |
| payments-service                  | Go               | Orquestra a transferência (saga), idempotência, estados e compensações  | PostgreSQL + outbox | 5            | Fluxo cross-service, ordem de eventos, retry                    |
| accounts-service                  | Java Spring Boot | Contas, limites e saldo como projeção (CQRS)                            | PostgreSQL          | 4            | Separação entre escrita e leitura                               |
| fraud-service                     | Go               | Consome eventos, calcula score em janela deslizante, aprova ou bloqueia | Redis               | 4            | Streaming, estado e latência                                    |
| identity-service                  | Java Spring Boot | Clientes, KYC simulado, tokens, chaves de transferência                 | PostgreSQL          | 3            | Segurança e dados pessoais (regras de PII nos guardrails)       |
| bff-gateway                       | Node.js (NestJS) | Entrada única da API, JWT, composição, rate limit                       | Redis               | 3            | Contratos OpenAPI consumidos por vários serviços                |
| statements-service                | Node.js          | Extrato como read-model dos eventos, busca e exportação                 | PostgreSQL          | 3            | Projeções e replay de eventos                                   |
| notification-service              | Node.js          | Templates, canais simulados, retry e DLQ                                | MongoDB             | 2            | Consumidor idempotente simples (baseline do harness)            |
| _cards-service (fase 2)_          | Java Spring Boot | Autorização de cartão com reserva de saldo (hold)                       | PostgreSQL          | 4            | Nova saga reaproveitando ledger e accounts                      |
| _reconciliation-service (fase 2)_ | Go               | Conciliação em lote do ledger contra um extrato externo simulado        | PostgreSQL          | 4            | Jobs batch e divergências                                       |

A divisão por stack segue a função: Java onde a regra de negócio é densa (ledger, accounts, identity), Go onde há orquestração e throughput (payments, fraud), Node onde há composição e I/O (bff, statements, notification). Isso dá ao harness três ecossistemas de build, teste e lint para cobrir.

## Arquitetura e estrutura do monorepo

Chamada síncrona só na borda (BFF para os serviços); entre serviços tudo é evento no Kafka, e quem tem banco publica pelo padrão outbox para não perder mensagem.

&#91;embedded content: arquitetura · 8 serviços, Kafka no centro\]

Exceto o bff-gateway, todos os serviços terminam em `-service`. Leconcentram as invariantes e são os que mais pedem cuidado do harness.dger e payments&#32;

**Saga de transferência e seus eventos**

| Tópico                  | Produtor | Consumidores                   | Papel na saga                                             |
| ----------------------- | -------- | ------------------------------ | --------------------------------------------------------- |
| `transfer.requested`    | payments | fraud                          | Início da saga                                            |
| `fraud.assessed`        | fraud    | payments                       | Aprova ou bloqueia                                        |
| `ledger.post-requested` | payments | ledger                         | Comando para lançar débito e crédito                      |
| `ledger.entries-posted` | ledger   | payments, accounts, statements | Lançamentos gravados                                      |
| `ledger.post-rejected`  | ledger   | payments                       | Invariante violada (saldo, limite); dispara a compensação |
| `transfer.completed`    | payments | notification, statements       | Fim feliz                                                 |
| `transfer.failed`       | payments | notification, statements       | Fim com compensação                                       |
| `customer.registered`   | identity | accounts                       | Abre a conta do cliente                                   |

Regras comuns: chave de partição = id da conta (ordem por conta); toda mensagem leva `eventId` e `correlationId`; consumidores são idempotentes por `eventId`; schemas versionados em `contracts/events/`.

**Estrutura do monorepo (pastas como se fossem repos separados)**

```
fintech/
├── AGENTS.md                  # contexto raiz do harness
├── harness/                   # skills, guardrails e sensores
├── contracts/
│   ├── events/                # schemas dos eventos Kafka
│   └── openapi/               # APIs síncronas
├── platform/
│   ├── docker-compose.yml     # Kafka, PostgreSQL, Redis, MongoDB
│   └── Makefile
└── services/
    ├── ledger-service/        # cada pasta: build, testes, Dockerfile e AGENTS.md próprios
    ├── payments-service/
    ├── accounts-service/
    ├── identity-service/
    ├── fraud-service/
    ├── bff-gateway/
    ├── statements-service/
    └── notification-service/
```

Regra que simula o multirepo: um serviço nunca importa código de outro, só os contratos de `contracts/`. Um sensor no CI local falha o build se isso acontecer.

## Desenho do harness

O harness tem três camadas de contexto (raiz, cross-service e serviço) e uma de sensores que confere o que o agente fez. A seta lateral mostra o ciclo: o erro do sensor volta ao agente, que corrige.

&#91;embedded content: harness · 4 camadas, com a falha voltando ao agente\]

**O que vai em cada peça**

| Peça                   | Conteúdo mínimo                                                                                                                                            |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AGENTS.md` da raiz    | Propósito do sistema, mapa dos serviços e stacks, comandos globais, regra de não importar entre serviços, links para as skills                             |
| `services/*/AGENTS.md` | Responsabilidade, stack e versão, comandos de build, teste e lint, estrutura de pacotes, invariantes locais, eventos que produz e consome, o que não tocar |
| `harness/skills/`      | Procedimentos repetíveis: mudar schema de evento, adicionar passo à saga, adicionar endpoint, criar serviço a partir do template                           |
| `harness/guardrails/`  | Regras escritas de forma verificável, cada uma ligada a um sensor                                                                                          |
| `harness/sensors/`     | Scripts que o agente roda sozinho e cujo resultado ele lê                                                                                                  |
| `contracts/`           | Fonte da verdade sobre eventos e APIs; o código segue o contrato, nunca o contrário                                                                        |

**Guardrails e o sensor que verifica cada um**

| Guardrail                                    | Sensor                                                         |
| -------------------------------------------- | -------------------------------------------------------------- |
| Ledger é append-only e débitos = créditos    | Testes de propriedade no ledger-service                        |
| Evento publicado só muda de forma compatível | Checagem de compatibilidade dos schemas em `contracts/events/` |
| Serviço não importa código de outro          | Script que varre dependências e imports                        |
| Sem dados pessoais em logs                   | Lint nos logs + teste no identity                              |
| Consumidor é idempotente                     | Teste que reentrega o mesmo `eventId` duas vezes               |
| API síncrona segue o contrato                | Contract test do bff-gateway contra os serviços                |

**Experimento: três níveis do harness para comparar**

1. Só `AGENTS.md` da raiz
2. Raiz + `AGENTS.md` por serviço
3. Completo: contexto, skills, guardrails e sensores

Todos os serviços nascem do mesmo template de `AGENTS.md`, para que a diferença de resultado venha do conteúdo do harness e não do formato.

## Plano de execução e avaliação

O harness cresce junto com os serviços, e cada tarefa de teste roda duas vezes: com e sem harness. A diferença entre as duas é o resultado do experimento.

1. **Esqueleto do monorepo:** pastas, docker-compose (Kafka, PostgreSQL, Redis, MongoDB), Makefile raiz e a pasta `contracts/`. Harness v0: só `AGENTS.md` na raiz.
2. **Núcleo do dinheiro:** ledger, accounts e payments. É aqui que as invariantes nascem, então os primeiros guardrails e testes de propriedade entram junto.
3. **Entrada e leitura:** identity, bff-gateway e statements. Primeiros contract tests e primeira skill cross-service.
4. **Periferia:** fraud e notification. Harness completo, com mapa de eventos e sensores no CI local.
5. **Avaliação:** bateria de tarefas de benchmark rodada com e sem harness.

Scaffolding rápido: um serviço por sessão do agente, a partir de um template por stack (Java, Node, Go) que já traz build, testes, lint, Dockerfile e o arquivo de contexto do serviço. Ledger e payments merecem revisão humana linha a linha; notification e statements podem sair quase direto do template.

**Tarefas de benchmark sugeridas**

- Adicionar um campo ao evento `TransferCompleted` sem quebrar os consumidores
- Criar um limite diário de transferência em accounts
- Adicionar uma regra de fraude nova com teste
- Mudar o formato do extrato mantendo o histórico
- Implementar transferência agendada (novo estado na saga)

| Métrica                       | Como medir                                                          |
| ----------------------------- | ------------------------------------------------------------------- |
| Sucesso na primeira tentativa | A tarefa passa nos testes sem intervenção humana                    |
| Violações de guardrail        | Diffs que quebram contrato ou invariante e são pegos pelos sensores |
| Iterações até ficar verde     | Ciclos de build e teste até passar                                  |
| Custo por tarefa              | Tokens e tempo de relógio                                           |
| Contexto fora de escopo       | Arquivos lidos que não tinham relação com a tarefa                  |

## Riscos, decisões em aberto e próximos passos

O maior risco é gastar o tempo nos serviços e deixar o harness para o fim. A mitigação está no plano: cada fase entrega código e harness juntos.

| Risco ou decisão                                             | Opções                                                                 | Inclinação inicial           |
| ------------------------------------------------------------ | ---------------------------------------------------------------------- | ---------------------------- |
| Serviços ficam rasos demais e o teste não prova nada         | Manter ledger e payments com invariantes reais e testes de propriedade | Manter                       |
| Escopo explode com 10 serviços                               | Começar pelo núcleo de 5 serviços                                      | Núcleo de 5, depois expandir |
| Contrato de eventos: Avro/Schema Registry ou JSON Schema     | Avro dá compatibilidade checável; JSON Schema é mais leve              | Em aberto                    |
| Orquestração da saga: orquestrador (payments) ou coreografia | Orquestrador é mais fácil de ensinar ao agente                         | Orquestrador                 |
| Qual agente e ferramenta vai usar o harness                  | Claude Code, outro agente, ou ambos para comparar                      | Em aberto                    |

**Próximos passos**

- [ ] Confirmar o domínio (banco digital) ou escolher outro
- [ ] Decidir núcleo de 5 ou MVP de 8 serviços
- [ ] Gerar o esqueleto do monorepo e o `docker-compose`
- [ ] Escrever o `AGENTS.md` da raiz e o template de contexto por serviço
- [ ] Gerar ledger-service com os testes de invariante primeiro
