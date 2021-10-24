module Config exposing (..)

import Types.Angle exposing (Angle(..))
import Types.Radius exposing (Radius(..))
import Types.Speed exposing (Speed(..))
import Types.Thickness exposing (Thickness(..))
import Types.Tickrate exposing (Tickrate(..))


theTickrate : Tickrate
theTickrate =
    Tickrate 60


theTurningRadius : Radius
theTurningRadius =
    Radius 28.5


theSpeed : Speed
theSpeed =
    Speed 60


theThickness : Thickness
theThickness =
    Thickness 3
