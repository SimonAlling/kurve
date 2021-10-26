module Types.Player exposing (HoleStatus(..), Player, Status(..))

import Config
import Random
import Set exposing (Set(..))
import Types.Angle exposing (Angle(..))
import World exposing (Position)


type alias Player =
    { config : Config.PlayerConfig
    , position : Position
    , direction : Angle
    , status : Status
    , holeStatus : HoleStatus
    , holeSeed : Random.Seed
    }


type Status
    = Alive
    | Dead


{-| In both cases, the integer represent the number of ticks left in the current state.
-}
type HoleStatus
    = Unholy Int
    | Holy Int
