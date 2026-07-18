-- Nahueltrek — esquema de base de datos para Supabase
-- Cómo usarlo: Supabase → tu proyecto → SQL Editor → pega este archivo completo → Run.

create table if not exists destinos (
  id text primary key,
  nombre text not null,
  altitud text,
  dificultad text,
  duracion text,
  descripcion text
);

create table if not exists agenda (
  id text primary key,
  "destinoId" text references destinos(id) on delete cascade,
  fecha date,
  cupos integer default 0,
  ocupados integer default 0
);

create table if not exists mensajes (
  id text primary key,
  nombre text,
  email text,
  mensaje text,
  fecha timestamptz default now(),
  leido boolean default false
);

create table if not exists productos (
  id text primary key,
  nombre text not null,
  categoria text,
  precio numeric default 0,
  unidad text,
  descripcion text,
  disponible boolean default true
);

-- Row Level Security: lectura pública para las 4 tablas (el sitio es público),
-- escritura pública también habilitada porque el panel admin usa solo una
-- contraseña dentro de la app (no autenticación real de Supabase).
--
-- IMPORTANTE — LEE ESTO:
-- Esto significa que cualquier persona que inspeccione el código del sitio
-- (o abra las herramientas de desarrollador del navegador) podría escribir
-- directamente en destinos/agenda/productos usando tu clave "anon", sin pasar
-- por la contraseña del panel. Para un sitio en producción con datos que te
-- importa proteger, el siguiente paso recomendado es activar Supabase Auth
-- (login real con email/contraseña) y restringir INSERT/UPDATE/DELETE a
-- usuarios autenticados. Puedo ayudarte con eso cuando quieras dar ese paso.

alter table destinos enable row level security;
alter table agenda enable row level security;
alter table mensajes enable row level security;
alter table productos enable row level security;

create policy "lectura publica destinos" on destinos for select using (true);
create policy "escritura publica destinos" on destinos for all using (true) with check (true);

create policy "lectura publica agenda" on agenda for select using (true);
create policy "escritura publica agenda" on agenda for all using (true) with check (true);

create policy "lectura publica mensajes" on mensajes for select using (true);
create policy "escritura publica mensajes" on mensajes for all using (true) with check (true);

create policy "lectura publica productos" on productos for select using (true);
create policy "escritura publica productos" on productos for all using (true) with check (true);
