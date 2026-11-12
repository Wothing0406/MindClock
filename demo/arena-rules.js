"use strict";
// Local training arithmetic. Production matches use docs/46 server settlement.
(function (host) {
  const clamp = (value, min, max) => Math.min(max, Math.max(min, value));
  function applyDamage(target, amount, targetId) {
    if (!Number.isInteger(amount) || amount < 0) throw new Error("invalid damage");
    let rest = amount;
    const w = Math.min(target.ward, rest); target.ward -= w; rest -= w;
    const a = Math.min(target.armor, rest); target.armor -= a; rest -= a;
    const h = Math.min(target.hp, rest); target.hp -= h;
    if (targetId === "han_boi_thap" && a > 0 && target.armor === 0 && !target.broken) target.broken = true;
    return {w, a, h};
  }
  const rules = {clamp, applyDamage};
  if (typeof module !== "undefined" && module.exports) module.exports = rules;
  host.ArenaRules = rules;
})(typeof window !== "undefined" ? window : globalThis);
