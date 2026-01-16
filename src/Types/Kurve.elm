module Types.Kurve exposing
    ( Fate(..)
    , Kurve
    , State
    , UserInteraction(..)
    , modifyReversedInteractions
    , reset
    )

import Color exposing (Color)
import Holes exposing (HoleStatus)
import Set exposing (Set)
import Types.Angle exposing (Angle)
import Types.PlayerId exposing (PlayerId)
import Types.Tick exposing (Tick)
import Types.TurningState exposing (TurningState)
import World exposing (Position)


type alias Kurve =
    { color : Color
    , id : PlayerId
    , controls : ( Set String, Set String ) -- `Set` is exactly what we want here; `String` is not, but since Elm doesn't support user-defined typeclass instances, we have to make do with a type that already is `comparable`.
    , state : State
    , stateAtSpawn : State
    , reversedInteractions : List UserInteraction
    }


type UserInteraction
    = HappenedBefore Tick TurningState


modifyReversedInteractions : (List UserInteraction -> List UserInteraction) -> Kurve -> Kurve
modifyReversedInteractions f kurve =
    { kurve | reversedInteractions = f kurve.reversedInteractions }


type alias State =
    { position : Position
    , direction : Angle
    , holeStatus : HoleStatus
    }


type Fate
    = Lives
    | Dies


reset : Kurve -> Kurve
reset kurve =
    { kurve | state = kurve.stateAtSpawn }
