"use strict";
// Visual research demo. The backend must own combat results in a real match.
window.ArenaRenderer = class ArenaRenderer {
  static facingFlip(slug, side) {
    const nativeFacing = {"ha-nhan":"right","han-boi-phap":"right","tuyet-dinh":"left"}[slug];
    if (!nativeFacing || !["left","right"].includes(side)) throw new Error("Unknown actor facing");
    return (side === "left" && nativeFacing === "left") || (side === "right" && nativeFacing === "right");
  }
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d", { alpha: false });
    this.root = "./assets/game/";
    this.cache = new Map();
    this.left = "ha-nhan";
    this.right = "han-boi-phap";
    this.motion = null;
    this.muted = true;
    this.currentAudio = null;
    this.reduced = matchMedia("(prefers-reduced-motion: reduce)");
    this.lastPaint = 0;
    this.preload("maps/study-courtyard.webp");
    this.loop = this.loop.bind(this);
    requestAnimationFrame(this.loop);
  }
  preload(path) {
    if (!this.cache.has(path)) {
      const img = new Image();
      img.decoding = "async";
      img.src = this.root + path;
      this.cache.set(path, img);
    }
    return this.cache.get(path);
  }
  draw(path, x, y, w, h, flip = false, alpha = 1) {
    const img = this.preload(path);
    if (!img.complete || !img.naturalWidth) {
      if (path.includes("/runtime/")) this.drawFallbackActor(x, y, w, h);
      return;
    }
    const c = this.ctx;
    c.save(); c.globalAlpha = alpha;
    if (flip) { c.translate(x + w, y); c.scale(-1, 1); c.drawImage(img, 0, 0, w, h); }
    else c.drawImage(img, x, y, w, h);
    c.restore();
  }
  drawFallbackActor(x, y, w, h) {
    const c = this.ctx;
    c.save(); c.fillStyle = "#334c51"; c.strokeStyle = "#e3d5b7"; c.lineWidth = 3;
    c.beginPath(); c.arc(x + w * .5, y + h * .34, w * .12, 0, Math.PI * 2); c.fill(); c.stroke();
    c.beginPath(); c.moveTo(x + w * .39, y + h * .44); c.lineTo(x + w * .31, y + h * .86); c.lineTo(x + w * .69, y + h * .86); c.lineTo(x + w * .61, y + h * .44); c.closePath(); c.fill(); c.stroke();
    c.restore();
  }
  setCharacters(left, right) {
    this.left = left; this.right = right; this.motion = null;
    for (const slug of [left, right]) this.preload(`characters/${slug}/runtime/idle.webp`);
  }
  setSound(on) { this.muted = !on; if(!on&&this.currentAudio){this.currentAudio.pause();this.currentAudio.currentTime=0;} }
  sound(path) {
    if (this.muted) return;
    if (this.currentAudio) { this.currentAudio.pause(); this.currentAudio.currentTime = 0; }
    const a = new Audio(this.root + path);
    a.volume = 0.45;
    this.currentAudio = a;
    a.play().catch(() => {});
  }
  motionFrame(slug, action, elapsed, side) {
    const count = ["hurt", "stun", "heal"].includes(action) ? 4 : 6;
    const duration = ["hurt", "stun", "heal"].includes(action) ? 580 : action === "victory" ? 900 : 760;
    const index = Math.min(count - 1, Math.floor(Math.max(0, elapsed) / (duration / count)));
    const frame = `characters/${slug}/runtime/frames/${action}/f${String(index).padStart(2, "0")}.webp`;
    const idle = `characters/${slug}/runtime/idle.webp`;
    return this.preload(frame).complete && this.preload(frame).naturalWidth ? frame : idle;
  }
  loop(now) {
    requestAnimationFrame(this.loop);
    if (document.hidden || now - this.lastPaint < (this.motion ? 28 : 150)) return;
    this.lastPaint = now;
    const c = this.ctx, m = this.motion, t = m ? now - m.start : 0;
    c.fillStyle = "#26353a"; c.fillRect(0, 0, 360, 380);
    const map = this.preload("maps/study-courtyard.webp");
    if (map.complete && map.naturalWidth) {
      const cropH = map.naturalWidth * 380 / 360;
      const top = Math.min(map.naturalHeight - cropH, map.naturalHeight * 0.30);
      c.drawImage(map, 0, top, map.naturalWidth, cropH, 0, 0, 360, 380);
    }
    c.fillStyle = "#19202166"; c.fillRect(0, 0, 360, 380);
    for (const [side, slug, x] of [["left", this.left, 92], ["right", this.right, 268]]) {
      const flip = ArenaRenderer.facingFlip(slug, side);
      c.fillStyle = "#0a17148a"; c.beginPath(); c.ellipse(x, 348, 37, 8, 0, 0, Math.PI * 2); c.fill();
      let path = `characters/${slug}/runtime/idle.webp`;
      if (m && m.side === side && t < m.duration) path = this.motionFrame(slug, m.action, t, side);
      if (m && m.kind === "attack" && side !== m.side && t > m.hitAt && t < m.hitAt + 430) path = this.motionFrame(slug, "hurt", t - m.hitAt, side);
      // All art is on the same 512px canvas and root (256,478). Never fit each frame by its alpha bounding box.
      const bounce = m?.action === "victory" && m.side === side ? 12 * Math.abs(Math.sin(t / 125)) : 0;
      this.draw(path, x - 120, 350 - 478 / 512 * 240 - bounce, 240, 240, flip);
    }
    if (m) this.paintMotion(m, t);
    if (m && t > m.duration) this.motion = null;
  }
  paintMotion(m, t) {
    const attackerX = m.side === "left" ? 92 : 268;
    const defenderX = m.side === "left" ? 268 : 92;
    const dir = m.side === "left" ? 1 : -1;
    if (m.kind === "attack") {
      const startX = attackerX + dir * 28, endX = defenderX - dir * 28;
      const p = Math.min(1, Math.max(0, (t - 120) / (m.hitAt - 120)));
      const x = startX + (endX - startX) * p, y = 251 - Math.sin(p * Math.PI) * 22;
      if (t >= 120 && t < m.hitAt) this.draw(`characters/${m.slug}/fx/${m.action}.svg`, x - 48, y - 48, 96, 96, dir < 0);
      if (t >= m.hitAt && t < m.hitAt + 300) {
        const age = t - m.hitAt;
        this.draw("effects/runtime/impact.svg", defenderX - 55, 198, 110, 110, false, 1 - age / 300);
        if (m.damage) { const c = this.ctx; c.fillStyle = "#fff0dd"; c.font = "bold 16px sans-serif"; c.textAlign = "center"; c.fillText(`−${m.damage}`, defenderX, 188 - age / 15); }
      }
      if (m.selfEffect && t >= m.hitAt && t < m.duration) this.draw(m.selfEffect, attackerX - 61, 206, 122, 122);
    } else {
      const x = attackerX, path = m.effect;
      if (path) this.draw(path, x - 60, m.action === "stun" ? 165 : 208, 120, 120, false, Math.max(0, 1 - t / m.duration));
    }
  }
  attack(slug, action, damage, selfEffect, side = "left") {
    const start = performance.now(), hitAt = 515;
    this.motion = this.reduced.matches ? null : {kind:"attack", side, slug, action, damage, selfEffect, start, hitAt, duration:950};
    this.sound(`characters/${slug}/audio/${action}.wav`);
    setTimeout(() => { if (this.motion?.start === start) this.sound("audio/impact.wav"); }, hitAt);
  }
  state(slug, action, side = "left") {
    const effect = action === "stun" ? "effects/runtime/stun.svg" : action === "heal" ? "effects/runtime/healing.svg" : action === "hurt" ? "effects/runtime/impact.svg" : `characters/${slug}/fx/passive.svg`;
    this.motion = this.reduced.matches ? null : {kind:"state", side, slug, action:action === "win" ? "victory" : action, effect, start:performance.now(), duration:action === "win" ? 1150 : 750};
    if (action === "stun" || action === "win") this.sound(`characters/${slug}/audio/${action === "win" ? "victory" : "stun"}.wav`);
    if (action === "heal") this.sound("audio/heal.wav");
  }
  passive(slug, side = "left") {
    this.motion = this.reduced.matches ? null : {kind:"state", side, slug, action:"idle", effect:`characters/${slug}/fx/passive.svg`, start:performance.now(), duration:680};
  }
  skip() { this.motion = null; if(this.currentAudio){this.currentAudio.pause();this.currentAudio.currentTime=0;} }
};
