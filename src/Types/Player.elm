module Types.Player exposing (Fate(..), HoleStatus(..), Player)

import Config
import Random
import Set exposing (Set(..))
import Types.Angle exposing (Angle(..))
import World exposing (Position)


type alias Player =
    { config : Config.PlayerConfig
    , position : Position
    , direction : Angle
    , holeStatus : HoleStatus
    , holeSeed : Random.Seed
    }


type Fate
    = Lives
    | Dies


{-| In both cases, the integer represent the number of ticks left in the current state.
-}
type HoleStatus
    = Unholy Int
    | Holy Int
