---
name: workflows
description: >
  Flujos de trabajo del proyecto cooking-cv: desarrollo local, migraciones Supabase,
  cache tags, testing con Vitest, deploy. Usar al preguntar sobre comandos, migraciones,
  cache, tests, o cualquier tarea del ciclo de desarrollo.
---

# Flujos de Trabajo — cooking-cv

## Comandos del proyecto

```bash
# Desarrollo
bun dev                        # Next.js dev server
bun build                      # build de producción
bun lint                       # ESLint

# Testing
bun test                       # Vitest watch mode
bun test:run                   # una ejecución (CI)
bun test:watch                 # watch explícito
bun test:coverage              # con cobertura

# Supabase local
bun supabase:start             # levanta Docker + Supabase local
bun supabase:stop              # detiene Supabase
bun supabase:status            # estado de servicios
bun supabase:reset             # reset completo de BD local
bun supabase:migration:new     # crear migración nueva

# Supabase producción
bun supabase:db:push           # aplica migraciones en producción
bun supabase:gen:types         # genera tipos → types/supabase.ts

# TypeScript
bun tsc --noEmit               # type check sin compilar
```

## Migraciones de base de datos

```bash
# 1. Crear migración
bun supabase:migration:new nombre-descriptivo
# → supabase/migrations/<timestamp>_nombre-descriptivo.sql

# 2. Escribir el SQL

# 3. Aplicar en local
bun supabase:reset

# 4. Regenerar tipos
bun supabase:gen:types
# → tipos/supabase.ts

# 5. Aplicar en producción
bun supabase:db:push
```

### Template de migración

```sql
-- Tabla con RLS
CREATE TABLE IF NOT EXISTS public.mi_tabla (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  some_id uuid NOT NULL REFERENCES public.some(id) ON DELETE CASCADE,
  name          text NOT NULL,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

ALTER TABLE public.mi_tabla ENABLE ROW LEVEL SECURITY;

-- Definir polices
CREATE POLICY "some police"
  ON public.mi_tabla FOR ALL
  USING (
    id IN (
    SELECT id FROM public.some_agents
      WHERE id = auth.uid()
    )
  );

-- Índices
CREATE INDEX IF NOT EXISTS idx_mi_tabla_some ON public.some(some_fk_id);
CREATE INDEX IF NOT EXISTS idx_some_created_at ON public.some(created_at DESC);
```

## Cache — CACHE_TAGS

Todos los tags están en `@config/constants.ts`. Usar **siempre** las constantes, nunca strings crudos, si se crea un feauture con entidad nueva documentar en actuales:

```typescript
// En Server Actions — invalidar al mutar
revalidateTag(CACHE_TAGS.SOME.ALL, { expire: 0 });
revalidateTag(CACHE_TAGS.SOME.DETAIL(id), { expire: 0 });
revalidateTag(CACHE_TAGS.SOME.PRINCIPAL, { expire: 0 });

//example:
revalidateTag(CACHE_TAGS.SOME.PRINCIPAL, { expire: 0 });
revalidateTag(CACHE_TAGS.SOME.BY_REAL_ESTATE(real_estate_id), { expire: 0 });

// En Services — leer con cache
unstable_cache(fn, CACHE_TAGS.KEY.SOME() | CACHE_TAGS.KEY.SOME, { revalidate: 300, tags: [CACHE_TAGS.SOME, CACHE_TAGS.SOME] })

//example: 
  getCachedById(id: string) {
    return unstable_cache(
      async () => this.service.findById(id),
      [CACHE_TAGS.SOME.KEYS.BY_ID(id)],
      {
        revalidate: 300,
        tags: [CACHE_TAGS.SOME.PRINCIPAL, CACHE_TAGS.SOME.DETAIL(id)],
      },
    )();
  }
```

Tags actuales: `

`.

**Al añadir una entidad nueva**, agregar sus tags en `constants.ts`:
```typescript
SOME: {
  PRINCIPAL: "some",
  ALL: "some:all",
  COUNT: "some-count",
  DETAIL: (id: string) => `some:${id}`,
  KEYS: {
    ALL: (filter?: object) =>
      filter ? `some:all:${JSON.stringify(filter)}` : "some:all",
      BY_ID: (id: string) => `some:${id}`
  }
},
```

## Testing

### Stack
- **Vitest 2** + **Testing Library** para unit/integration
- **Playwright** para E2E

### Patrón — servicios de dominio (prioridad)

```typescript
// __tests__/domain/services/my-entity.service.test.ts
import { describe, it, expect, vi, beforeEach } from "vitest";
import { SomeService } from "@/domain/services/my-entity.service";

describe("SomeService", () => {
  let service: SomeService;

  beforeEach(() => {
    mockRepo = {
      findById: vi.fn(),
      create: vi.fn(),
      delete: vi.fn(),
      // ...todos los métodos del port
    };
    service = new SomeService(mockRepo);
  });

  it("crea entidad correctamente", async () => {
    vi.mocked(mockRepo.create).mockResolvedValue({ id: "1", name: "Test" });
    const result = await service.create({ name: "Test" });
    expect(result.name).toBe("Test");
    expect(mockRepo.create).toHaveBeenCalledWith({ name: "Test" });
  });
});
```

### Patrón — componentes React

```typescript
// __tests__/features/my-feature/my-component.test.tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

it("muestra error si campo vacío", async () => {
  render(<MyForm />);
  await userEvent.click(screen.getByRole("button", { name: /guardar/i }));
  expect(screen.getByText(/requerido/i)).toBeInTheDocument();
});
```

Setup en `__tests__/setup/components.tsx` — revisar para wrappers de providers.

### Qué NO testear directamente
- Adapters de Supabase (testear el servicio con mock del port)
- Server Actions directamente
- Componentes de página de Next.js

## Gestión de issues

**Solo Linear** — nunca GitHub Issues ni otros tableros.
Ver skill `linear-planning` (`.opencode/skills/linear-planning/`) para el flujo completo.

## Variables de entorno

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=    # solo server-side

# Google Maps
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=

# hCaptcha
NEXT_PUBLIC_HCAPTCHA_SITE_KEY=

# Google OAuth
NEXT_PUBLIC_GOOGLE_CLIENT_ID=
```

## Checklist antes de hacer commit

- [ ] `bun tsc --noEmit` sin errores
- [ ] `bun test:run` pasa
- [ ] `bun lint` sin warnings nuevos
- [ ] Si hubo cambios de schema: migración creada y tipos regenerados
- [ ] Cache tags invalidados en los actions correspondientes
- [ ] Sin `any` nuevo en TypeScript (excepto mappers)
- [ ] Traducciones añadidas en `locales/es/` y `locales/en/`
