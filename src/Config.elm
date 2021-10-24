module Config exposing (..)

import Types.Angle exposing (Angle(..))
import Types.Radius exposing (Radius(..))
import Types.Speed exposing (Speed(..))
import Types.Thickness exposing (Thickness(..))
import Types.Tickrate exposing (Tickrate(..))


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
