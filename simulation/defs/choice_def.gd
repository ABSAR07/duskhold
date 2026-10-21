class_name ChoiceDef
extends Resource
## One card of a branching choice (BLDG-05, D-02, D-05). Any building tier may carry a list of
## these in BuildingTierDef.choices: the player buys the tier with exactly one of them and the pick
## is permanent for the run. The castle's tier II is the first user; Phase 6 (tower
## specialisations) and Phase 7 (unit choices) add more. Data only: the card's effect is a list of
## stat modifiers that ChoiceLedger hands to the StatStack under this card's id, so what a card says
## is what the game applies.

## Unique among every card of the map; it is the StatStack source id and what a BuildIntent carries.
@export var id: StringName = &""
## The card's name, e.g. "Royal Training".
@export var display_name: String = ""
## One short flavour line (at most 70 characters).
@export var flavour: String = ""
## The card's icon; null draws an empty icon slot (the icons arrive in plan 05-04).
@export var icon: Texture2D
## What the card does, as stat modifiers (flat, percent and multiplier buckets, META-08).
@export var modifiers: Array[StatModifierDef] = []
