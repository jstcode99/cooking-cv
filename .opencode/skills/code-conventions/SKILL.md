---
name: code-conventions
description: >
  Convenciones de código del proyecto — TypeScript, Server Actions, React,
  formularios, hooks, cache. Usar SIEMPRE al escribir o revisar cualquier
  archivo TypeScript/React del proyecto, o cuando el usuario pregunte cómo implementar algo.
---

# Convenciones de Código — Arquitectura Modular

## Server Actions

Todo action vive en `src/modules/<dominio>/actions.ts` con esta estructura exacta:

```typescript
"use server";

import { revalidatePath, revalidateTag } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { myEntitySchema } from "./schema";

export async function createMyEntityAction(formData: FormData) {
  const supabase = await createClient();

  const raw = Object.fromEntries(formData);
  const input = myEntitySchema.parse(raw);

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Unauthorized");

  const { error } = await supabase
    .from("my_entities")
    .insert({ ...input, user_id: user.id });

  if (error) throw new Error(error.message);

  revalidatePath("/dashboard/my-entities");
}
```

**Reglas de actions:**
- Siempre `"use server"` al inicio del archivo
- Instanciar el cliente Supabase **dentro** del action con `createClient()` — nunca recibirlo como parámetro
- Validar con Zod (`.parse()` lanza automáticamente si hay error) usando el schema del mismo módulo (`./schema`)
- Verificar auth con `supabase.auth.getUser()` cuando la operación lo requiera
- Invalidar rutas con `revalidatePath` y/o tags con `revalidateTag`
- Sin capas intermedias: el action llama **directamente** a Supabase, no a un servicio ni adapter

## Services — Queries de lectura

Todo read/query vive en `src/modules/<dominio>/services.ts`:

```typescript
import { unstable_cache } from "next/cache";
import { createClient } from "@/lib/supabase/server";

// Sin cache — para reads directos o datos que cambian mucho
export async function getMyEntityById(id: string) {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("my_entities")
    .select("*")
    .eq("id", id)
    .single();

  if (error) throw new Error(error.message);
  return data;
}

// Con cache — para Server Components que leen datos estables
export const getCachedMyEntities = unstable_cache(
  async () => {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("my_entities")
      .select("*");

    if (error) throw new Error(error.message);
    return data;
  },
  ["my-entities-all"],
  { revalidate: 300, tags: ["my-entities"] },
);
```

**Reglas de services:**
- Solo lecturas (`select`) — las escrituras van siempre en `actions.ts`
- Instanciar `createClient()` **dentro** de cada función — no a nivel módulo
- Exponer dos variantes cuando aplique: función directa + `getCached*` con `unstable_cache`
- Importar el cliente desde `@/lib/supabase/server` — nunca el cliente browser

## Schemas Zod

```typescript
// src/modules/<dominio>/schema.ts
import { z } from "zod";

export const myEntitySchema = z.object({
  name: z.string().min(1, "El nombre es requerido").max(100),
  description: z.string().optional(),
});

export type MyEntityInput = z.infer<typeof myEntitySchema>;

export const defaultMyEntityValues: MyEntityInput = {
  name: "",
  description: "",
};
```

**Reglas de schemas:**
- Usar **Zod** (no Yup) — `.parse()` para validar en actions, `safeParse()` cuando se quiere manejar el error manualmente
- El schema es la **fuente de verdad** de tipos: siempre `z.infer<typeof schema>` en lugar de tipos manuales
- Un archivo `schema.ts` por módulo — si crece mucho, dividir en `schema/<nombre>.schema.ts` dentro del módulo
- Los actions y hooks del mismo módulo lo importan con `"./schema"` (relativo)

## Formularios en Client Components

Usar `react-hook-form` con `zodResolver` y los componentes de `@/components/ui/form`:

```typescript
"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import { Form } from "@/components/ui/form";
import { myEntitySchema, MyEntityInput, defaultMyEntityValues } from "../schema";
import { createMyEntityAction } from "../actions";

export function MyEntityForm() {
  const form = useForm<MyEntityInput>({
    resolver: zodResolver(myEntitySchema),
    defaultValues: defaultMyEntityValues,
    mode: "onBlur",
  });

  async function onSubmit(data: MyEntityInput) {
    const formData = new FormData();
    Object.entries(data).forEach(([k, v]) => formData.append(k, String(v)));

    try {
      await createMyEntityAction(formData);
      toast.success("Creado correctamente");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Error inesperado");
    }
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)}>
        {/* Usar <Form.Field>, <Form.Item>, <Form.Label>, <Form.Control>, <Form.Message> */}
        {/* Para formularios grandes, dividir en secciones con <Form.Set> */}
      </form>
    </Form>
  );
}
```

**Reglas de formularios:**
- Siempre `zodResolver` — nunca `yupResolver`
- Importar schema y tipos desde `"../schema"` (mismo módulo, relativo)
- Llamar el action directamente — sin hooks wrapper intermedios
- `mode: "onBlur"` por defecto para validación
- Dividir formularios grandes en secciones con `<Form.Set>`

## TypeScript

- **Sin `any`** — excepto al tipar rows crudos de Supabase antes de castear
- **`interface` para props y contratos de componentes**, `type` para uniones y aliases
- **Sin `React.FC`** — funciones normales con destructuring de props
- **Path aliases `@/`** siempre — nunca rutas relativas que suban más de un nivel (`../../`)
- Agrupar imports: librerías externas → `@/` internos → relativos del módulo (`./`)

```typescript
// ✅ Props con interface
interface MyComponentProps {
  entity: MyEntityInput;
  onSave?: () => void;
}

export function MyComponent({ entity, onSave }: MyComponentProps) { ... }

// ❌ Evitar
const MyComponent: React.FC<Props> = ...
```

## React / Next.js

- **Server Components por defecto** — `"use client"` solo para: hooks de estado, event handlers, `useState`, `useEffect`, APIs de browser
- Las páginas en `app/<ruta>/page.tsx` importan **directamente** desde el módulo correspondiente
- No existe una capa de contenedor entre la página y el módulo

```typescript
// ✅ Server Component — llama directo al service del módulo
import { getCachedMyEntities } from "@/modules/my-entities/services";
import { MyEntityList } from "@/modules/my-entities/components/my-entity-list";

export default async function MyEntitiesPage() {
  const entities = await getCachedMyEntities();
  return <MyEntityList entities={entities} />;
}

// ✅ Client Component — solo cuando hay interactividad
"use client";
import { MyEntityForm } from "@/modules/my-entities/components/my-entity-form";

export default function NewMyEntityPage() {
  return <MyEntityForm />;
}
```

## Íconos e imágenes

- Íconos: `@iconify/react` → `<Icon icon="mdi:home" />` o `@tabler/icons-react`
- Imágenes: `next/image` con `fill` o dimensiones explícitas — nunca `<img>`

## Estilos

- **Tailwind CSS** — clases utilitarias en JSX
- `cn()` de `@/lib/utils` para clases condicionales
- Variantes con `cva` (class-variance-authority) en componentes con múltiples estados
- `framer-motion` para animaciones

## Nombrado de archivos

| Tipo | Convención | Ejemplo |
|---|---|---|
| Schema + tipos | `schema.ts` | `modules/tickets/schema.ts` |
| Queries (reads) | `services.ts` | `modules/tickets/services.ts` |
| Mutaciones | `actions.ts` | `modules/tickets/actions.ts` |
| Hooks cliente | `hooks.ts` | `modules/tickets/hooks.ts` |
| Componente | `kebab-case.tsx` | `ticket-form.tsx` |
| Hook global | `use-<nombre>.ts` | `hooks/use-mobile.ts` |
| Cliente Supabase | `client.ts / server.ts / admin.ts` | `lib/supabase/server.ts` |
