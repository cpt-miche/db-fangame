const canvas = document.getElementById('world');
const ctx = canvas.getContext('2d');
const worldHint = document.getElementById('worldHint');
const battleStatus = document.getElementById('battleStatus');
const statsGrid = document.getElementById('statsGrid');
const controls = document.getElementById('controls');
const actionsEl = document.getElementById('actions');
const combatLog = document.getElementById('combatLog');
const kiInfusion = document.getElementById('kiInfusion');
const kiInfusionLabel = document.getElementById('kiInfusionLabel');

const keys = new Set();
let mode = 'explore';

const playerWorld = { x: 140, y: 270, w: 34, h: 64, speed: 4 };
const enemyWorld = { x: 740, y: 270, w: 34, h: 64, name: 'Raditz (Scout)' };

const actions = [
  { key: 'strike', label: 'Physical Strike' },
  { key: 'kiBlast', label: 'Ki Blast' },
  { key: 'volley', label: 'Ki Blast Volley' },
  { key: 'barrage', label: 'Ki Blast Barrage' },
  { key: 'powerUp', label: 'Power Up (+Drawn Ki)' },
  { key: 'guard', label: 'Guard' },
  { key: 'transform', label: 'Kaioken' }
];

function makeFighter(name, isPlayer = false) {
  return {
    name,
    isPlayer,
    maxHp: 450,
    hp: 450,
    maxStamina: 240,
    stamina: 240,
    maxStoredKi: 360,
    storedKi: 360,
    maxDrawnKi: 240,
    drawnKi: 80,
    physical: 56,
    ki: 50,
    speed: 46,
    control: 42,
    escalation: 0,
    guard: false,
    kaioken: false,
    roundDrain: { hp: 0, stamina: 0, drawnKi: 0 }
  };
}

let battle;

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function addLog(text) {
  const li = document.createElement('li');
  li.textContent = text;
  combatLog.prepend(li);
}

function setupActionButtons() {
  actionsEl.innerHTML = '';
  actions.forEach((action) => {
    const button = document.createElement('button');
    button.textContent = action.label;
    button.addEventListener('click', () => playerAction(action.key));
    actionsEl.appendChild(button);
  });
}

function startBattle() {
  mode = 'battle';
  battle = {
    player: makeFighter('Player', true),
    enemy: makeFighter(enemyWorld.name),
    turn: 1,
    suppressionBase: 35,
    winner: null
  };
  battle.enemy.physical = 52;
  battle.enemy.ki = 48;
  battle.enemy.speed = 40;
  battle.enemy.drawnKi = 90;
  battle.enemy.control = 36;
  controls.classList.remove('hidden');
  kiInfusion.value = '0';
  addLog('Fight starts cautiously. Both fighters are holding back.');
  renderBattle();
}

function endBattle(win) {
  mode = 'explore';
  controls.classList.add('hidden');
  battleStatus.textContent = win
    ? 'Victory! You learned Ki Control +1. Walk around to challenge again.'
    : 'Defeat! Recover and challenge again.';
}

function getSuppression(fighter) {
  return clamp((battle.suppressionBase - fighter.escalation) / 100, 0, 0.5);
}

function mitigation(defender, type) {
  const sPct = defender.stamina / defender.maxStamina;
  const kPct = defender.drawnKi / defender.maxDrawnKi;
  const mix = type === 'physical' ? (0.65 * sPct + 0.35 * kPct) : (0.65 * kPct + 0.35 * sPct);
  return clamp(0.1 + mix * 0.55 + (defender.guard ? 0.2 : 0), 0.08, 0.88);
}

function tryVanish(attacker, defender, attackTier) {
  const vanishCost = 12 + attackTier * 8;
  if (defender.drawnKi < vanishCost) return false;
  const speedEdge = defender.speed - attacker.speed;
  const fatiguePenalty = defender.stamina / defender.maxStamina < 0.2 ? 0.15 : 0;
  const trackingBonus = attackTier * 0.08;
  const chance = clamp(0.2 + speedEdge * 0.008 - trackingBonus - fatiguePenalty, 0.05, 0.7);
  if (Math.random() < chance) {
    defender.drawnKi -= vanishCost;
    addLog(`${defender.name} vanished! (-${vanishCost} drawn ki)`);
    if (defender.stamina > 15 && defender.drawnKi > 10 && Math.random() < 0.45) {
      defender.stamina -= 12;
      defender.drawnKi -= 10;
      const counter = 16 + defender.physical * 0.5;
      attacker.hp -= counter;
      addLog(`${defender.name} countered for ${Math.round(counter)} damage!`);
    }
    return true;
  }
  return false;
}

function applyAttack(attacker, defender, cfg) {
  const infusionPct = Number(kiInfusion.value) / 100;
  const infusionCap = cfg.infusionCap ?? 0;
  const infusionCost = Math.round(attacker.maxDrawnKi * infusionPct * infusionCap);

  if (attacker.stamina < (cfg.staminaCost ?? 0) || attacker.drawnKi < (cfg.kiCost ?? 0) + infusionCost) {
    addLog(`${attacker.name} tried ${cfg.label}, but lacked resources.`);
    return;
  }

  attacker.stamina -= cfg.staminaCost ?? 0;
  attacker.drawnKi -= (cfg.kiCost ?? 0) + infusionCost;

  const hitChance = clamp(
    cfg.baseHit + (attacker.speed - defender.speed) * 0.006 + infusionPct * 0.08 - (defender.guard ? 0.14 : 0),
    0.1,
    0.95
  );

  if (Math.random() > hitChance) {
    addLog(`${attacker.name}'s ${cfg.label} missed.`);
    return;
  }

  if (cfg.canVanish && tryVanish(attacker, defender, cfg.tier)) return;

  const suppression = 1 - getSuppression(attacker);
  const transBoost = attacker.kaioken ? 1.28 : 1;
  const statPower = cfg.type === 'physical' ? attacker.physical : attacker.ki;
  const infusionBoost = 1 + infusionPct * 0.9;
  const raw = (cfg.base + statPower * cfg.scaling) * suppression * transBoost * infusionBoost;
  const finalDmg = Math.max(1, Math.round(raw * (1 - mitigation(defender, cfg.type))));
  defender.hp -= finalDmg;
  attacker.escalation += cfg.escalationGain;
  defender.escalation += 2;
  addLog(`${attacker.name} used ${cfg.label} for ${finalDmg} damage.`);
}

function applyRoundDrain(fighter) {
  if (!fighter.kaioken) return;
  const hpDrain = 8;
  const staminaDrain = 14 - Math.round(fighter.control * 0.06);
  fighter.hp -= hpDrain;
  fighter.stamina -= staminaDrain;
  addLog(`${fighter.name}'s Kaioken drains ${hpDrain} HP and ${staminaDrain} stamina.`);
}

function playerAction(actionKey) {
  if (mode !== 'battle' || battle.winner) return;
  const p = battle.player;
  const e = battle.enemy;
  p.guard = false;

  switch (actionKey) {
    case 'strike':
      applyAttack(p, e, {
        label: 'Physical Strike', type: 'physical', base: 28, scaling: 1.15,
        baseHit: 0.78, staminaCost: 18, kiCost: 0, infusionCap: 0.2,
        canVanish: true, tier: 1, escalationGain: 7
      });
      break;
    case 'kiBlast':
      applyAttack(p, e, {
        label: 'Ki Blast', type: 'ki', base: 24, scaling: 1.05,
        baseHit: 0.75, staminaCost: 4, kiCost: 22, infusionCap: 0.32,
        canVanish: true, tier: 1, escalationGain: 8
      });
      break;
    case 'volley':
      applyAttack(p, e, {
        label: 'Ki Blast Volley', type: 'ki', base: 34, scaling: 1.08,
        baseHit: 0.85, staminaCost: 8, kiCost: 44, infusionCap: 0.4,
        canVanish: true, tier: 2, escalationGain: 10
      });
      break;
    case 'barrage':
      applyAttack(p, e, {
        label: 'Ki Blast Barrage', type: 'ki', base: 50, scaling: 0.95,
        baseHit: 0.92, staminaCost: 12, kiCost: 70, infusionCap: 0.55,
        canVanish: true, tier: 3, escalationGain: 13
      });
      break;
    case 'powerUp': {
      const amount = Math.min(45, p.storedKi, p.maxDrawnKi - p.drawnKi);
      if (amount <= 0) {
        addLog('No stored ki available to draw.');
      } else {
        p.storedKi -= amount;
        p.drawnKi += amount;
        p.escalation += 5;
        addLog(`Power up: converted ${amount} stored ki into drawn ki.`);
      }
      break;
    }
    case 'guard':
      p.guard = true;
      p.stamina = clamp(p.stamina + 8, 0, p.maxStamina);
      addLog('Player braces and guards.');
      break;
    case 'transform':
      if (p.kaioken) {
        p.kaioken = false;
        addLog('Kaioken deactivated.');
      } else if (p.stamina >= 35 && p.hp >= 40) {
        p.kaioken = true;
        p.escalation += 12;
        addLog('Kaioken activated: power up, but it drains stamina and HP each round.');
      } else {
        addLog('Not enough HP/Stamina to safely activate Kaioken.');
      }
      break;
  }

  if (checkWinner()) return;
  enemyTurn();
  checkWinner();
  battle.turn += 1;
  battle.player.escalation += 3;
  battle.enemy.escalation += 3;
  applyRoundDrain(battle.player);
  applyRoundDrain(battle.enemy);
  battle.player.stamina = clamp(battle.player.stamina + 10, 0, battle.player.maxStamina);
  battle.enemy.stamina = clamp(battle.enemy.stamina + 10, 0, battle.enemy.maxStamina);
  renderBattle();
}

function enemyTurn() {
  const p = battle.player;
  const e = battle.enemy;
  e.guard = false;

  const lowKi = e.drawnKi < 30;
  const lowStam = e.stamina < 25;

  if (lowKi && e.storedKi > 20 && Math.random() < 0.8) {
    const gain = Math.min(40, e.storedKi, e.maxDrawnKi - e.drawnKi);
    e.storedKi -= gain;
    e.drawnKi += gain;
    addLog(`${e.name} powers up (+${gain} drawn ki).`);
    return;
  }

  if (!e.kaioken && e.hp < 220 && e.stamina > 60 && Math.random() < 0.35) {
    e.kaioken = true;
    e.escalation += 10;
    addLog(`${e.name} flares into Kaioken!`);
    return;
  }

  if (lowStam && Math.random() < 0.5) {
    e.guard = true;
    addLog(`${e.name} guards and regains footing.`);
    return;
  }

  const roll = Math.random();
  if (roll < 0.35) {
    applyAttack(e, p, {
      label: 'Wild Strike', type: 'physical', base: 25, scaling: 1.06,
      baseHit: 0.74, staminaCost: 16, kiCost: 0, infusionCap: 0.2,
      canVanish: true, tier: 1, escalationGain: 6
    });
  } else if (roll < 0.72) {
    applyAttack(e, p, {
      label: 'Ki Blast', type: 'ki', base: 22, scaling: 1.03,
      baseHit: 0.76, staminaCost: 4, kiCost: 20, infusionCap: 0.22,
      canVanish: true, tier: 1, escalationGain: 7
    });
  } else {
    applyAttack(e, p, {
      label: 'Ki Volley', type: 'ki', base: 32, scaling: 1.01,
      baseHit: 0.85, staminaCost: 8, kiCost: 40, infusionCap: 0.28,
      canVanish: true, tier: 2, escalationGain: 9
    });
  }
}

function checkWinner() {
  const p = battle.player;
  const e = battle.enemy;
  if (p.hp <= 0 || e.hp <= 0) {
    battle.winner = p.hp > 0 ? 'player' : 'enemy';
    addLog(battle.winner === 'player' ? 'You win!' : `${e.name} wins!`);
    renderBattle();
    endBattle(battle.winner === 'player');
    return true;
  }
  return false;
}

function renderFighter(f) {
  const suppressionPct = Math.round(getSuppression(f) * 100);
  const fatiguePhys = f.stamina / f.maxStamina < 0.2 ? 'LOW STAMINA: physical debuff' : '';
  const fatigueKi = f.drawnKi / f.maxDrawnKi < 0.2 ? 'LOW DRAWN KI: ki/vanish debuff' : '';

  return `
  <div class="card">
    <strong>${f.name} ${f.kaioken ? '(Kaioken)' : ''}</strong>
    ${renderBar('HP', f.hp, f.maxHp)}
    ${renderBar('Stam', f.stamina, f.maxStamina)}
    ${renderBar('Stored Ki', f.storedKi, f.maxStoredKi)}
    ${renderBar('Drawn Ki', f.drawnKi, f.maxDrawnKi)}
    <div>STR ${f.physical} | KI ${f.ki} | SPD ${f.speed}</div>
    <div>Escalation: ${Math.round(f.escalation)} | Hold-back Penalty: -${suppressionPct}%</div>
    <div style="color:#ffd58a">${fatiguePhys} ${fatigueKi}</div>
  </div>`;
}

function renderBar(label, value, max) {
  const pct = clamp((value / max) * 100, 0, 100);
  return `<div class="stat"><span>${label}</span><div class="bar"><div class="fill" style="width:${pct}%"></div></div><span>${Math.max(0, Math.round(value))}/${max}</span></div>`;
}

function renderBattle() {
  if (!battle) return;
  statsGrid.innerHTML = `${renderFighter(battle.player)}${renderFighter(battle.enemy)}`;
  battleStatus.textContent = `Turn ${battle.turn}. Escalation rises each round and when big actions happen.`;
}

function drawWorld() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  const gradient = ctx.createLinearGradient(0, 0, 0, canvas.height);
  gradient.addColorStop(0, '#25365f');
  gradient.addColorStop(1, '#101726');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  ctx.fillStyle = '#2f6d3b';
  ctx.fillRect(0, 310, canvas.width, 50);

  drawCharacter(playerWorld, '#4db2ff', 'YOU');
  drawCharacter(enemyWorld, '#ff7e54', 'RADITZ');

  if (mode === 'explore') {
    const near = Math.abs(playerWorld.x - enemyWorld.x) < 55;
    worldHint.textContent = near ? 'Press E to talk/fight.' : 'Move with A/D or ←/→.';
    if (near && keys.has('e')) startBattle();
  }
}

function drawCharacter(ch, color, label) {
  ctx.fillStyle = color;
  ctx.fillRect(ch.x - ch.w / 2, ch.y - ch.h, ch.w, ch.h);
  ctx.fillStyle = '#fff';
  ctx.font = '12px sans-serif';
  ctx.fillText(label, ch.x - ch.w / 2 - 4, ch.y - ch.h - 8);
}

function tick() {
  if (mode === 'explore') {
    if (keys.has('a') || keys.has('arrowleft')) playerWorld.x -= playerWorld.speed;
    if (keys.has('d') || keys.has('arrowright')) playerWorld.x += playerWorld.speed;
    playerWorld.x = clamp(playerWorld.x, 20, canvas.width - 20);
  }
  drawWorld();
  requestAnimationFrame(tick);
}

window.addEventListener('keydown', (event) => keys.add(event.key.toLowerCase()));
window.addEventListener('keyup', (event) => keys.delete(event.key.toLowerCase()));
kiInfusion.addEventListener('input', () => {
  kiInfusionLabel.textContent = `${kiInfusion.value}%`;
});

setupActionButtons();
tick();
