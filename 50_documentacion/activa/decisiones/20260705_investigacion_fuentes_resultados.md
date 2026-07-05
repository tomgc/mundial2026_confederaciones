# Investigacion de fuentes de resultados del Mundial 2026 (real, no sintetico)

Fecha de la investigacion: 2026-07-05. Todas las pruebas se hicieron con
`curl` (sin renderizado JS) contra endpoints en vivo, en modo solo lectura.
Ningun archivo del pipeline fue modificado; este documento es el unico
artefacto producido.

## Nota sobre la cita P15

Se cito `P15, POLITICA_PROYECTO.md` como restriccion no negociable (nada
sintetico ni generado por IA). Al buscar esa referencia en el documento
actual (`50_documentacion/activa/POLITICA_PROYECTO.md`) y en
`SETTINGS_Y_PROMPTS_OPERACIONALES.md`, no existe una seccion o principio
numerado "P15" en ninguno de los dos. Puede ser una cita de una version
anterior de la politica, de un traspaso no versionado en este repo, o un
error de referencia. El principio en si (no aceptar datos sinteticos como
si fueran reales) ya esta explicitamente implementado en
`30_procesamiento/32_ingesta_resultados.R` (el fallback CC0 se marca
`fuente_usada = "fallback_cc0_sintetico"` y dispara un WARN fuerte), asi
que se investigo bajo ese principio igual. Si P15 existe en otro
documento, conviene citarlo con su fuente exacta la proxima vez.

## Contexto: estado de las fuentes ya usadas por el proyecto

Antes de buscar candidatas nuevas, se verifico el estado actual de las dos
fuentes que ya usa `32_ingesta_resultados.R`, para tener una linea base.

### openfootball/worldcup.json (fuente primaria actual)

- URL: `https://raw.githubusercontent.com/openfootball/worldcup.json/master/2026/worldcup.json`
- Ultimo commit real (verificado via API de GitHub): **2026-07-04T23:05:55Z**
  ("auto-gen - week 27/6"), es decir, menos de 24 h antes de esta
  investigacion (2026-07-05). No se confirmo un desfase de 2+ dias al
  momento de esta prueba puntual; puede que el desfase citado se haya
  observado en un chequeo anterior o se refiera a otro aspecto.
- Licencia: **CC0-1.0** (confirmado via API de GitHub `/license`).
- Cobertura: 104 partidos totales, 90 con marcador (`score.ft` presente)
  al momento de la prueba, incluyendo partidos del 2026-07-04
  (Paraguay 0-1 Francia, Canada 0-3 Marruecos ya en Round of 16).

**Hallazgo critico (no es un problema de fuente, es un bug de parseo):**
el JSON de openfootball **si trae** los campos `score.et` (tiempo extra)
y `score.p` (penales) cuando el partido se resuelve fuera del tiempo
reglamentario. Ejemplo real extraido en esta prueba:

```json
// Argentina vs Cabo Verde, 2026-07-03, Round of 32
"score": { "et": [3, 2], "ft": [1, 1], "ht": [1, 0] }

// Australia vs Egipto, 2026-07-03, Round of 32
"score": { "p": [2, 4], "et": [1, 1], "ft": [1, 1], "ht": [0, 1] }
```

Pero `intentar_openfootball()` en `32_ingesta_resultados.R` solo lee
`partidos_raw$score$ft` (linea ~103 del script). Para ambos partidos de
arriba, `ft` es un empate (1-1), asi que el CSV de salida registra un
empate en fase eliminatoria sin ganador — **esto explica exactamente**
el WARN del motor Elo visto en sesiones anteriores: *"2 partido(s)
empatado(s) de eliminacion sin fase posterior jugada: W=0.5
provisional."* Los datos reales ya estan disponibles en la fuente
primaria; el pipeline simplemente no los esta leyendo.

### thestatsapi.com/fixtures.csv (validacion cruzada actual)

- URL: `https://www.thestatsapi.com/world-cup/data/fixtures.csv`
- Confirmado: el CSV **no tiene columnas de marcador** (columnas reales:
  `match_number, date, kickoff_utc, stage, group, home_team, away_team,
  stadium, host_city, match_url`). Coincide con el comentario del script:
  solo sirve para detectar partidos faltantes o mal mapeados, nunca para
  resultado.
- El dominio responde (200 OK en `/` y `/terms`), pero no es una marca de
  datos deportivos ampliamente reconocida; no se pudo verificar quien lo
  mantiene ni su politica de actualizacion mas alla de la respuesta HTTP.
  Riesgo de continuidad bajo (dominio no institucional, sin garantia
  contractual conocida).

## Candidatas nuevas probadas

### 1. ESPN API no documentada (`site.api.espn.com`)

- URL probada: `http://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard?dates=20260703`
- Resultado de la prueba: **HTTP 200**, JSON, sin necesidad de API key.
- Verificacion de actualizacion real: se confirmo el partido conocido
  Argentina vs Cabo Verde (2026-07-03) con **marcador final correcto
  3-2 (despues de tiempo extra)**, `status.type.description = "Final
  Score - After Extra Time"`.
- Para el caso mas dificil (definicion por penales), Australia vs Egipto
  trae el campo explicito `shootoutScore` por equipo (Australia 2,
  Egipto 4), `winner: true/false` y `advance: true/false` por
  competidor, ademas de una nota en lenguaje natural: *"Egypt advance
  4-2 on penalties"*. Es mas explicito que openfootball para resolver
  quien avanza, sin necesidad de interpretar `et`/`p` a mano.
- Formato: JSON anidado, requiere mapeo de nombres de equipo (usa
  `displayName` en ingles, mismo problema de alias que ya resuelve
  `mapear_codigo()`).
- API key: **no requiere**.
- Licencia / terminos de uso: **no publicada**. Es una API interna de
  ESPN usada por su propia web/app, ampliamente reutilizada por la
  comunidad pero sin contrato de uso formal. Riesgo real: puede
  cambiar de forma, agregar rate-limiting o bloquearse sin aviso.

### 2. football-data.org

- URL probada: `https://api.football-data.org/v4/competitions/WC/matches?dateFrom=2026-07-03&dateTo=2026-07-03`
- Resultado de la prueba: **HTTP 403** (`"errorCode":403`, recurso
  restringido sin suscripcion). No se pudo verificar cobertura ni
  formato de datos reales sin registrar una API key (no se genero
  ninguna cuenta ni credencial en esta sesion, por alcance: "solo
  investigacion").
- API key: **si requiere** (nivel gratuito existe segun documentacion
  publica del proveedor, pero no se probo empiricamente aqui).
- Licencia / terminos: proveedor establecido con terminos de servicio
  publicos y plan gratuito documentado (no verificado en esta sesion
  por no contar con clave). Candidata razonable si se decide registrar
  una API key en una sesion futura, con aprobacion explicita para crear
  la cuenta.

### 3. TheSportsDB

- URL probada: `https://www.thesportsdb.com/api/v1/json/3/all_leagues.php`
  (clave de prueba publica "3") y `search_all_leagues.php?s=Soccer`.
- Resultado de la prueba: **HTTP 200**, pero la liga "FIFA World Cup" **no
  aparece** en el listado de ligas disponible con la clave de prueba
  gratuita (solo ligas domesticas como Premier League, Bundesliga,
  etc.). El endpoint de busqueda de liga especifica
  (`searchleague.php?l=...`) devolvio **404**.
- Conclusion: cobertura del torneo **no disponible en el nivel
  gratuito** probado. Podria existir en un nivel de pago (no evaluado).
- **Se descarta** para este proyecto mientras no se justifique un plan
  pago.

## Tabla comparativa

| Fuente | HTTP | Requiere key | Cobertura Mundial 2026 | Resuelve ET/penales | Licencia/ToS |
|---|---|---|---|---|---|
| openfootball/worldcup.json (actual) | 200 | No | Si, completa | Si (dato existe, **no se lee**) | CC0-1.0 |
| thestatsapi.com/fixtures.csv (actual) | 200 | No | Solo calendario, sin marcador | N/A | Desconocida (dominio no institucional) |
| ESPN `site.api.espn.com` (nueva) | 200 | No | Si, completa y detallada | Si, explicito (`shootoutScore`, `winner`, `advance`) | No publicada (API no oficial) |
| football-data.org (nueva) | 403 sin key | Si | No verificado | No verificado | ToS publicos, no probados aqui |
| TheSportsDB (nueva) | 200 (endpoint) / 404 (busqueda) | No (nivel probado) | **No**, ausente en nivel gratuito | N/A | No aplica (torneo no disponible) |

## Recomendacion final

1. **Prioridad inmediata, antes de sumar cualquier fuente nueva:** corregir
   `intentar_openfootball()` en `32_ingesta_resultados.R` para que lea
   `score$et` y `score$p` cuando `score$ft` sea un empate, tomando el
   marcador de la instancia que efectivamente resolvio el partido. Esto
   resuelve el WARN de "partidos pendientes de resolucion" con la fuente
   primaria que **ya esta en el pipeline y ya es real (CC0, actualizada
   hace <24 h)** — no requiere agregar ninguna fuente nueva. (No se
   implemento este cambio en esta sesion: la tarea pedia solo
   investigacion, sin tocar codigo.)
2. **Complementaria, opcional:** agregar la API no documentada de ESPN
   (`site.api.espn.com`) como segunda validacion cruzada — reemplazando o
   sumandose a `thestatsapi.com`, que hoy no aporta marcador. ESPN si
   aporta marcador real y resuelve explicitamente los casos de tiempo
   extra/penales, sirviendo como chequeo independiente del arreglo del
   punto 1. Riesgo a documentar si se adopta: es una API no oficial, sin
   ToS publicado, y podria cambiar sin aviso; tratarla igual que
   `thestatsapi.com` hoy (validacion opcional que no bloquea el
   pipeline si falla).
3. **No usar** TheSportsDB en el nivel gratuito (sin cobertura del
   torneo) ni football-data.org sin antes decidir explicitamente crear
   una cuenta/API key (implica una decision fuera del alcance de esta
   investigacion: registrar un servicio externo).

Ninguna fuente sintetica fue considerada como reemplazo; el dataset CC0
de `mominullptr/FIFA-World-Cup-2026-Dataset` sigue documentado en el
codigo como fallback de ultima instancia con advertencia explicita, sin
cambios propuestos aqui a ese tratamiento.
