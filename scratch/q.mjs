import { query } from '../scripts/lib/consulta.mjs';
import { readFileSync } from 'node:fs';
const sql = process.argv[2].startsWith('@') ? readFileSync(process.argv[2].slice(1),'utf-8') : process.argv[2];
console.log(JSON.stringify(query(sql), null, 1));
