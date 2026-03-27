# CookingCV
This a adapter CV to employes offerts with AI
This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

## Acerca del proyecto

Es un proyecto para la hackaton con ningun objetivo comercial mas alla de GANAR :D,
el proyecto usara una arquitectura Hexogal + Layared by feauteres. conectada con Supabase
en gestion de base de datos.

para la validacion de formulario se usara Zod + React Hook Forms
para la UI minimalista con Shadcn + lucide icons

### Estructura de carpetas

``
/app
  /..
/application
    /actions
        other.actions.ts
    /container
        other.container.ts
    /validations
        other.validations.ts // yup 
/domain
    /entities
        other.entity.ts
    /ports
        other.port.ts
    /use-cases
        other.cases.ts
/infrastructure
    /cache
    /db
        supabase.proxy.ts
        supabase.route.ts
        supabase.server.ts
    /adapters
        /supabase
            other.adapter.ts.ts
/features
    /other
        other-form.tsx
``
