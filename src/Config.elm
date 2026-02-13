module Config exposing
    ( Config
    , HoleConfig
    , KurveConfig
    , ReplayConfig
    , SpawnConfig
    , WorldConfig
    , default
    , getSettings
    , withEnableAlternativeControls
    , withHardcodedHoles
    , withPersistHoleStatus
    , withSettings
    , withSpawnkillProtection
    , withSpeed
    )

import Settings exposing (Settings)
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
            { minSolidTicks = 90
            , maxSolidTicks = 300
            , minHolyTicks = 7
            , maxHolyTicks = 11
            , persistBetweenRounds = Settings.default.persistHoleStatus
            }
        }
    , spawn =
        { margin = 100 -- The minimum distance from the wall that a Kurve can spawn.
        , desiredMinimumDistanceTurningRadiusFactor = 1
        , protectionAudacity = 0.25 -- Closer to 1 ⇔ less risk of spawn kills but higher risk of no solution
        , flickerFrequency = 10 -- How many times per second the spawning Kurve performs a full cycle of being visible and then invisible.
        , numberOfFlickers = 3
        , angleInterval = ( 0, pi )
        , spawnkillProtection = Settings.default.spawnkillProtection
        }
    , world =
        { width = 559
        , height = 480
        }
    , replay =
        { skipStepInMs = 5000
        }
    , enableAlternativeControls = Settings.default.enableAlternativeControls
    }


type alias Config =
    { kurves : KurveConfig
    , spawn : SpawnConfig
    , world : WorldConfig
    , replay : ReplayConfig
    , enableAlternativeControls : Bool
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
    , flickerFrequency : Float
    , numberOfFlickers : Int
    , angleInterval : ( Float, Float )
    , spawnkillProtection : Bool
    }


type alias WorldConfig =
    { width : Int
    , height : Int
    }


type alias ReplayConfig =
    { skipStepInMs : Int
    }


type alias HoleConfig =
    { minSolidTicks : Int
    , maxSolidTicks : Int
    , minHolyTicks : Int
    , maxHolyTicks : Int
    , persistBetweenRounds : Bool
    }


getSettings : Config -> Settings
getSettings config =
    { spawnkillProtection = config.spawn.spawnkillProtection
    , persistHoleStatus = config.kurves.holes.persistBetweenRounds
    , enableAlternativeControls = config.enableAlternativeControls
    }


withSettings : Settings -> Config -> Config
withSettings settings config =
    config
        |> withSpawnkillProtection settings.spawnkillProtection
        |> withPersistHoleStatus settings.persistHoleStatus
        |> withEnableAlternativeControls settings.enableAlternativeControls


withSpawnkillProtection : Bool -> Config -> Config
withSpawnkillProtection newValue config =
    let
        spawnConfig : SpawnConfig
        spawnConfig =
            config.spawn
    in
    { config | spawn = { spawnConfig | spawnkillProtection = newValue } }


withPersistHoleStatus : Bool -> Config -> Config
withPersistHoleStatus newValue config =
    let
        kurveConfig : KurveConfig
        kurveConfig =
            config.kurves

        holeConfig : HoleConfig
        holeConfig =
            kurveConfig.holes
    in
    { config | kurves = { kurveConfig | holes = { holeConfig | persistBetweenRounds = newValue } } }


withEnableAlternativeControls : Bool -> Config -> Config
withEnableAlternativeControls newValue config =
    { config | enableAlternativeControls = newValue }


withSpeed : Speed -> Config -> Config
withSpeed speed config =
    let
        kurveConfig : KurveConfig
        kurveConfig =
            config.kurves
    in
    { config
        | kurves =
            { kurveConfig
                | speed = speed
            }
    }


withHardcodedHoles : Int -> Int -> Config -> Config
withHardcodedHoles solidTicks holyTicks config =
    let
        defaultKurveConfig : KurveConfig
        defaultKurveConfig =
            config.kurves
    in
    { config
        | kurves =
            { defaultKurveConfig
                | holes =
                    { minSolidTicks = solidTicks
                    , maxSolidTicks = solidTicks
                    , minHolyTicks = holyTicks
                    , maxHolyTicks = holyTicks
                    , persistBetweenRounds = defaultKurveConfig.holes.persistBetweenRounds
                    }
            }
    }
