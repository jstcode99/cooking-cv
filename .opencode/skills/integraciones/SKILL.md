---
name: integraciones
description: >
  Integraciones con servicios externos en cooking-cv: Supabase Auth, Storage (buckets reales),
  RLS, hCaptcha, Google OAuth, Github OAuth. Usar al trabajar con autenticación,
  subida de archivos, políticas RLS, mapas, o cualquier servicio externo del proyecto.
---

# Integraciones — cooking-cv

## Clientes de Supabase — cuál usar

| Contexto | Import | Cuándo |
|---|---|---|
| Server Components / Server Actions | `SupabaseServerClient()` de `@lib/supabase.server` | Lectura/escritura server-side normal |
| Operaciones admin (bypass RLS) | `SupabaseAdminClient()` de `@lib/supabase.server-admin` | Triggers, operaciones entre tenants |
| Client Components | `createClientFromLib()` de `@lib/supabase.client` | Solo para auth listeners en el cliente |
| Proxy server components | `@lib/supabase.proxy` | Componentes server con revalidación |

**Nunca inicialices `createServerClient()` o `createBrowserClient()` directamente.**

```typescript
// ✅ Server Action / Server Component
import { SupabaseServerClient } from "@lib/supabase.server";
const supabase = await SupabaseServerClient();

// ✅ Admin (bypass RLS)
import { SupabaseAdminClient } from "@lib/supabase.server-admin";
const supabase = await SupabaseAdminClient();
```

## Supabase Auth

```typescript
// Obtener usuario actual en server (siempre getUser, nunca getSession)
const { data: { user } } = await supabase.auth.getUser();

// Verificar sesión en Server Action via sessionService
const { sessionService } = await modules(cookieStore);
const userId = await sessionService.getCurrentUserId();
if (!userId) throw new Error(t("common:exceptions.unauthorized"));
```

### Roles de usuario (cookies)
```typescript
const { cookiesService } = await module(cookieStore);

const role = await cookiesService.getProfileRole();
// "admin" | "coordinator" | "agent" | "client"

const realEstateId = await cookiesService.getRealEstateId();
const realEstateRole = await cookiesService.getRealEstateRole();
```

Nombres de cookies definidos en `COOKIE_NAMES` de `@config/constants.ts`:
- `ROLE`: `"user_role"`
- `REAL_ESTATE`: `"real_estate_id"`
- `REAL_ESTATE_ROLE`: `"real_estate_role"`

## Supabase Storage — buckets reales del proyecto

```typescript
import { STORAGE_BUCKETS } from "@config/constants";

// STORAGE_BUCKETS.AVATARS          = "avatars"
```

### Subir archivo
```typescript
const supabase = await SupabaseServerClient();

const { data, error } = await supabase.storage
  .from(STORAGE_BUCKETS.SOME)
  .upload(`${some}/${id}/${fileName}`, file, {
    cacheControl: "3600",
    upsert: false,
  });

if (error) throw new Error(`Upload fallido: ${error.message}`);
```

### URL pública
```typescript
const { data } = supabase.storage
  .from(STORAGE_BUCKETS.SOME)
  .getPublicUrl(`${some}/${id}/${fileName}`);

const url = data.publicUrl;
```

### Eliminar archivo
```typescript
await supabase.storage
  .from(STORAGE_BUCKETS.SOME)
  .remove([`${some}/${id}/${fileName}`]);
```

### Límites de archivos (FILE_LIMITS de constants.ts)
```typescript
// FILE_LIMITS.AVATAR_MAX_SIZE   = 5MB
// FILE_LIMITS.LOGO_MAX_SIZE     = 2MB
// FILE_LIMITS.ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif']
```

## Google OAuth

```typescript
// modules/auth/components/google-auth.tsx
// Usa @react-oauth/google
// Variable: NEXT_PUBLIC_GOOGLE_CLIENT_ID
// Callback manejado en app/[lang]/auth/callback/route.ts
```

## hCaptcha

```typescript
// modules/auth/components — sign-up y sign-in forms
// Usa @hcaptcha/react-hcaptcha
// Variable: NEXT_PUBLIC_HCAPTCHA_SITE_KEY
```

## Notificaciones (servidor)

```typescript
// infrastructure/notifications/notification.service.ts
// Usado para notificaciones internas del sistema
import { NotificationService } from "@modules/notifications/notification.service";
```

## Integrar un servicio externo nuevo

1. Definir port en `@modules/services/<servicio>.services.ts`
3. Registrar en `@modules/module.ts`
4. Credenciales en `.env.local` (nunca hardcodeadas)
5. Acceder solo desde Server Actions — nunca desde Client Components

## Rutas de la app (`@config/routes.ts`)

```typescript
import { createRouter } from "@/i18n/router";

// En server
const routes = createRouter(lang);
routes.dashboard()
routes.properties()
routes.property(id)
routes.listings()
routes.listing(id)
routes.realEstates()
routes.realEstate(id)
routes.users()
routes.profile()
// etc.

// En client
import { useRoutes } from "@/i18n/client-router";
const routes = useRoutes();
```
