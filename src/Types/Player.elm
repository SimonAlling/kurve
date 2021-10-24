module Types.Player exposing (Fate(..), Player)

import Set exposing (Set(..))
import Types.Angle exposing (Angle(..))
import World exposing (Position)


type alias Player =
    { color : String
    , controls : ( Set String, Set String )
    , position : Position
    , direction : Angle
    , fate : Fate
    }


type Fate
    = Lives
    | Dies
