module Types.Player exposing (Fate(..), Player)

import Set exposing (Set(..))
import World exposing (Position)
import Types.Angle exposing (Angle(..))


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
