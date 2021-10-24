module Config exposing (..)

import Set exposing (Set)
import Types.Angle exposing (Angle(..))
import Types.Radius exposing (Radius(..))
import Types.Speed exposing (Speed(..))
import Types.Thickness exposing (Thickness(..))
import Types.Tickrate exposing (Tickrate(..))


type alias PlayerConfig =
    { color : String
    , controls : ( Set String, Set String )
    }


tickrate : Tickrate
tickrate =
    Tickrate 60


turningRadius : Radius
turningRadius =
    Radius 28.5


speed : Speed
speed =
    Speed 60


thickness : Thickness
thickness =
    Thickness 3


{-| The minimum distance from the wall that a player can spawn.
-}
spawnMargin : Float
spawnMargin =
    100


worldWidth : Int
worldWidth =
    559


worldHeight : Int
worldHeight =
    480


players : List PlayerConfig
players =
    [ { color = "red"
      , controls = ( Set.fromList [ "1" ], Set.fromList [ "q" ] )
      }
    , { color = "green"
      , controls = ( Set.fromList [ "ArrowLeft" ], Set.fromList [ "ArrowDown" ] )
      }
    ]
