begin;

-- Un esquema métrico isosilábico es un ciclo de una posición.
--
-- El mismo hecho —todos los versos de la unidad miden lo mismo— se declaraba de dos maneras:
-- diecinueve arquitecturas repetían la posición tantas veces como versos tiene la unidad, y
-- tres la declaraban una sola vez como ciclo. Las tres eran el soneto y las dos sextinas, es
-- decir, justo aquellas en las que desarrollarla era inviable: la sextina doble habría
-- necesitado setenta y cinco posiciones y un slug de doscientos veinticuatro caracteres.
--
-- Se unifica en el ciclo. `secuencia_repetible` pasa a significar «esto se repite hasta
-- agotar la unidad», y cuántos versos tiene la unidad lo sigue diciendo la arquitectura, que
-- es donde vive. `secuencia_fija` queda para los esquemas en que cada posición se declara
-- una vez porque las medidas cambian.
--
-- No se tocan los ciclos heterométricos —`8-8-4` de la sextilla de pie quebrado, `7-5` de la
-- seguidilla, `7-11` del sexteto-lira—. El sexteto-lira tiene cinco esquemas y solo uno es
-- cíclico: declararlo distinto de sus cuatro hermanos empeoraría la comparación.
--
-- El nombre conserva la cuenta: «Seis endecasílabos» sigue diciendo seis aunque el slug ya
-- no los enumere.

create temporary table esquemas_isosilabicos on commit drop as
select
	esquema.esquema_metrico_id,
	min(metro.silabas) as silabas,
	count(*) as posiciones
from public.esquemas_metricos esquema
join public.esquema_metrico_posiciones posicion
	on posicion.esquema_metrico_id = esquema.esquema_metrico_id
join public.metros metro
	on metro.metro_id = posicion.metro_id
where esquema.tipo = 'secuencia_fija'
group by esquema.esquema_metrico_id
having count(distinct posicion.metro_id) = 1 and count(*) > 1;

do $$
declare
	v_total integer;
begin
	select count(*) into v_total from esquemas_isosilabicos;
	if v_total <> 19 then
		raise exception 'Se esperaban 19 esquemas isosilábicos desarrollados y hay %', v_total;
	end if;
end;
$$;

-- El ciclo conserva la primera posición y descarta las repeticiones.
delete from public.esquema_metrico_posiciones posicion
using esquemas_isosilabicos isosilabico
where posicion.esquema_metrico_id = isosilabico.esquema_metrico_id
	and posicion.posicion > 1;

update public.esquemas_metricos esquema
set tipo = 'secuencia_repetible',
	slug = format('%s-repetido', isosilabico.silabas)
from esquemas_isosilabicos isosilabico
where esquema.esquema_metrico_id = isosilabico.esquema_metrico_id;

do $$
declare
	v_pendientes integer;
	v_posiciones integer;
begin
	-- Ningún esquema de secuencia fija puede tener ya todas sus posiciones iguales.
	select count(*) into v_pendientes
	from (
		select esquema.esquema_metrico_id
		from public.esquemas_metricos esquema
		join public.esquema_metrico_posiciones posicion
			on posicion.esquema_metrico_id = esquema.esquema_metrico_id
		where esquema.tipo = 'secuencia_fija'
		group by esquema.esquema_metrico_id
		having count(distinct posicion.metro_id) = 1 and count(*) > 1
	) as restantes;
	if v_pendientes <> 0 then
		raise exception 'Quedan % esquemas isosilábicos desarrollados', v_pendientes;
	end if;

	-- Y todo ciclo tiene exactamente una posición por medida distinta.
	select count(*) into v_posiciones
	from public.esquema_metrico_posiciones posicion
	join public.esquemas_metricos esquema
		on esquema.esquema_metrico_id = posicion.esquema_metrico_id
	join esquemas_isosilabicos isosilabico
		on isosilabico.esquema_metrico_id = esquema.esquema_metrico_id;
	if v_posiciones <> 19 then
		raise exception 'Los 19 ciclos deben tener una posición cada uno y suman %', v_posiciones;
	end if;
end;
$$;

commit;
