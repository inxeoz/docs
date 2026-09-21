---
title: "How to Use FizzBee for Formal Verification of Distributed Systems"
date: 2026-06-16
draft: false
tags: ["fizzbee", "formal methods", "model checking", "distributed systems", "tla+"]
categories: ["Tech"]
viewMode: docs
showToc: true
---

**FizzBee** is a formal specification language and model checker for designing and verifying distributed systems. It uses a Python-like syntax (Starlark) — far more approachable than TLA+ or Alloy while offering the same rigorous state-space exploration.

You write a model of your system, specify invariants (safety) and liveness properties, and FizzBee exhaustively checks every possible state transition to find bugs *before* you write production code.

## Quick Start

### Online Playground

No installation needed: [https://fizzbee.io/play](https://fizzbee.io/play)

### Local Binary

Download a pre-built binary from the [releases page](https://github.com/fizzbee-io/fizzbee/releases/latest):

```bash
chmod +x fizz
./fizz path/to/model.fizz
```

## Basic Concepts

Every FizzBee model has three ingredients:

| Concept | What It Does |
|---------|-------------|
| **Actions** | Define what *can* happen in the system (user events, timer ticks, network messages) |
| **State** | Variables initialized in `Init` and mutated by actions |
| **Invariants** | Properties that must hold in every state (safety) or eventually hold (liveness) |

Actions are either `serial` (default — yield point between each statement, crash possible) or `atomic` (all-or-nothing). The model checker explores every interleaving.

## Example 1: Two Counter Variables

A minimal model to see the checker in action:

```python
# Safety invariant: neither counter may exceed 4
always assertion AlwaysBelowLimit:
    return all([counters[key] <= 4 for key in C])

# Initialize two counters, 'a' and 'b', both to 0
atomic action Init:
    C = ['a', 'b']
    counters = {key: 0 for key in C}

# Non-deterministically pick a key and increment its counter
atomic action Next:
    any key in C:            # forks a branch for each key
        counters[key] = counters[key] + 1
```

Save this as `TwoCounters.fizz`.

The `any` statement introduces non-determinism — at each step the model checker forks a branch for every possible key. Run it:

```bash
./fizz TwoCounters.fizz
```

Output:

```
Model checking TwoCounters.json
Nodes: 25, elapsed: 579.792µs
PASSED: Model checker completed successfully
```

The assertion `AlwaysBelowLimit` checks that neither counter exceeds 4. Change the limit to 2 and re-run — the checker will fail with an explicit trace of the violating path.

### Limit the State Space

Create `fizz.yaml`:

```yaml
options:
  max_actions: 4
```

Now the model only explores 4 steps of actions. The output shrinks to 25 nodes (instead of infinite) and a Graphviz dot file is generated for visualization.

## Example 2: Wire Transfer with Safety Invariant

This is the classic formal-methods example — ensure no money is lost in a transfer.

```python
# Safety: sum of all balances must always equal 5
always assertion BalanceMatchTotal:
    total = 0
    for balance in balances.values():
        total += balance
    return total == 5

# Initial state: Alice has 3, Bob has 2
action Init:
    balances = {'Alice': 3, 'Bob': 2}

# Atomic transfer: debit Alice, credit Bob in one step
atomic action FundTransfer:
    any amount in range(0, 100):     # try every possible amount
        if balances['Alice'] >= amount:
            balances['Alice'] -= amount  # deduct from sender
            balances['Bob'] += amount    # credit recipient
```

Run it — the checker passes. The `atomic` keyword ensures the debit and credit happen together, like a database transaction.

Now remove `atomic` and re-run. The checker will find a violation: a context switch after deducting Alice but before crediting Bob. The total drops to 2, breaking the invariant. This is the exact kind of bug formal methods catch that unit tests miss.

## Example 3: Liveness — Money Eventually Arrives

Suppose the transfer is not atomic: Alice is debited immediately, but Bob is credited later.

```python
# Liveness: total must eventually return to 5
always eventually assertion BalanceMatchTotal:
    total = 0
    for balance in balances.values():
        total += balance
    return total == 5

# Initial state: two accounts, empty pending queue
action Init:
    balances = {'Alice': 3, 'Bob': 2}
    wire_requests = []                    # pending transfers

# Step 1: deduct from Alice, queue the transfer for later
atomic action Wire:
    any amount in range(1, 10):
        if balances['Alice'] >= amount:
            balances['Alice'] -= amount
            wire_requests.append(('Alice', 'Bob', amount))

# Step 2: process one queued transfer, credit Bob
# 'fair' means this action must eventually execute
atomic fair action DepositWireTransfer:
    any req in wire_requests:
        balances[req[1]] += req[2]        # credit recipient
        wire_requests.remove(req)         # remove from queue
```

Key differences from the previous example:

- `always eventually` asserts that the total *will eventually* equal 5 — a liveness property, not a safety one
- `fair` marks `DepositWireTransfer` as an action that *must* eventually be taken (the system can't stall forever)
- Wire requests are queued as a list; the deposit action processes them one by one

Run it — the checker will show a **deadlock**: once Alice runs out of money, no action is enabled. The model forces you to confront this edge case. Fix by adding a `NoOp` action or by allowing Bob to transfer back.

## Running the Model Checker

```bash
./fizz model.fizz
```

| Outcome | Meaning |
|---------|---------|
| `PASSED` | All invariants hold in every reachable state |
| `FAILED` | A violation was found — a trace is printed |
| `Deadlock` | No action is enabled from some state (design error) |

When violations occur, FizzBee prints the full trace and generates an error graph in `out/run_*/error-graph.dot`. Render it with Graphviz:

```bash
dot -Tpng out/run_2024-03-05_13-09-25/error-graph.dot -o error.png
```

## Safety vs Liveness vs Fairness

| Property | Keyword | Meaning | Example |
|----------|---------|---------|---------|
| Safety | `always assertion` | Nothing bad ever happens | Balance never goes negative |
| Liveness | `always eventually assertion` | Something good eventually happens | Transfer eventually completes |
| Stability | `eventually always assertion` | Something good happens and stays | System eventually reaches steady state |
| Weak fairness | `fair` / `fair<weak>` | Action enabled continuously → taken eventually | |
| Strong fairness | `fair<strong>` | Action enabled infinitely often → taken eventually | |

## When to Use FizzBee

- **Distributed protocol design** — consensus, replication, 2PC
- **Concurrent data structures** — lock-free queues, atomic registers
- **State machines** — leader election, workflow orchestration
- **Database transactions** — isolation levels, consistency guarantees

## FizzBee vs TLA+

If you've heard of TLA+ (Leslie Lamport's formal specification language used at AWS, Azure, and MongoDB), you might wonder how FizzBee compares.

| Dimension | FizzBee | TLA+ |
|-----------|---------|------|
| **Syntax** | Python-like (Starlark) — familiar to any developer | Math-like (`\E`, `\A`, `[][NEXT]_vars`) — steep learning curve |
| **Readability** | Non-authors can read and review specs | Requires TLA+ knowledge; reviewers often skip the spec |
| **Atomicity** | Explicit `atomic` / `serial` / `parallel` / `oneof` blocks | Everything is atomic by default; no yield-point control |
| **State graph** | Built-in Graphviz output | Requires external tools or TLA+ Toolbox |
| **Online playground** | Yes — [fizzbee.io/play](https://fizzbee.io/play) | No official playground |
| **Probabilistic** | Built-in — steady-state probabilities, custom distributions | Not supported natively; requires PRISM |
| **Performance** | Built-in — cost/reward counters, latency modeling | Not supported natively |
| **Fairness** | `fair<weak>` / `fair<strong>` | `WF_vars` / `SF_vars` |
| **Maturity** | Newer (2024) — smaller community, fewer examples | Mature (1990s+) — vast ecosystem, AWS uses it in production |
| **Tooling** | Single binary, simple YAML config | TLA+ Toolbox, VS Code extension, `apalache`, `tlc` |

### When to pick which

**Choose FizzBee when:**
- Your team has little or no formal-methods experience
- You want readable specs that double as design documentation
- You need probabilistic or performance modeling (latency distributions, cost analysis)
- You want an online playground for quick iteration

**Choose TLA+ when:**
- You need battle-tested tooling for a critical production system
- You're modeling at AWS/Microsoft scale and the team already knows TLA+
- You need advanced temporal logic beyond `always`/`eventually`/`always eventually`
- You want to verify existing TLA+ specs from the literature (Raft, Paxos, etc.)

### Practical reality

In practice, FizzBee can express the same distributed protocols (Raft, 2PC, token ring, leader election) that TLA+ can. The model-checking engine explores the same state space. The difference is accessibility — a junior engineer can read a FizzBee spec on day one, while TLA+ requires weeks of ramp-up. Both are better than no formal verification at all.

## Example 4: Missionaries and Cannibals — Reachability Puzzle

A classic AI/river-crossing puzzle to show FizzBee on a finite-state reachability problem.

**The puzzle:** 3 missionaries and 3 cannibals must cross a river using a boat that holds at most 2 people. If cannibals outnumber missionaries on either bank at any point, the missionaries get eaten. The boat needs at least one person to row.

```python
# Safety: cannibals must never outnumber missionaries on either bank
always assertion NoEaten:
    return ((ml == 0 or cl <= ml) and
            (mr == 0 or cr <= mr))

# Initial state: everyone on left bank, boat on left
action Init:
    ml = 3    # missionaries on left
    cl = 3    # cannibals on left
    mr = 0    # missionaries on right
    cr = 0    # cannibals on right
    boat = "left"

# Cross from left to right: pick a valid (dm, dc) move
atomic action CrossLeftToRight:
    require boat == "left"                                  # boat must be here
    any move in [(1,0), (2,0), (0,1), (0,2), (1,1)]:       # (dm, dc) combinations
        dm = move[0]
        dc = move[1]
        require ml >= dm and cl >= dc                       # enough people on left
        require (ml - dm == 0 or cl - dc <= ml - dm)       # left bank stays safe
        require (mr + dm == 0 or cr + dc <= mr + dm)       # right bank stays safe
        ml -= dm
        cl -= dc
        mr += dm
        cr += dc
        boat = "right"                                      # boat moves

# Cross from right to left: symmetric
atomic action CrossRightToLeft:
    require boat == "right"
    any move in [(1,0), (2,0), (0,1), (0,2), (1,1)]:
        dm = move[0]
        dc = move[1]
        require mr >= dm and cr >= dc                       # enough people on right
        require (mr - dm == 0 or cr - dc <= mr - dm)       # right bank stays safe
        require (ml + dm == 0 or cl + dc <= ml + dm)       # left bank stays safe
        mr -= dm
        cr -= dc
        ml += dm
        cl += dc
        boat = "left"
```

Same problem expressed in TLA+ for comparison:

```tla
---- MODULE Missionaries ----
EXTENDS Naturals

VARIABLES ml, cl, mr, cr, boat

Init == /\ ml = 3 /\ cl = 3        \* everyone on left bank
        /\ mr = 0 /\ cr = 0        \* nobody on right bank yet
        /\ boat = "left"

\* possible (missionaries, cannibals) the boat can carry
Moves == {<<1,0>>, <<2,0>>, <<0,1>>, <<0,2>>, <<1,1>>}

\* cross left -> right: pick a move, apply deltas
CrossLeftToRight(move) ==
    /\ boat = "left"
    /\ ml >= move[1] /\ cl >= move[2]    \* enough people on left
    /\ (ml - move[1] = 0 \/ cl - move[2] <= ml - move[1])  \* left stays safe
    /\ (mr + move[1] = 0 \/ cr + move[2] <= mr + move[1])  \* right stays safe
    /\ ml' = ml - move[1]
    /\ cl' = cl - move[2]
    /\ mr' = mr + move[1]
    /\ cr' = cr + move[2]
    /\ boat' = "right"

\* cross right -> left: symmetric
CrossRightToLeft(move) ==
    /\ boat = "right"
    /\ mr >= move[1] /\ cr >= move[2]
    /\ (mr - move[1] = 0 \/ cr - move[2] <= mr - move[1])
    /\ (ml + move[1] = 0 \/ cl + move[2] <= ml + move[1])
    /\ mr' = mr - move[1]
    /\ cr' = cr - move[2]
    /\ ml' = ml + move[1]
    /\ cl' = cl + move[2]
    /\ boat' = "left"

\* pick any move, fork between left->right and right->left
Next == \E move \in Moves:
            CrossLeftToRight(move) \/ CrossRightToLeft(move)

\* safety: cannibals never outnumber missionaries on either bank
NoEaten == (ml = 0 \/ cl <= ml) /\ (mr = 0 \/ cr <= mr)

Spec == Init /\ [][Next]_<<ml, cl, mr, cr, boat>>
```

The TLA+ version is more verbose due to mathematical notation (`/\`, `\/`, `\E`, `'` for primed variables), but expresses the exact same state space. The FizzBee version is closer to how you'd *think* about the puzzle — sequential steps, mutable state, guard clauses — while TLA+ treats everything as predicate logic on state transitions.

The safety guards inside each action are essential: checking `ml >= dm and cl >= dc` only ensures you *have* enough people on the source bank, not that the resulting bank composition is safe. Without the bank-safety checks, the model checker fires the invariant on the very first move (1 missionary crosses, leaving 3 cannibals vs 2 missionaries on the left).

Key modelling decisions:

- **State** is the count of missionaries/cannibals on each bank plus boat position
- **Moves** are defined as `(dm, dc)` pairs — 5 possible combinations the boat can carry
- **`require`** acts as an enabling condition: the move is only allowed if enough people are on the current bank **and** both banks remain safe after the crossing
- **`boat`** toggles between `"left"` and `"right"` after each crossing

Run the checker:

```bash
./fizz missionaries.fizz
```

The model checker now explores 20 nodes — every valid configuration of (ml, cl, mr, cr, boat) where nobody gets eaten. If you remove the bank-safety guards, the checker catches the violation in 3 nodes.

To verify the puzzle is solvable, add a liveness goal:

```python
always eventually assertion GoalReached:
    return mr == 3 and cr == 3
```

With fairness on both crossing actions, the checker confirms that the goal state is reachable from any valid state. Open the state graph to see the path: `(3,3,0,0,left) → (2,2,1,1,right) → ... → (0,0,3,3,right)` in 11 moves.

## Other Specification & Verification Tools

| Tool | Language | Domain | Notable For |
|------|----------|--------|-------------|
| **FizzBee** | Python-like (Starlark) | Distributed systems, state machines | Easiest learning curve, built-in probabilistic & performance modeling |
| **TLA+** | Math-like (TLA) | Distributed protocols, concurrent algorithms | AWS-production proven, largest formal-methods ecosystem (Lamport) |
| **Alloy** | Relational logic | Software design, data models, security | Automatic visualization, great for structural constraints & data integrity |
| **P** | C-like (P) | Event-driven systems, device drivers | Microsoft's language for asynchronous event-driven protocols |
| **PlusCal** | Pseudo-code | Distributed systems | TLA+'s algorithmic language — transpiles to TLA+ |
| **Dafny** | Imperative + contracts | Sequential programs, data structures | Auto-active verification — compiles to C#/Java/JS |
| **PRISM** | Property-spec (PRISM lang) | Probabilistic systems, Markov chains | Gold standard for probabilistic model checking |
| **Spin** | Promela | Communication protocols, concurrent systems | Explicit-state model checking, LTL verification |
| **Coq / Isabelle** | Functional (gallina / HOL) | Formal proofs, language semantics | Proof assistants — interactive theorem proving |
| **Z3** | SMT-LIB (API: Python/C++/..) | Constraint solving, program analysis | Microsoft's SMT solver — automated theorem proving at scale |
| **CBMC** | C (annotated) | C programs, embedded systems | Bounded model checking for C with assertions |
| **KLEE** | LLVM bytecode | C/C++ programs, symbolic execution | Automatic test-case generation via symbolic execution |

### Quick decision guide

1. **New to formal methods, want to verify a system design** → start with **FizzBee** (Python syntax, playground, state graphs)
2. **Need battle-proven distributed protocol verification** → **TLA+** (used by AWS for S3, DynamoDB, etc.)
3. **Designing data models or relational constraints** → **Alloy** (lightweight, visual)
4. **Verifying implementation (not just design)** → **Dafny** (auto-active, compiles) or **CBMC** (C code)
5. **Proof of program correctness end-to-end** → **Coq** or **Isabelle**
6. **Probabilistic systems (reliability, performance)** → **PRISM**
7. **Satisfiability / constraint solving** → **Z3**

## Resources

- [Online Playground](https://fizzbee.io/play) — try without installing
- [Tutorials](https://fizzbee.io/design/tutorials/) — official getting-started guide
- [Examples](https://fizzbee.io/design/examples/) — Raft, 2PC, token ring
- [GitHub](https://github.com/fizzbee-io/fizzbee) — source and releases
- [TLA+ Examples](https://github.com/tlaplus/Examples) — classic TLA+ specs to compare and port to FizzBee
