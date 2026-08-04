# 🥦 Hortifruti App

App white-label para hortifrutis — vitrine digital com catálogo, promoções e pedidos via WhatsApp.

---

## Visão geral

Um hortifruti tem o catálogo no Instagram, os pedidos no WhatsApp e nenhuma vitrine profissional. Este projeto resolve isso: um app mobile com catálogo organizado, ofertas do dia e finalização de pedido diretamente pelo WhatsApp — sem depender de marketplace ou gateway de pagamento.

A arquitetura é **multiempresa (white-label)**: um único backend serve múltiplos hortifrutis, cada um com seu catálogo, banners e pedidos isolados por `company_id`.

---

## Stack

### Backend
| Tecnologia | Versão | Uso |
|---|---|---|
| PHP | 8.3 | Linguagem |
| Laravel | 11 | Framework |
| PostgreSQL | 16 | Banco de dados |
| Laravel Sanctum | — | Autenticação API |
| Intervention Image | 3 | Pipeline de imagens |
| Cloudflare R2 | — | Storage de imagens (CDN) |

### App Mobile
| Tecnologia | Versão | Uso |
|---|---|---|
| Flutter | 3.x | Framework mobile |
| Dart | 3.12+ | Linguagem |
| flutter_bloc | 9.x | Gerenciamento de estado |
| get_it | 9.x | Injeção de dependência |
| freezed | 3.x | Modelos imutáveis (requer `abstract class` na declaração, ver nota abaixo) |
| Dio | 5.5 | Cliente HTTP |
| go_router | 17 | Navegação |

> **Nota — Freezed 3.x:** a partir da v3, classes anotadas com `@freezed` precisam ser declaradas como `abstract class`, não `class`. Omitir isso gera erro de compilação (`Missing concrete implementations`) mesmo com os arquivos `.freezed.dart`/`.g.dart` corretamente gerados.

---

## Funcionalidades

### App cliente (planejado)
- Vitrine com banners e campanhas programadas
- Catálogo por categorias com busca
- Ofertas do dia e produtos em destaque
- Detalhe do produto com imagem, preço e unidade (kg, un, bandeja...)
- Carrinho persistente (mantido ao fechar o app)
- Checkout com entrega ou retirada
- Pedido enviado como mensagem formatada no WhatsApp
- Informações da loja: horário, endereço, contato

### Painel admin (no próprio app, planejado)
- Gestão de categorias e produtos
- Upload de fotos com geração automática de 3 variantes (thumb, card, full)
- Banners com período de exibição configurável
- Gestão de pedidos com controle de status
- Configurações da loja (horário, taxas, dados de contato)

### O que fica fora da v1 (por design)
- Pagamento online
- Rastreio de entrega
- Sistema de fidelidade
- Estoque em tempo real
- Marketplace com múltiplas lojas na mesma tela

---

## Arquitetura

### Backend — estrutura de pastas

app/
├── Actions/
│ └── PlaceOrderAction.php # orquestra criação do pedido
├── Http/
│ ├── Controllers/Api/
│ │ ├── AuthController.php
│ │ ├── Admin/ # endpoints autenticados
│ │ └── Client/ # endpoints públicos
│ ├── Middleware/
│ │ └── ResolveCompany.php # resolve company_id por header
│ ├── Requests/ # validação por FormRequest
│ └── Resources/ # serialização das responses
├── Models/ # Company, Store, Category, Product...
└── Services/
├── ImageService.php # pipeline de imagens (3 variantes)
└── WhatsAppService.php # monta URL do pedido


### App Flutter — estrutura de pastas (estado atual)

lib/
├── app/
│ ├── app.dart # HortifrutiApp — MaterialApp.router
│ ├── router.dart # buildRouter() — rotas via go_router
│ └── theme.dart # ThemeData
├── core/
│ ├── constants/ # app_constants.dart (baseUrl, companyId)
│ ├── di/
│ │ └── injection.dart # setupDependencies() — registro get_it
│ ├── network/
│ │ ├── api_endpoint.dart
│ │ ├── api_exception.dart
│ │ ├── dio_client.dart
│ │ └── paginated.dart # wrapper genérico Paginated<T>, reaproveitável
│ ├── storage/
│ │ └── local_storage.dart
│ └── utils/
│ ├── currency_formatter.dart
│ └── whatsapp_helper.dart
├── features/
│ ├── category/
│ │ ├── data/ # category_repository.dart
│ │ └── domain/ # category.dart (model freezed)
│ ├── home/
│ │ └── home_page.dart
│ └── store/
│ ├── data/ # store_repository.dart
│ └── domain/ # store.dart (model freezed)
├── shared/
│ └── widgets/ # cached_image, error_retry_widget, store_closed_banner
└── main.dart


Cada feature segue a separação `data → domain` (camada de apresentação ainda não implementada em nenhuma feature). O padrão estabelecido: `domain` define o model (freezed) → `data` implementa o repository usando `DioClient` → repository é registrado no `get_it` via `injection.dart`.

**Ainda não implementado:** `auth/`, `product/`, `cart/`, `checkout/` — endpoints já existem no backend e estão mapeados em `ApiEndpoint`, mas as features Flutter correspondentes não foram criadas.

### Banco de dados

companies ← raiz do multiempresa (UUID)
└── users ← admins do painel
└── stores ← dados operacionais da loja
└── categories ← hierarquia com parent_id
└── products ← catálogo com 3 variantes de imagem
└── product_images ← galeria adicional
└── banners ← campanhas com período de exibição
└── orders ← pedidos (UUID)
└── order_items ← snapshot do produto no momento do pedido


Toda tabela de negócio tem `company_id NOT NULL`. O isolamento entre clientes é garantido em todas as queries sem exceção.

---

## Pipeline de imagens

O admin tira foto no celular (4MB+). O app comprime antes de enviar (~200kb). O servidor gera 3 variantes e salva no R2:

Flutter (image_picker)
→ flutter_image_compress (≤1200px, JPEG 78%)
→ upload multipart para Laravel
→ Intervention Image gera variantes:
thumb 300×300px ~15kb → grid de produtos, carrinho
card 600×600px ~50kb → home, destaques
full 1200×1200px ~200kb → detalhe do produto
→ salvas no Cloudflare R2
→ URLs retornadas e salvas no banco


---

## Fluxo do pedido

Cliente monta carrinho
→ preenche checkout (nome, telefone, endereço)
→ POST /api/client/orders
→ backend valida produtos e estoque
→ cria Order + OrderItems (snapshot)
→ retorna whatsapp_url
→ app abre WhatsApp com mensagem formatada
→ dono do hortifruti recebe e confirma manualmente
→ admin atualiza status no painel


---

## Como rodar localmente

### Pré-requisitos
- PHP 8.3 + Composer
- PostgreSQL 16
- Flutter 3.x
- Conta Cloudflare R2 (ou usar `local` driver para desenvolvimento)

### Backend

```bash
# Clonar e instalar
git clone <repo>
cd hortifruti-api
composer install

# Configurar ambiente
cp .env.example .env
php artisan key:generate

# Editar .env com suas credenciais de banco e R2
# DB_DATABASE, DB_USERNAME, DB_PASSWORD
# AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_ENDPOINT, AWS_BUCKET

# Banco
php artisan migrate
php artisan db:seed

# Subir servidor
php artisan serve
# → http://localhost:8000
```

Credenciais do admin criadas pelo seeder:

Email: admin@hortifruti.test
Senha: password


### App Flutter

```bash
cd freshbox_app
flutter pub get
dart run build_runner build

# Editar lib/core/constants/app_constants.dart
# baseUrl: 'http://10.0.2.2:8000/api'   ← emulador Android
# baseUrl: 'http://127.0.0.1:8000/api'  ← iOS Simulator
# companyId: '<UUID da company do seeder>'

flutter run
```

> Se o build_runner reclamar de conflito de outputs, use `dart run build_runner clean` antes de rodar `build` de novo — **não** apague os arquivos `.freezed.dart`/`.g.dart` manualmente, isso dessincroniza o cache do build_runner e causa erros de compilação difíceis de diagnosticar.

---

## Rotas da API

### Públicas (requerem header `X-Company-ID`)

| Método | Rota | Descrição |
|---|---|---|
| GET | `/client/store` | Dados da loja |
| GET | `/client/banners` | Banners ativos |
| GET | `/client/categories` | Categorias ativas |
| GET | `/client/categories/{slug}/products` | Produtos da categoria |
| GET | `/client/products/{slug}` | Detalhe do produto |
| GET | `/client/products/featured` | Produtos em destaque |
| GET | `/client/products/on-promo` | Produtos em promoção |
| GET | `/client/products/search?q=` | Busca por nome |
| POST | `/client/orders` | Criar pedido |

### Admin (requerem Bearer token + `X-Company-ID`)

| Método | Rota | Descrição |
|---|---|---|
| POST | `/auth/login` | Login |
| POST | `/auth/logout` | Logout |
| GET | `/auth/me` | Usuário logado |
| GET/POST | `/admin/categories` | Listar / criar |
| GET/PUT/DELETE | `/admin/categories/{id}` | Detalhe / editar / deletar |
| GET/POST | `/admin/products` | Listar / criar |
| POST | `/admin/products/{id}/image` | Upload de imagem |
| PATCH | `/admin/products/{id}/toggle` | Ativar / desativar |
| GET/POST | `/admin/banners` | Listar / criar |
| GET | `/admin/orders` | Listar pedidos |
| GET | `/admin/orders/{id}` | Detalhe do pedido |
| PATCH | `/admin/orders/{id}/status` | Atualizar status |
| GET/PUT | `/admin/store` | Ver / editar loja |
| POST | `/admin/store/logo` | Upload de logo |

---

## Modelo de negócio

O projeto é estruturado como produto reaproveitável:

Taxa de implantação (única)

Mensalidade por loja

Planos sugeridos:

| Plano | Funcionalidades |
|---|---|
| Vitrine | Catálogo, ofertas, banners, dados da loja |
| Pedidos | Tudo do Vitrine + carrinho + pedido via WhatsApp |
| Pro | Tudo acima + painel avançado + multiunidade |

Para ativar um novo cliente: criar `company` + `store` + `user` admin no banco. O app Flutter recebe o `companyId` via configuração — sem alterar código.

---

## Decisões técnicas relevantes

**`order_items` sem FK para `products`**
O pedido guarda um snapshot completo do produto (nome, preço, unidade) no momento da compra. Isso permite deletar ou alterar produtos sem corromper o histórico de pedidos.

**Slug único por empresa, não global**
`UNIQUE(company_id, slug)` em produtos e categorias. Dois hortifrutis diferentes podem ter produtos com o mesmo slug sem conflito.

**`business_hours` como JSON**
`{"mon":{"open":"08:00","close":"18:00"},"sun":null}`. Flexível para feriados e horários especiais sem alterar o schema.

**Gerenciamento de estado: get_it + flutter_bloc (não Riverpod)**
O projeto começou com Riverpod parcialmente implementado, mas foi revertido antes de qualquer feature de UI depender dele — troca feita cedo o suficiente para não gerar retrabalho relevante. `get_it` cuida de instâncias singleton (DioClient, repositories, GoRouter); `flutter_bloc` cuida do ciclo de vida de estado por tela.

**`Paginated<T>` genérico**
Endpoints de listagem do Laravel (`categories`, `products`, futuramente `orders` no admin) retornam paginação no formato `{data, links, meta}`. Em vez de tratar cada listagem como caso especial, existe um wrapper genérico `Paginated<T>` em `core/network/` que extrai `data`, `current_page`, `last_page` e `total` do `meta`, reaproveitado por qualquer feature paginada.

---

## Status do projeto

**Backend**
- [x] Estrutura completa (models, controllers, middleware multiempresa)
- [x] Migrations com multiempresa
- [x] Pipeline de imagens (3 variantes + R2)
- [x] Fluxo de pedido com WhatsApp

**App Flutter**
- [x] Fundação: DI (get_it), navegação (go_router), rede (Dio + interceptors)
- [x] Feature Store: model + repository, integração validada contra a API
- [x] Feature Category: model + repository, `Paginated<T>` genérico
- [ ] `CategoryBloc` + tela de Categorias
- [ ] Feature Produtos (featured, promo, busca, detalhe)
- [ ] Feature Carrinho
- [ ] Feature Checkout / Pedidos
- [ ] Autenticação (admin)
- [ ] Painel admin
- [ ] Deploy em produção
- [ ] Primeiro cliente em uso