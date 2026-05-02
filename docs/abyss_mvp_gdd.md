# Abyss MVP Game Design Document

Status: Draft 0.1  
Scope: MVP-first, web-first, app-friendly later

## 1. Product Frame

### High concept

`Abyss` is a persistent strategy game where each player rules a single city on the rim of a giant shared abyss. The city cannot thrive on local land alone. Instead, players build an extraction-and-war machine around one dangerous truth: the abyss is the only path to growth.

Players gather resources from abyss expeditions, expand their city in real time, recruit units from specialized buildings, and tune lineups for two connected goals:

- survive deeper PvE expeditions into the abyss
- compete in opt-in PvP tournaments that reward prestige and social status

### Player fantasy

The player should feel like a pragmatic frontier ruler making hard tradeoffs at the edge of something vast and hostile:

- turn dangerous abyss harvests into a functioning city
- choose what to build now versus what to unlock later
- assemble efficient squads instead of simply building the biggest army
- use smart roster design to win tournaments without risking the city itself

### Target platforms

- MVP target: web
- Later target: mobile app using the same live game backend and account

### Genre statement

`Abyss` is a real-time city builder and asynchronous squad strategy game with:

- persistent base progression
- timer-based economy and recruitment
- auto-battle resolution
- PvE-first resource extraction
- instanced tournament PvP

### Core pillars

1. `Build the city`
   Real-time building, storage, queue, and unlock decisions should matter every day.

2. `Harvest the abyss`
   The abyss is the primary source of progression, risk, and pacing pressure. Players should need it, not merely visit it.

3. `Optimize armies for expeditions and tournaments`
   Combat should reward composition, counterplay, and synergies more than raw unit count.

### Reference lens

The game should borrow selectively from these references without cloning any one of them:

- [Ikariam](https://gameforge.com/da-DK/games/ikariam-ressourcer.html): persistent city growth, timed upgrades, macro pressure
- [Travian](https://support.travian.com/en/support/solutions/articles/7000060369): build queues, military production, long-horizon planning
- [Hearthstone Battlegrounds](https://news.blizzard.com/en-us/hearthstone/23193647/battlegrounds-early-access-now-live): readable auto-battle outcomes, composition identity, low-input combat payoff
- [Super Auto Pets](https://store.steampowered.com/app/1714040/Super_Auto_Pets/): roster clarity, async-friendly battles, strong unit roles

The intended blend is:

- economy and timers from city builders
- squad clarity and synergy from auto-battlers
- PvE-first progression with optional PvP prestige

## 2. Current Prototype

This section describes what exists in the repository today so the GDD stays anchored to reality.

### Implemented now

- A playable Flutter battle prototype exists under `battle simulation/`.
- The app opens on a battle setup flow rather than a city screen.
- Players can choose between `Battle` mode and `Tournament` mode before starting a run.
- Players can choose board presets and deploy unit formations on a grid.
- Battles resolve automatically and can be replayed through a timeline view.
- A shared unit catalog exists, with unit browsing and unit editing flows.
- The web build is already wired for Firebase-backed data where needed.
- The canonical combat rules live in [battle_logic.md](battle_logic.md).

### Current battle capabilities

The prototype already supports:

- grid-based auto-battle resolution
- attacker/defender battle mode
- symmetric tournament mode
- unit attack patterns
- targeted skills
- on-hit effects
- passive skills
- turn cleanup timing
- replay snapshots and autoplay

### Current product truth

Today the project is best understood as:

- a combat sandbox
- a unit catalog/editor
- a battle replay tool

It is not yet:

- a persistent city game
- an abyss expedition game
- a live PvP service
- a progression economy

## 3. Core Loop And Player Timeline

### MVP core loop

The main progression loop is:

1. collect passive city output and finished jobs
2. spend `Wood`, `Steel`, and `Dark Crystal` on upgrades and recruits while keeping `Water` income above upkeep
3. form one or more expedition squads
4. send squads into abyss nodes with chosen risk and duration
5. receive resources, wounds, losses, and unlock progress from the results
6. use those gains to push the city and roster forward
7. optionally enter tournament runs for prestige and side rewards

### First 10 minutes

The first session should let the player:

- claim the starting city
- repair or place the first economy buildings
- recruit a first basic squad
- launch a short beginner expedition
- watch at least one resolved battle outcome
- return with enough reward to start a meaningful upgrade

### First day

By the end of the first day, the player should understand these repeating decisions:

- which building finishes next
- whether to invest in storage, military, or research
- which unit mix is best for current abyss enemies
- whether to run safe farming expeditions or deeper risky ones
- whether to spend scarce `Dark Crystal` on long-term progression or magical power spikes

### First week

By the end of the first week, the player should have:

- a recognizable city specialization
- several unit archetypes unlocked
- access to deeper abyss bands with better rewards
- a reason to care about tournament participation
- a clear medium-term goal, such as a city tier unlock or a signature squad composition

## 4. World Model

### MVP structure

- Every player owns one persistent city.
- All cities exist around the rim of one giant shared abyss.
- The shared world should be visible in presentation and fiction, but MVP gameplay does not require open-world marching between cities.
- In MVP, the abyss is the main interaction surface. Direct city-vs-city warfare is not.

### Why this structure

This keeps the first version focused on:

- persistent progression
- readable pacing
- economy balance
- combat composition

without forcing the project to also solve:

- territory conquest
- multi-city logistics
- alliance warfare
- city destruction recovery

## 5. Locked System Definitions

### City

A `City` is the player's single persistent hub. It contains:

- building slots
- one construction queue for MVP
- one research queue for MVP
- storage caps
- population support pressure
- recruitment capacity
- expedition slots
- progression gates tied to city tier

### Resource

Each `Resource` must clearly answer:

- where it comes from
- what spends it
- how storage works
- whether it is generated in the city, the abyss, or both

#### MVP resources

| Resource | Main sources | Main sinks | Storage rule | Source type |
| --- | --- | --- | --- | --- |
| `Water` | abyss expeditions, small passive output from `Pump` | passive population upkeep, passive army upkeep, `Forest` conversion jobs | capped by `Cistern` | both |
| `Wood` | `Forest` conversion from `Water`, small abyss finds | early and mid-tier buildings, basic units, structural upgrades | capped by `Warehouse` | both |
| `Steel` | abyss expeditions | advanced buildings, armored units, city tier gates | capped by `Warehouse` | abyss |
| `Dark Crystal` | small abyss drops, PvE boss victories | special units, magical research, and other magical systems | intentionally scarce, with no large passive source in MVP | abyss |

### Building

A `Building` must answer:

- what it costs
- what it unlocks
- what timer it uses
- whether it produces, converts, recruits, stores, or upgrades

#### MVP building set

| Building | Role | Main function | Timer model | Unlock pressure |
| --- | --- | --- | --- | --- |
| `Pump` | production | extracts a small passive trickle of `Water` outside the abyss | passive timed output | emergency baseline economy |
| `Forest` | conversion | converts `Water` into `Wood` over time | job queue | building supply stability |
| `Cistern` | storage | raises `Water` cap | upgrade timer | prevents overflow and drought stalls |
| `Warehouse` | storage | raises `Wood` and `Steel` caps | upgrade timer | enables larger upgrades and military spends |
| `Barracks` | recruit | trains frontline units | recruit queue | military breadth |
| `Workshop` | recruit | trains ranged, support, and specialist units | recruit queue | roster complexity |
| `Infirmary` | recovery | reduces recovery time and permanent losses | passive plus upgrade timer | expedition resilience |
| `Academy` | research | unlocks new units, magical research, and city tier gates | research queue | long-term progression |
| `Abyss Gate` | expedition | unlocks deeper expeditions and more active squad slots | upgrade timer | PvE advancement |

### Unit

A `Unit` must map to:

- a source building
- a battlefield role
- a recruitment cost
- a recruit time
- an expedition value
- any upkeep or recovery interaction

#### MVP unit role families

- `Frontline`: durable units that hold formation and buy time
- `Striker`: efficient damage dealers for common farming runs
- `Support`: healers, buffers, and utility units that improve consistency
- `Control`: stun, knockback, poison, or positioning pressure
- `Breaker`: expensive units tuned for elite encounters or tournaments

### Abyss Expedition

An `Abyss Expedition` is the main PvE job loop. It defines:

- a chosen squad
- a target node or depth band
- a duration
- one resolved battle sequence
- a reward bundle
- a loss outcome

### Tournament Run

A `Tournament Run` is an opt-in PvP activity. It defines:

- an entry cost
- a locked roster snapshot for the run
- matchmaking into an instanced bracket or ladder set
- battle resolution without city damage
- prestige-first rewards that do not replace abyss progression

### Progression

`Progression` advances through more than raw resources. MVP progression tracks are:

- city tier
- academy research
- abyss depth access
- unit roster breadth
- tournament prestige

## 6. City Economy

### Pacing goals

The city layer should create decisions across short, medium, and long time scales:

- short: what to collect, queue, or launch right now
- medium: which building branch or squad archetype to favor this week
- long: how the city specializes around economy stability, deep expeditions, or tournament strength

### MVP economy rules

- One construction queue keeps upgrade choices meaningful.
- One research queue creates intentional long-term prioritization.
- Recruitment has its own queue, so players can still prepare squads while buildings upgrade.
- `Water` is not a building cost in MVP. It is a continuous upkeep resource that sustains population and army strength.
- Passive city generation should be helpful but never enough to replace abyss expeditions, especially for `Water` and `Steel`.
- Storage caps should regularly matter so upgrading storage feels necessary, not decorative.
- The city should mostly process and stabilize the economy, while the abyss remains the main source of `Water`, all meaningful `Steel`, and scarce `Dark Crystal`.

### Daily city decisions

The minimum daily decision set should be:

- which building or storage upgrade to queue next
- whether to spend on recruits or economy first
- whether current `Water` income can safely support population, army upkeep, and `Forest` conversion
- which research unlock is worth delaying another
- which squad should occupy limited expedition slots
- whether to spend scarce `Dark Crystal` on magical power, magical research, or to save it for later unlocks

### What the city should not become in MVP

- no multi-city empire management
- no complex worker assignment screen
- no deep market simulation
- no alliance-owned structures
- no city destruction from PvP losses

## 7. Abyss PvE

### Purpose of the abyss

The abyss is the main content engine of the game. It must provide:

- the most important resources
- risk/reward decisions
- enemy variety
- progression gates
- the thematic identity of the game

### MVP expedition flow

1. player chooses an expedition slot
2. player selects a target node or depth band
3. player assigns a squad from available units
4. the squad is committed for the duration
5. the encounter resolves automatically
6. rewards and losses are returned when the timer completes

### Depth model

MVP should use simple depth bands instead of a giant freeform map:

- `Outer Rim`
  short timers, safe fights, mostly `Water` and small `Wood` finds
- `Fracture Zone`
  mixed enemies, better `Steel` yields and steadier `Water`
- `Deep Chasm`
  stronger compositions, first meaningful `Dark Crystal`
- `Ancient Core`
  elite risk, boss-heavy encounters, best `Dark Crystal` odds, late-MVP aspiration

This keeps the shared world fantasy intact while minimizing navigation complexity.

### Encounter resolution

- Expeditions resolve through the existing auto-battle model.
- PvE enemy squads are authored encounter templates, not player-built armies.
- Node identity comes from enemy composition, modifiers, and reward tables.
- Higher depth means harder battles, longer timers, and better reward efficiency.

### Loss rules

MVP losses should create tension without deleting weeks of progress:

- surviving units return immediately or after a short travel delay
- defeated units enter recovery in the `Infirmary`
- some failed runs lose part of the expected haul
- full squad wipes may destroy a portion of the committed units, but should be rare and readable

The player should fear a bad run, but not quit after one.

### Reward bundles

Each expedition should grant some mix of:

- `Water`
- `Wood`
- `Steel`
- `Dark Crystal`
- depth progress
- research fragments or one-off unlock items later in the roadmap

### Decision the abyss creates

The player is always deciding between:

- short safe runs versus deep risky runs
- consistent farming versus unlock chasing
- broad roster reliability versus narrow specialist power

## 8. Combat And Tournament PvP

### Combat model for MVP

Combat should continue to use the current battle simulator as the starting ruleset:

- turn-based resolution on a grid
- composition-driven outcomes
- clear skill and pattern identity
- replayable results

For MVP, combat appears in two contexts.

### Context 1: Abyss PvE encounters

- The player attacks authored abyss squads.
- PvE battle outcomes directly affect city progression.
- Losses apply recovery or partial attrition rules.
- Battle readability matters more than high-action animation.

### Context 2: Tournament PvP

- Tournament PvP is separate from city progression pressure.
- Players submit a roster snapshot for a run.
- Matches are instanced and asynchronous.
- Tournament losses do not damage buildings or steal city resources.
- Rewards should be prestige-forward and should never become the main source of core resources or `Dark Crystal`.

### Tournament run structure

The MVP tournament loop should be:

1. pay an entry cost in tickets or a dedicated tournament currency
2. lock a squad or small roster set for the run
3. play through a short async bracket or a limited match card
4. receive rewards based on wins reached
5. re-enter with changes after the run ends

### Why tournaments stay separate

This lets PvP add excitement and social comparison without forcing the city layer to absorb:

- raid protection rules
- offline defense abuse
- grief-heavy progression losses
- alliance escalation systems

## 9. Progression And Session Cadence

### Primary progression tracks

- `City Tier`
  unlocked through key building levels and research milestones
- `Academy Research`
  unlocks new units, better processing, magical options, and depth access
- `Abyss Depth`
  opens stronger nodes and better rewards
- `Roster Development`
  expands what squad archetypes the player can field
- `Tournament Prestige`
  signals mastery and awards status-driven bonuses

### Session cadence goals

The game should support:

- short check-ins to collect, queue, and launch
- medium sessions to review squads and watch important results
- longer sessions for tournament preparation, roster updates, and progression planning

### Web-first UX implications

- important actions should work well in brief browser sessions
- timers and finished jobs should be legible without excessive navigation
- battle replays should be optional and fast to parse
- mobile support later should inherit the same async-friendly loop rather than require real-time input

## 10. MVP Boundaries, Later Roadmap, And Out Of Scope

### Explicit MVP boundaries

- one city per player
- PvE-first progression
- instanced tournament PvP
- authored abyss encounters
- no alliance warfare
- no direct city raiding
- no open-world marching between players

### Later roadmap candidates

- alliances and shared faction goals
- a richer world map around the abyss
- multi-city expansion
- trading or market systems
- co-op abyss events
- seasonal tournament formats
- rarer abyss bosses with server-wide participation

### Out of scope for the first GDD draft

- detailed monetization design
- full narrative script
- alliance diplomacy rules
- territory capture simulation
- app-specific UX flows beyond responsive support assumptions

## 11. GDD Validation Checklist

This draft is only useful if a new reader can answer these questions quickly:

- What does the player do in the first 10 minutes, first day, and first week?
- Why is the abyss necessary for progression?
- How do resources enter and leave the economy?
- What happens when an expedition fails?
- What does a tournament win provide?
- How does combat feed back into city growth?
- Which parts exist today and which parts are still planned?

If a future section adds flavor but does not create a player decision, it should be cut or reframed.
