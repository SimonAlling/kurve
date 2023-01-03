module Config exposing (Config, GameConfig, HoleConfig, KurveConfig, SpawnConfig, WorldConfig, default)

import Dict
import Players exposing (ParticipatingPlayers)
import Types.Distance exposing (Distance(..))
import Types.Radius exposing (Radius(..))
import Types.Score exposing (Score(..), isAtLeast)
import Types.Speed exposing (Speed(..))
import Types.Thickness exposing (Thickness(..))
import Types.Tickrate exposing (Tickrate(..))


default : Config
default =
    { kurves =
        { tickrate = Tickrate 60
        , turningRadius = Radius 28.5
        , speed = Speed 60
        , thickness = Thickness 3
        , holes =
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
        , angleInterval = ( -pi / 2, pi / 2 )
        }
    , world =
        { width = 559
        , height = 480
        }
    , game =
        { isGameOver = defaultGameOverCondition
        }
    }


defaultGameOverCondition : ParticipatingPlayers -> Bool
defaultGameOverCondition participatingPlayers =
    let
        numberOfPlayers : Int
        numberOfPlayers =
            Dict.size participatingPlayers

        targetScore : Score
        targetScore =
            Score ((numberOfPlayers - 1) * 10)

        someoneHasReachedTargetScore : Bool
        someoneHasReachedTargetScore =
            not <|
                Dict.isEmpty <|
                    Dict.filter (always (Tuple.second >> isAtLeast targetScore)) participatingPlayers
    in
    numberOfPlayers > 1 && someoneHasReachedTargetScore


type alias Config =
    { kurves : KurveConfig
    , spawn : SpawnConfig
    , world : WorldConfig
    , game : GameConfig
    }


type alias KurveConfig =
    { tickrate : Tickrate
    , speed : Speed
    , turningRadius : Radius
    , thickness : Thickness
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


type alias GameConfig =
    { isGameOver : ParticipatingPlayers -> Bool
    }


type alias HoleConfig =
    { minInterval : Distance
    , maxInterval : Distance
    , minSize : Distance
    , maxSize : Distance
    }
