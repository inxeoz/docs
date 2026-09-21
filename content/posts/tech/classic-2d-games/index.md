---
title: "Classic 2D Games — Play in Browser"
date: 2026-05-31
draft: false
viewMode: docs
tags: ["games", "javascript", "canvas", "fun"]
categories: ["Tech"]
lightbox: false
showToc: false
---

5 classic arcade games, implemented from scratch in HTML Canvas + JavaScript. No frameworks, no dependencies — just you, the keyboard, and a few hundred lines of game loop.

<style>
.game-wrap{margin:2rem 0}
.game-wrap details{background:var(--surface-color);border:2px solid var(--border-color);border-radius:8px;margin:1rem 0;overflow:hidden}
.game-wrap details summary{padding:1rem 1.25rem;cursor:pointer;font-weight:700;font-size:1.1rem;user-select:none;background:var(--surface-color);border-bottom:2px solid transparent}
.game-wrap details[open] summary{border-bottom-color:var(--border-color);margin-bottom:0}
.game-body{padding:1.25rem;text-align:center}
.game-body canvas{display:block;margin:0 auto;background:#111;border-radius:4px;max-width:100%}
.game-controls{display:flex;gap:.5rem;justify-content:center;margin-top:.75rem;flex-wrap:wrap}
.game-controls button{padding:.4rem 1rem;font-family:var(--font-mono);font-size:.85rem;cursor:pointer;background:var(--link-color);color:#fff;border:none;border-radius:4px;transition:filter .15s}
.game-controls button:hover{filter:brightness(1.15)}
.game-controls button.secondary{background:var(--secondary-text)}
.game-score{margin-top:.5rem;font-family:var(--font-mono);font-size:1rem;color:var(--secondary-text)}
.game-hint{font-size:.78rem;color:var(--secondary-text);margin-top:.5rem;opacity:.7}
@media(max-width:600px){.game-body{padding:.75rem}.game-body canvas{width:100%!important;height:auto!important}}
</style>

<div class="game-wrap">

## Select a game

<details id="g-snake">
<summary>🐍 Snake</summary>
<div class="game-body">
<canvas id="snakeCanvas" width="400" height="400"></canvas>
<div class="game-controls">
<button onclick="startSnake()">Start / Restart</button>
</div>
<div class="game-score">Score: <span id="snakeScore">0</span></div>
<div class="game-hint">Arrow keys to move &middot; P to pause</div>
</div>
</details>

<details id="g-tetris">
<summary>🧱 Tetris</summary>
<div class="game-body">
<canvas id="tetrisCanvas" width="300" height="600"></canvas>
<div class="game-controls">
<button onclick="startTetris()">Start / Restart</button>
</div>
<div class="game-score">Score: <span id="tetrisScore">0</span> &middot; Lines: <span id="tetrisLines">0</span></div>
<div class="game-hint">← → move &middot; ↑ rotate &middot; ↓ soft drop &middot; Space hard drop &middot; P pause</div>
</div>
</details>

<details id="g-pong">
<summary>🏓 Pong</summary>
<div class="game-body">
<canvas id="pongCanvas" width="600" height="400"></canvas>
<div class="game-controls">
<button onclick="startPong()">Start / Restart</button>
</div>
<div class="game-score"><span id="pongScore">0 - 0</span></div>
<div class="game-hint">W/S to move left paddle &middot; ↑/↓ for right (2-player) &middot; Space to serve</div>
</div>
</details>

<details id="g-breakout">
<summary>🧱 Breakout</summary>
<div class="game-body">
<canvas id="breakoutCanvas" width="480" height="360"></canvas>
<div class="game-controls">
<button onclick="startBreakout()">Start / Restart</button>
</div>
<div class="game-score">Score: <span id="breakoutScore">0</span></div>
<div class="game-hint">← → to move paddle &middot; mouse also works</div>
</div>
</details>

<details id="g-minesweeper">
<summary>💣 Minesweeper</summary>
<div class="game-body">
<canvas id="mineCanvas" width="360" height="360"></canvas>
<div class="game-controls">
<button onclick="startMinesweeper()">New Game</button>
</div>
<div class="game-score"><span id="mineStatus">Click a cell to start</span></div>
<div class="game-hint">Left-click to reveal &middot; Right-click to flag</div>
</div>
</details>

</div>

<script>
/* ───────── Snake ───────── */
let snakeGame = null;

function startSnake() {
  if (snakeGame) { snakeGame.stop(); snakeGame = null; }
  snakeGame = new SnakeGame();
}

class SnakeGame {
  constructor() {
    this.canvas = document.getElementById('snakeCanvas');
    this.ctx = this.canvas.getContext('2d');
    this.size = 20; this.grid = 20;
    this.reset();
    this.bindKeys();
    this.loop();
  }
  reset() {
    this.snake = [{x:10,y:10}];
    this.dir = {x:1,y:0}; this.nextDir = {x:1,y:0};
    this.food = this.spawnFood();
    this.score = 0; this.running = true; this.paused = false;
    this.draw();
  }
  spawnFood() {
    let p;
    do { p = {x:Math.floor(Math.random()*this.grid), y:Math.floor(Math.random()*this.grid)}; }
    while (this.snake.some(s => s.x===p.x && s.y===p.y));
    return p;
  }
  bindKeys() {
    this._key = e => {
      if (e.key==='p'||e.key==='P') { this.paused = !this.paused; this.draw(); return; }
      if (this.paused) return;
      const map = {'ArrowUp':{x:0,y:-1},'ArrowDown':{x:0,y:1},'ArrowLeft':{x:-1,y:0},'ArrowRight':{x:1,y:0}};
      const d = map[e.key]; if (!d) return;
      if (d.x !== -this.dir.x || d.y !== -this.dir.y) this.nextDir = d;
      e.preventDefault();
    };
    document.addEventListener('keydown', this._key);
  }
  update() {
    if (!this.running || this.paused) return;
    this.dir = this.nextDir;
    const head = {x:this.snake[0].x+this.dir.x, y:this.snake[0].y+this.dir.y};
    if (head.x<0||head.x>=this.grid||head.y<0||head.y>=this.grid || this.snake.some(s=>s.x===head.x&&s.y===head.y)) {
      this.running = false; this.draw(); return;
    }
    this.snake.unshift(head);
    if (head.x===this.food.x && head.y===this.food.y) {
      this.score += 10; document.getElementById('snakeScore').textContent = this.score;
      this.food = this.spawnFood();
    } else this.snake.pop();
    this.draw();
  }
  draw() {
    const ctx = this.ctx, s = this.canvas.width/this.grid;
    ctx.fillStyle = '#111'; ctx.fillRect(0,0,this.canvas.width,this.canvas.height);
    this.snake.forEach((p,i) => { ctx.fillStyle = i===0?'#39ff14':'#1a8a0a'; ctx.fillRect(p.x*s,p.y*s,s-1,s-1); });
    ctx.fillStyle = '#ff3333'; ctx.fillRect(this.food.x*s,this.food.y*s,s-1,s-1);
    if (!this.running) { ctx.fillStyle = 'rgba(0,0,0,.6)'; ctx.fillRect(0,0,this.canvas.width,this.canvas.height);
      ctx.fillStyle = '#fff'; ctx.font = '24px monospace'; ctx.textAlign = 'center';
      ctx.fillText('Game Over', this.canvas.width/2, this.canvas.height/2); }
    else if (this.paused) { ctx.fillStyle = 'rgba(0,0,0,.5)'; ctx.fillRect(0,0,this.canvas.width,this.canvas.height);
      ctx.fillStyle = '#fff'; ctx.font = '24px monospace'; ctx.textAlign = 'center';
      ctx.fillText('Paused', this.canvas.width/2, this.canvas.height/2); }
  }
  loop() { this.update(); this._timer = setTimeout(()=>this.loop(), 120); }
  stop() { clearTimeout(this._timer); document.removeEventListener('keydown', this._key); }
}

/* ───────── Tetris ───────── */
let tetrisGame = null;

function startTetris() {
  if (tetrisGame) { tetrisGame.stop(); tetrisGame = null; }
  tetrisGame = new TetrisGame();
}

class TetrisGame {
  constructor() {
    this.canvas = document.getElementById('tetrisCanvas');
    this.ctx = this.canvas.getContext('2d');
    this.cols = 10; this.rows = 20; this.bs = this.canvas.width/this.cols;
    this.pieces = [
      {blocks:[[1,1],[1,1]],color:'#ffd700'}, // O
      {blocks:[[0,1,0],[1,1,1]],color:'#9b59b6'}, // T
      {blocks:[[1,0,0],[1,1,1]],color:'#3498db'}, // L
      {blocks:[[0,0,1],[1,1,1]],color:'#e67e22'}, // J
      {blocks:[[1,1,0],[0,1,1]],color:'#2ecc71'}, // S
      {blocks:[[0,1,1],[1,1,0]],color:'#e74c3c'}, // Z
      {blocks:[[1,1,1,1]],color:'#1abc9c'} // I
    ];
    this.reset(); this.bindKeys(); this.loop();
  }
  reset() {
    this.board = Array.from({length:this.rows},()=>Array(this.cols).fill(0));
    this.score = 0; this.lines = 0; this.running = true; this.paused = false; this.dropInt = 500;
    this.spawnPiece();
  }
  spawnPiece() {
    const p = this.pieces[Math.floor(Math.random()*this.pieces.length)];
    this.piece = {blocks:p.blocks, color:p.color, x:Math.floor((this.cols-p.blocks[0].length)/2), y:0};
    this.lockDelay = 0;
    if (this.collides(0,0)) { this.running = false; this.draw(); }
  }
  collides(dx,dy) {
    for (let r=0;r<this.piece.blocks.length;r++) for (let c=0;c<this.piece.blocks[r].length;c++) {
      if (!this.piece.blocks[r][c]) continue;
      const nx = this.piece.x+c+dx, ny = this.piece.y+r+dy;
      if (nx<0||nx>=this.cols||ny>=this.rows) return true;
      if (ny>=0 && this.board[ny][nx]) return true;
    }
    return false;
  }
  lock() {
    for (let r=0;r<this.piece.blocks.length;r++) for (let c=0;c<this.piece.blocks[r].length;c++) {
      if (!this.piece.blocks[r][c]) continue;
      const ny = this.piece.y+r;
      if (ny>=0) this.board[ny][this.piece.x+c] = this.piece.color;
    }
    this.clearLines(); this.spawnPiece();
  }
  clearLines() {
    let cleared = 0;
    for (let r=this.rows-1;r>=0;r--) {
      if (this.board[r].every(c=>c)) {
        this.board.splice(r,1); this.board.unshift(Array(this.cols).fill(0));
        cleared++; r++;
      }
    }
    if (cleared) {
      this.lines += cleared; this.score += [0,100,300,500,800][cleared];
      document.getElementById('tetrisScore').textContent = this.score;
      document.getElementById('tetrisLines').textContent = this.lines;
      this.dropInt = Math.max(100,500-this.lines*15);
    }
  }
  move(dx) { if (!this.collides(dx,0)) this.piece.x += dx; }
  rotate() {
    const old = this.piece.blocks;
    const rot = old[0].map((_,i)=>old.map(r=>r[i]).reverse());
    this.piece.blocks = rot;
    if (this.collides(0,0)) this.piece.blocks = old;
  }
  hardDrop() { while (!this.collides(0,1)) this.piece.y++; this.lock(); }
  bindKeys() {
    this._key = e => {
      if (e.key==='p'||e.key==='P') { this.paused=!this.paused; this.draw(); return; }
      if (!this.running||this.paused) return;
      if (e.key==='ArrowLeft') { this.move(-1); this.draw(); }
      if (e.key==='ArrowRight') { this.move(1); this.draw(); }
      if (e.key==='ArrowUp') { this.rotate(); this.draw(); }
      if (e.key==='ArrowDown') { if (!this.collides(0,1)) { this.piece.y++; this.draw(); } }
      if (e.key===' ') { e.preventDefault(); this.hardDrop(); this.draw(); }
    };
    document.addEventListener('keydown', this._key);
  }
  draw() {
    const ctx = this.ctx, bs = this.bs;
    ctx.fillStyle='#111'; ctx.fillRect(0,0,this.canvas.width,this.canvas.height);
    for (let r=0;r<this.rows;r++) for (let c=0;c<this.cols;c++) {
      if (this.board[r][c]) { ctx.fillStyle=this.board[r][c]; ctx.fillRect(c*bs,r*bs,bs-1,bs-1); }
    }
    if (this.piece && this.running) {
      for (let r=0;r<this.piece.blocks.length;r++) for (let c=0;c<this.piece.blocks[r].length;c++) {
        if (!this.piece.blocks[r][c]) continue;
        const ny = this.piece.y+r;
        if (ny>=0) { ctx.fillStyle=this.piece.color; ctx.fillRect((this.piece.x+c)*bs,ny*bs,bs-1,bs-1); }
      }
    }
    ctx.strokeStyle='#333'; ctx.lineWidth=1; ctx.strokeRect(0,0,this.canvas.width,this.canvas.height);
    if (!this.running) { ctx.fillStyle='rgba(0,0,0,.6)'; ctx.fillRect(0,0,this.canvas.width,this.canvas.height);
      ctx.fillStyle='#fff'; ctx.font='24px monospace'; ctx.textAlign='center'; ctx.fillText('Game Over',this.canvas.width/2,this.canvas.height/2); }
    else if (this.paused) { ctx.fillStyle='rgba(0,0,0,.5)'; ctx.fillRect(0,0,this.canvas.width,this.canvas.height);
      ctx.fillStyle='#fff'; ctx.font='24px monospace'; ctx.textAlign='center'; ctx.fillText('Paused',this.canvas.width/2,this.canvas.height/2); }
  }
  loop() { this._timer = setTimeout(()=>{ if(this.running&&!this.paused) { if(!this.collides(0,1))this.piece.y++; else this.lock(); this.draw(); } this.loop(); }, this.dropInt); }
  stop() { clearTimeout(this._timer); document.removeEventListener('keydown', this._key); }
}

/* ───────── Pong ───────── */
let pongGame = null;

function startPong() {
  if (pongGame) { pongGame.stop(); pongGame = null; }
  pongGame = new PongGame();
}

class PongGame {
  constructor() {
    this.canvas = document.getElementById('pongCanvas');
    this.ctx = this.canvas.getContext('2d');
    this.W=this.canvas.width; this.H=this.canvas.height;
    this.reset(); this.bindKeys(); this.last=performance.now(); this.loop();
  }
  reset() {
    this.lScore=0; this.rScore=0;
    this.ball={x:this.W/2,y:this.H/2,dx:4*(Math.random()>.5?1:-1),dy:3*(Math.random()>.5?1:-1),r:6};
    this.paddleH=60; this.paddleW=8; this.lPaddle=this.H/2; this.rPaddle=this.H/2;
    this.keys={}; this.running=true; this.serving=true;
  }
  bindKeys() {
    this._down = e => { this.keys[e.key]=true; if(e.key===' '&&this.serving){this.serving=false;this.ball.dx=4*(Math.random()>.5?1:-1);this.ball.dy=3*(Math.random()>.5?1:-1);}};
    this._up = e => { this.keys[e.key]=false; };
    document.addEventListener('keydown',this._down); document.addEventListener('keyup',this._up);
  }
  update(dt) {
    if (!this.running) return;
    if (this.keys['w']||this.keys['W']) this.lPaddle = Math.max(0,this.lPaddle-400*dt);
    if (this.keys['s']||this.keys['S']) this.lPaddle = Math.min(this.H-this.paddleH,this.lPaddle+400*dt);
    if (this.keys['ArrowUp']) this.rPaddle = Math.max(0,this.rPaddle-400*dt);
    if (this.keys['ArrowDown']) this.rPaddle = Math.min(this.H-this.paddleH,this.rPaddle+400*dt);
    if (this.serving) return;
    this.ball.x += this.ball.dx; this.ball.y += this.ball.dy;
    if (this.ball.y-this.ball.r<0||this.ball.y+this.ball.r>this.H) this.ball.dy = -this.ball.dy;
    if (this.ball.x-this.ball.r<this.paddleW && this.ball.y>this.lPaddle && this.ball.y<this.lPaddle+this.paddleH && this.ball.dx<0)
      { this.ball.dx = -this.ball.dx*1.05; this.ball.x = this.paddleW+this.ball.r; }
    if (this.ball.x+this.ball.r>this.W-this.paddleW && this.ball.y>this.rPaddle && this.ball.y<this.rPaddle+this.paddleH && this.ball.dx>0)
      { this.ball.dx = -this.ball.dx*1.05; this.ball.x = this.W-this.paddleW-this.ball.r; }
    if (this.ball.x<0) { this.rScore++; this.serving=true; this.ball={x:this.W/2,y:this.H/2,dx:0,dy:0,r:6}; }
    if (this.ball.x>this.W) { this.lScore++; this.serving=true; this.ball={x:this.W/2,y:this.H/2,dx:0,dy:0,r:6}; }
    document.getElementById('pongScore').textContent = this.lScore+' - '+this.rScore;
  }
  draw() {
    const ctx=this.ctx;
    ctx.fillStyle='#111'; ctx.fillRect(0,0,this.W,this.H);
    ctx.fillStyle='#fff'; ctx.fillRect(0,this.lPaddle,this.paddleW,this.paddleH);
    ctx.fillRect(this.W-this.paddleW,this.rPaddle,this.paddleW,this.paddleH);
    ctx.beginPath(); ctx.arc(this.ball.x,this.ball.y,this.ball.r,0,Math.PI*2); ctx.fillStyle='#fff'; ctx.fill();
    ctx.strokeStyle='#333'; ctx.setLineDash([8,8]); ctx.beginPath(); ctx.moveTo(this.W/2,0); ctx.lineTo(this.W/2,this.H); ctx.stroke(); ctx.setLineDash([]);
    if (this.serving) { ctx.fillStyle='#fff'; ctx.font='16px monospace'; ctx.textAlign='center'; ctx.fillText('Press Space to serve',this.W/2,30); }
  }
  loop() { const now=performance.now(); this.update((now-this.last)/1000); this.last=now; this.draw(); this._timer=requestAnimationFrame(()=>this.loop()); }
  stop() { cancelAnimationFrame(this._timer); document.removeEventListener('keydown',this._down); document.removeEventListener('keyup',this._up); }
}

/* ───────── Breakout ───────── */
let breakoutGame = null;

function startBreakout() {
  if (breakoutGame) { breakoutGame.stop(); breakoutGame = null; }
  breakoutGame = new BreakoutGame();
}

class BreakoutGame {
  constructor() {
    this.canvas = document.getElementById('breakoutCanvas');
    this.ctx = this.canvas.getContext('2d');
    this.W=this.canvas.width; this.H=this.canvas.height;
    this.reset(); this.bindKeys(); this.bindMouse(); this.last=performance.now(); this.loop();
  }
  reset() {
    this.paddleW=80; this.paddleH=12; this.paddleX=(this.W-this.paddleW)/2;
    this.ball={x:this.W/2,y:this.H-30,r:6,dx:4,dy:-4};
    this.bricks=[]; this.score=0; this.running=true;
    const colors=['#ff6b6b','#ffd93d','#6bcb77','#4d96ff','#9b59b6'];
    for (let r=0;r<5;r++) for (let c=0;c<8;c++)
      this.bricks.push({x:c*60+4,y:r*22+4,w:56,h:18,color:colors[r],alive:true});
  }
  bindKeys() {
    this._key = e => { if (e.key==='ArrowLeft') this.moveLeft=true; if (e.key==='ArrowRight') this.moveRight=true; if (e.key===' ') { e.preventDefault(); this.launch(); } };
    this._keyUp = e => { if (e.key==='ArrowLeft') this.moveLeft=false; if (e.key==='ArrowRight') this.moveRight=false; };
    document.addEventListener('keydown',this._key); document.addEventListener('keyup',this._keyUp);
  }
  bindMouse() {
    this._mouse = e => { const r=this.canvas.getBoundingClientRect(); this.mouseX=e.clientX-r.left; };
    document.addEventListener('mousemove',this._mouse);
  }
  launch() { if (!this.running) this.reset(); }
  update(dt) {
    if (!this.running) return;
    const speed=400;
    if (this.moveLeft) this.paddleX=Math.max(0,this.paddleX-speed*dt);
    if (this.moveRight) this.paddleX=Math.min(this.W-this.paddleW,this.paddleX+speed*dt);
    if (this.mouseX!=null) this.paddleX=Math.max(0,Math.min(this.W-this.paddleW,this.mouseX-this.paddleW/2));
    this.ball.x+=this.ball.dx; this.ball.y+=this.ball.dy;
    if (this.ball.x-this.ball.r<0||this.ball.x+this.ball.r>this.W) this.ball.dx=-this.ball.dx;
    if (this.ball.y-this.ball.r<0) this.ball.dy=-this.ball.dy;
    if (this.ball.y+this.ball.r>this.H) { this.running=false; this.ball.dx=0; this.ball.dy=0; return; }
    if (this.ball.y+this.ball.r>this.H-this.paddleH-5 && this.ball.x>this.paddleX && this.ball.x<this.paddleX+this.paddleW) {
      const hit=(this.ball.x-this.paddleX)/this.paddleW;
      const angle=hit*Math.PI-Math.PI/2;
      const spd=Math.sqrt(this.ball.dx*this.ball.dx+this.ball.dy*this.ball.dy);
      this.ball.dx=Math.cos(angle)*spd; this.ball.dy=-Math.abs(Math.sin(angle)*spd);
      this.ball.y=this.H-this.paddleH-5-this.ball.r;
    }
    for (const b of this.bricks) {
      if (!b.alive) continue;
      if (this.ball.x> b.x && this.ball.x<b.x+b.w && this.ball.y> b.y && this.ball.y<b.y+b.h) {
        b.alive=false; this.ball.dy=-this.ball.dy; this.score+=10;
        document.getElementById('breakoutScore').textContent=this.score;
      }
    }
  }
  draw() {
    const ctx=this.ctx;
    ctx.fillStyle='#111'; ctx.fillRect(0,0,this.W,this.H);
    for (const b of this.bricks) if(b.alive){ctx.fillStyle=b.color;ctx.fillRect(b.x,b.y,b.w,b.h);}
    ctx.fillStyle='#fff'; ctx.fillRect(this.paddleX,this.H-this.paddleH-5,this.paddleW,this.paddleH);
    ctx.beginPath(); ctx.arc(this.ball.x,this.ball.y,this.ball.r,0,Math.PI*2); ctx.fillStyle='#fff'; ctx.fill();
    if (!this.running) { ctx.fillStyle='rgba(0,0,0,.5)'; ctx.fillRect(0,0,this.W,this.H);
      ctx.fillStyle='#fff'; ctx.font='24px monospace'; ctx.textAlign='center'; ctx.fillText('Game Over',this.W/2,this.H/2);
      ctx.font='14px monospace'; ctx.fillText('Press Start again',this.W/2,this.H/2+30); }
  }
  loop() { const now=performance.now(); this.update((now-this.last)/1000); this.last=now; this.draw(); this._timer=requestAnimationFrame(()=>this.loop()); }
  stop() { cancelAnimationFrame(this._timer); document.removeEventListener('keydown',this._key); document.removeEventListener('keyup',this._keyUp); document.removeEventListener('mousemove',this._mouse); }
}

/* ───────── Minesweeper ───────── */
let mineGame = null;

function startMinesweeper() {
  if (mineGame) { mineGame.stop(); mineGame = null; }
  mineGame = new MineGame();
}

class MineGame {
  constructor() {
    this.canvas=document.getElementById('mineCanvas');
    this.ctx=this.canvas.getContext('2d');
    this.rows=9; this.cols=9; this.mines=10; this.bs=this.canvas.width/this.cols;
    this.reset(); this.bindMouse();
  }
  reset() {
    this.board=Array.from({length:this.rows},()=>Array(this.cols).fill(0));
    this.revealed=Array.from({length:this.rows},()=>Array(this.cols).fill(false));
    this.flagged=Array.from({length:this.rows},()=>Array(this.cols).fill(false));
    this.gameOver=false; this.won=false; this.first=true;
    document.getElementById('mineStatus').textContent='Click a cell to start';
    this.draw();
  }
  plant(startR,startC) {
    let placed=0;
    while(placed<this.mines) {
      const r=Math.floor(Math.random()*this.rows), c=Math.floor(Math.random()*this.cols);
      if (this.board[r][c]===-1||(Math.abs(r-startR)<=1&&Math.abs(c-startC)<=1)) continue;
      this.board[r][c]=-1; placed++;
    }
    for(let r=0;r<this.rows;r++) for(let c=0;c<this.cols;c++)
      if(this.board[r][c]!==-1) this.board[r][c]=this.countAdj(r,c);
  }
  countAdj(r,c) { let n=0; for(let dr=-1;dr<=1;dr++) for(let dc=-1;dc<=1;dc++) { const nr=r+dr,nc=c+dc; if(nr>=0&&nr<this.rows&&nc>=0&&nc<this.cols&&this.board[nr][nc]===-1) n++; } return n; }
  reveal(r,c) {
    if(r<0||r>=this.rows||c<0||c>=this.cols||this.revealed[r][c]||this.flagged[r][c]) return;
    this.revealed[r][c]=true;
    if(this.board[r][c]===-1) { this.gameOver=true; this.draw(); document.getElementById('mineStatus').textContent='💥 Game Over! Click New Game'; return; }
    if(this.board[r][c]===0) for(let dr=-1;dr<=1;dr++) for(let dc=-1;dc<=1;dc++) this.reveal(r+dr,c+dc);
    this.checkWin();
  }
  checkWin() {
    let total=0,rev=0;
    for(let r=0;r<this.rows;r++) for(let c=0;c<this.cols;c++) { total++; if(this.revealed[r][c]||this.flagged[r][c]) rev++; }
    this.won=(total-rev)===this.mines;
    if(this.won) document.getElementById('mineStatus').textContent='🎉 You Win!';
    else document.getElementById('mineStatus').textContent='Keep going...';
  }
  bindMouse() {
    this._click = e => {
      const r=this.canvas.getBoundingClientRect();
      const x=Math.floor((e.clientX-r.left)/this.bs), y=Math.floor((e.clientY-r.top)/this.bs);
      if(x<0||x>=this.cols||y<0||y>=this.rows||this.gameOver||this.won) return;
      if(e.button===2) { this.flagged[y][x]=!this.flagged[y][x]; this.draw(); e.preventDefault(); return; }
      if(this.first) { this.plant(y,x); this.first=false; }
      this.reveal(y,x); this.draw();
    };
    this._cm = e => e.preventDefault();
    this.canvas.addEventListener('mousedown',this._click);
    this.canvas.addEventListener('contextmenu',this._cm);
  }
  draw() {
    const ctx=this.ctx, bs=this.bs;
    for(let r=0;r<this.rows;r++) for(let c=0;c<this.cols;c++) {
      ctx.fillStyle=this.revealed[r][c]?'#2a2a2a':'#333'; ctx.fillRect(c*bs,r*bs,bs-1,bs-1);
      if(this.flagged[r][c]) { ctx.fillStyle='#ff4444'; ctx.font='16px monospace'; ctx.textAlign='center'; ctx.textBaseline='middle'; ctx.fillText('🚩',c*bs+bs/2,r*bs+bs/2); }
      else if(this.revealed[r][c]) {
        if(this.board[r][c]===-1) { ctx.fillStyle='#ff0000'; ctx.font='16px monospace'; ctx.textAlign='center'; ctx.textBaseline='middle'; ctx.fillText('💣',c*bs+bs/2,r*bs+bs/2); }
        else if(this.board[r][c]>0) { ctx.fillStyle=['#fff','#4d96ff','#6bcb77','#ff6b6b','#9b59b6','#ffd93d','#ff9ff3','#54a0ff','#5f27cd'][this.board[r][c]]; ctx.font='bold 14px monospace'; ctx.textAlign='center'; ctx.textBaseline='middle'; ctx.fillText(this.board[r][c],c*bs+bs/2,r*bs+bs/2); }
      }
    }
    if(this.gameOver) for(let r=0;r<this.rows;r++) for(let c=0;c<this.cols;c++) if(this.board[r][c]===-1&&!this.revealed[r][c]) { ctx.fillStyle='#cc4444'; ctx.font='14px monospace'; ctx.textAlign='center'; ctx.textBaseline='middle'; ctx.fillText('💣',c*bs+bs/2,r*bs+bs/2); }
  }
  stop() { this.canvas.removeEventListener('mousedown',this._click); this.canvas.removeEventListener('contextmenu',this._cm); }
}
</script>
