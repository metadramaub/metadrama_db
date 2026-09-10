import { query } from '../scripts/lib/consulta.mjs';
const nombres = process.argv.slice(2);
const rows = query(`select proname, pg_get_functiondef(p.oid) def from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and proname = any(array[${nombres.map(n=>`'${n}'`).join(',')}])`);
for (const r of rows) console.log('\n===================== ' + r.proname + '\n' + r.def);
