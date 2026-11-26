from pathlib import Path
p=Path('services/api/app/product.js')
s=p.read_text(encoding='utf-8').replace('crypto.randomUUID()', 'newId()')
s=s.replace("'use strict';", """'use strict';
function newId(){
  if(globalThis.crypto.randomUUID)return globalThis.crypto.randomUUID();
  const bytes=new Uint8Array(16);globalThis.crypto.getRandomValues(bytes);
  return Array.from(bytes,b=>b.toString(16).padStart(2,'0')).join('');
}""")
p.write_text(s,encoding='utf-8')
print('Mobile HTTP-compatible identifiers added')
