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
import { createClient } from "@supabase/server";
import { moduleValidation } from "@modules/<module>/validations/some.validation";
import { useTranslation } from "react-i18next";
import { initI18n } from "@i18n/server";

export async function createModuleAction(formData: FormData) {
  const supabase = await createClient();
  const lang = await getLangServerSide();
  const i18n = await initI18n(lang);
  const t = i18n.getFixedT(lang);
  const routes = createRouter(lang);


  const raw = Object.fromEntries(formData);
  const input = moduleValidation.parse(raw);

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error(t('module:exceptions.some'));

  const { error } = await supabase
    .from("my_entities")
    .insert({ ...input, user_id: user.id });

  if (error) throw new Error(error.message);

 revalidatePath(routes.module());
 // if neccesary 
 revalidateTag(CACHE_TAGS.MODULE.ALL, { expire: 0 });
}
```

**Reglas de actions:**
- Siempre `"use server"` al inicio del archivo
- Instanciar el cliente Supabase **dentro** del action con `createClient()` — nunca recibirlo como parámetro
- Validar con Zod (`.parse()` lanza automáticamente si hay error) usando el schema del mismo módulo (`./schema`)
- Verificar auth con `supabase.auth.getUser()` cuando la operación lo requiera
- Invalidar rutas con `revalidatePath` y/o tags con `revalidateTag`
- Sin capas intermedias: el action llama **directamente** a Supabase, no a un servicio ni adapter
- kebab-case para los nombres de los archivos `some-one.<ext>`

## Services — Queries de lectura

Todo read/query vive en `src/modules/<dominio>/services/some.service.ts`:

```typescript
import { unstable_cache } from "next/cache";
import { createClient } from "@lib/supabase/server";

// Sin cache — para reads directos o datos que cambian mucho
export async function getMyEntityById(id: string) {
  const supabase = await createClient();
  const lang = await getLangServerSide();
  const i18n = await initI18n(lang);
  const t = i18n.getFixedT(lang);
  
  const { data, error } = await supabase
    .from("my_entities")
    .select("*")
    .eq("id", id)
    .single();

  if (error) throw new Error(t('module:exceptions.some'));
  return data;
}

// Con cache — para Server Components que leen datos estables
export const getCachedMyEntities = unstable_cache(
  async () => {
    const supabase = await createClient();
    const lang = await getLangServerSide();
    const i18n = await initI18n(lang);
    const t = i18n.getFixedT(lang);
    
    const { data, error } = await supabase
      .from("my_entities")
      .select("*");

    if (error) throw new Error(t('module:exceptions.some'));
    return data;
  },
  [CACHE_TAGS.SOME.THING()],
  { revalidate: 300, tags: [CACHE_TAGS.SOME, CACHE_TAGS.SOME.KEY] },
);
```

**Reglas de services:**
- Solo lecturas (`select`) — las escrituras van siempre en `actions.ts`
- Instanciar `createClient()` **dentro** de cada función — no a nivel módulo
- Exponer dos variantes cuando aplique: función directa + `getCached*` con `unstable_cache`
- Importar el cliente desde `@lib/supabase/server` — nunca el cliente browser

## validations Zod

```typescript
// src/modules/<dominio>/schema.ts
import { z } from "zod";
import i18next from "i18next";

export const myEntitySchema = z.object({
  name: z.string().min(
    0,
    i18next.t("validations:min.numeric", {
      attribute: "built_area",
      min: "0",
    }),
  ).max(100),
  description: z.string().optional(),
});

export type MyEntityInput = z.infer<typeof myEntitySchema>;

export const defaultMyEntityValues: MyEntityInput = {
  name: "",
  description: "",
};
```

**Reglas de validations:**
- Usar **Zod** (no Yup) — `.parse()` para validar en actions, `safeParse()` cuando se quiere manejar el error manualmente
- El validation es la **fuente de verdad** de tipos: siempre `z.infer<typeof validation>` en lugar de tipos manuales
- Un archivo `validation.ts` por módulo — si crece mucho, dividir en `validation/<name>.validation.ts` dentro del módulo
- Los actions y hooks del mismo módulo lo importan con `"./schema"` (relativo)

## Formularios en Client Components

Usar `react-hook-form` con `zodResolver` y los componentes de `@components/ui/form`:

```typescript
"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import * as React from "react"
import { zodResolver } from "@hookform/resolvers/zod"
import { Controller, useForm } from "react-hook-form"
import { toast } from "sonner"
import * as z from "zod"
import { Button } from "@components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@components/ui/card"
import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@components/ui/field"
import { Input } from "@components/ui/input"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupText,
  InputGroupTextarea,
} from "@components/ui/input-group"
import { moduleValidation, ModuleInput, defaultModuleValues } from "@modules/<module>/validations/some.validation";
import { createModuleAction } from "@modules/<module>/actions/some.action";

export function MyEntityForm() {
  const { t } = useTranslation("module");
  
  const form = useForm<MyEntityInput>({
    resolver: zodResolver(moduleValidation),
    defaultValues: defaultModuleValues,
    mode: "onBlur",
  });

  async function onSubmit(data: MyEntityInput) {
    const formData = new FormData();
    Object.entries(data).forEach(([k, v]) => formData.append(k, String(v)));

    try {
      await createMyEntityAction(formData);
      toast.success(t("messages.success.sent"));
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Error inesperado");
    }
  }

  return (
    <Form {...form}>
    <form id="form-rhf-demo" onSubmit={form.handleSubmit(onSubmit)}>
      <FieldGroup>
        <Controller
          name="title"
          control={form.control}
          render={({ field, fieldState }) => (
            <Field data-invalid={fieldState.invalid}>
              <FieldLabel htmlFor="form-rhf-demo-title">
                Bug Title
              </FieldLabel>
              <Input
                {...field}
                id="form-rhf-demo-title"
                aria-invalid={fieldState.invalid}
                placeholder="Login button not working on mobile"
                autoComplete="off"
              />
              {fieldState.invalid && (
                <FieldError errors={[fieldState.error]} />
              )}
            </Field>
          )}
        />
        <Controller
          name="description"
          control={form.control}
          render={({ field, fieldState }) => (
            <Field data-invalid={fieldState.invalid}>
              <FieldLabel htmlFor="form-rhf-demo-description">
                Description
              </FieldLabel>
              <InputGroup>
                <InputGroupTextarea
                  {...field}
                  id="form-rhf-demo-description"
                  placeholder="I'm having an issue with the login button on mobile."
                  rows={6}
                  className="min-h-24 resize-none"
                  aria-invalid={fieldState.invalid}
                />
                <InputGroupAddon align="block-end">
                  <InputGroupText className="tabular-nums">
                    {field.value.length}/100 characters
                  </InputGroupText>
                </InputGroupAddon>
              </InputGroup>
              <FieldDescription>
                Include steps to reproduce, expected behavior, and what
                actually happened.
              </FieldDescription>
              {fieldState.invalid && (
                <FieldError errors={[fieldState.error]} />
              )}
            </Field>
          )}
        />
      </FieldGroup>
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
- **Path aliases `@`** siempre — nunca rutas relativas que suban más de un nivel (`../../`)
- Agrupar imports: librerías externas → `@` internos → relativos del módulo (`./`)

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
import { getCachedMyEntities } from "@modules/<module>/services/some.service.ts";
import { MyEntityList } from "@modules/<module>/components/my-entity-list";

export default async function MyEntitiesPage() {
  const entities = await getCachedMyEntities();
  return <MyEntityList entities={entities} />;
}

// ✅ Client Component — solo cuando hay interactividad
"use client";
import { SomeForm } from "@modules/<module>/components/some-form";

export default function page() {
  return <SomeForm />;
}
```

## Íconos e imágenes

- Íconos: `@iconify/react` → `<Icon icon="mdi:home" />` o `@tabler/icons-react`
- Imágenes: `next/image` con `fill` o dimensiones explícitas — nunca `<img>`

## Estilos

- **Tailwind CSS** — clases utilitarias en JSX
- `cn()` de `@lib/utils` para clases condicionales
- Variantes con `cva` (class-variance-authority) en componentes con múltiples estados
- `framer-motion` para animaciones

## Nombrado de archivos

| Tipo | Convención | Ejemplo |
|---|---|---|
| validation + tipos | `validation.ts` | `modules/<module>/validation/some.validation.ts` |
| Queries (reads) | `services.ts` | `modules/<module>/services/some.service.ts` |
| Mutaciones | `actions.ts` | `modules/<module>/actions/some.action.ts` |
| Hooks cliente | `hooks.ts` | `modules/<module>/hooks/some.hook.ts` |
| Componente | `kebab-case.tsx` | `ticket-form.tsx` |
| Hook global | `use-<nombre>.ts` | `hooks/use-mobile.ts` |
| Cliente Supabase | `client.ts / server.ts / admin.ts` | `lib/supabase/server.ts` |
