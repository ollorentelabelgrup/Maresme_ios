# CLAUDE.md — Maresme iOS

## Proyecto

App iOS nativa para **Maresme.es** — plataforma inmobiliaria y lifestyle del Maresme.

- **Repositorio backend (Laravel):** `/Users/macbookpro/Documents/www/maresme.es` (rama `main`)
- **Repositorio iOS:** este proyecto (rama `main`)
- **API base:** `https://maresme.es/api/v1`

---

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Lenguaje | Swift 6 |
| UI | SwiftUI (iOS 17.0+) |
| Navegación | TabView + NavigationStack |
| Estado | `@Observable` (iOS 17) |
| Networking | `actor APIClient` (URLSession nativa, sin librerías externas) |
| Auth | Laravel Sanctum — Bearer token en Keychain |
| Concurrencia | Swift Concurrency (`async/await`) |
| Xcode | 26.5 |

### Flags de proyecto críticos (`project.pbxproj`)

```
IPHONEOS_DEPLOYMENT_TARGET = 17.0
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor   ← IMPORTANTE: afecta toda la arquitectura
SWIFT_APPROACHABLE_CONCURRENCY = YES
```

---

## Arquitectura

```
Maresme/
├── Core/
│   ├── Config.swift                  — URLs, timeouts, Keychain keys
│   ├── Networking/
│   │   ├── APIClient.swift           — actor, request/decode/validate
│   │   ├── APIError.swift            — enum APIError: Error
│   │   ├── APIResponse.swift         — WrappedResponse<T>, PaginatedResponse<T>
│   │   └── HTTPMethod.swift          — enum HTTPMethod
│   └── Services/
│       ├── AuthService.swift         — login/register/logout/me
│       ├── SessionManager.swift      — @Observable, fuente de verdad auth
│       ├── KeychainService.swift     — token persistido en Keychain
│       └── DeviceService.swift       — APNs skeleton (MB-7)
├── Models/
│   ├── UserModel.swift               — coincide con UserResource del backend
│   ├── AgencyModel.swift             — coincide con AgencyResource
│   ├── PropertyCard.swift            — listado ligero
│   ├── ZoneModel.swift
│   ├── FavoriteModel.swift
│   ├── AlertModel.swift
│   ├── Recommendation.swift
│   └── AppNotification.swift
├── DesignSystem/
│   ├── MaresmeColors.swift           — Color extensions (maresmeBlue, etc.)
│   ├── MaresmeTypography.swift       — Font extensions
│   └── Components/
│       ├── PrimaryButton.swift
│       ├── LoadingView.swift
│       ├── EmptyStateView.swift
│       └── BadgeView.swift
├── Features/
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   ├── RegisterView.swift
│   │   └── AuthViewModel.swift       — @Observable, llama AuthService
│   ├── Home/HomeView.swift           — MÍNIMO: solo info usuario + sesión
│   ├── Search/SearchView.swift       — placeholder MB-1
│   ├── Favorites/FavoritesView.swift — placeholder MB-2
│   ├── Alerts/AlertsView.swift       — placeholder MB-3
│   └── Profile/ProfileView.swift     — placeholder
├── AppRootView.swift                 — switch isAuthenticated → TabView/LoginView
├── MaresmeApp.swift                  — @State SessionManager, .environment(session)
└── Preview Content/
    ├── PreviewData.swift             — datos mock estáticos
    └── MockAPIClient.swift           — actor MockAPIClient para previews
```

---

## Fases completadas

### MB-6 — SwiftUI Foundation (commit `87de2ee`)

Arquitectura iOS completa:
- `actor APIClient` con URLSession nativa
- `@Observable SessionManager` como fuente de verdad de auth
- `KeychainService` para token persistente
- Todos los modelos alineados con los Resources del backend
- DesignSystem con colores y tipografía Maresme
- Flujos de Auth (Login/Register) funcionales
- Shell de 5 tabs con NavigationStack
- HomeView minimal (solo usuario + estado sesión)

**Estado:** Login y Register funcionando en producción. ✅

---

## Gotchas críticos Swift 6 + SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor

Estas restricciones afectan TODO el proyecto. Cualquier nuevo código debe tenerlas en cuenta.

### 1. `actor APIClient` NO es @MainActor

El actor tiene su propio executor. Con `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, todo lo que se llame desde el actor debe ser accesible de forma `nonisolated`.

**Soluciones aplicadas:**
- `nonisolated(unsafe) static let shared = APIClient()` — singleton accesible desde cualquier contexto
- `nonisolated(unsafe) static let isoWithMs/isoWithoutMs` — formatters no-Sendable como estáticos del actor
- `nonisolated static func` en todos los métodos de `KeychainService`
- `nonisolated init(from:)` explícito en `MessageResponse` y `ValidationErrorResponse`
- `Endpoint.encodedBody: Data?` — el body se pre-codifica en el call site (@MainActor) y se pasa como `Data` (Sendable)

### 2. `Tab(_, systemImage:content:)` requiere iOS 18

Usar siempre el patrón de iOS 17:
```swift
// ✅ iOS 17
View().tabItem { Label("Título", systemImage: "icon") }

// ❌ iOS 18+ only
Tab("Título", systemImage: "icon") { View() }
```

### 3. `keyDecodingStrategy = .convertFromSnakeCase` + `CodingKeys` — TRAMPA

Con `convertFromSnakeCase`, el decoder convierte **primero** los keys del JSON a camelCase y **luego** los compara con los raw values de `CodingKeys`.

**Consecuencia:** NO usar raw values snake_case en CodingKeys cuando el decoder ya tiene `convertFromSnakeCase`.

```swift
// ❌ ROTO — "email_verified" no coincide con la clave ya convertida "emailVerified"
enum CodingKeys: String, CodingKey {
    case emailVerified = "email_verified"
}

// ✅ CORRECTO — dejar que convertFromSnakeCase actúe sin CodingKeys
struct UserModel: Decodable {
    let emailVerified: Bool   // JSON "email_verified" → convertFromSnakeCase → emailVerified ✓
    let createdAt: Date?      // JSON "created_at" → convertFromSnakeCase → createdAt ✓
}
```

**Regla:** Solo usar `CodingKeys` cuando el campo JSON tiene un nombre completamente diferente al de Swift (no solo snake_case vs camelCase).

### 4. Carbon `toISOString()` devuelve 6 decimales (microsegundos)

`"2026-06-10T07:30:53.116553Z"` — `ISO8601DateFormatter` con `.withFractionalSeconds` solo gestiona 3 cifras de forma fiable.

**Fix en `APIClient.init()`:** el `dateDecodingStrategy` normaliza la cadena truncando a 3 decimales antes de parsear.

### 5. `Button` en SwiftUI — sintaxis sin ambigüedad

```swift
// ✅ Correcto en Swift 6 / Xcode 26
Button {
    action()
} label: {
    ZStack { ... }   // usar ZStack, no Group (Xcode 26 confunde Group con Table.Group)
}
```

---

## Contrato API backend

### Auth

```
POST /api/v1/auth/login      → { data: { access_token, token_type, user: UserResource } }
POST /api/v1/auth/register   → { data: { access_token, token_type, user: UserResource } }
POST /api/v1/auth/logout     → { message: "..." }
GET  /api/v1/me              → { data: { user, agency, unread_notifications_count, active_sessions_count } }
```

**Campos obligatorios en login/register:** `email`, `password`, `device_name` (string, max 100).

### UserResource (campos exactos)

```json
{
  "id": 2,
  "ulid": "01KTK3Q6NJCX7GQRRDV7HKRZTA",
  "name": "Oscar",
  "email": "info@oscarllorente.com",
  "phone": null,
  "avatar": null,
  "bio": null,
  "role": "admin",
  "email_verified": true,
  "created_at": "2026-06-10T07:30:53.116553Z"
}
```

**Roles existentes:** `user`, `professional`, `admin`, `super_admin`

### Headers obligatorios en todas las requests

```
Accept: application/json
Content-Type: application/json
Authorization: Bearer <sanctum_token>   (excepto login/register)
```

---

## Próxima fase: MB-7 — Push Notifications + Device Tokens

Endpoints ya implementados en el backend (MB-5):

```
POST   /api/v1/notifications/device-tokens      — registrar APNs token
DELETE /api/v1/notifications/device-tokens/{uuid}
GET    /api/v1/notifications                    — lista notificaciones
POST   /api/v1/notifications/{id}/read
POST   /api/v1/notifications/read-all
DELETE /api/v1/notifications/{id}
```

`DeviceService.swift` tiene el skeleton preparado. Pendiente:
1. Solicitar permisos APNs (`UNUserNotificationCenter`)
2. Registrar token en el backend tras login
3. `NotificationCenter` view en Features/

---

## Roadmap móvil

| Fase | Estado | Descripción |
|------|--------|-------------|
| MB-0.1 | ✅ Backend | API auth base (login, register, me) |
| MB-0.1.5 | ✅ Backend | Google Login, social_accounts |
| MB-0.2 | ✅ Backend | OTP, sessions, reset password |
| MB-1 | ✅ Backend | Properties API (listado, detalle, featured, zonas) |
| MB-2 | ✅ Backend | Favoritos API |
| MB-3 | ✅ Backend | Alertas/SavedSearches API |
| MB-4 | ✅ Backend | Recomendaciones API |
| MB-5 | ✅ Backend | Notificaciones + Device tokens API |
| MB-6 | ✅ iOS | SwiftUI Foundation — Auth funcional |
| MB-7 | 🔜 iOS | Push Notifications + Device tokens |
| MB-8 | 🔜 iOS | Listado y detalle de propiedades |
| MB-9 | 🔜 iOS | Favoritos |
| MB-10 | 🔜 iOS | Alertas |

---

## Entorno de desarrollo

- El backend (`maresme.es`) está en producción — se puede llamar directamente desde el simulador
- No hay entorno de staging — usar credenciales reales de usuario `admin`
- El `.env` del backend NUNCA se commitea (tiene credenciales Google OAuth)
- Para probar la API: `curl -X POST https://maresme.es/api/v1/auth/login -H "Accept: application/json" -H "Content-Type: application/json" -d '{"email":"...","password":"...","device_name":"debug"}'`
