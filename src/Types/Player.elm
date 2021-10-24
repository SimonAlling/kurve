module Types.Player exposing (Player, Status(..))

import Config
import Set exposing (Set(..))
import Types.Angle exposing (Angle(..))
import World exposing (Position)


type alias Player =
    { config : Config.PlayerConfig
    , position : Position
    , direction : Angle
    , status : Status
    }


type Status
    = Alive
    | Dead
