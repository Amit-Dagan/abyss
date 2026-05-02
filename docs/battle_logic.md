# Battle Design And Progression

This is the canonical design document for the battle system.

For the broader city-builder and abyss-loop product vision, see
[abyss_mvp_gdd.md](abyss_mvp_gdd.md).

It includes:

- the current implemented battle rules
- planned combat extensions
- example unit roster ideas
- example upgrade trees

Sections are intentionally split between:

- `Current Implementation`
- `Planned Extensions`

So the doc can stay useful without confusing shipped behavior with design drafts.

## Current Implementation

## Core idea

A battle is resolved in turns on a grid.

Each unit is modeled as:

- `currentState`
- `pendingEffects`

Units do not immediately change the board when they act. During the turn they only add effects into `pendingEffects`. Those effects are applied together in cleanup.

Example:

```text
Before cleanup:
{ currentState: { health: 4 }, pendingEffects: { health: -3 } }

After cleanup:
{ currentState: { health: 1 }, pendingEffects: {} }
```

This applies to:

- basic attack damage
- skill damage
- healing
- attack buffs
- knockback

Because all of those are delayed until cleanup:

- a unit always acts from the same board state seen at the start of the turn
- a unit that dies in cleanup still resolves the effects it already committed that turn
- a buff never increases the attack already committed in the same turn

## Battle sides

- `Army A` is the `Red Team`
- `Army B` is the `Blue Team`

In battle mode:

- Red is the attacker
- Blue is the defender
- Red advances
- Blue does not advance

In tournament mode:

- both sides are aggressors
- both sides advance toward the center

Facing direction:

- Red faces downward, so its forward direction is increasing row index: `+1`
- Blue faces upward, so its forward direction is decreasing row index: `-1`

This forward direction is used for:

- targeting
- attack patterns
- knockback direction
- movement only in modes where that side is allowed to advance

## Battle formats

There are 2 battle formats.

### 1. Battle mode

- Rows are always `8`
- Columns are selectable from `4` to `8`
- Deployment rows:
  - Red: top `3` rows
  - Blue: bottom `3` rows
  - middle: `2` empty neutral rows at the start

### 2. Tournament mode

The board is split directly into top half and bottom half, with no neutral gap.

Tournament mode is symmetric:

- Red and Blue are both aggressors
- there is no breakthrough win condition
- the goal for both sides is to eliminate the other army

Supported presets:

- `2 x 1`
- `2 x 4`
- `4 x 2`
- `8 x 1`

Deployment rows:

- Red owns the top half
- Blue owns the bottom half

## Unit definition

Each unit definition currently includes:

- `id`
- `name`
- `iconKey`
- `attack`
- `health`
- `attackPattern`
- optional `attackPatternAmount`
- `onHitEffects`
- `targetedSkills`
- `passiveSkills`

Important rule:

- every unit always has a built-in basic attack
- that basic attack is not stored in skills

## Attack patterns

Every unit performs one attack pattern every turn.

All attack patterns:

- deal `[currentAttack]` damage to every target they hit
- commit their damage into pending effects
- resolve through cleanup, not immediately

Implemented attack patterns:

- `Front`
  - hit the enemy directly in front
- `Range N`
  - hit the first enemy in the same column, up to `N` tiles away
- `Piercer`
  - hit the first 2 enemies ahead in the same column
- `Cleave`
  - hit 3 spaces in the front row
- `Swinger`
  - hit all adjacent enemies
- `Volley`
  - hit the full first enemy row
- `Longshot`
  - skip the front square and strike 2 rows ahead
- `Crusher`
  - hit the first 2 squares in the front column
- `Whirlwind`
  - hit adjacent enemies and the front row

## Skills

Units currently use 3 skill categories on top of their attack pattern:

- `onHitEffects`
- `targetedSkills`
- `passiveSkills`

### Targeted skills

Targeted skills use:

- `effectType`
- `amount`
- `targetKey`

Implemented targeted `effectType` values:

- `heal`
- `damage`
- `buff_attack`
- `debuff_attack`
- `stun`
- `knockback`
- `fire`
- `poison`

### On-hit effects

On-hit effects use:

- `effectType`
- `amount`

Implemented on-hit `effectType` values:

- `poison`
- `fire`
- `stun`
- `knockback`
- `debuff_attack`

On-hit effects apply to every target hit by the current attack pattern.

Example:

- if a unit has `Cleave` plus `Poison 1`
- the attack uses the `Cleave` pattern
- every target hit by that attack also gets `Poison 1`

### Passive skills

Passive skills currently include:

- `taunt`
- `summoner`
- `rage`

## Targeting rules

Implemented `targetKey` values:

- `front_enemy`
- `front_ally`
- `adjacent_enemies`
- `adjacent_allies`
- `all_allies_next_to_me`
- `allies_behind_me`
- `enemies_behind_me`
- `same_column_enemies`
- `first_enemy_row`
- `back_row_enemies`
- `fallen_allies`

### `front_enemy`

- one enemy
- same column
- one row forward

### `front_ally`

- one allied unit
- same column
- one row forward

### `adjacent_enemies`

All enemy units in the 8 neighboring cells around the source unit:

- up
- down
- left
- right
- all 4 diagonals

### `adjacent_allies`

All allied units in the 8 neighboring cells around the source unit.

### `all_allies_next_to_me`

Currently behaves the same as `adjacent_allies`.

### `allies_behind_me`

All allied units behind the source unit relative to its facing direction.

### `enemies_behind_me`

All enemy units behind the source unit relative to its facing direction.

### `same_column_enemies`

All enemy units in the same column.

### `first_enemy_row`

All enemy units in the first row directly in front of the source unit.

That means:

- one row forward toward the opponent
- all columns in that row

### `back_row_enemies`

All enemies in their army's back rank.

### `fallen_allies`

Used internally by summoner logic to revive previously defeated allied units.

## Current passive and status rules

### `Taunt`

- implemented as a passive skill
- redirects attack-pattern hits and their attached on-hit riders from protected allies
- does not redirect unrelated targeted skills

### `Rage`

- implemented as a passive skill
- grants attack after the unit takes damage
- the attack gain only matters on later turns

### `Summoner`

- implemented as a passive skill
- revives fallen allies up to the summoner's remaining summon count
- revival uses the fallen unit's original starting tile
- if that tile is occupied, the summon is skipped

### `Stun`

- implemented as both an on-hit effect and a targeted skill
- stunned units lose their next turn

### `Fire`

- implemented as both an on-hit effect and a targeted skill
- fire deals decreasing cleanup damage: `5 -> 4 -> 3 -> ...`
- each fire application is tracked as its own stack

### `Poison`

- implemented as both an on-hit effect and a targeted skill
- poison deals increasing cleanup damage: `1 -> 2 -> 3 -> ...`
- each poison application is tracked as its own stack

### `Buff Attack`

- increases attack after cleanup resolves
- never affects the attack already committed in the same turn

### `Debuff Attack`

- reduces attack after cleanup resolves
- never changes the attack already committed earlier in the same turn

### `Knockback`

- pushes targets away from the acting unit's side
- resolves in cleanup after health and attack changes
- dead units are removed before knockback starts
- resolves before the normal advancing step
- a unit targeted by knockback cannot use the normal advancing step later in that same turn
- each target can be pushed up to `amount` squares
- push direction is straight away from the attacker, in the same column
- a push step only works if the next square is inside the board and empty
- if multiple knockback pushes propose the same square on the same step, none of those conflicting pushes happen

## Planned Extensions

The main combat extension ideas that are still not implemented are:

- `Explosive`
  - when this unit dies, deal `attack x 2` to the chosen target set
- `Opportunity Attack`
  - when protected allies get hit, this unit hits back

The larger meta progression systems are also still planned:

- rarity tiers
- upgrade trees

## Turn structure

Each turn is resolved in this order:

1. take actions
2. cleanup
3. advancing
4. breakthrough check, only in battle mode

### 1. Take actions

Every living unit acts once.

What happens here:

- commit basic attack to `pendingEffects`
- commit all skill effects to `pendingEffects`
- do not mutate health or attack yet

All targeting is based on the current board state before cleanup.

### 2. Cleanup

All pending effects are applied together.

For each unit:

- apply `pendingHealthDelta` to `currentHealth`
- apply `pendingAttackDelta` to `currentAttack`

Rules:

- health is clamped between `0` and the unit's base max health
- attack is clamped to at least `1`

After all pending effects are applied:

- units with `currentHealth <= 0` die and are removed
- then queued knockback is resolved on the surviving units
- then pending effects are cleared

Then victory is checked in this order:

1. if Blue has no units left, Red wins
2. else if Red has no units left, Blue wins

If both sides are wiped in the same cleanup, Red wins because defender elimination is checked first.

### 3. Advancing

#### Battle mode movement

Only Red units move.

Blue never advances.

Rules:

- move one tile straight forward
- only if the destination is inside the board
- only if the destination tile is empty
- if multiple Red units propose the same destination, none of those conflicting moves happen

#### Tournament mode movement

Both sides move.

Rules:

- Red moves one tile downward toward the center
- Blue moves one tile upward toward the center
- units only compress toward the center line inside their own half
- units do not move into the enemy half by movement
- movement is one tile straight forward in the same column
- movement checks the board after cleanup
- movement does not chain through newly vacated cells in the same turn
- if multiple units propose the same destination, none of those conflicting moves happen

Examples on an `8 x 1` board:

```text
[r,r,r,0,b,b,b,b] -> [r,r,0,r,b,b,b,b]
[r,r,0,r,b,b,b,b] -> [r,0,r,r,b,b,b,b]
[r,r,0,r,0,b,b,b] -> [r,0,r,r,b,0,b,b]
[r,0,0,0,b,b,b,b] -> [0,r,0,0,b,b,b,b]
```

### 4. Breakthrough check

This step only exists in battle mode.

After Red movement:

- if any Red unit reaches the last row of the board, Red wins immediately

This is the defender back rank.

## Victory conditions

### Red attacker victory

Red wins if either:

- all Blue defenders die
- any Red unit reaches the Blue back rank

### Blue defender victory

Blue wins if:

- all Red attackers die

### Tournament victory

In tournament mode:

- Red wins if all Blue units die
- Blue wins if all Red units die
- movement itself never wins the battle

## Anti-stall safety rules

The intended design is that battles should naturally end because:

- battle mode has attacker pressure and breakthrough
- tournament mode compresses both sides toward the center
- every unit always has a basic attack

The simulator still includes hidden safety guards:

- maximum `200` turns
- repeated board-state detection
- no meaningful change detection

If combat gets stuck or repeats forever:

- battle mode gives Blue the safety win
- tournament mode uses a health-based tiebreak
- if total health is also tied in tournament mode, unit count breaks the tie
- if that is also tied, Red wins the final tiebreak

These are implementation safety fallbacks, not the intended normal result path.

## Built-in starter units

The default catalog currently includes these units.

### Poison Swinger

- attack: `2`
- health: `5`
- icon: `beast`
- attack pattern: `Swinger`
- on-hit: `Poison 1`

### Summoner Support

- attack: `1`
- health: `4`
- icon: `banner`
- attack pattern: `Front`
- skill: `Heal 2 adjacent allies`
- passive: `Summoner 2`

### Stun Cleaver

- attack: `3`
- health: `4`
- icon: `ranged`
- attack pattern: `Cleave`
- on-hit: `Stun 1`

### Taunt Tank

- attack: `2`
- health: `8`
- icon: `soldier`
- attack pattern: `Front`
- skill: `Buff Attack 1 adjacent allies`
- passives:
  - `Taunt adjacent allies`
  - `Rage 1`

## State model summary

At runtime, the important combat values per unit are:

- position: `row`, `column`
- `currentHealth`
- `currentAttack`
- `pendingHealthDelta`
- `pendingAttackDelta`
- `pendingKnockbackNet`
- `pendingFireStacks`
- `pendingPoisonStacks`
- `pendingStunTurns`
- active `fireStacks`
- active `poisonStacks`
- `stunTurnsRemaining`
- `damageTakenThisTurn`

The battle UI and snapshots only show post-cleanup state.

Pending effects are internal simulator state and are cleared after each cleanup.

## Design principles this spec preserves

- simultaneous commitment, delayed resolution
- buffs affect future turns only
- dead units still finish the turn they already committed to
- attacker and defender are asymmetric
- movement happens after cleanup, not before
- board size can change, but combat timing stays the same

## Planned rarity tiers

Units can have one of 4 rarities:

- `Common`
- `Rare`
- `Epic`
- `Legendary`

Suggested use:

- `Common`: simple stats and 1 skill
- `Rare`: stronger numbers or 2 simple skills
- `Epic`: more specialized builds and stronger synergies
- `Legendary`: unique battle-defining units

## Planned example unit roster

### Common

#### Sentry

- Rarity: `Common`
- Attack: `2`
- Health: `6`
- Skills:
  - `Knock Back 1 front enemy`

Role:

- simple frontline control unit

#### Ember Acolyte

- Rarity: `Common`
- Attack: `2`
- Health: `4`
- Skills:
  - `Fire 5 front enemy`

Role:

- early damage-over-time caster

#### Grave Whisperer

- Rarity: `Common`
- Attack: `1`
- Health: `5`
- Skills:
  - `Heal 2 front ally`

Role:

- simple support that upgrades into priest or summoner paths

### Rare

#### Shield Bearer

- Rarity: `Rare`
- Attack: `3`
- Health: `8`
- Skills:
  - `Taunt adjacent allies`
  - `Knock Back 1 front enemy`

Role:

- protector tank

#### Duel Marshal

- Rarity: `Rare`
- Attack: `4`
- Health: `5`
- Skills:
  - `Opportunity Attack adjacent allies`

Role:

- punish enemies for hitting your frontline

#### Fire Disciple

- Rarity: `Rare`
- Attack: `3`
- Health: `5`
- Skills:
  - `Fire 5 first enemy row`

Role:

- backline burn caster

#### Plague Keeper

- Rarity: `Rare`
- Attack: `2`
- Health: `6`
- Skills:
  - `Swinger`
  - `Poison 1`

Role:

- attrition specialist

#### Spirit Caller

- Rarity: `Rare`
- Attack: `2`
- Health: `5`
- Skills:
  - `Summoner 1 fallen allies`

Role:

- first revive unit

### Epic

#### Bastion Warden

- Rarity: `Epic`
- Attack: `4`
- Health: `11`
- Skills:
  - `Taunt adjacent allies`
  - `Knock Back 2 front enemy`

Role:

- elite tank wall

#### Counterblade

- Rarity: `Epic`
- Attack: `5`
- Health: `7`
- Skills:
  - `Opportunity Attack adjacent allies`
  - `Rage 1 self`

Role:

- snowball fighter

#### Inferno Priest

- Rarity: `Epic`
- Attack: `4`
- Health: `6`
- Skills:
  - `Fire 5 first enemy row`
  - `Buff 1 adjacent allies`

Role:

- offensive support mage

#### Death Shepherd

- Rarity: `Epic`
- Attack: `3`
- Health: `7`
- Skills:
  - `Summoner 2 fallen allies`
  - `Heal 2 adjacent allies`

Role:

- sustain and resurrection support

### Legendary

#### Iron Colossus

- Rarity: `Legendary`
- Attack: `6`
- Health: `15`
- Skills:
  - `Taunt all allies next to me`
  - `Knock Back 2 front enemy`
  - `Explosive adjacent enemies`

Role:

- ultimate frontline anchor

#### Phoenix Saint

- Rarity: `Legendary`
- Attack: `5`
- Health: `8`
- Skills:
  - `Fire 5 first enemy row`
  - `Heal 3 adjacent allies`
  - `Summoner 2 fallen allies`

Role:

- late-game revival and burn engine

#### Venom Tyrant

- Rarity: `Legendary`
- Attack: `5`
- Health: `10`
- Skills:
  - `Cleave`
  - `Poison 1`
  - `Stun 1 front enemy`

Role:

- control finisher

## Planned example upgrade trees

Units upgrade only if they survive a battle.

Suggested progression:

- `Common -> Rare`
- `Rare -> Epic`
- `Epic -> Legendary`

Each upgrade should replace the old unit with a new node in the tree.

### Tree 1: Frontline control path

```text
Sentry (Common)
|- Shield Bearer (Rare)
|  `- Bastion Warden (Epic)
|     `- Iron Colossus (Legendary)
`- Duel Marshal (Rare)
   `- Counterblade (Epic)
      `- Iron Colossus (Legendary)
```

Theme:

- protection
- knockback
- counterattacks

### Tree 2: Fire and support path

```text
Ember Acolyte (Common)
`- Fire Disciple (Rare)
   `- Inferno Priest (Epic)
      `- Phoenix Saint (Legendary)
```

Theme:

- burn
- support buffs
- resurrection

### Tree 3: Death and attrition path

```text
Grave Whisperer (Common)
|- Spirit Caller (Rare)
|  `- Death Shepherd (Epic)
|     `- Phoenix Saint (Legendary)
`- Plague Keeper (Rare)
   `- Venom Tyrant (Legendary)
```

Theme:

- healing
- poison
- revives

## Planned implementation notes

- `Explosive` needs exact timing and target rules
- `Opportunity Attack` needs exact trigger timing and retaliation targeting
- rarity can be added directly to the unit definition and shown on the card border
- the upgrade tree can be stored as edges:
  - `fromUnitId`
  - `toUnitId`
  - optional `choiceGroup`

## Suggested next implementation order

1. Add `rarity` to unit definitions and cards
2. Add `Explosive`
3. Add `Opportunity Attack`
4. Add unit upgrade tree data
