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
| Dart | 3.3+ | Linguagem |
| Riverpod | 2.5 | Gerenciamento de estado |
| freezed | 2.5 | Modelos imutáveis |
| Dio | 5.5 | Cliente HTTP |
| go_router | 14 | Navegação |

---

## Funcionalidades

### App cliente
- Vitrine com banners e campanhas programadas
- Catálogo por categorias com busca
- Ofertas do dia e produtos em destaque
- Detalhe do produto com imagem, preço e unidade (kg, un, bandeja...)
- Carrinho persistente (mantido ao fechar o app)
- Checkout com entrega ou retirada
- Pedido enviado como mensagem formatada no WhatsApp
- Informações da loja: horário, endereço, contato

### Painel admin (no próprio app)
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

```
app/
├── Actions/
│   └── PlaceOrderAction.php       # orquestra criação do pedido
├── Http/
│   ├── Controllers/Api/
│   │   ├── AuthController.php
│   │   ├── Admin/                 # endpoints autenticados
│   │   └── Client/                # endpoints públicos
│   ├── Middleware/
│   │   └── ResolveCompany.php     # resolve company_id por header
│   ├── Requests/                  # validação por FormRequest
│   └── Resources/                 # serialização das responses
├── Models/                        # Company, Store, Category, Product...
└── Services/
    ├── ImageService.php           # pipeline de imagens (3 variantes)
    └── WhatsAppService.php        # monta URL do pedido
```

### App Flutter — estrutura de pastas

```
lib/
├── core/
│   ├── network/        # DioClient, endpoints, exceções
│   ├── storage/        # wrapper SharedPreferences
│   ├── utils/          # formatação de moeda, helper WhatsApp
│   └── constants/      # baseUrl, companyId
├── features/
│   ├── auth/           # login, AuthNotifier
│   ├── catalog/        # categorias, produtos, busca
│   ├── cart/           # CartNotifier, CartState, CartItem
│   ├── checkout/       # CheckoutNotifier, formulário
│   ├── home/           # banners, destaques
│   └── store/          # dados operacionais da loja
├── shared/
│   └── widgets/        # ErrorRetryWidget, CachedImage, PromoBadge...
├── app/
│   ├── router.dart     # go_router com guards de rota
│   └── theme.dart      # ThemeData
└── main.dart
```

Cada feature segue a separação `data → domain → presentation`. Uma feature nunca importa outra diretamente — comunicação é via providers do Riverpod.

### Banco de dados

```
companies          ← raiz do multiempresa (UUID)
  └── users        ← admins do painel
  └── stores       ← dados operacionais da loja
  └── categories   ← hierarquia com parent_id
  └── products     ← catálogo com 3 variantes de imagem
      └── product_images  ← galeria adicional
  └── banners      ← campanhas com período de exibição
  └── orders       ← pedidos (UUID)
      └── order_items     ← snapshot do produto no momento do pedido
```

Toda tabela de negócio tem `company_id NOT NULL`. O isolamento entre clientes é garantido em todas as queries sem exceção.

---

## Pipeline de imagens

O admin tira foto no celular (4MB+). O app comprime antes de enviar (~200kb). O servidor gera 3 variantes e salva no R2:

```
Flutter (image_picker)
  → flutter_image_compress (≤1200px, JPEG 78%)
  → upload multipart para Laravel
  → Intervention Image gera variantes:
      thumb  300×300px  ~15kb  → grid de produtos, carrinho
      card   600×600px  ~50kb  → home, destaques
      full  1200×1200px ~200kb → detalhe do produto
  → salvas no Cloudflare R2
  → URLs retornadas e salvas no banco
```

---

## Fluxo do pedido

```
Cliente monta carrinho
  → preenche checkout (nome, telefone, endereço)
  → POST /api/client/orders
  → backend valida produtos e estoque
  → cria Order + OrderItems (snapshot)
  → retorna whatsapp_url
  → app abre WhatsApp com mensagem formatada
  → dono do hortifruti recebe e confirma manualmente
  → admin atualiza status no painel
```

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
```
Email:  admin@hortifruti.test
Senha:  password
```

### App Flutter

```bash
cd hortifruti-app
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Editar lib/core/constants/app_constants.dart
# baseUrl: 'http://10.0.2.2:8000/api'   ← emulador Android
# baseUrl: 'http://127.0.0.1:8000/api'  ← iOS Simulator
# companyId: '<UUID da company do seeder>'

flutter run
```

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

```
Taxa de implantação (única)
  + Mensalidade por loja
```

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

**`CartNotifier` síncrono**
`SharedPreferences` é inicializado antes do `runApp` e injetado via `ProviderScope.overrides`. O `build()` do notifier é síncrono — sem `AsyncNotifier`, sem tela de loading para o carrinho.

**`.select()` nos cards de produto**
`ref.watch(cartNotifierProvider.select((s) => s.quantityOf(id)))` garante que cada card rebuilda apenas quando a quantidade do seu produto específico muda — não quando qualquer item do carrinho muda.

---

## Status do projeto

- [x] Backend completo e testado
- [x] Migrations com multiempresa
- [x] Pipeline de imagens (3 variantes + R2)
- [x] Fluxo de pedido com WhatsApp
- [ ] App Flutter — em desenvolvimento
- [ ] Deploy em produção
- [ ] Primeiro cliente em uso