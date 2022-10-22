module Types.Player exposing (Fate(..), HoleStatus(..), Player)

import Config
import Set exposing (Set(..))
import Types.Angle exposing (Angle(..))
import World exposing (Position)


type alias Player =
    { config : Config.PlayerConfig
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
