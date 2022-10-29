module Types.Player exposing (Fate(..), HoleStatus(..), Player)

import Color exposing (Color)
import Set exposing (Set(..))
import Types.Angle exposing (Angle(..))
import World exposing (Position)


type alias Player =
    { color : Color
    , controls : ( Set String, Set String ) -- `Set` is exactly what we want here; `String` is not, but since Elm doesn't support user-defined typeclass instances, we have to make do with a type that already is `comparable`.
    , position : Position
    , direction : Angle
    , holeStatus : HoleStatus
    }


type Fate
    = Lives
    | Dies


{-| In both cases, the integer represent the number of ticks left in the current state.
-}
type HoleStatus
    = Unholy Int
    | Holy Int
