# Unit Skills And Upgrade Tree Draft

This document is a design draft for the next version of the unit system.

It describes:

- the skill grammar
- the target grammar
- rarity tiers
- example units
- example upgrade trees

This is not a full implementation spec yet. It is a roster and progression draft to guide future work.

## Core unit formula

Each unit has:

- `name`
- `icon`
- `rarity`
- `attack`
- `health`
- `basic attack`
- `skills`

Basic attack is always:

- `Deal [attack] to front enemy`

The basic attack is implicit and does not need to be written on the card.

## Skill grammar

There are 4 skill formats.

### 1. Numbered targeted skills

- `(skill) + (number) + (target)`

Examples:

- `Knock Back 2 front enemies`
- `Heal 3 adjacent allies`
- `Buff 2 ally in front`
- `Fire 5 first enemy row`

Some skills use the number in a special way:

- `Knock Back 2`: push up to 2 squares
- `Stun 1`: skip 1 turn
- `Summoner 2`: summon up to 2 fallen allies over the battle

### 2. Keyword targeted skills

- `(skill) + (target)`

Examples:

- `Explosive adjacent enemies`
- `Taunt adjacent allies`
- `Opportunity Attack adjacent allies`

These skills do not have a numeric parameter.

### 3. Attack keywords

- `(attack keyword)`

These skills do not choose a separate target. They change what the unit's basic attack hits.

Examples:

- `Piercer`
- `Cleave`
- `Swinger`
- `Volley`
- `Longshot`

### 4. On-hit riders

- `(skill) + (number)`

These skills are added to every target hit by the unit's current attack pattern.

Examples:

- `Poison 1`
- `Fire 5`
- `Stun 1`
- `Knock Back 1`

Example combo:

- `Cleave + Poison 1`

Meaning:

- the unit's attack hits the `Cleave` pattern
- every enemy hit by that attack also gets `Poison 1`

## Target grammar

Target format:

- `(enemies | allies) + (squares)`

Some target phrases are positional keywords instead of a full `side + squares` formula.

Examples:

- `front enemy`
- `front ally`
- `adjacent enemies`
- `adjacent allies`
- `allies behind me`
- `enemies behind me`
- `first enemy row`
- `same column enemies`
- `back row enemies`
- `all allies next to me`

Suggested target library:

- `front enemy`
- `front ally`
- `adjacent enemies`
- `adjacent allies`
- `all allies next to me`
- `allies behind me`
- `enemies behind me`
- `first enemy row`
- `same column enemies`
- `back row enemies`
- `front row allies`
- `front row enemies`
- `weakest ally`
- `strongest ally`
- `fallen allies`

## Attack keywords

Attack keywords modify the built-in basic attack.

Default basic attack:

- `Deal [attack] to front enemy`

If a unit has an attack keyword, that keyword changes the hit pattern.

### Piercer

- hit `2` enemies in front
- same column
- first target and the next enemy behind it

### Cleave

- hit the front enemy and the enemies directly left and right of that target

### Swinger

- hit all adjacent (8) enemies

### Volley

- hit all enemies in the first row ahead

### Snipe
- hit the farthest enemy in the column

### Longshot

- skip the front square and hit the first enemy `2` squares ahead

## On-hit riders

On-hit riders are added to every target hit by the attack pattern.

Example:

- `Cleave + Poison 1`

Meaning:

- the unit attacks `3` enemies in front
- each enemy hit gets poison applied

Another example:

- `Piercer + Knock Back 1`

Meaning:

- the unit attacks `2` enemies in front
- each enemy hit is pushed back up to `1` square

Suggested rider list:

- `Poison [number]`
- `Fire [number]`
- `Stun [number]`
- `Knock Back [number]`
- `Debuff [number]`

## Skill list

### Explosive

- `Explosive [target]`
- When this unit dies, deal `[attack x 2]` damage to the target

Example:

- `Explosive adjacent enemies`

Meaning:

- on death, deal `attack x 2` damage to all adjacent enemies

### Knock Back

- `Knock Back [number] [target]`
- On hit, push the target away up to `[number]` squares
- Happens in cleanup
- Happens before advancing
- A knocked target cannot advance in that same turn

This can also be used as an on-hit rider:

- `Knock Back [number]`
- applies to every unit hit by the current attack pattern

### Taunt

- `Taunt [target]`
- This unit takes damage instead of the target allies

Example:

- `Taunt adjacent allies`

Meaning:

- damage aimed at adjacent allies is redirected to this unit

### Opportunity Attack

- `Opportunity Attack [target]`
- When target allies get hit, this unit hits back

Example:

- `Opportunity Attack adjacent allies`

Meaning:

- when adjacent allies are hit, this unit hits back at the attacker

### Stun

- `Stun [number] [target]`
- Target loses its next `[number]` turns

This can also be used as an on-hit rider:

- `Stun [number]`
- every unit hit by the current attack pattern is stunned

Example:

- `Stun 1 front enemy`

### Buff

- `Buff [number] [target]`
- Give a positive stat bonus to the target

Suggested v1 buff types:

- `+attack`
- `+health`
- `+shield`

Example:

- `Buff 2 front ally`

### Debuff

- `Debuff [number] [target]`
- Apply a negative stat modifier to the target

Suggested v1 debuff types:

- `-attack`
- `-health`
- `-movement`

This can also be used as an on-hit rider.

Example:

- `Debuff 1 first enemy row`

### Heal

- `Heal [number] [target]`
- Restore health in cleanup

Example:

- `Heal 3 adjacent allies`

### Fire

- `Fire [number] [target]`
- Apply decreasing damage over time
- Example sequence: `5 -> 4 -> 3 -> 2 -> 1`

Example:

- `Fire 5 front enemy`

This can also be used as an on-hit rider:

- `Fire 5`
- every target hit by the attack receives the burning sequence

### Poison

- `Poison [number] [target]`
- Apply increasing damage over time
- Example sequence: `1 -> 2 -> 3 -> 4 -> 5`

Example:

- `Poison 1 front enemy`

On-hit reading:

- `Poison 1`
- add increasing damage on hit to every target hit by the current attack pattern

### Summoner

- `Summoner [number] [target]`
- When allies die, summon them back
- Up to `[number]` fallen allies

Example:

- `Summoner 2 fallen allies`

Meaning:

- over the battle, this unit can bring back up to 2 defeated allies

### Rage

- `Rage [number] [target]`
- Gain power when the target condition is met

Suggested v1 interpretation:

- when this unit takes damage, gain `+[number] attack`

Example:

- `Rage 1 self`

## Rarity tiers

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

## Example unit roster

## Common

### Sentry

- Rarity: `Common`
- Attack: `2`
- Health: `6`
- Skills:
  - `Knock Back 1 front enemy`

Role:

- simple frontline control unit

### Ember Acolyte

- Rarity: `Common`
- Attack: `2`
- Health: `4`
- Skills:
  - `Fire 5 front enemy`

Role:

- early damage-over-time caster

### Grave Whisperer

- Rarity: `Common`
- Attack: `1`
- Health: `5`
- Skills:
  - `Heal 2 front ally`

Role:

- simple support that upgrades into priest or summoner paths

## Rare

### Shield Bearer

- Rarity: `Rare`
- Attack: `3`
- Health: `8`
- Skills:
  - `Taunt adjacent allies`
  - `Knock Back 1 front enemy`

Role:

- protector tank

### Duel Marshal

- Rarity: `Rare`
- Attack: `4`
- Health: `5`
- Skills:
  - `Opportunity Attack adjacent allies`

Role:

- punish enemies for hitting your frontline

### Fire Disciple

- Rarity: `Rare`
- Attack: `3`
- Health: `5`
- Skills:
  - `Fire 5 first enemy row`

Role:

- backline burn caster

### Plague Keeper

- Rarity: `Rare`
- Attack: `2`
- Health: `6`
- Skills:
  - `Swinger`
  - `Poison 1`

Role:

- attrition specialist

### Spirit Caller

- Rarity: `Rare`
- Attack: `2`
- Health: `5`
- Skills:
  - `Summoner 1 fallen allies`

Role:

- first revive unit

## Epic

### Bastion Warden

- Rarity: `Epic`
- Attack: `4`
- Health: `11`
- Skills:
  - `Taunt adjacent allies`
  - `Knock Back 2 front enemy`

Role:

- elite tank wall

### Counterblade

- Rarity: `Epic`
- Attack: `5`
- Health: `7`
- Skills:
  - `Opportunity Attack adjacent allies`
  - `Rage 1 self`

Role:

- snowball fighter

### Inferno Priest

- Rarity: `Epic`
- Attack: `4`
- Health: `6`
- Skills:
  - `Fire 5 first enemy row`
  - `Buff 1 adjacent allies`

Role:

- offensive support mage

### Death Shepherd

- Rarity: `Epic`
- Attack: `3`
- Health: `7`
- Skills:
  - `Summoner 2 fallen allies`
  - `Heal 2 adjacent allies`

Role:

- sustain and resurrection support

## Legendary

### Iron Colossus

- Rarity: `Legendary`
- Attack: `6`
- Health: `15`
- Skills:
  - `Taunt all allies next to me`
  - `Knock Back 2 front enemy`
  - `Explosive adjacent enemies`

Role:

- ultimate frontline anchor

### Phoenix Saint

- Rarity: `Legendary`
- Attack: `5`
- Health: `8`
- Skills:
  - `Fire 5 first enemy row`
  - `Heal 3 adjacent allies`
  - `Summoner 2 fallen allies`

Role:

- late-game revival and burn engine

### Venom Tyrant

- Rarity: `Legendary`
- Attack: `5`
- Health: `10`
- Skills:
  - `Cleave`
  - `Poison 1`
  - `Stun 1 front enemy`

Role:

- control finisher

## Example upgrade trees

Units upgrade only if they survive a battle.

Suggested progression:

- `Common -> Rare`
- `Rare -> Epic`
- `Epic -> Legendary`

Each upgrade should replace the old unit with a new node in the tree.

## Tree 1: Frontline control path

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

## Tree 2: Fire and support path

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

## Tree 3: Death and attrition path

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

## Notes for future implementation

- `Explosive`, `Opportunity Attack`, `Stun`, `Fire`, `Poison`, `Summoner`, and `Rage` need exact timing rules
- `Taunt` needs a clear interception priority when multiple taunt units can protect the same ally
- `Summoner` needs a resurrection placement rule
- `Buff` and `Debuff` should likely become typed effects, not only numeric effects
- rarity can be added directly to the unit definition and shown on the card border
- the upgrade tree can be stored as edges:
  - `fromUnitId`
  - `toUnitId`
  - optional `choiceGroup`

## Suggested next implementation order

1. Add `rarity` to unit definitions and cards
2. Add `stun`
3. Add `rage`
4. Add `taunt`
5. Add `fire` and `poison`
6. Add unit upgrade tree data
