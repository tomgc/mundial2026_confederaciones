# Decisión: prohibición permanente de datos sintéticos

**Fecha:** 2026-07-04. **Sesión:** 5. **Pendiente que resuelve:** P15.

## Decisión

Ninguna fuente de datos del proyecto (presente o futura) puede ser
sintética o ficticia. Toda fuente nueva debe validarse contra 2-3
fuentes independientes cuando sea posible. Todo fallback debe declarar
explícitamente su naturaleza (real vs. potencialmente sintético) en el
log de cada corrida donde se activa, no solo en el nombre de la URL o
un comentario de código.

## Origen

Instrucción explícita y permanente del usuario en sesión 4, tras
detectar en producción que `resultados_partidos.csv` usaba el fallback
CC0 (`mominullptr/FIFA-World-Cup-2026-Dataset`) con resultados que no
correspondían al torneo real. Causa raíz: `worldfootballR`/FBref
(fuente primaria original) archivado desde sept-2025, fallback activo
sin verificación de facto desde la sesión 1.

## Alternativas consideradas

- **CSV manual del usuario:** descartada, el usuario no quiere ingresar
  datos a mano.
- **Solo `openfootball/worldcup.json` sin segunda fuente:** descartada,
  el usuario pidió explícitamente 2-3 fuentes de validación.
- **Mantener fallback CC0 con warning:** aceptada solo como último
  recurso, nunca como fuente operativa de facto.

## Implementación ya realizada (sesión 4, P14)

`32_ingesta_resultados.R` reescrito: fuente primaria
`openfootball/worldcup.json` (real, mantenida a mano, sincronizada con
ESPN/FIFA); validación cruzada `thestatsapi.com/fixtures.csv` (por
`codigo_fifa`, no texto crudo); fallback de última instancia con
`fuente_usada = "fallback_cc0_sintetico"` y WARN explícito si se activa.

## Alcance

Aplica a cualquier insumo nuevo que se incorpore al proyecto en el
futuro, no solo a resultados de partidos. Es un principio de gobernanza
de datos, no una tarea puntual.

## Limitación aceptada

No existe fuente gratuita con marcador real para doble validación del
dato más crítico (`gf`/`gc`); solo hay una fuente de score
(openfootball) y una de existencia/calendario (thestatsapi). Ver P16
(pendiente, decidir si se busca tercera fuente).
