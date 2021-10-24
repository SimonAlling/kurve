module Types.Player exposing (Fate(..), Player)

import Config
import Set exposing (Set(..))
import Types.Angle exposing (Angle(..))
import World exposing (Position)


type alias Player =
    { config : Config.PlayerConfig
    , position : Position
    , direction : Angle
    , fate : Fate
    }


type Fate
    = Lives
    | Dies
