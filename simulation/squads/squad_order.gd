class_name SquadOrder
extends RefCounted
## The vocabulary of squad commands (D-09 to D-13): the verbs a player can give and the resting
## stances a squad settles into. Only the names live here for now; the order record and its logic
## arrive with the command plan (03-06). The HUD reads these names through SquadSystem, which
## reports a squad's resting stance and the verb it is carrying out.

## Walk with the king and keep the formation around him.
const VERB_FOLLOW := &"follow"
## Stand where you are and fight what comes.
const VERB_HOLD := &"hold"
## Return to the building's post.
const VERB_RALLY := &"rally"
## Walk to a point without stopping to fight.
const VERB_MOVE := &"move"
## Walk to a point and fight what is met on the way.
const VERB_ATTACK_MOVE := &"attack_move"
## Walk a path of points back and forth, fighting.
const VERB_PATROL := &"patrol"

## Standing at the building's post, the default of a fresh squad.
const STANCE_POST := &"post"
## Resting beside the king after a follow command.
const STANCE_FOLLOW := &"follow"
## Resting where it was told to hold.
const STANCE_HOLD := &"hold"
## Resting on a patrol path.
const STANCE_PATROL := &"patrol"
