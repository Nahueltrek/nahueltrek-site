# Nahueltrek — sitio autoadministrable

Landing pública (Inicio, Destinos, Agenda, Tienda, Contacto) + panel de administración
(Destinos, Agenda, Tienda, Mensajes) con datos guardados en Supabase.

## 1. Requisitos

- Node.js 18 o superior instalado en tu computador.
- Una cuenta gratuita en [supabase.com](https://supabase.com).
- Una cuenta en [github.com](https://github.com).

## 2. Crear el backend (Supabase)

1. Entra a [supabase.com](https://supabase.com) → **New project**.
2. Cuando el proyecto esté listo, ve a **SQL Editor** → pega el contenido completo
   de `supabase-schema.sql` (incluido en este proyecto) → **Run**. Esto crea las
   4 tablas (`destinos`, `agenda`, `mensajes`, `productos`).
3. Ve a **Project Settings → API**. Copia:
   - **Project URL**
   - **anon public key**

## 3. Configurar el proyecto en tu computador

```bash
# Descomprime el proyecto y entra a la carpeta
cd nahueltrek-site

# Instala dependencias
npm install

# Crea tu archivo de variables de entorno
cp .env.example .env
```

Abre `.env` y pega tu URL y anon key de Supabase:

```
VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
VITE_SUPABASE_ANON_KEY=tu-anon-key
```

Prueba localmente:

```bash
npm run dev
```

Abre la URL que te muestre la terminal (normalmente `http://localhost:5173`).
La primera vez que cargue, el sitio sembrará automáticamente los destinos y
productos de ejemplo en tus tablas de Supabase.

## 4. Subir el código a GitHub

```bash
git init
git add .
git commit -m "Primera versión del bosquejo"
```

Crea un repositorio nuevo (vacío, sin README) en GitHub, luego:

```bash
git remote add origin https://github.com/TU-USUARIO/nahueltrek-site.git
git branch -M main
git push -u origin main
```

## 5. Publicar el sitio (hosting)

La forma más simple es [Vercel](https://vercel.com) o [Netlify](https://netlify.com),
ambos gratuitos para este tamaño de proyecto y con despliegue automático en cada
`git push`.

**Vercel:**
1. "Add New Project" → importa tu repo de GitHub.
2. Framework: detecta Vite automáticamente.
3. En "Environment Variables" agrega `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`
   con los mismos valores de tu `.env`.
4. Deploy.
5. Cuando tengas dominio propio (nahueltrek.cl), lo conectas desde
   Project Settings → Domains.

**Netlify** funciona igual: conecta el repo, agrega las mismas variables de
entorno en Site settings → Environment variables, y build command `npm run build`
con publish directory `dist`.

## 6. Contraseña del panel admin

Por ahora el panel usa una contraseña simple definida en el código
(`ADMIN_PASSCODE` en `src/App.jsx`, valor actual: `trek2026`). Cámbiala antes
de publicar. Ten presente que esto es una protección básica, no autenticación
real — cualquiera con acceso al código fuente puede verla. Ver la nota de
seguridad en `supabase-schema.sql` sobre el siguiente paso recomendado
(Supabase Auth) antes de depender de esto para datos sensibles.

## 7. Cabeceras de seguridad (headers)

El proyecto ya incluye configuración lista para las cabeceras mínimas
recomendadas, en dos formatos (usa el que corresponda a tu hosting):

- `vercel.json` → si despliegas en Vercel.
- `public/_headers` → si despliegas en Netlify.

Incluyen:

- **Strict-Transport-Security (HSTS)**: fuerza HTTPS por 2 años, incluyendo subdominios.
- **Content-Security-Policy (CSP)**: solo permite cargar scripts y estilos desde el propio sitio, fuentes de Google Fonts, imágenes propias/embebidas (`data:`), y conexiones a tu proyecto de Supabase (`*.supabase.co`). Todo lo demás queda bloqueado por defecto.
- **X-Content-Type-Options: nosniff**: evita que el navegador intente adivinar tipos de archivo.
- **X-Frame-Options / frame-ancestors**: evita que el sitio se pueda incrustar en un iframe ajeno (clickjacking).
- **Referrer-Policy** y **Permissions-Policy**: reducen filtración de datos de navegación y bloquean acceso a cámara/micrófono/geolocalización, que este sitio no usa.

**Sobre CORS**: este proyecto es un sitio estático sin API propia (todo el
backend es Supabase, que gestiona su propio CORS), así que no hay cabeceras
CORS que configurar de tu lado por ahora. Si más adelante agregas funciones
serverless propias (por ejemplo, una función de Vercel para procesar el
formulario de contacto en el servidor en vez de escribir directo a Supabase
desde el navegador), esa función sí debería responder con
`Access-Control-Allow-Origin` restringido a tu dominio (`https://nahueltrek.cl`),
no a `*`.

Si actualizas el CSP más adelante (por ejemplo, agregas Google Analytics u
otro script de terceros), tendrás que sumar su dominio a `script-src` o
`connect-src` en ambos archivos, o el navegador lo bloqueará.


## Estructura del proyecto

```
src/
  App.jsx              → toda la interfaz (sitio público + panel admin)
  lib/supabaseClient.js → conexión a Supabase
  lib/api.js            → funciones para leer/guardar datos
supabase-schema.sql      → esquema de base de datos
.env.example              → variables de entorno necesarias
```
