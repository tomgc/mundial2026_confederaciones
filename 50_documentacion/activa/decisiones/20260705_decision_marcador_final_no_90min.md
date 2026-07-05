# Decision: marcador usado por el modelo (final real, no 90 minutos)

Fecha: 2026-07-05. Sesion: 6. Pendiente relacionado: P19, P20.

## Decision

`gf_local`/`gf_visita` en `resultados_partidos.csv` representa el
marcador final que decide quien avanza (penales o tiempo extra si los
hubo), nunca el marcador de 90 minutos cuando este quedo en empate. El
motor Elo (`33_motor_elo.R`) consume ese marcador para calcular `W`
(victoria/derrota) y `factor_goles()`.

Ejemplo real (sesion 2026-07-05): Alemania vs. Paraguay,
dieciseisavos. 90 minutos: 1-1. Tiempo extra: 1-1. Penales: 3-4.
`gf_local=3, gf_visita=4` (Paraguay avanza). El motor nunca ve el 1-1.

## Origen

Pregunta explicita del usuario sobre que marcador usa el modelo, tras
implementar P19 (lectura de `score.et`/`score.p` en
`32_ingesta_resultados.R`, ver
`20260705_investigacion_fuentes_resultados.md`).

## Justificacion

Un modelo de rating basado en resultados debe reflejar quien gano el
partido, no el marcador parcial de una fase intermedia. Usar 90
minutos perderia la informacion de avance real en partidos de
eliminacion (Paraguay seria registrado como "empate" pese a haber
avanzado), contradiciendo el proposito del proyecto (medir desempeno
observado vs. esperado por confederacion).

## Alcance de `factor_goles()`

El margen de gol (`|gf-gc|`) tambien se calcula sobre el marcador
final. En el ejemplo, el margen es 1 (3-4), no 0 (1-1). Esto es
consistente con la decision de arriba: si el resultado final es 3-4,
el margen de esa resolucion es el que corresponde.

## Alternativa considerada y descartada

Usar siempre el marcador de 90 minutos (`ft`), ignorando `et`/`p`.
Descartada: era el comportamiento del bug corregido en P19 (el parser
anterior solo leia `ft`), y generaba empates fantasma en partidos que
si tuvieron ganador, disparando W=0.5 provisional innecesario en el
motor (ver WARN "partidos pendientes de resolucion" en sesiones
anteriores a la v06/v07).

## Limitacion declarada (relacionada con P20)

El contrato de datos no distingue si el partido se resolvio en 90
minutos, tiempo extra o penales (`resuelto_por` existe en
`resultados_partidos.csv` pero no se propaga al JSON de la interfaz
ni se usa en el motor). Si en el futuro se quisiera ponderar distinto
un partido resuelto por penales (por ejemplo, dar menos peso al
resultado por su componente de azar), seria una decision de diseño
nueva, no implementada hoy.
