// Run only against the local demo Firestore emulator; never production.
import assert from 'node:assert/strict';
const project = 'demo-civicfix';
const base = `http://127.0.0.1:8080/v1/projects/${project}/databases/(default)/documents`;
const root = `projects/${project}/databases/(default)/documents`;
function token(uid) {
  const now = Math.floor(Date.now() / 1000);
  return [
    {alg: 'none', typ: 'JWT'},
    {sub: uid, user_id: uid, aud: project, iss: `https://securetoken.google.com/${project}`,
      iat: now, exp: now + 3600, auth_time: now,
      firebase: {sign_in_provider: 'password', identities: {}}},
  ].map(x => Buffer.from(JSON.stringify(x)).toString('base64url')).join('.') + '.';
}
function value(x) {
  if (x === null) return {nullValue: null};
  if (typeof x === 'string') return {stringValue: x};
  if (typeof x === 'boolean') return {booleanValue: x};
  if (typeof x === 'number') return {integerValue: String(x)};
  return {mapValue: {fields: fields(x)}};
}
function fields(x) {return Object.fromEntries(Object.entries(x).map(([k,v]) => [k,value(v)]));}
async function commit(writes, bearer = token('test-citizen')) {
  return fetch(`${base}:commit`, {method:'POST', headers: {'content-type':'application/json', authorization:`Bearer ${bearer}`}, body:JSON.stringify({writes})});
}
function write(path, data) {return {update:{name:`${root}/${path}`, fields:fields(data)}};}
function complaint(id, overrides = {}) {
  return [write(`complaints/${id}`, {
    citizenId:'test-citizen', ticketNumber:id, title:'Emulator regression', description:'Test only',
    status:'reported', priority:'medium', location:{latitude:19,longitude:72,address:'Mumbai'},
    upvotes:0, assignedTo:null, resolvedAt:null, isHazard:false, ...overrides,
  }), write(`complaints/${id}/complaint_updates/initial`, {status:'reported',updatedBy:'test-citizen'})];
}
const suffix = Date.now();
let r = await commit(complaint(`missing-field-${suffix}`));
assert.equal(r.status,403,await r.text());
console.log('PASS: original payload without departmentId reproduces permission-denied');
const id = `fixed-${suffix}`;
r = await commit(complaint(id,{departmentId:null}));
assert.equal(r.status,200,await r.text());
console.log('PASS: repaired complaint + initial timeline commit atomically');
r = await commit(complaint(`spoof-${suffix}`,{departmentId:null}),token('other-citizen'));
assert.equal(r.status,403,await r.text());
console.log('PASS: another citizen cannot submit on behalf of the owner');
r = await commit([write('government_users/test-officer',{role:'ward_department_lead',active:true})],'owner');
assert.equal(r.status,200,await r.text());
r = await fetch(`${base}/complaints/${id}`, {headers:{authorization:`Bearer ${token('test-officer')}`}});
assert.equal(r.status,200,await r.text());
console.log('PASS: government profile without custom role claims can read registered complaint');
r = await fetch(`${base}/complaints/${id}`, {headers:{authorization:`Bearer ${token('other-citizen')}`}});
assert.equal(r.status,403,await r.text());
console.log('PASS: unrelated citizen cannot read the private complaint');
