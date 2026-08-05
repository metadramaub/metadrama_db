-- Qué dice la notación y qué dicen los enlaces.
--
-- `[aA]…` y `[-a]…` tienen la misma forma y significan cosas distintas: la silva estrena
-- rima en cada pareado —aA, bB, cC— y el romance mantiene la asonancia en todos los pares.
-- La notación no puede distinguirlos, y no debe intentarlo: lo que las separa no es la
-- forma del bloque sino si la rima se arrastra de un bloque al siguiente, y eso es una
-- relación, no un dibujo.
--
-- Lo dice `esquema_rima_enlaces`, y ya estaba bien puesto:
--
--   Romance `[-a]…`             b1p2 → +1 → p2   misma_rima   la asonancia no avanza
--   Silva `[aA]…`               (ningún enlace)               cada pareado estrena rima
--   Terceto encadenado `[aba]…` b1p2 → +1 → p1 y p3           la central pasa a exterior
--   Zéjel `… | [BBBA]…`         b2p4 → −1 → p1                la vuelta recupera la cabeza
--
-- Solo se deja escrita la regla que las junta, para que quien lea una notación sepa qué
-- puede y qué no puede deducir de ella.

begin;

comment on column public.esquemas_rima.notacion is
	'Notación normalizada: minúscula arte menor, mayúscula arte mayor, «-» verso suelto, «( )» opcional, «:» pausa dentro de un bloque, «|» frontera de bloque, «[ ]…» bloque que se repite. Cada posición aparece una sola vez: la repetición se marca, no se escribe. Dentro de un bloque repetido, cada clase de rima **avanza** en cada repetición salvo que un enlace de `esquema_rima_enlaces` declare lo contrario: por eso `[aA]…` es aA bB cC y `[-a]…` mantiene una sola asonancia.';

comment on table public.esquema_rima_enlaces is
	'Qué rima se arrastra de un bloque a otro. Es lo que distingue una serie monorrima de una que estrena rima en cada bloque, cosa que la notación no puede expresar. `desplazamiento_bloque` es la distancia: +1 al siguiente, −1 al anterior.';

commit;
