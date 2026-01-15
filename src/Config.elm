module Config exposing
    ( Config
    , KurveConfig
    , SpawnConfig
    , WorldConfig
    , default
    )

import Holes exposing (HoleConfig(..))
import Types.Distance exposing (Distance(..))
import Types.Radius exposing (Radius(..))
import Types.Speed exposing (Speed(..))
import Types.Tickrate exposing (Tickrate(..))


default : Config
default =
    { kurves =
        { tickrate = Tickrate 60
        , turningRadius = Radius 28.5
        , speed = Speed 60
        , holes =
            UseRandomHoles
                { minInterval = Distance 90
                , maxInterval = Distance 300
                , minSize = Distance 5
                , maxSize = Distance 9
                }
        }
    , spawn =
        { margin = 100 -- The minimum distance from the wall that a Kurve can spawn.
        , desiredMinimumDistanceTurningRadiusFactor = 1
        , protectionAudacity = 0.25 -- Closer to 1 ⇔ less risk of spawn kills but higher risk of no solution
        , flickerTicksPerSecond = 20 -- At each tick, the spawning Kurve is toggled between visible and invisible.
        , numberOfFlickerTicks = 5
        , angleInterval = ( 0, pi )
        }
    , world =
        { width = 559
        , height = 480
        }
    , replay =
        { skipStepInMs = 5000
        }
    }


type alias Config =
    { kurves : KurveConfig
    , spawn : SpawnConfig
    , world : WorldConfig
    , replay : ReplayConfig
    }


type alias KurveConfig =
    { tickrate : Tickrate
    , speed : Speed
    , turningRadius : Radius
    , holes : HoleConfig
    }


type alias SpawnConfig =
    { margin : Float
    , desiredMinimumDistanceTurningRadiusFactor : Float
    , protectionAudacity : Float
    , flickerTicksPerSecond : Float
    , numberOfFlickerTicks : Int
    , angleInterval : ( Float, Float )
    }


type alias WorldConfig =
    { width : Int
    , height : Int
    }


type alias ReplayConfig =
    { skipStepInMs : Int
    }
