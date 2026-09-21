---
title: "Attention Is All You Need — Explained Simply"
date: 2026-05-21
draft: false
tags: ["ai", "deep-learning", "transformer", "paper"]
categories: ["Tech"]
viewMode: docs
---

<style>
  :root{
    --paper:#f5f0e5;
    --paper-2:#ece4d4;
    --ink:#211b16;
    --ink-soft:#5b5147;
    --terra:#c0492b;
    --teal:#176b63;
    --gold:#cf952a;
    --panel:#171311;
    --panel-2:#231c18;
    --panel-line:#3a2f28;
    --glow:#f0b35a;
  }
  [data-theme="dark"]{
    --paper:#1a1714;
    --paper-2:#231e1a;
    --ink:#e8ddd0;
    --ink-soft:#a89a89;
    --panel:#0e0b09;
    --panel-2:#1a1511;
    --panel-line:#2c241e;
    --glow:#e8a84a;
  }
  *{box-sizing:border-box;}
  html{scroll-behavior:smooth;}
  .post-content #progress{position:fixed;top:0;left:0;height:4px;width:0;background:linear-gradient(90deg,var(--terra),var(--gold));z-index:200;transition:width .1s linear;}
  .post-content nav#dots{position:fixed;right:18px;top:50%;transform:translateY(-50%);z-index:150;display:flex;flex-direction:column;gap:11px;}
  .post-content nav#dots a{width:11px;height:11px;border-radius:50%;border:1.5px solid var(--ink-soft);background:transparent;transition:all .25s;display:block;}
  .post-content nav#dots a.active{background:var(--terra);border-color:var(--terra);transform:scale(1.35);}
  .post-content nav#dots a:hover{border-color:var(--terra);}
  @media(max-width:880px){.post-content nav#dots{display:none;}}
  .post-content header.hero{min-height:96vh;display:flex;flex-direction:column;justify-content:center;max-width:920px;margin:0 auto;position:relative;overflow:hidden;background:var(--paper);font-family:"Newsreader",Georgia,serif;-webkit-font-smoothing:antialiased;background-image:radial-gradient(circle at 12% -10%, rgba(192,73,43,.06), transparent 40%),radial-gradient(circle at 100% 8%, rgba(23,107,99,.06), transparent 38%);border:12px double var(--ink);padding:clamp(32px,6vh,70px);}
  [data-theme="dark"] .post-content header.hero{background-image:radial-gradient(circle at 12% -10%, rgba(192,73,43,.12), transparent 40%),radial-gradient(circle at 100% 8%, rgba(23,107,99,.12), transparent 38%);border-color:var(--ink);}
  .post-content header.hero::before{content:'';position:absolute;inset:-1px;border:1px solid var(--ink-soft);pointer-events:none;}
  [data-theme="dark"] .post-content header.hero::before{border-color:var(--ink-soft);}
  .post-content header.hero::after{content:'';position:absolute;inset:0;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.5'/%3E%3C/svg%3E");opacity:0.04;mix-blend-mode:overlay;pointer-events:none;}
  [data-theme="dark"] .post-content header.hero::after{opacity:0.025;}
  .post-content .eyebrow{font-family:"JetBrains Mono",monospace;font-size:13px;letter-spacing:.22em;text-transform:uppercase;color:var(--terra);margin-bottom:22px;}
  .post-content h1{font-family:"Fraunces",serif;font-weight:900;font-size:clamp(46px,9vw,104px);line-height:.95;letter-spacing:-.02em;margin:0 0 8px;color:var(--ink);}
  .post-content h1 .light{font-weight:400;font-style:italic;color:var(--teal);}
  .post-content .subtitle{font-size:clamp(20px,2.6vw,27px);color:var(--ink-soft);max-width:620px;margin-top:24px;font-style:italic;}
  .post-content .byline{font-family:"JetBrains Mono",monospace;font-size:13px;color:var(--ink-soft);margin-top:38px;line-height:1.8;}
  .post-content .byline b{color:var(--ink);font-weight:600;}

  .post-content .stage{background:var(--panel);color:#efe7da;border-radius:16px;padding:30px 28px;margin:34px 0;box-shadow:0 24px 60px -28px rgba(33,20,10,.6);font-family:"Newsreader",serif;border:1px solid var(--panel-line);}
  [data-theme="dark"] .post-content .stage{box-shadow:0 24px 60px -28px rgba(0,0,0,.8);}
  .post-content .stage .stage-label{font-family:"JetBrains Mono",monospace;font-size:11px;letter-spacing:.2em;text-transform:uppercase;color:var(--glow);margin-bottom:6px;}
  .post-content .stage h4{font-family:"Fraunces",serif;font-weight:600;font-size:22px;margin:0 0 14px;color:#fff;}
  .post-content .stage p{font-size:16px;line-height:1.55;color:#cfc3b2;margin:12px 0;}
  .post-content .stage .mono{font-family:"JetBrains Mono",monospace;font-size:13px;}
  .post-content .btn{font-family:"JetBrains Mono",monospace;font-size:13px;cursor:pointer;border:none;background:var(--terra);color:#fff;padding:9px 16px;border-radius:8px;letter-spacing:.04em;transition:transform .12s,filter .12s;}
  .post-content .btn:hover{filter:brightness(1.1);transform:translateY(-1px);}
  .post-content .btn.ghost{background:transparent;border:1px solid var(--panel-line);color:#cfc3b2;}
  .post-content .btn.ghost.on{background:var(--teal);border-color:var(--teal);color:#fff;}
  .post-content .btn.small{padding:6px 12px;font-size:12px;}
  .post-content .controls{display:flex;flex-wrap:wrap;gap:8px;align-items:center;margin:14px 0;}
  .post-content table.calc{width:100%;border-collapse:collapse;font-family:"JetBrains Mono",monospace;font-size:13px;margin-top:10px;}
  .post-content table.calc td,.post-content table.calc th{padding:7px 8px;text-align:left;border-bottom:1px solid var(--panel-line);}
  .post-content table.calc th{color:var(--glow);font-weight:600;font-size:11px;letter-spacing:.08em;text-transform:uppercase;}
  .post-content .bar{height:14px;border-radius:7px;background:linear-gradient(90deg,var(--teal),var(--glow));transition:width .5s cubic-bezier(.2,.8,.2,1);}
  .post-content .barwrap{background:#2c241e;border-radius:7px;overflow:hidden;width:120px;display:inline-block;vertical-align:middle;}
  .post-content .clockrow{display:flex;gap:6px;flex-wrap:wrap;margin:10px 0;}
  .post-content .cell{width:44px;height:44px;border-radius:8px;background:var(--panel-2);border:1px solid var(--panel-line);display:flex;align-items:center;justify-content:center;font-family:"JetBrains Mono",monospace;font-size:13px;color:#9c8e7d;transition:all .3s;}
  .post-content .cell.done{background:var(--teal);color:#fff;border-color:var(--teal);}
  .post-content .cell.active{background:var(--terra);color:#fff;border-color:var(--terra);transform:scale(1.08);}
  .post-content .sent{line-height:2.6;margin:10px 0;}
  .post-content .aw{position:relative;display:inline-block;padding:4px 8px;border-radius:7px;margin:2px;font-family:"JetBrains Mono",monospace;font-size:15px;transition:background .35s,color .35s;color:#e7ddcd;}
  .post-content input[type=range]{width:100%;accent-color:var(--terra);height:24px;}
  .post-content .lbl{font-family:"JetBrains Mono",monospace;font-size:12px;color:#cfc3b2;display:flex;justify-content:space-between;}
  .post-content .headbtns{display:flex;gap:6px;flex-wrap:wrap;}
  .post-content .arch{display:flex;gap:18px;justify-content:center;flex-wrap:wrap;margin-top:12px;}
  .post-content .stackcol{flex:1;min-width:210px;}
  .post-content .stackcol h5{font-family:"JetBrains Mono",monospace;font-size:12px;letter-spacing:.15em;text-transform:uppercase;color:var(--glow);text-align:center;margin:0 0 10px;}
  .post-content .block{background:var(--panel-2);border:1px solid var(--panel-line);border-radius:9px;padding:11px 12px;margin:8px 0;font-size:13px;cursor:pointer;transition:all .2s;color:#cfc3b2;}
  .post-content .block:hover{border-color:var(--glow);background:#2e251f;color:#fff;}
  .post-content .block b{color:#fff;font-family:"Fraunces",serif;font-weight:600;font-size:15px;display:block;}
  .post-content .explainbox{min-height:54px;margin-top:14px;padding:13px 15px;background:#0e0b09;border-radius:9px;font-size:14px;color:#cfc3b2;border:1px dashed var(--panel-line);}
  .post-content .chart{display:flex;align-items:flex-end;gap:20px;height:230px;margin:24px 0 8px;padding:0 6px;}
  .post-content .chbar{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:flex-end;height:100%;}
  .post-content .chbar .col{width:100%;border-radius:8px 8px 0 0;background:var(--panel-2);transition:height 1.1s cubic-bezier(.2,.8,.2,1);height:0;position:relative;}
  .post-content .chbar.us .col{background:linear-gradient(180deg,var(--terra),var(--gold));}
  .post-content .chbar .val{font-family:"JetBrains Mono",monospace;font-size:13px;margin-bottom:6px;color:#e7ddcd;}
  .post-content .chbar .name{font-family:"JetBrains Mono",monospace;font-size:11px;margin-top:8px;color:#9c8e7d;text-align:center;line-height:1.3;}
  .post-content .legend{font-family:"JetBrains Mono",monospace;font-size:12px;color:#9c8e7d;margin-top:8px;}
  .post-content textarea{width:100%;height:150px;background:#0e0b09;border:1px solid var(--panel-line);color:#e7ddcd;padding:12px;border-radius:10px;font-family:'JetBrains Mono',monospace;font-size:13px;line-height:1.6;resize:vertical;}
  [data-theme="dark"] .post-content .barwrap{background:#3a2f28;}
  [data-theme="dark"] .post-content .block:hover{background:#3a2f28;color:#e7ddcd;}
  [data-theme="dark"] .post-content textarea,[data-theme="dark"] .post-content .explainbox{background:#000;}
  [data-theme="dark"] .post-content .chbar .name{color:#7a6a59;}
</style>

<div id="progress"></div>
<nav id="dots"></nav>

<header class="hero">
  <div class="eyebrow">The paper that built modern AI &middot; Vaswani et al., 2017</div>
  <h1>Attention Is<br>All You <span class="light">Need</span></h1>
  <div style="width:80px;height:2px;background:var(--terra);margin:16px 0 22px;"></div>
  <div class="subtitle">The famous research paper behind ChatGPT, translation apps, and almost every AI you use today — rewritten so anyone can follow it, with things you can actually play with.</div>
  <div class="byline">
    Original authors: <b>Vaswani, Shazeer, Parmar, Uszkoreit, Jones, Gomez, Kaiser, Polosukhin</b><br>
    Google Brain &amp; Google Research &middot; Published at NeurIPS 2017<br>
    This page: a plain-language, interactive walkthrough.
  </div>
</header>

<span id="s1" class="s"></span>

**01 · The problem**

## Why old AI read like a slow reader

Before this paper, the best language AIs read a sentence the way you might read in a noisy room — **one word at a time, in strict order**, holding everything in your head as you go.

These models were called *RNNs* (recurrent neural networks). To understand word number 50, the model first had to process words 1 through 49, in sequence. It could not look at word 50 until everything before it was done.

> **Relatable example**
> Imagine reading a book where each page is glued shut until you finish the previous one. You can never skip ahead or glance at two pages side by side. That is fine for a short note, but painful for a long chapter — and you can never use more than one pair of hands.

This caused two big headaches: it was **slow** (no skipping ahead, no doing things at the same time), and it had a **bad memory** for things far apart. By the time the model reached the end of a long sentence, it had often half-forgotten the beginning.

<div class="stage">
  <div class="stage-label">Try it</div>
  <h4>Reading one word at a time vs. all at once</h4>
  <p>Watch how an old model (RNN) must crawl through a sentence in order, while a Transformer looks at every word in the same instant.</p>
  <div class="controls">
    <button class="btn" id="seqBtn">Old way (sequential)</button>
    <button class="btn ghost" id="parBtn">Transformer way (parallel)</button>
  </div>
  <div class="mono" style="color:#9c8e7d;margin-bottom:6px;">"The cat sat on the warm mat"</div>
  <div class="clockrow" id="seqRow"></div>
  <div class="mono" id="seqStatus" style="color:var(--glow);min-height:20px;">Press a button above.</div>
</div>

The Transformer's trick was to throw out the "one word at a time" rule completely. But if you read every word at once, how does the model know which words are *related* to which? That is where **attention** comes in.

<span id="s2" class="s"></span>

**02 · The big idea**

## Attention: letting words look at each other

"Attention" is just a fancy word for a simple human habit: when you read a word, you instinctively glance at **other words that help explain it**.

> **Relatable example**
> Read this sentence: *"The animal didn't cross the street because **it** was too tired."* What does "it" mean — the animal or the street? You instantly look back at "animal." Your brain paid **attention** to the right earlier word. That glance is the entire idea.

The Transformer gives every word the ability to do this glancing, all at once. For each word, the model asks: *"Which other words in this sentence should I pay attention to in order to understand myself?"*

<div class="stage">
  <div class="stage-label">Try it &middot; click any word</div>
  <h4>What is each word looking at?</h4>
  <p>Click a word below. The darker another word glows, the more this word "pays attention" to it. Notice that <strong>it</strong> strongly attends to <strong>animal</strong> — the model has learned what "it" refers to.</p>
  <div class="sent" id="attnSent"></div>
  <div class="legend" id="attnHint">Selected word glows orange. Attention strength shown by green glow on the others.</div>
</div>

*These attention strengths are illustrative, chosen to match the kind of patterns the real trained model learns — the paper shows real examples of exactly this "it → animal" behavior.*

<span id="s3" class="s"></span>

**03 · Words into numbers**

## First, turn every word into a list of numbers

Computers can't do math on the letters c-a-t. So the very first step is to turn each word into a list of numbers called a **vector** (the paper uses lists of 512 numbers each).

You can picture each word as a **point in space**. Words with similar meanings end up near each other. "King" sits near "queen"; "cat" sits near "dog"; "Monday" sits far from "banana." The model learns these positions on its own by reading huge amounts of text.

> **Relatable example**
> Think of a map of a country. Cities that are culturally similar tend to be close together. A "word map" works the same way: the *direction and distance* between word-points carries meaning. Famously, "king − man + woman" lands you right next to "queen."

This list of numbers is called an **embedding**. Everything that follows — all the attention magic — is just arithmetic on these number-lists.

<span id="s4" class="s"></span>

**04 · Word order**

## Reminding the model where each word sits

There's a catch. Because the Transformer reads all words at once instead of in order, it has no built-in sense of **which word came first**.

But order matters enormously:

> **Relatable example**
> *"The dog bit the man"* and *"The man bit the dog"* use the exact same words. Only the order tells you who is in trouble. Without order, both sentences look identical to the model.

The fix is clever: before the words enter the model, each one gets a unique **"position fingerprint"** added to its number-list. Position 1 gets one fingerprint, position 2 a slightly different one, and so on.

The paper builds these fingerprints out of **sine and cosine waves** of different speeds — like a row of clocks all ticking at different rates. Each position lights up a unique combination of fast and slow waves, giving it a signature the model can recognize. A nice bonus: this method lets the model handle sentences longer than any it saw during training.

<div class="stage">
  <div class="stage-label">Try it</div>
  <h4>Each position has its own wave-fingerprint</h4>
  <p>Drag to move through positions. Each vertical slice is one word-position; the colored stripes are the sine/cosine values that make its unique signature. No two columns look the same.</p>
  <canvas id="posCanvas" width="680" height="180" style="width:100%;border-radius:10px;background:#0e0b09;display:block;"></canvas>
  <div class="lbl" style="margin-top:10px;"><span>Position in sentence</span><span id="posLabel">position 0</span></div>
  <input type="range" id="posSlider" min="0" max="40" value="0">
</div>

<span id="s5" class="s"></span>

**05 · The mechanism**

## Query, Key, and Value: the heart of attention

Here is the one idea that the whole paper is built on. To decide what to pay attention to, every word produces three little number-lists, with three jobs.

> **Relatable example · a library search**
> Imagine searching a library.
> **Query** is what you're looking for ("books about space").
> **Key** — each book has a label on its spine describing what it's about.
> **Value** — the actual content inside.
> You compare your *query* against every *key*, find the best matches, and then collect mostly the *values* of the books that matched well.

Attention does exactly this. For one word (the Query), the model compares it against the Key of every word. Strong matches get a high score; weak matches get a low score. Those scores become **percentages** (they add up to 100%), and the word's new representation is a **blend of all the Values, weighted by those percentages.**

The "comparison" is a **dot product** — a quick way to measure how aligned two number-lists are. Then a function called **softmax** squashes the scores into clean percentages.

> *Output = a weighted blend of Values, where the weights come from Query-meets-Key.*

<div class="stage">
  <div class="stage-label">Try it &middot; a real calculation</div>
  <h4>Pick a query word and watch attention compute</h4>
  <p>Choose which word is "asking." We compare its Query against every word's Key (a real dot product), scale and softmax the scores into percentages, then blend. The math below is actually being computed live.</p>
  <div class="controls" id="qkvBtns"></div>
  <table class="calc" id="qkvTable">
    <thead><tr><th>Word (Key)</th><th>Q·K score</th><th>&divide;&radic;d</th><th>Attention %</th></tr></thead>
    <tbody></tbody>
  </table>
  <p class="mono" id="qkvOut" style="color:var(--glow);margin-top:14px;"></p>
</div>

<span id="s6" class="s"></span>

**06 · A small but vital tweak**

## Why divide by the square root of the size

The paper's name for its method is **"Scaled Dot-Product Attention."** The word that matters there is *scaled*.

When the number-lists are long, the dot-product scores can get huge. And when scores are huge, softmax becomes **too confident** — it slams almost all the attention onto a single word and ignores everything else. That makes the model hard to train.

The fix is tiny: divide every score by the square root of the list length (&radic;d) before softmax. This keeps the scores in a sensible range so attention stays smooth and balanced.

> **Relatable example**
> It's like turning down an over-sensitive microphone. Too sensitive, and the loudest voice drowns out everyone in the room. Dial it back, and you can hear the whole conversation in proportion.

<div class="stage">
  <div class="stage-label">Try it &middot; drag the slider</div>
  <h4>Watch softmax go from balanced to all-or-nothing</h4>
  <p>Same scores, different scaling. Slide right (less scaling / bigger numbers) and watch attention collapse onto one bar. Slide left and it spreads out fairly.</p>
  <div class="lbl"><span>more scaled (smooth)</span><span id="tempLabel">balanced</span><span>less scaled (spiky)</span></div>
  <input type="range" id="tempSlider" min="1" max="100" value="35">
  <div id="softBars" style="margin-top:18px;"></div>
</div>

<span id="s7" class="s"></span>

**07 · Multi-head attention**

## Looking at the sentence from several angles at once

One round of attention captures one *type* of relationship. But language has many at the same time — grammar, meaning, who-did-what-to-whom.

So the Transformer runs attention **several times in parallel** (the paper uses 8), each with its own learned way of looking. These are called **heads**. One head might track which adjective describes which noun; another might track which pronoun points to which name. Their findings are then combined.

> **Relatable example**
> It's like having 8 expert proofreaders read the same sentence. One checks grammar, one checks tone, one checks facts, one checks pronouns. Each notices different things, and you merge all their notes into one richer understanding.

<div class="stage">
  <div class="stage-label">Try it &middot; click a word, then toggle the experts</div>
  <h4>Eight named heads, each doing a different job</h4>
  <p>First click any word in the sentence to choose who is "looking." Then switch heads on and off below. Each head is one expert with one specialty; the green glow shows where the selected experts look. Turn several on to see their <em>combined</em> view, or hit "All experts" to see everything at once.</p>
  <div class="sent" id="headSent" style="font-size:17px;"></div>
  <div class="controls" style="gap:6px;margin-top:6px;"><button class="btn small" id="headAll">All experts</button><button class="btn small ghost" id="headNone">Clear</button></div>
  <div class="controls headbtns" id="headBtns" style="gap:6px;"></div>
  <div class="legend" id="headDesc" style="margin-top:8px;"></div>
</div>

<span id="s8" class="s"></span>

**08 · The full machine**

## Putting it together: encoder and decoder

The Transformer has two halves. The **encoder** reads and understands the input. The **decoder** writes the output, one word at a time.

Think of translating English to French. The encoder fully digests the English sentence into rich number-lists. The decoder then produces French words, at each step glancing both at the English meaning (via attention) and at the French words it has already written.

<div class="stage">
  <div class="stage-label">Try it &middot; hover or tap any block</div>
  <h4>The architecture, one piece at a time</h4>
  <div class="arch">
    <div class="stackcol">
      <h5>Encoder (reads input) &times;6</h5>
      <div class="block" data-x="Each input word becomes a number-list (vector) the model can do math on."><b>Input embeddings</b>Words &rarr; numbers</div>
      <div class="block" data-x="The position fingerprint is added so the model knows word order, even though it reads in parallel."><b>+ Positional encoding</b>Adds word order</div>
      <div class="block" data-x="Every word looks at every other word in the input to build context. This is the core idea from section 05."><b>Self-attention</b>Words look at each other</div>
      <div class="block" data-x="A small standard neural network refines each word's representation on its own. Same recipe applied to every position."><b>Feed-forward network</b>Refine each word</div>
    </div>
    <div class="stackcol">
      <h5>Decoder (writes output) &times;6</h5>
      <div class="block" data-x="Masked attention: while writing word number 5, the decoder may only look at words 1-4. It cannot peek at the answer ahead of it."><b>Masked self-attention</b>No peeking ahead</div>
      <div class="block" data-x="Encoder-decoder attention: the output side looks back at the fully-understood input. This is how a translation stays faithful to the source."><b>Cross-attention</b>Looks at the input</div>
      <div class="block" data-x="Another feed-forward network refines the representation before predicting."><b>Feed-forward network</b>Refine again</div>
      <div class="block" data-x="A final step turns the numbers into probabilities over every possible next word, and the most likely one is chosen."><b>Output probabilities</b>Pick the next word</div>
    </div>
  </div>
  <div class="explainbox" id="archBox">Hover over (or tap) any block to see what it does.</div>
  <p style="font-size:13px;color:#9c8e7d;margin-top:14px;">Two quiet helpers wrap every block: a <b style="color:#cfc3b2">residual connection</b> (a shortcut that keeps the original input around so nothing important gets lost) and <b style="color:#cfc3b2">layer normalization</b> (keeps the numbers tidy and stable). The whole stack is repeated 6 times so understanding deepens layer by layer.</p>
</div>

### Why "no peeking" matters

When the decoder writes a sentence, it must predict the next word using only the words before it — exactly like you do when finishing someone's sentence. The paper enforces this with a **mask** that hides all future words during training, so the model can't cheat by looking at the answer.

<span id="s9" class="s"></span>

**09 · The results**

## Faster to train, and better than everything before it

The payoff was dramatic. On standard translation tests, the Transformer beat every previous model — while training in a fraction of the time, because it could finally do all that work in parallel.

Translation quality is scored with **BLEU** (higher is better). On English-to-German, the big Transformer set a new record of **28.4**, beating even ensembles — combinations of many models — by more than 2 points.

<div class="stage">
  <div class="stage-label">English &rarr; German translation quality (BLEU, higher is better)</div>
  <h4>The Transformer vs. the previous best</h4>
  <div class="chart" id="bleuChart"></div>
  <div class="legend">Source: Table 2 of the paper. The orange bar is the Transformer (big).</div>
</div>

And the cost? The big model trained in about **3.5 days** on 8 GPUs — a small fraction of what competing models needed. The base model reached state-of-the-art in roughly **12 hours**. Crucially, it also generalized: applied to a totally different task (English grammar parsing), it again performed near the top without special tuning.

<span id="s10" class="s"></span>

**10 · Why it changed everything**

## The paper that quietly started a revolution

In 2017 this looked like a smart improvement to machine translation. Today we know it was the foundation of nearly all modern AI.

Because the Transformer dropped the "one word at a time" rule, it could be trained on enormous amounts of text using thousands of processors at once. That scalability is exactly what made today's large language models possible.

The **"GPT"** in ChatGPT stands for *Generative Pre-trained **Transformer***. **BERT**, the model behind years of Google Search improvements, is a Transformer. So are the models that generate images, write code, transcribe speech, and fold proteins. They are all descendants of the simple idea in this paper: **let the pieces of your input pay attention to each other, and that is enough.**

> *Attention, it turned out, really was all you needed.*

<span id="s11" class="s"></span>

**11 · Build it yourself · zero to hero**

## From raw text to a question-answering model

This is the whole journey, running for real in your browser on text **you** provide. A genuine tiny Transformer: it tokenizes your text, learns embeddings, runs multi-head masked attention, pre-trains itself to predict the next word, and then gets **fine-tuned** into a model that answers questions. Nothing is pre-loaded — every weight is learned live, in front of you.

Go through the steps in order. Each one unlocks the next.

<div class="stage">
  <div class="stage-label">Step 1 &middot; your training text</div>
  <h4>Give the model something to read</h4>
  <p>This is the raw material the model learns language from (its "pre-training data"). Keep sentences simple and repetitive so a tiny model can find the patterns. Edit it freely, then build the dataset.</p>
  <textarea id="txtTrain" spellcheck="false"></textarea>
  <div class="controls"><button class="btn" id="buildBtn">Build dataset &rarr;</button><span class="mono" id="buildStatus" style="color:#9c8e7d;">waiting for your text</span></div>
</div>

<div class="stage" id="step2" style="opacity:.4;pointer-events:none;">
  <div class="stage-label">Step 2 &middot; tokenize &amp; vocabulary</div>
  <h4>Turn words into numbered tokens</h4>
  <p>The model can't read letters, so every unique word becomes a numbered <strong>token</strong>. The full list of tokens is the <strong>vocabulary</strong>. Three special tokens are added too: <span class="mono" style="color:var(--glow)">&lt;q&gt;</span> and <span class="mono" style="color:var(--glow)">&lt;a&gt;</span> (to mark questions and answers later) and <span class="mono" style="color:var(--glow)">&lt;end&gt;</span>.</p>
  <div class="mono" style="font-size:13px;color:#cfc3b2;">One sentence becomes a list of token ids:</div>
  <div id="tokDemo" class="mono" style="font-size:13px;background:#0e0b09;border-radius:9px;padding:12px;margin:8px 0;color:#e7ddcd;line-height:1.9;"></div>
  <div class="legend">Vocabulary (word : id)</div>
  <div id="vocabList" style="display:flex;flex-wrap:wrap;gap:5px;margin-top:6px;"></div>
</div>

<div class="stage" id="step3" style="opacity:.4;pointer-events:none;">
  <div class="stage-label">Step 3 &middot; embeddings</div>
  <h4>Give every token a vector of numbers</h4>
  <p>Each token id is mapped to a row of numbers (its <strong>embedding</strong>). Below is the entire embedding table: one row per word, one column per dimension, colour = value. Right now it is <strong>random noise</strong> — the model knows nothing yet. Watch this same picture after training to see meaning appear.</p>
  <canvas id="embCanvas" width="640" height="300" style="width:100%;background:#0e0b09;border-radius:10px;"></canvas>
  <div class="legend" id="embCap">Each row is one word. Random values for now.</div>
</div>

<div class="stage" id="step4" style="opacity:.4;pointer-events:none;">
  <div class="stage-label">Step 4 &middot; positional encoding</div>
  <h4>Stamp each slot with its position</h4>
  <p>Because the model reads all words at once, we add a unique wave-based "position fingerprint" to each word's vector so order is preserved. Type a sentence; each column below is the fingerprint added at that position.</p>
  <div class="controls"><input id="peSentence" class="mono" value="the cat is small" style="flex:1;min-width:160px;background:#0e0b09;border:1px solid var(--panel-line);color:#e7ddcd;padding:8px 11px;border-radius:8px;font-size:13px;"><button class="btn small" id="peBtn">Show</button></div>
  <canvas id="peCanvas" width="640" height="220" style="width:100%;background:#0e0b09;border-radius:10px;"></canvas>
</div>

<div class="stage" id="step5" style="opacity:.4;pointer-events:none;">
  <div class="stage-label">Step 5 &middot; attention (forward pass)</div>
  <h4>Watch the words look at each other</h4>
  <p>Here is one real forward pass: the model computes Query, Key and Value for every word, scores them, masks the future, and softmaxes into the attention grid below (row looks at column). This model has <strong>8 heads</strong> running in parallel. Pick any one to see it alone, or select several to see their <em>combined</em> view. Each head is named by what it actually does (the names become meaningful after you pre-train in Step 6).</p>
  <div class="controls"><input id="atnSentence" class="mono" value="the cat is small" style="flex:1;min-width:160px;background:#0e0b09;border:1px solid var(--panel-line);color:#e7ddcd;padding:8px 11px;border-radius:8px;font-size:13px;"><button class="btn small" id="atnBtn">Run</button></div>
  <div class="controls" style="gap:6px;"><button class="btn small" id="atnAll">All heads</button><button class="btn small ghost" id="atnNone">Clear</button></div>
  <div class="controls headbtns" id="atnHeadPick" style="gap:6px;"></div>
  <canvas id="atnCanvas" width="520" height="520" style="width:100%;max-width:440px;display:block;margin:6px auto;background:#0e0b09;border-radius:10px;"></canvas>
  <div class="legend" style="text-align:center;">Dark upper-right triangle = the causal mask (no peeking ahead).</div>
  <div class="legend" id="atnHeadDesc" style="margin-top:10px;"></div>

  <div style="border-top:1px solid var(--panel-line);margin-top:22px;padding-top:18px;">
    <h4 style="margin-top:0;">Design your own head</h4>
    <p>Instead of letting the model learn where to look, you can <strong>force</strong> a focusing rule and test it. Pick a preset or build your own with the sliders, preview the pattern, then score it: the model runs with every head forced to use your rule, and we compare its prediction error to the model's own learned attention. Lower loss = better head.</p>
    <div class="controls" style="gap:6px;" id="custPresets">
      <button class="btn small ghost" data-p="self">Self only</button>
      <button class="btn small ghost" data-p="prev">Previous word</button>
      <button class="btn small ghost" data-p="first">First word</button>
      <button class="btn small ghost" data-p="uniform">Spread evenly</button>
    </div>
    <div class="lbl"><span>looks back: <span id="kVal" style="color:var(--glow)">1</span> word(s)</span></div>
    <input type="range" id="kSlider" min="0" max="6" value="1">
    <div class="lbl"><span>sharp focus</span><span id="spreadVal" style="color:var(--glow)">medium</span><span>wide spread</span></div>
    <input type="range" id="spreadSlider" min="1" max="100" value="20">
    <div style="display:flex;gap:18px;flex-wrap:wrap;align-items:flex-start;margin-top:12px;">
      <div style="flex:1;min-width:200px;">
        <div class="legend">your head's pattern (on the sentence above)</div>
        <canvas id="custCanvas" width="420" height="420" style="width:100%;max-width:300px;display:block;background:#0e0b09;border-radius:10px;"></canvas>
      </div>
      <div style="flex:1;min-width:200px;">
        <div class="controls"><button class="btn small" id="evalBtn">Score this head</button></div>
        <div class="mono" id="evalStatus" style="font-size:13px;color:#9c8e7d;min-height:20px;margin-top:6px;"></div>
        <div class="legend" style="margin-top:10px;">Results (lower loss is better)</div>
        <div id="evalList" class="mono" style="font-size:12px;color:#cfc3b2;line-height:1.8;margin-top:4px;"></div>
      </div>
    </div>
  </div>
</div>

<div class="stage" id="step6" style="opacity:.4;pointer-events:none;">
  <div class="stage-label">Step 6 &middot; pre-training</div>
  <h4>Teach it to predict the next word</h4>
  <p>Now the model reads your text over and over, each time nudging its weights to better predict the next word. The <strong>loss</strong> (how wrong it is) should drop fast. On the right, watch it try to continue a sentence and get better.</p>
  <div class="controls"><button class="btn" id="preBtn">Pre-train the model</button><span class="mono" id="preStatus" style="color:#9c8e7d;">not trained yet</span></div>
  <div style="display:flex;gap:18px;flex-wrap:wrap;margin-top:6px;">
    <div style="flex:1;min-width:230px;"><div class="legend">Loss</div><canvas id="preLoss" width="360" height="160" style="width:100%;background:#0e0b09;border-radius:10px;"></canvas></div>
    <div style="flex:1;min-width:230px;"><div class="legend" id="watchSeedLbl">continuing a sentence as it learns</div><div id="preLog" class="mono" style="font-size:12px;background:#0e0b09;border-radius:10px;padding:12px;height:148px;overflow:auto;color:#cfc3b2;line-height:1.7;"></div></div>
  </div>
</div>

<div class="stage" id="step7" style="opacity:.4;pointer-events:none;">
  <div class="stage-label">Step 7 &middot; meet your base model</div>
  <h4>It can autocomplete &mdash; but it can't answer</h4>
  <p>Your pre-trained "base model" is a talented autocomplete. Give it a few words and it continues them. But ask it a direct question and it just rambles, because it was only ever taught to continue text, not to answer. That is exactly why the next step exists.</p>
  <div class="controls"><input id="baseSeed" class="mono" value="the sun" style="flex:1;min-width:150px;background:#0e0b09;border:1px solid var(--panel-line);color:#e7ddcd;padding:8px 11px;border-radius:8px;font-size:13px;"><button class="btn small" id="baseGenBtn">Autocomplete (step by step)</button></div>
  <div class="mono" id="baseOut" style="font-size:16px;color:var(--glow);min-height:24px;margin-top:6px;"></div>
  <div class="legend" id="baseGenNote" style="margin-top:6px;min-height:18px;"></div>
  <div class="legend" style="margin-top:10px;">Model's next-word vote at this step (top 5)</div>
  <div id="baseProbs" style="margin-top:4px;"></div>
  <div class="controls" style="margin-top:18px;"><input id="baseAsk" class="mono" value="what color is the sky" style="flex:1;min-width:150px;background:#0e0b09;border:1px solid var(--panel-line);color:#e7ddcd;padding:8px 11px;border-radius:8px;font-size:13px;"><button class="btn small ghost" id="baseAskBtn">Ask the base model</button></div>
  <div class="mono" id="baseAskOut" style="font-size:15px;color:#c98b6b;min-height:22px;"></div>
</div>

<div class="stage" id="step8" style="opacity:.4;pointer-events:none;">
  <div class="stage-label">Step 8 &middot; fine-tuning data</div>
  <h4>Show it examples of good answers</h4>
  <p>To turn the autocomplete into an assistant, we give it example <strong>question | answer</strong> pairs. The model is wrapped in a format it can recognise: <span class="mono" style="color:var(--glow)">&lt;q&gt; question &lt;a&gt; answer &lt;end&gt;</span>. One pair per line, with a vertical bar between question and answer.</p>
  <textarea id="txtQA" spellcheck="false"></textarea>
  <div class="controls"><button class="btn" id="prepBtn">Prepare fine-tune data &rarr;</button><span class="mono" id="prepStatus" style="color:#9c8e7d;"></span></div>
</div>

<div class="stage" id="step9" style="opacity:.4;pointer-events:none;">
  <div class="stage-label">Step 9 &middot; fine-tuning</div>
  <h4>Continue training &mdash; on the task this time</h4>
  <p>Fine-tuning does <strong>not</strong> start from scratch. It keeps all the language the base model already learned and gently nudges it (a smaller learning rate) to follow the question-answer format. The loss on the answers should plunge toward zero.</p>
  <div class="controls"><button class="btn" id="ftBtn">Fine-tune the model</button><span class="mono" id="ftStatus" style="color:#9c8e7d;">base model loaded</span></div>
  <div class="legend">Fine-tuning loss (answers only)</div>
  <canvas id="ftLoss" width="360" height="150" style="width:100%;max-width:420px;background:#0e0b09;border-radius:10px;"></canvas>
</div>

<div class="stage" id="step10" style="opacity:.4;pointer-events:none;">
  <div class="stage-label">Step 10 &middot; your assistant</div>
  <h4>Ask it a question</h4>
  <p>The same model that could only autocomplete now answers in the format it was fine-tuned on. Try the questions you trained it on, and then try slight variations to see how much (or how little) a tiny model can generalise.</p>
  <div class="controls" id="askChips"></div>
  <div class="controls"><input id="askInput" class="mono" value="what color is the sky" style="flex:1;min-width:180px;background:#0e0b09;border:1px solid var(--panel-line);color:#e7ddcd;padding:9px 12px;border-radius:8px;font-size:14px;"><button class="btn" id="askBtn">Ask</button></div>
  <div id="askOut" class="mono" style="margin-top:12px;font-size:17px;color:var(--glow);min-height:26px;"></div>
  <div class="legend" id="askNote" style="margin-top:6px;min-height:18px;"></div>
  <div class="legend" style="margin-top:10px;">Building the answer one word at a time (top 5 each step)</div>
  <div id="askProbs" style="margin-top:4px;"></div>
</div>

*This is a real but deliberately small model (32-dim embeddings, 2 heads, one Transformer block) trained on a handful of sentences, so it memorises more than it generalises. The exact same machinery — tokenize, embed, attend, pre-train, fine-tune — scaled to billions of weights and much of the internet, is what produces ChatGPT and its peers. You just did the whole pipeline, end to end.*

**In one breath**

## The whole paper, summarized

- **The problem:** Old models read text one word at a time — slow, and forgetful over long distances.
- **The idea:** Let every word directly "attend" to every other word, all at once, instead of in sequence.
- **The mechanism:** Each word makes a Query, Key, and Value. Match queries to keys, turn matches into percentages, blend the values.
- **The refinements:** Scale the scores for stability; use several attention "heads" for different relationships; add position fingerprints so word order survives.
- **The result:** Better translations, far faster training — and the blueprint for ChatGPT, BERT, and modern AI.

*A plain-language, interactive retelling of "Attention Is All You Need" (Vaswani et al., 2017). For the precise math, figures, and experiments, read the original at arxiv.org/abs/1706.03762.*

<script>
const markers=[...document.querySelectorAll('.post-content .s')];
const dotsNav=document.querySelector('.post-content #dots');
markers.forEach((s,i)=>{const a=document.createElement('a');a.href='#'+s.id;a.title='Section '+(i+1);dotsNav.appendChild(a);});
const dots=[...dotsNav.children];
const prog=document.querySelector('.post-content #progress');
function onScroll(){
  const h=document.documentElement;
  const sc=h.scrollTop/(h.scrollHeight-h.clientHeight);
  prog.style.width=(sc*100)+'%';
  let cur=0;
  markers.forEach((s,i)=>{if(s.getBoundingClientRect().top<window.innerHeight*0.45)cur=i;});
  dots.forEach((d,i)=>d.classList.toggle('active',i===cur));
}
window.addEventListener('scroll',onScroll);onScroll();

const words1=["The","cat","sat","on","the","warm","mat"];
const seqRow=document.querySelector('.post-content #seqRow');
const seqStatus=document.querySelector('.post-content #seqStatus');
words1.forEach(w=>{const c=document.createElement('div');c.className='cell';c.textContent=w;seqRow.appendChild(c);});
const cells=[...seqRow.children];let seqTimer=null;
function resetCells(){clearInterval(seqTimer);cells.forEach(c=>c.className='cell');}
document.querySelector('.post-content #seqBtn').onclick=()=>{
  resetCells();let i=0;seqStatus.textContent='Reading word 1... must wait for each before the next.';
  seqTimer=setInterval(()=>{
    if(i>0)cells[i-1].className='cell done';
    if(i<cells.length){cells[i].className='cell active';seqStatus.textContent='Reading word '+(i+1)+' of '+cells.length+' (one at a time).';i++;}
    else{clearInterval(seqTimer);seqStatus.textContent='Done — but it took '+cells.length+' separate steps in strict order.';}
  },520);
};
document.querySelector('.post-content #parBtn').onclick=()=>{
  resetCells();seqStatus.textContent='Reading ALL words in one step...';
  setTimeout(()=>{cells.forEach(c=>c.className='cell active');seqStatus.textContent='Done in a single step. Every word processed at the same time.';},120);
};

const attnWords=["The","animal","didn't","cross","the","street","because","it","was","too","tired"];
const attnMap={7:[0.05,0.95,0.05,0.08,0.04,0.30,0.06,1.0,0.10,0.05,0.55],1:[0.20,1.0,0.05,0.40,0.05,0.10,0.05,0.30,0.05,0.05,0.45],5:[0.30,0.10,0.05,0.55,0.40,1.0,0.05,0.10,0.05,0.05,0.10],10:[0.05,0.70,0.05,0.10,0.05,0.10,0.20,0.45,0.30,0.40,1.0],3:[0.10,0.55,0.20,1.0,0.10,0.65,0.05,0.05,0.05,0.05,0.10]};
const attnSent=document.querySelector('.post-content #attnSent');
const attnHint=document.querySelector('.post-content #attnHint');
attnWords.forEach((w,i)=>{const s=document.createElement('span');s.className='aw';s.textContent=w;s.dataset.i=i;attnSent.appendChild(s);});
const awEls=[...attnSent.children];
function showAttn(qi){
  let weights=attnMap[qi];
  awEls.forEach((el,i)=>{
    el.classList.toggle('query',i===qi);
    if(i===qi){el.style.background='';el.style.color='';return;}
    let w=weights?weights[i]:0;
    el.style.background='rgba(23,107,99,'+(w*0.9)+')';
    el.style.color=w>0.5?'#fff':'#e7ddcd';
  });
  if(qi===7)attnHint.textContent='"it" attends most to "animal" — the model has resolved the pronoun.';
  else attnHint.textContent='Showing what "'+attnWords[qi]+'" pays attention to. Try clicking "it".';
}
awEls.forEach(el=>el.onclick=()=>showAttn(+el.dataset.i));
showAttn(7);

const pc=document.querySelector('.post-content #posCanvas'),pctx=pc.getContext('2d');
const DMODEL=24;
function peVal(pos,i){const den=Math.pow(10000,(2*Math.floor(i/2))/DMODEL);return i%2===0?Math.sin(pos/den):Math.cos(pos/den);}
function drawPos(highlight){
  pctx.clearRect(0,0,pc.width,pc.height);const cols=41,cw=pc.width/cols,ch=pc.height/DMODEL;
  for(let p=0;p<cols;p++)for(let i=0;i<DMODEL;i++){const v=peVal(p,i),t=(v+1)/2;const r=Math.round(23+t*(207-23)),g=Math.round(107+t*(149-107)),b=Math.round(99+t*(42-99));pctx.fillStyle='rgb('+r+','+g+','+b+')';pctx.fillRect(p*cw,i*ch,cw+0.5,ch+0.5);}
  if(highlight!=null){pctx.strokeStyle='#fff';pctx.lineWidth=2;pctx.strokeRect(highlight*cw,0,cw,pc.height);}
}
const posSlider=document.querySelector('.post-content #posSlider'),posLabel=document.querySelector('.post-content #posLabel');
posSlider.oninput=()=>{posLabel.textContent='position '+posSlider.value;drawPos(+posSlider.value);};
drawPos(0);

const vocab={"cat":[0.9,0.1,0.8,0.0],"sat":[0.2,0.9,0.1,0.3],"on":[0.1,0.2,0.1,0.9],"mat":[0.8,0.2,0.7,0.1],"animal":[0.85,0.15,0.75,0.05]};
const vwords=Object.keys(vocab);
const qkvBtns=document.querySelector('.post-content #qkvBtns');
const qkvBody=document.querySelector('.post-content #qkvTable tbody');
const qkvOut=document.querySelector('.post-content #qkvOut');
function dot(a,b){return a.reduce((s,x,i)=>s+x*b[i],0);}
function computeQKV(qword){
  const q=vocab[qword];const d=q.length;const sqrt=Math.sqrt(d);
  const raw=vwords.map(w=>dot(q,vocab[w]));
  const scaled=raw.map(r=>r/sqrt);
  const mx=Math.max(...scaled);const exp=scaled.map(s=>Math.exp(s-mx));const sum=exp.reduce((a,b)=>a+b,0);
  const soft=exp.map(e=>e/sum);
  qkvBody.innerHTML='';
  vwords.forEach((w,i)=>{const tr=document.createElement('tr');tr.innerHTML='<td style="color:'+(w===qword?'#f0b35a':'#e7ddcd')+'">'+w+(w===qword?' (query)':'')+'</td><td>'+raw[i].toFixed(2)+'</td><td>'+scaled[i].toFixed(2)+'</td><td><div class="barwrap"><div class="bar" style="width:'+(soft[i]*100).toFixed(0)+'%"></div></div> '+(soft[i]*100).toFixed(0)+'%</td>';qkvBody.appendChild(tr);});
  const best=vwords[soft.indexOf(Math.max(...soft))];
  qkvOut.textContent='"'+qword+'" pays the most attention to "'+best+'".';
}
vwords.forEach((w,idx)=>{const b=document.createElement('button');b.className='btn'+(idx===0?'':' ghost');b.textContent=w;
  b.onclick=()=>{[...qkvBtns.children].forEach(c=>c.className='btn ghost');b.className='btn';computeQKV(w);};qkvBtns.appendChild(b);});
computeQKV('cat');

const rawScores=[3.0,2.2,1.6,0.8,0.3];
const sLabels=["word A","word B","word C","word D","word E"];
const softBars=document.querySelector('.post-content #softBars');
const tempSlider=document.querySelector('.post-content #tempSlider'),tempLabel=document.querySelector('.post-content #tempLabel');
sLabels.forEach((l,i)=>{const row=document.createElement('div');row.style.cssText='display:flex;align-items:center;gap:10px;margin:7px 0;';row.innerHTML='<span style="font-family:JetBrains Mono;font-size:12px;width:54px;color:#cfc3b2">'+l+'</span><div class="barwrap" style="flex:1;width:auto"><div class="bar" id="sb'+i+'" style="width:0%"></div></div><span id="sp'+i+'" style="font-family:JetBrains Mono;font-size:12px;width:42px;color:#9c8e7d"></span>';softBars.appendChild(row);});
function drawSoft(){const k=+tempSlider.value/35;const sc=rawScores.map(s=>s*k);const mx=Math.max(...sc);const exp=sc.map(s=>Math.exp(s-mx));const sum=exp.reduce((a,b)=>a+b,0);const soft=exp.map(e=>e/sum);soft.forEach((v,i)=>{document.querySelector('.post-content #sb'+i).style.width=(v*100).toFixed(0)+'%';document.querySelector('.post-content #sp'+i).textContent=(v*100).toFixed(0)+'%';});const top=Math.max(...soft);tempLabel.textContent=top>0.8?'all-or-nothing':top>0.55?'fairly spiky':top>0.4?'balanced':'very smooth';}
tempSlider.oninput=drawSoft;drawSoft();

const hWords=["the","tired","old","dog","chased","its","tail"];
const NOUNS=new Set(["dog","tail","cat","sun","mat"]);const ADJ=new Set(["tired","old","big","small","happy"]);const ART=new Set(["the","a"]);const VERB=new Set(["chased","sat","ran","likes"]);const PRON=new Set(["its","it","his","her"]);
function nearestBefore(f,set){for(let i=f-1;i>=0;i--)if(set.has(hWords[i]))return i;return -1;}
function nearestAfter(f,set){for(let i=f+1;i<hWords.length;i++)if(set.has(hWords[i]))return i;return -1;}
const expertHeads=[
  {name:"Neighbour",info:"looks at the word immediately before — captures local phrasing.",rule:f=>{const w=Array(hWords.length).fill(0);if(f>0)w[f-1]=1;else w[f]=1;return w;}},
  {name:"Self",info:"keeps a word focused on itself, preserving its own meaning.",rule:f=>{const w=Array(hWords.length).fill(0);w[f]=1;return w;}},
  {name:"Describer",info:"links a noun to the adjectives and article describing it.",rule:f=>{const w=Array(hWords.length).fill(0);if(NOUNS.has(hWords[f])){for(let i=f-1;i>=0;i--){if(ADJ.has(hWords[i])||ART.has(hWords[i]))w[i]=1;else break;}}if(!w.some(Boolean))w[f]=0.5;return w;}},
  {name:"Subject-finder",info:"from an action, finds who is doing it.",rule:f=>{const w=Array(hWords.length).fill(0);if(VERB.has(hWords[f])){const s=nearestBefore(f,NOUNS);if(s>=0)w[s]=1;}else w[f]=0.4;return w;}},
  {name:"Object-finder",info:"from an action, finds what it acts on.",rule:f=>{const w=Array(hWords.length).fill(0);if(VERB.has(hWords[f])){const o=nearestAfter(f,NOUNS);if(o>=0)w[o]=1;}else w[f]=0.4;return w;}},
  {name:"Pronoun-resolver",info:"works out what a pronoun refers to.",rule:f=>{const w=Array(hWords.length).fill(0);if(PRON.has(hWords[f])){const a=nearestBefore(f,NOUNS);if(a>=0)w[a]=1;}else w[f]=0.4;return w;}},
  {name:"Article-binder",info:"ties a/the to the noun it introduces.",rule:f=>{const w=Array(hWords.length).fill(0);if(ART.has(hWords[f])){const n=nearestAfter(f,NOUNS);if(n>=0)w[n]=1;}else w[f]=0.4;return w;}},
  {name:"Wide-angle",info:"spreads attention over the whole sentence for general context.",rule:f=>{const w=Array(hWords.length).fill(0);for(let i=0;i<=f;i++)w[i]=0.5;return w;}}
];
const headBtns=document.querySelector('.post-content #headBtns');
const headSent=document.querySelector('.post-content #headSent');
const headDesc=document.querySelector('.post-content #headDesc');
let focusWord=3;let activeExperts=new Set([2]);
hWords.forEach((w,i)=>{const s=document.createElement('span');s.className='aw';s.textContent=w;s.style.cursor='pointer';s.onclick=()=>{focusWord=i;renderExperts();};headSent.appendChild(s);});
const hEls=[...headSent.children];
expertHeads.forEach((h,idx)=>{const b=document.createElement('button');b.dataset.i=idx;b.className='btn small'+(activeExperts.has(idx)?'':' ghost');b.textContent=h.name;b.onclick=()=>{const i=+b.dataset.i;if(activeExperts.has(i)){if(activeExperts.size>1)activeExperts.delete(i);}else activeExperts.add(i);renderExperts();};headBtns.appendChild(b);});
document.querySelector('.post-content #headAll').onclick=()=>{activeExperts=new Set(expertHeads.map((_,i)=>i));renderExperts();};
document.querySelector('.post-content #headNone').onclick=()=>{activeExperts=new Set([0]);renderExperts();};
function renderExperts(){
  [...headBtns.children].forEach(b=>b.className='btn small'+(activeExperts.has(+b.dataset.i)?'':' ghost'));
  const sel=[...activeExperts];const comb=Array(hWords.length).fill(0);
  sel.forEach(idx=>{const w=expertHeads[idx].rule(focusWord);for(let i=0;i<w.length;i++)comb[i]+=w[i]/sel.length;});
  const mx=Math.max(...comb,0.001);
  hEls.forEach((el,i)=>{el.classList.toggle('query',i===focusWord);if(i===focusWord){el.style.background='';el.style.color='';return;}const v=comb[i]/mx;el.style.background='rgba(23,107,99,'+(v*0.92)+')';el.style.color=v>0.5?'#fff':'#e7ddcd';});
  const list=sel.map(i=>'<span style="color:#e7ddcd">'+expertHeads[i].name+'</span> ('+expertHeads[i].info+')').join('<br>');
  headDesc.innerHTML='Focus word: <span style="color:var(--terra)">"'+hWords[focusWord]+'"</span> &middot; '+sel.length+(sel.length>1?' experts combined:':' expert:')+'<br>'+list;
}
renderExperts();

const archBox=document.querySelector('.post-content #archBox');
document.querySelectorAll('.post-content .block').forEach(b=>{const show=()=>archBox.textContent=b.dataset.x;b.addEventListener('mouseenter',show);b.addEventListener('click',show);});

const bleu=[{name:"GNMT + RL",v:24.6,us:false},{name:"ConvS2S",v:25.16,us:false},{name:"GNMT ensemble",v:26.30,us:false},{name:"ConvS2S ensemble",v:26.36,us:false},{name:"Transformer (big)",v:28.4,us:true}];
const chart=document.querySelector('.post-content #bleuChart');const maxB=30;
bleu.forEach(d=>{const wrap=document.createElement('div');wrap.className='chbar'+(d.us?' us':'');wrap.innerHTML='<div class="val">'+d.v.toFixed(1)+'</div><div class="col" data-h="'+((d.v/maxB)*100)+'"></div><div class="name">'+d.name+'</div>';chart.appendChild(wrap);});
const chartIO=new IntersectionObserver((es)=>es.forEach(e=>{if(e.isIntersecting){chart.querySelectorAll('.col').forEach(c=>c.style.height=c.dataset.h+'%');chartIO.disconnect();}}),{threshold:.4});chartIO.observe(chart);

(function(){
const D=32,H=8,DH=D/H,DFF=64,EPS=1e-5;
function zeros(r,c){const m=new Array(r);for(let i=0;i<r;i++)m[i]=new Float64Array(c);return m;}
function randn(){let u=0,v=0;while(u===0)u=Math.random();while(v===0)v=Math.random();return Math.sqrt(-2*Math.log(u))*Math.cos(2*Math.PI*v);}
function randMat(r,c,s){const m=zeros(r,c);for(let i=0;i<r;i++)for(let j=0;j<c;j++)m[i][j]=randn()*s;return m;}
function matmul(A,B){const r=A.length,k=A[0].length,c=B[0].length,O=zeros(r,c);for(let i=0;i<r;i++){const Ai=A[i],Oi=O[i];for(let t=0;t<k;t++){const a=Ai[t];if(a===0)continue;const Bt=B[t];for(let j=0;j<c;j++)Oi[j]+=a*Bt[j];}}return O;}
function transpose(A){const r=A.length,c=A[0].length,O=zeros(c,r);for(let i=0;i<r;i++)for(let j=0;j<c;j++)O[j][i]=A[i][j];return O;}
function addInto(A,B){for(let i=0;i<A.length;i++)for(let j=0;j<A[0].length;j++)A[i][j]+=B[i][j];return A;}
function add(A,B){const O=zeros(A.length,A[0].length);for(let i=0;i<A.length;i++)for(let j=0;j<A[0].length;j++)O[i][j]=A[i][j]+B[i][j];return O;}
function clone(A){const O=zeros(A.length,A[0].length);for(let i=0;i<A.length;i++)for(let j=0;j<A[0].length;j++)O[i][j]=A[i][j];return O;}
function softmaxRow(arr,len){let mx=-Infinity;for(let j=0;j<len;j++)if(arr[j]>mx)mx=arr[j];let s=0;const o=new Float64Array(len);for(let j=0;j<len;j++){o[j]=Math.exp(arr[j]-mx);s+=o[j];}for(let j=0;j<len;j++)o[j]/=s;return o;}
let V=0,vocab=[],stoi={},Q_TOK,A_TOK,END_TOK,P=null,opt=null;let pretrainData=[],qaData=[];let built=false,pretrained=false,prepped=false,finetuned=false,busy=false;
function buildVocab(text,qa){const words=new Set();text.split("\n").forEach(l=>l.trim().split(/\s+/).forEach(w=>{if(w)words.add(w);}));if(qa)qa.split("\n").forEach(l=>{l.split("|").forEach(part=>part.trim().split(/\s+/).forEach(w=>{if(w)words.add(w);}));});vocab=["<end>","<q>","<a>",...Array.from(words).sort()];V=vocab.length;stoi={};vocab.forEach((w,i)=>stoi[w]=i);END_TOK=stoi["<end>"];Q_TOK=stoi["<q>"];A_TOK=stoi["<a>"];}
function buildPretrain(text){return text.split("\n").map(l=>l.trim()).filter(Boolean).map(l=>{const ids=l.split(/\s+/).map(w=>stoi[w]);ids.push(END_TOK);const mask=ids.map((_,t)=>t<ids.length-1?1:0);return {ids,mask};});}
function buildQA(qa){return qa.split("\n").map(l=>l.trim()).filter(Boolean).map(l=>{const parts=l.split("|");if(parts.length<2)return null;const q=parts[0].trim(),a=parts[1].trim();const ids=[Q_TOK,...q.split(/\s+/).map(w=>stoi[w]),A_TOK,...a.split(/\s+/).map(w=>stoi[w]),END_TOK];if(ids.some(x=>x===undefined))return null;const aPos=ids.indexOf(A_TOK);const mask=ids.map((_,t)=>(t>=aPos&&t<ids.length-1)?1:0);return {ids,mask,q,a};}).filter(Boolean);}
function posEncoding(T){const pe=zeros(T,D);for(let p=0;p<T;p++)for(let i=0;i<D;i++){const den=Math.pow(10000,(2*Math.floor(i/2))/D);pe[p][i]=(i%2===0)?Math.sin(p/den):Math.cos(p/den);}return pe;}
function initParams(){const p={};p.E=randMat(V,D,0.1);p.Wq=[];p.Wk=[];p.Wv=[];for(let h=0;h<H;h++){p.Wq.push(randMat(D,DH,0.18));p.Wk.push(randMat(D,DH,0.18));p.Wv.push(randMat(D,DH,0.18));}p.Wo=randMat(D,D,0.18);p.W1=randMat(D,DFF,0.18);p.b1=zeros(1,DFF);p.W2=randMat(DFF,D,0.18);p.b2=zeros(1,D);p.g1=zeros(1,D);p.bn1=zeros(1,D);for(let j=0;j<D;j++)p.g1[0][j]=1;p.g2=zeros(1,D);p.bn2=zeros(1,D);for(let j=0;j<D;j++)p.g2[0][j]=1;p.Wlm=randMat(D,V,0.08);p.blm=zeros(1,V);return p;}
function layernorm(X,g,b){const T=X.length,out=zeros(T,D),cache=[];for(let t=0;t<T;t++){let mu=0;for(let j=0;j<D;j++)mu+=X[t][j];mu/=D;let vv=0;for(let j=0;j<D;j++){const d=X[t][j]-mu;vv+=d*d;}vv/=D;const inv=1/Math.sqrt(vv+EPS);const xh=new Float64Array(D);for(let j=0;j<D;j++){xh[j]=(X[t][j]-mu)*inv;out[t][j]=g[0][j]*xh[j]+b[0][j];}cache.push({xhat:xh,inv});}return {out,cache};}
function layernormBack(dOut,g,cache,dg,db){const T=dOut.length,dX=zeros(T,D);for(let t=0;t<T;t++){const {xhat,inv}=cache[t];const dxh=new Float64Array(D);let sdx=0,sdxx=0;for(let j=0;j<D;j++){dg[0][j]+=dOut[t][j]*xhat[j];db[0][j]+=dOut[t][j];dxh[j]=dOut[t][j]*g[0][j];sdx+=dxh[j];sdxx+=dxh[j]*xhat[j];}for(let j=0;j<D;j++)dX[t][j]=inv*(dxh[j]-sdx/D-xhat[j]*sdxx/D);}return dX;}
function forward(ids){const T=ids.length,PE=posEncoding(T);const h0=zeros(T,D);for(let t=0;t<T;t++)for(let j=0;j<D;j++)h0[t][j]=P.E[ids[t]][j]+PE[t][j];const heads=[],concat=zeros(T,D),scale=Math.sqrt(DH);for(let h=0;h<H;h++){const Q=matmul(h0,P.Wq[h]),K=matmul(h0,P.Wk[h]),Vv=matmul(h0,P.Wv[h]);const A=zeros(T,T);for(let i=0;i<T;i++){const row=new Float64Array(i+1);for(let j=0;j<=i;j++){let dot=0;for(let d=0;d<DH;d++)dot+=Q[i][d]*K[j][d];row[j]=dot/scale;}const sm=softmaxRow(row,i+1);for(let j=0;j<=i;j++)A[i][j]=sm[j];}const O=matmul(A,Vv);for(let t=0;t<T;t++)for(let d=0;d<DH;d++)concat[t][h*DH+d]=O[t][d];heads.push({Q,K,V:Vv,A});}const attn=matmul(concat,P.Wo);const u1=add(h0,attn);const ln1=layernorm(u1,P.g1,P.bn1);const h1=ln1.out;const z=matmul(h1,P.W1);for(let t=0;t<T;t++)for(let j=0;j<DFF;j++)z[t][j]+=P.b1[0][j];const a=zeros(T,DFF);for(let t=0;t<T;t++)for(let j=0;j<DFF;j++)a[t][j]=Math.max(0,z[t][j]);const ff=matmul(a,P.W2);for(let t=0;t<T;t++)for(let j=0;j<D;j++)ff[t][j]+=P.b2[0][j];const u2=add(h1,ff);const ln2=layernorm(u2,P.g2,P.bn2);const h2=ln2.out;const logits=matmul(h2,P.Wlm);for(let t=0;t<T;t++)for(let j=0;j<V;j++)logits[t][j]+=P.blm[0][j];return {T,h0,heads,concat,ln1,h1,z,a,ln2,h2,logits};}
function zeroGrads(){const g={};g.E=zeros(V,D);g.Wq=[];g.Wk=[];g.Wv=[];for(let h=0;h<H;h++){g.Wq.push(zeros(D,DH));g.Wk.push(zeros(D,DH));g.Wv.push(zeros(D,DH));}g.Wo=zeros(D,D);g.W1=zeros(D,DFF);g.b1=zeros(1,DFF);g.W2=zeros(DFF,D);g.b2=zeros(1,D);g.g1=zeros(1,D);g.bn1=zeros(1,D);g.g2=zeros(1,D);g.bn2=zeros(1,D);g.Wlm=zeros(D,V);g.blm=zeros(1,V);return g;}
function lossAndGrad(ex,grads){const ids=ex.ids,mask=ex.mask;const f=forward(ids),T=f.T;let N=0;for(let t=0;t<T-1;t++)if(mask[t])N++;if(N===0)N=1;let loss=0;const dlog=zeros(T,V);for(let t=0;t<T-1;t++){if(!mask[t])continue;const p=softmaxRow(f.logits[t],V);const tgt=ids[t+1];loss+=-Math.log(Math.max(p[tgt],1e-12));for(let j=0;j<V;j++)dlog[t][j]=(p[j]-(j===tgt?1:0))/N;}loss/=N;if(!grads)return loss;addInto(grads.Wlm,matmul(transpose(f.h2),dlog));for(let t=0;t<T;t++)for(let j=0;j<V;j++)grads.blm[0][j]+=dlog[t][j];let dh2=matmul(dlog,transpose(P.Wlm));const du2=layernormBack(dh2,P.g2,f.ln2.cache,grads.g2,grads.bn2);let dh1=clone(du2);const dff=du2;for(let t=0;t<T;t++)for(let j=0;j<D;j++)grads.b2[0][j]+=dff[t][j];addInto(grads.W2,matmul(transpose(f.a),dff));let da=matmul(dff,transpose(P.W2));const dz=zeros(T,DFF);for(let t=0;t<T;t++)for(let j=0;j<DFF;j++)dz[t][j]=f.z[t][j]>0?da[t][j]:0;for(let t=0;t<T;t++)for(let j=0;j<DFF;j++)grads.b1[0][j]+=dz[t][j];addInto(grads.W1,matmul(transpose(f.h1),dz));addInto(dh1,matmul(dz,transpose(P.W1)));const du1=layernormBack(dh1,P.g1,f.ln1.cache,grads.g1,grads.bn1);let dh0=clone(du1);const dattn=du1;addInto(grads.Wo,matmul(transpose(f.concat),dattn));const dconcat=matmul(dattn,transpose(P.Wo));const scale=Math.sqrt(DH);for(let h=0;h<H;h++){const hd=f.heads[h];const dO=zeros(T,DH);for(let t=0;t<T;t++)for(let d=0;d<DH;d++)dO[t][d]=dconcat[t][h*DH+d];const dA=matmul(dO,transpose(hd.V));const dV=matmul(transpose(hd.A),dO);const dS=zeros(T,T);for(let i=0;i<T;i++){let dot=0;for(let j=0;j<=i;j++)dot+=dA[i][j]*hd.A[i][j];for(let j=0;j<=i;j++)dS[i][j]=hd.A[i][j]*(dA[i][j]-dot)/scale;}const dQ=matmul(dS,hd.K),dK=matmul(transpose(dS),hd.Q);addInto(grads.Wq[h],matmul(transpose(f.h0),dQ));addInto(grads.Wk[h],matmul(transpose(f.h0),dK));addInto(grads.Wv[h],matmul(transpose(f.h0),dV));addInto(dh0,matmul(dQ,transpose(P.Wq[h])));addInto(dh0,matmul(dK,transpose(P.Wk[h])));addInto(dh0,matmul(dV,transpose(P.Wv[h])));}for(let t=0;t<T;t++)for(let j=0;j<D;j++)grads.E[ids[t]][j]+=dh0[t][j];return loss;}
function makeAdam(){const m={},v={};m.E=zeros(V,D);v.E=zeros(V,D);m.Wo=zeros(D,D);v.Wo=zeros(D,D);m.W1=zeros(D,DFF);v.W1=zeros(D,DFF);m.b1=zeros(1,DFF);v.b1=zeros(1,DFF);m.W2=zeros(DFF,D);v.W2=zeros(DFF,D);m.b2=zeros(1,D);v.b2=zeros(1,D);m.g1=zeros(1,D);v.g1=zeros(1,D);m.bn1=zeros(1,D);v.bn1=zeros(1,D);m.g2=zeros(1,D);v.g2=zeros(1,D);m.bn2=zeros(1,D);v.bn2=zeros(1,D);m.Wlm=zeros(D,V);v.Wlm=zeros(D,V);m.blm=zeros(1,V);v.blm=zeros(1,V);m.Wq=[];v.Wq=[];m.Wk=[];v.Wk=[];m.Wv=[];v.Wv=[];for(let h=0;h<H;h++){m.Wq.push(zeros(D,DH));v.Wq.push(zeros(D,DH));m.Wk.push(zeros(D,DH));v.Wk.push(zeros(D,DH));m.Wv.push(zeros(D,DH));v.Wv.push(zeros(D,DH));}return {m,v,t:0};}
function adamStep(G,lr){opt.t++;const b1=0.9,b2=0.999,e=1e-8,t=opt.t;function upd(p,g,m,v){for(let i=0;i<p.length;i++)for(let j=0;j<p[0].length;j++){m[i][j]=b1*m[i][j]+(1-b1)*g[i][j];v[i][j]=b2*v[i][j]+(1-b2)*g[i][j]*g[i][j];const mh=m[i][j]/(1-Math.pow(b1,t)),vh=v[i][j]/(1-Math.pow(b2,t));p[i][j]-=lr*mh/(Math.sqrt(vh)+e);}}upd(P.E,G.E,opt.m.E,opt.v.E);upd(P.Wo,G.Wo,opt.m.Wo,opt.v.Wo);upd(P.W1,G.W1,opt.m.W1,opt.v.W1);upd(P.b1,G.b1,opt.m.b1,opt.v.b1);upd(P.W2,G.W2,opt.m.W2,opt.v.W2);upd(P.b2,G.b2,opt.m.b2,opt.v.b2);upd(P.g1,G.g1,opt.m.g1,opt.v.g1);upd(P.bn1,G.bn1,opt.m.bn1,opt.v.bn1);upd(P.g2,G.g2,opt.m.g2,opt.v.g2);upd(P.bn2,G.bn2,opt.m.bn2,opt.v.bn2);upd(P.Wlm,G.Wlm,opt.m.Wlm,opt.v.Wlm);upd(P.blm,G.blm,opt.m.blm,opt.v.blm);for(let h=0;h<H;h++){upd(P.Wq[h],G.Wq[h],opt.m.Wq[h],opt.v.Wq[h]);upd(P.Wk[h],G.Wk[h],opt.m.Wk[h],opt.v.Wk[h]);upd(P.Wv[h],G.Wv[h],opt.m.Wv[h],opt.v.Wv[h]);}}
function generate(ids,maxLen,temp,greedy){const out=ids.slice();for(let s=0;s<maxLen;s++){const f=forward(out);const last=f.logits[out.length-1];const sc=new Float64Array(V);for(let j=0;j<V;j++)sc[j]=last[j]/temp;const p=softmaxRow(sc,V);let pick;if(greedy){pick=0;for(let j=0;j<V;j++)if(p[j]>p[pick])pick=j;}else{let r=Math.random(),acc=0;pick=V-1;for(let j=0;j<V;j++){acc+=p[j];if(r<=acc){pick=j;break;}}}if(pick===END_TOK)break;out.push(pick);}return out;}
function strip(ids){return ids.map(i=>vocab[i]).filter(w=>!w.startsWith("<")).join(" ");}
function ask(q){const seed=[Q_TOK,...q.trim().split(/\s+/).map(w=>stoi[w]).filter(x=>x!==undefined),A_TOK];const out=generate(seed,14,0.25,true);const aPos=out.lastIndexOf(A_TOK);const ans=out.slice(aPos+1).map(i=>vocab[i]).filter(w=>!w.startsWith("<")).join(" ");return ans||"(no answer)";}
function drawLoss(canvas,hist){const ctx=canvas.getContext('2d'),w=canvas.width,h=canvas.height;ctx.clearRect(0,0,w,h);if(hist.length<2)return;const mx=Math.max(...hist),mn=Math.min(...hist,0),pad=16;ctx.strokeStyle='#3a2f28';ctx.beginPath();ctx.moveTo(pad,h-pad);ctx.lineTo(w-4,h-pad);ctx.stroke();ctx.strokeStyle='#cf952a';ctx.lineWidth=2;ctx.beginPath();hist.forEach((L,i)=>{const x=pad+(i/(hist.length-1))*(w-pad-4),y=h-pad-((L-mn)/((mx-mn)||1))*(h-pad*2);i?ctx.lineTo(x,y):ctx.moveTo(x,y);});ctx.stroke();ctx.fillStyle='#9c8e7d';ctx.font='11px monospace';ctx.fillText(mx.toFixed(2),pad+2,pad);ctx.fillText(mn.toFixed(2),pad+2,h-pad-2);}
function col(v){const t=Math.max(0,Math.min(1,(v+1)/2));const r=Math.round(20+t*(220)),g=Math.round(30+t*(149)),b=Math.round(40+t*(20));return 'rgb('+r+','+g+','+b+')';}
function drawEmb(){const c=document.querySelector('.post-content #embCanvas'),ctx=c.getContext('2d');const rows=V,cols=D;const lw=70;const cw=(c.width-lw)/cols,ch=c.height/rows;ctx.clearRect(0,0,c.width,c.height);let mx=1e-6;for(let i=0;i<rows;i++)for(let j=0;j<cols;j++)mx=Math.max(mx,Math.abs(P.E[i][j]));for(let i=0;i<rows;i++){for(let j=0;j<cols;j++){ctx.fillStyle=col(P.E[i][j]/mx);ctx.fillRect(lw+j*cw,i*ch,cw+0.5,ch+0.5);}ctx.fillStyle='#cfc3b2';ctx.font=Math.min(11,ch-1)+'px monospace';ctx.textAlign='right';ctx.fillText((vocab[i]||'').slice(0,9),lw-5,i*ch+ch/2+3);}}
function drawPE(T){const c=document.querySelector('.post-content #peCanvas'),ctx=c.getContext('2d');const pe=posEncoding(T);const cw=c.width/T,ch=c.height/D;ctx.clearRect(0,0,c.width,c.height);for(let p=0;p<T;p++)for(let i=0;i<D;i++){ctx.fillStyle=col(pe[p][i]);ctx.fillRect(p*cw,i*ch,cw+0.5,ch+0.5);}ctx.strokeStyle='#3a2f28';for(let p=1;p<T;p++){ctx.beginPath();ctx.moveTo(p*cw,0);ctx.lineTo(p*cw,c.height);ctx.stroke();}}
function drawAttn(canvas,A,ids,head){const ctx=canvas.getContext('2d'),T=ids.length,size=canvas.width,pad=72,grid=size-pad-8,cell=grid/T;ctx.clearRect(0,0,size,size);for(let i=0;i<T;i++)for(let j=0;j<T;j++){const v=A[i][j],t=Math.min(1,v);const r=Math.round(14+t*226),g=Math.round(11+t*168),b=Math.round(9+t*81);ctx.fillStyle='rgb('+r+','+g+','+b+')';ctx.fillRect(pad+j*cell,pad+i*cell,cell-1.5,cell-1.5);}ctx.fillStyle='#cfc3b2';ctx.font='10px monospace';ctx.textAlign='right';for(let i=0;i<T;i++)ctx.fillText((vocab[ids[i]]||'').slice(0,8),pad-5,pad+i*cell+cell/2+3);ctx.textAlign='left';for(let j=0;j<T;j++){ctx.save();ctx.translate(pad+j*cell+cell/2+3,pad-5);ctx.rotate(-Math.PI/4);ctx.fillText((vocab[ids[j]]||'').slice(0,8),0,0);ctx.restore();}}
const DEF_TEXT=`the sun is hot\nthe fire is hot\nthe ice is cold\nthe snow is cold\nthe cat likes milk\nthe dog likes bones\nthe sky is blue\nthe grass is green\na cat is small\na dog is big\nthe cat is small\nthe dog is big`;
const DEF_QA=`what is hot | the sun is hot\nwhat is cold | the ice is cold\nwhat does the cat like | the cat likes milk\nwhat does the dog like | the dog likes bones\nwhat color is the sky | the sky is blue\nwhat color is the grass | the grass is green\nis the cat big or small | the cat is small\nis the dog big or small | the dog is big`;
document.querySelector('.post-content #txtTrain').value=DEF_TEXT;
document.querySelector('.post-content #txtQA').value=DEF_QA;
const $=id=>document.querySelector('.post-content #'+id);
function enable(id,on){const e=$(id);e.style.opacity=on?'1':'.4';e.style.pointerEvents=on?'auto':'none';}
$('buildBtn').onclick=()=>{const text=$('txtTrain').value.trim();if(!text){$('buildStatus').textContent='please enter some text';return;}buildVocab(text,$('txtQA').value);P=initParams();opt=makeAdam();pretrainData=buildPretrain(text);built=true;pretrained=false;prepped=false;finetuned=false;$('buildStatus').textContent=vocab.length+' tokens, '+pretrainData.length+' sentences';const first=text.split("\n").map(s=>s.trim()).filter(Boolean)[0]||"the cat";const toks=first.split(/\s+/);$('tokDemo').innerHTML=toks.map(w=>'<span style="color:#e7ddcd">'+w+'</span>').join(' ')+'<br><span style="color:#9c8e7d">ids:</span> ['+toks.map(w=>'<span style="color:var(--glow)">'+(stoi[w]!==undefined?stoi[w]:'?')+'</span>').join(', ')+']';const vl=$('vocabList');vl.innerHTML='';vocab.forEach((w,i)=>{const s=document.createElement('span');s.className='token';s.style.fontSize='12px';s.style.padding='3px 8px';s.innerHTML=w+'<span style="color:var(--glow)">:'+i+'</span>';vl.appendChild(s);});drawEmb();$('embCap').textContent='Each row is one word ('+V+' words &times; '+D+' dimensions). Random values for now &mdash; re-check after Step 6.';drawPE(($('peSentence').value.trim().split(/\s+/).length)||4);buildHeadPicks();runAttn();syncCust();[2,3,4,5,6].forEach(n=>enable('step'+n,true));[7,8,9,10].forEach(n=>enable('step'+n,false));$('preStatus').textContent='not trained yet';$('preLog').innerHTML='';};
$('peBtn').onclick=()=>{const T=Math.max(1,$('peSentence').value.trim().split(/\s+/).filter(Boolean).length);drawPE(T);};
let activeHeads=new Set([0]);
function computeHeadInfo(){const info=[];const data=pretrainData.length?pretrainData:[{ids:[stoi['the']||1,stoi['cat']||2,stoi['is']||3]}];const acc=[];for(let h=0;h<H;h++)acc.push({self:0,prev:0,first:0,n:0});for(const ex of data){const f=forward(ex.ids);const T=ex.ids.length;for(let h=0;h<H;h++){const A=f.heads[h].A;for(let i=1;i<T;i++){acc[h].self+=A[i][i];acc[h].prev+=A[i][i-1];acc[h].first+=A[i][0];acc[h].n++;}}}for(let h=0;h<H;h++){const a=acc[h],n=a.n||1;const self=a.self/n,prev=a.prev/n,first=a.first/n;let name,desc,key;const m=Math.max(self,prev,first);if(m<0.34){name="Broad context";desc="spreads its attention across many earlier words rather than fixating on one.";key=Math.round((1-m)*100);}else if(m===prev){name="Previous-word";desc="focuses on the word immediately before &mdash; good for local phrasing.";key=Math.round(prev*100);}else if(m===self){name="Self-focused";desc="keeps each word attending mostly to itself, preserving its own meaning.";key=Math.round(self*100);}else{name="Start-anchor";desc="looks back toward the first word of the sentence for global context.";key=Math.round(first*100);}info.push({name,desc,key});}return info;}
let headInfo=[];
function buildHeadPicks(){headInfo=computeHeadInfo();const hp=$('atnHeadPick');hp.innerHTML='';for(let h=0;h<H;h++){const b=document.createElement('button');b.dataset.h=h;b.className='btn small'+(activeHeads.has(h)?'':' ghost');b.innerHTML=headInfo[h].name+' <span style="opacity:.7">'+headInfo[h].key+'%</span>';b.onclick=()=>{const i=+b.dataset.h;if(activeHeads.has(i)){if(activeHeads.size>1)activeHeads.delete(i);}else activeHeads.add(i);refreshHeadBtns();runAttn();};hp.appendChild(b);}}
function refreshHeadBtns(){[...$('atnHeadPick').children].forEach(b=>{b.className='btn small'+(activeHeads.has(+b.dataset.h)?'':' ghost');});}
$('atnAll').onclick=()=>{activeHeads=new Set([...Array(H).keys()]);refreshHeadBtns();runAttn();};
$('atnNone').onclick=()=>{activeHeads=new Set([0]);refreshHeadBtns();runAttn();};
function runAttn(){if(!built)return;let ids=$('atnSentence').value.trim().split(/\s+/).map(w=>stoi[w]).filter(x=>x!==undefined);if(ids.length<2)ids=[stoi['the']||1,stoi['cat']||2];const f=forward(ids);headInfo=computeHeadInfo();refreshHeadLabels();const T=ids.length;const avg=zeros(T,T);const sel=[...activeHeads];for(const h of sel){const A=f.heads[h].A;for(let i=0;i<T;i++)for(let j=0;j<T;j++)avg[i][j]+=A[i][j]/sel.length;}drawAttn($('atnCanvas'),avg,ids,0);const names=sel.map(h=>headInfo[h].name+' ('+headInfo[h].key+'%)').join(', ');const descs=sel.length===1?(' &mdash; this head '+headInfo[sel[0]].desc):'';$('atnHeadDesc').innerHTML=(pretrained?'':'<span style="color:#c98b6b">Heads look alike now because the model is untrained. Pre-train in Step 6, then run this again to watch them specialize.</span><br>')+'Showing '+(sel.length>1?('the average of '+sel.length+' heads: '):'1 head: ')+'<span style="color:#e7ddcd">'+names+'</span>'+descs;drawCustPreview();}
function refreshHeadLabels(){[...$('atnHeadPick').children].forEach(b=>{const h=+b.dataset.h;b.innerHTML=headInfo[h].name+' <span style="opacity:.7">'+headInfo[h].key+'%</span>';});}
$('atnBtn').onclick=runAttn;
let custMode='offset',custK=1,custSigma=0.5;
function custRow(i){const len=i+1;const target=custMode==='first'?0:Math.max(0,Math.min(i,i-custK));const row=new Float64Array(len);let s=0;for(let j=0;j<len;j++){const d=j-target;const w=Math.exp(-(d*d)/(2*custSigma*custSigma));row[j]=w;s+=w;}for(let j=0;j<len;j++)row[j]/=(s||1);return row;}
function forwardLogits(ids,patFn){const T=ids.length,PE=posEncoding(T);const h0=zeros(T,D);for(let t=0;t<T;t++)for(let j=0;j<D;j++)h0[t][j]=P.E[ids[t]][j]+PE[t][j];const concat=zeros(T,D),scale=Math.sqrt(DH);for(let h=0;h<H;h++){const Q=matmul(h0,P.Wq[h]),K=matmul(h0,P.Wk[h]),Vv=matmul(h0,P.Wv[h]);const A=zeros(T,T);for(let i=0;i<T;i++){if(patFn){const r=patFn(i);for(let j=0;j<=i;j++)A[i][j]=r[j];}else{const row=new Float64Array(i+1);for(let j=0;j<=i;j++){let dot=0;for(let d=0;d<DH;d++)dot+=Q[i][d]*K[j][d];row[j]=dot/scale;}const sm=softmaxRow(row,i+1);for(let j=0;j<=i;j++)A[i][j]=sm[j];}}const O=matmul(A,Vv);for(let t=0;t<T;t++)for(let d=0;d<DH;d++)concat[t][h*DH+d]=O[t][d];}const attn=matmul(concat,P.Wo);const u1=add(h0,attn);const h1=layernorm(u1,P.g1,P.bn1).out;const z=matmul(h1,P.W1);for(let t=0;t<T;t++)for(let j=0;j<DFF;j++)z[t][j]+=P.b1[0][j];const a=zeros(T,DFF);for(let t=0;t<T;t++)for(let j=0;j<DFF;j++)a[t][j]=Math.max(0,z[t][j]);const ff=matmul(a,P.W2);for(let t=0;t<T;t++)for(let j=0;j<D;j++)ff[t][j]+=P.b2[0][j];const u2=add(h1,ff);const h2=layernorm(u2,P.g2,P.bn2).out;const logits=matmul(h2,P.Wlm);for(let t=0;t<T;t++)for(let j=0;j<V;j++)logits[t][j]+=P.blm[0][j];return logits;}
function evalLoss(patFn){let tot=0,n=0;for(const ex of pretrainData){const lg=forwardLogits(ex.ids,patFn);const T=ex.ids.length;for(let t=0;t<T-1;t++){if(!ex.mask[t])continue;const p=softmaxRow(lg[t],V);tot+=-Math.log(Math.max(p[ex.ids[t+1]],1e-12));n++;}}return tot/(n||1);}
function drawCustPreview(){if(!built)return;let ids=$('atnSentence').value.trim().split(/\s+/).map(w=>stoi[w]).filter(x=>x!==undefined);if(ids.length<2)ids=[stoi['the']||1,stoi['cat']||2];const T=ids.length;const A=zeros(T,T);for(let i=0;i<T;i++){const r=custRow(i);for(let j=0;j<=i;j++)A[i][j]=r[j];}drawAttn($('custCanvas'),A,ids,0);}
function spreadLabel(){return custSigma<0.6?'sharp':custSigma<1.5?'medium':custSigma<3?'wide':'very wide';}
function syncCust(){$('kVal').textContent=custK;$('spreadVal').textContent=spreadLabel();$('kSlider').value=custK;drawCustPreview();}
$('kSlider').oninput=()=>{custK=+$('kSlider').value;custMode='offset';syncCust();};
$('spreadSlider').oninput=()=>{custSigma=0.3+(+$('spreadSlider').value/100)*4;syncCust();};
[...document.querySelector('.post-content #custPresets').children].forEach(b=>{b.onclick=()=>{const p=b.dataset.p;if(p==='self'){custMode='offset';custK=0;custSigma=0.4;document.querySelector('.post-content #spreadSlider').value=3;}else if(p==='prev'){custMode='offset';custK=1;custSigma=0.4;document.querySelector('.post-content #spreadSlider').value=3;}else if(p==='first'){custMode='first';custSigma=0.4;document.querySelector('.post-content #spreadSlider').value=3;}else if(p==='uniform'){custMode='offset';custK=0;custSigma=6;document.querySelector('.post-content #spreadSlider').value=100;}syncCust();};});
let evalResults=[];
function renderEval(){const base=evalResults.find(r=>r.base);const list=evalResults.slice().sort((a,b)=>a.loss-b.loss);document.querySelector('.post-content #evalList').innerHTML=list.map(r=>{const better=base&&!r.base&&r.loss<=base.loss*1.05;const colr=r.base?'#7fd1c9':(better?'#9bd17f':'#c98b6b');return '<div><span style="color:'+colr+'">'+r.loss.toFixed(3)+'</span> &middot; '+r.label+(r.base?' (the model\'s own &mdash; baseline)':'')+'</div>';}).join('');}
document.querySelector('.post-content #evalBtn').onclick=()=>{if(!pretrained){document.querySelector('.post-content #evalStatus').textContent='pre-train the model first (Step 6), then come back to score heads';return;}if(!evalResults.some(r=>r.base)){const bl=evalLoss(null);evalResults.push({label:'learned attention',loss:bl,base:true});}const base=evalResults.find(r=>r.base).loss;const loss=evalLoss(custRow);let label;if(custMode==='first')label='first-word ('+spreadLabel()+')';else label='look back '+custK+', '+spreadLabel();evalResults.push({label,loss});const pct=((loss-base)/base*100);document.querySelector('.post-content #evalStatus').innerHTML='your head: loss <span style="color:var(--glow)">'+loss.toFixed(3)+'</span> vs learned '+base.toFixed(3)+' &mdash; '+(pct<=5?'<span style="color:#9bd17f">about as good</span>':'<span style="color:#c98b6b">'+pct.toFixed(0)+'% worse</span>');renderEval();};
function runTraining(data,total,lr,lossCanvas,statusEl,btn,btnLabel,onTick,onDone){if(busy)return;busy=true;btn.disabled=true;const hist=[];let step=0;function loop(){if(step>=total){busy=false;btn.disabled=false;btn.textContent=btnLabel;onDone(hist[hist.length-1]);return;}let L=0;const CH=6;for(let c=0;c<CH&&step<total;c++){const G=zeroGrads();let l=0;for(const ex of data)l+=lossAndGrad(ex,G);l/=data.length;adamStep(G,lr);L=l;step++;}hist.push(L);drawLoss(lossCanvas,hist);statusEl.textContent='step '+step+'/'+total+' &middot; loss '+L.toFixed(3);if(onTick)onTick(step);requestAnimationFrame(loop);}requestAnimationFrame(loop);}
document.querySelector('.post-content #preBtn').onclick=()=>{if(!built||busy)return;P=initParams();opt=makeAdam();document.querySelector('.post-content #preLog').innerHTML='';const seedTxt=(pretrainData[0]?strip(pretrainData[0].ids).split(' ').slice(0,2).join(' '):'the sun');document.querySelector('.post-content #watchSeedLbl').textContent='continuing "'+seedTxt+'" as it learns';document.querySelector('.post-content #preBtn').textContent='Pre-training...';runTraining(pretrainData,450,0.01,document.querySelector('.post-content #preLoss'),document.querySelector('.post-content #preStatus'),document.querySelector('.post-content #preBtn'),'Re-train (fresh)',(step)=>{if(step%36===0){const ids=seedTxt.split(' ').map(w=>stoi[w]).filter(x=>x!==undefined);const o=strip(generate(ids,8,0.3,true));const d=document.createElement('div');d.innerHTML='<span style="color:#6f6356">step '+step+':</span> '+o;document.querySelector('.post-content #preLog').appendChild(d);document.querySelector('.post-content #preLog').scrollTop=document.querySelector('.post-content #preLog').scrollHeight;}},(finalLoss)=>{pretrained=true;document.querySelector('.post-content #preStatus').textContent='base model ready &middot; loss '+finalLoss.toFixed(3);drawEmb();document.querySelector('.post-content #embCap').textContent='Trained embeddings &mdash; notice the structured patterns that replaced the random noise.';buildHeadPicks();enable('step7',true);enable('step8',true);document.querySelector('.post-content #ftStatus').textContent='base model loaded';baseGen();baseAskRun();});};
let animTimer=null;
function stopAnim(){if(animTimer){clearTimeout(animTimer);animTimer=null;}}
function topK(p,k){const idx=[...Array(V).keys()].sort((a,b)=>p[b]-p[a]).slice(0,k);return idx.map(i=>({w:vocab[i],i,p:p[i]}));}
function renderProbs(el,list,pick){el.innerHTML=list.map(o=>{const isPick=o.i===pick;const w=o.w==='<end>'?'&lt;end&gt;':o.w;return '<div style="display:flex;align-items:center;gap:8px;margin:3px 0;"><span class="mono" style="width:66px;font-size:12px;color:'+(isPick?'var(--glow)':'#cfc3b2')+'">'+w+'</span><div class="barwrap" style="flex:1;width:auto"><div class="bar" style="width:'+(o.p*100).toFixed(0)+'%;'+(isPick?'':'opacity:.5')+'"></div></div><span class="mono" style="width:38px;font-size:12px;color:#9c8e7d">'+(o.p*100).toFixed(0)+'%</span>'+(isPick?'<span class="mono" style="color:var(--glow);font-size:11px">&larr; picked</span>':'')+'</div>';}).join('');}
function animateGen(seed,renderFrom,prefix,outEl,probEl,noteEl,maxLen,onDone){stopAnim();let out=seed.slice();function renderOut(hlLast,stopped){const toks=[];for(let idx=renderFrom;idx<out.length;idx++){const w=vocab[out[idx]];if(w.startsWith('<'))continue;const isNew=hlLast&&idx===out.length-1;toks.push(isNew?'<span style="background:var(--terra);color:#fff;padding:1px 6px;border-radius:5px">'+w+'</span>':'<span>'+w+'</span>');}outEl.innerHTML=prefix+(toks.join(' ')||'<span style="opacity:.4">...</span>')+(stopped?'':' <span style="opacity:.5;animation:bob 1s infinite">&#9608;</span>');}renderOut(false,false);let step=0;function tick(){const f=forward(out);const logits=f.logits[out.length-1];const p=softmaxRow(logits,V);const list=topK(p,5);let pick=0;for(let j=0;j<V;j++)if(p[j]>p[pick])pick=j;renderProbs(probEl,list,pick);if(pick===END_TOK){noteEl.innerHTML='Most likely next token is <span class="mono" style="color:var(--glow)">&lt;end&gt;</span> ('+(p[END_TOK]*100).toFixed(0)+'%) &mdash; the model is saying "I\'m done." Generation stops.';renderOut(false,true);animTimer=null;if(onDone)onDone(out);return;}out.push(pick);renderOut(true,false);noteEl.innerHTML='Most likely next word: <span class="mono" style="color:var(--glow)">'+vocab[pick]+'</span> ('+(p[pick]*100).toFixed(0)+'%). Appended it; now predicting from the new position...';step++;if(step>=maxLen){noteEl.innerHTML+=' (length limit reached)';renderOut(false,true);animTimer=null;if(onDone)onDone(out);return;}animTimer=setTimeout(tick,820);}noteEl.textContent='Looking at the seed and predicting the first next word...';animTimer=setTimeout(tick,450);}
function baseGen(){if(!pretrained)return;let ids=document.querySelector('.post-content #baseSeed').value.trim().split(/\s+/).map(w=>stoi[w]).filter(x=>x!==undefined);if(!ids.length)ids=[stoi['the']];animateGen(ids,0,'"',document.querySelector('.post-content #baseOut'),document.querySelector('.post-content #baseProbs'),document.querySelector('.post-content #baseGenNote'),9,(out)=>{document.querySelector('.post-content #baseOut').innerHTML='"'+strip(out)+'"';});}
function baseAskRun(){if(!pretrained)return;document.querySelector('.post-content #baseAskOut').textContent='base model says: "'+ask(document.querySelector('.post-content #baseAsk').value)+'"  (rambles &mdash; not trained to answer questions)';}
document.querySelector('.post-content #baseGenBtn').onclick=baseGen;document.querySelector('.post-content #baseAskBtn').onclick=baseAskRun;
document.querySelector('.post-content #prepBtn').onclick=()=>{if(!pretrained){document.querySelector('.post-content #prepStatus').textContent='pre-train first';return;}const totalLines=document.querySelector('.post-content #txtQA').value.split("\n").map(s=>s.trim()).filter(s=>s.includes("|")).length;qaData=buildQA(document.querySelector('.post-content #txtQA').value);if(!qaData.length){document.querySelector('.post-content #prepStatus').textContent='no usable pairs (format: question | answer, using known words)';return;}prepped=true;const dropped=totalLines-qaData.length;document.querySelector('.post-content #prepStatus').textContent=qaData.length+' pairs ready'+(dropped>0?' ('+dropped+' skipped: unknown words &mdash; rebuild from Step 1 to add them)':'');const ex=qaData[0];const aPos=ex.ids.indexOf(A_TOK);document.querySelector('.post-content #maskDemo').innerHTML=ex.ids.map((id,t)=>{const w=vocab[id];return '<span style="color:'+(t>aPos?'#f0b35a':'#6f6356')+'">'+w+'</span>';}).join(' ');enable('step9',true);const ac=document.querySelector('.post-content #askChips');ac.innerHTML='';qaData.slice(0,6).forEach(p=>{const b=document.createElement('button');b.className='btn ghost small';b.textContent=p.q;b.onclick=()=>{document.querySelector('.post-content #askInput').value=p.q;askRun();};ac.appendChild(b);});};
document.querySelector('.post-content #ftBtn').onclick=()=>{if(!prepped||busy)return;document.querySelector('.post-content #ftBtn').textContent='Fine-tuning...';runTraining(qaData,320,0.006,document.querySelector('.post-content #ftLoss'),document.querySelector('.post-content #ftStatus'),document.querySelector('.post-content #ftBtn'),'Fine-tune again',null,(finalLoss)=>{finetuned=true;document.querySelector('.post-content #ftStatus').textContent='fine-tuned &middot; answer loss '+finalLoss.toFixed(3);enable('step10',true);askRun();});};
function askRun(){if(!finetuned){document.querySelector('.post-content #askOut').textContent='fine-tune the model first';return;}const q=document.querySelector('.post-content #askInput').value.trim().split(/\s+/).map(w=>stoi[w]).filter(x=>x!==undefined);const seed=[Q_TOK,...q,A_TOK];animateGen(seed,seed.length,'A: ',document.querySelector('.post-content #askOut'),document.querySelector('.post-content #askProbs'),document.querySelector('.post-content #askNote'),14,null);}
document.querySelector('.post-content #askBtn').onclick=askRun;document.querySelector('.post-content #askInput').addEventListener('keydown',e=>{if(e.key==='Enter')askRun();});
})();
</script>
