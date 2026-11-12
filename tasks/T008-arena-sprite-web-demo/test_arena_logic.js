const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");

function element(dataset = {}) {
  return {
    dataset, style: {}, className: "", textContent: "", src: "",
    classList: { add() {}, remove() {}, toggle() {} },
    addEventListener() {}, setAttribute() {}, append() {}, replaceChildren(...children) { this.children = children; },
    pause() {}, load() {}, removeAttribute() {}, play() { return Promise.resolve(); },
  };
}
const elements = new Map();
const get = id => {
  if (!elements.has(id)) elements.set(id, element());
  return elements.get(id);
};
const roster = ["ha_nhan", "han_boi_thap", "tuyet_dinh"].map(character => element({ character }));
const previews = ["hurt", "stun", "heal", "win"].map(preview => element({ preview }));
const document = {
  getElementById: get,
  createElement: () => element(),
  querySelectorAll(selector) {
    if (selector === ".roster-card") return roster;
    if (selector === "[data-preview]") return previews;
    if (selector === ".pose-card") return get("pose-grid").children || [];
    return [];
  },
};
const context = vm.createContext({
  document, window: { matchMedia: () => ({ matches: true }) },
  setTimeout: () => 1, clearTimeout() {}, console, Date,
});
const source = fs.readFileSync(path.join(__dirname, "../../demo/arena.js"), "utf8");
vm.runInContext(source, context);
const run = code => vm.runInContext(code, context);

assert.equal(run("hero.hp"), 100);
assert.equal(run("enemy.armor"), 50);
run('perform("basic")');
assert.equal(run("enemy.armor"), 22);
assert.equal(run("enemy.hp"), 100);
run("answer(true)");
run('perform("skill1")');
assert.equal(run("enemy.armor"), 0);
assert.equal(run("enemy.hp"), 97);
assert.equal(run("hero.qi"), 0);
run('preview("hurt")');
assert.equal(run("hero.armor"), 22);
run("answer(true)");
assert.equal(run("hero.armor"), 30);
assert.equal(run("hero.passiveCount"), 1);

run('selected="han_boi_thap";reset();answer(true);perform("skill1")');
assert.equal(run("hero.ward"), 14);
assert.equal(run("enemy.armor"), 32);
run('perform("skill1")');
assert.equal(run("enemy.armor"), 32);
run("answer(true)");
assert.equal(run("hero.ward"), 0); // active ward expires at the next round
run('reset();preview("hurt");preview("hurt")');
assert.equal(run("hero.broken"), true);
run("answer(false)");
assert.equal(run("hero.ward"), 12); // guardian passive starts next round

run('selected="tuyet_dinh";reset();answer(true);answer(true);perform("basic")');
assert.equal(run("enemy.armor"), 16); // Kiếm Ý: 28 + 6
run('answer(true);perform("skill2")');
assert.equal(run("enemy.hp"), 70); // 46 damage, 16 armor left
assert.equal(run("hero.weakBasic"), true);
run('perform("basic")');
assert.equal(run("hero.weakBasic"), false);
console.log("Arena logic OK");
