"use strict";
const assert = require("node:assert/strict");
global.window={};
require("../../demo/arena-renderer.js");
const Renderer=window.ArenaRenderer;
assert.equal(Renderer.facingFlip("ha-nhan","left"),false);
assert.equal(Renderer.facingFlip("ha-nhan","right"),true);
assert.equal(Renderer.facingFlip("tuyet-dinh","left"),true);
assert.equal(Renderer.facingFlip("tuyet-dinh","right"),false);
assert.equal(Renderer.facingFlip("han-boi-phap","left"),false);
assert.equal(Renderer.facingFlip("han-boi-phap","right"),true);
assert.throws(()=>Renderer.facingFlip("unknown","left"));
function calls(side,time){
  const list=[];
  const fake={draw:(...args)=>list.push(args),ctx:{fillText(){},save(){},restore(){}}};
  Renderer.prototype.paintMotion.call(fake,{kind:"attack",side,slug:"tuyet-dinh",action:"skill1",damage:0,hitAt:515,duration:950},time);
  return list;
}
for(const side of ["left","right"]){
  const flying=calls(side,300);
  assert.equal(flying.length,1);
  assert.match(flying[0][0],/tuyet-dinh\/fx\/skill1.svg/);
  const hit=calls(side,600);
  const impact=hit.find(x=>x[0]==="effects/runtime/impact.svg");
  assert.ok(impact);
  assert.equal(impact[1],side==="left"?213:37);
}
console.log("PASS per-character projectile, bidirectional impact target and facing");
