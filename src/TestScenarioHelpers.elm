module TestScenarioHelpers exposing
    ( CumulativeInteraction
    , EffectsExpectation(..)
    , RefreshRate
    , RoundEndingInterpretation
    , RoundOutcome
    , defaultConfigWithSpeed
    , draw
    , makeUserInteractions
    , makeZombieKurve
    , playerIds
    , roundWith
    , tickNumber
    )

import Color
import Config exposing (Config, KurveConfig)
import Effect exposing (Effect)
import Random
import Round exposing (RoundInitialState)
import Set
import Types.Angle exposing (Angle(..))
import Types.Kurve as Kurve exposing (HoleStatus(..), Kurve, UserInteraction(..))
import Types.PlayerId exposing (PlayerId)
import Types.Speed exposing (Speed)
import Types.Tick as Tick exposing (Tick)
import Types.TurningState exposing (TurningState)
import World exposing (DrawingPosition)


playerIds :
    { red : PlayerId
    , yellow : PlayerId
    , orange : PlayerId
    , green : PlayerId
    , pink : PlayerId
    , blue : PlayerId
    }
playerIds =
    { red = 0
    , yellow = 1
    , orange = 2
    , green = 3
    , pink = 4
    , blue = 5
    }


{-| Creates a Kurve that just moves forward.
-}
makeZombieKurve : { color : Color.Color, id : PlayerId, state : Kurve.State } -> Kurve
makeZombieKurve { color, id, state } =
    { color = color
    , id = id
    , controls = ( Set.empty, Set.empty )
    , state = state
    , stateAtSpawn =
        { position = ( 0, 0 )
        , direction = Angle (pi / 2)
        , holeStatus = Unholy 0
        }
    , reversedInteractions = []
    }


roundWith : List Kurve -> RoundInitialState
roundWith spawnedKurves =
    { seedAfterSpawn = Random.initialSeed 0
    , spawnedKurves = spawnedKurves
    }


{-| How many ticks to wait before performing some action, and that action.

The number of ticks to wait is counted from the previous action (or, for the first action, from the beginning of the round).

-}
type alias CumulativeInteraction =
    ( Int, TurningState )


{-| Makes it easy for a human to "program" a Kurve.

The input is a chronologically ordered list representing how a human will typically think about a Kurve's actions.

-}
makeUserInteractions : List CumulativeInteraction -> List UserInteraction
makeUserInteractions cumulativeInteractions =
    let
        accumulate : CumulativeInteraction -> ( List CumulativeInteraction, Int ) -> ( List CumulativeInteraction, Int )
        accumulate ( ticksBeforeAction, turningState ) ( soFar, previousTickNumber ) =
            let
                thisTickNumber : Int
                thisTickNumber =
                    previousTickNumber + ticksBeforeAction
            in
            ( ( thisTickNumber, turningState ) :: soFar, thisTickNumber )

        toUserInteraction : CumulativeInteraction -> UserInteraction
        toUserInteraction ( n, turningState ) =
            HappenedBefore (tickNumber n) turningState
    in
    List.foldl accumulate ( [], 0 ) cumulativeInteractions |> Tuple.first |> List.map toUserInteraction


tickNumber : Int -> Tick
tickNumber n =
    case Tick.fromInt n of
        Nothing ->
            Tick.genesis

        Just tick ->
            tick


{-| A description of when and how a round should end.
-}
type alias RoundOutcome =
    { tickThatShouldEndIt : Tick
    , howItShouldEnd : RoundEndingInterpretation
    , effectsItShouldProduce : EffectsExpectation
    }


type alias RoundEndingInterpretation =
    { aliveAtTheEnd : List AliveKurve
    , deadAtTheEnd : List DeadKurve
    }


type alias AliveKurve =
    { id : PlayerId
    }


type alias DeadKurve =
    { id : PlayerId
    , theDrawingPositionItNeverMadeItTo : DrawingPosition
    }


type EffectsExpectation
    = DoNotCare
    | ExpectEffects (List Effect)


type alias RefreshRate =
    Int


defaultConfigWithSpeed : Speed -> Config
defaultConfigWithSpeed speed =
    let
        defaultConfig : Config
        defaultConfig =
            Config.default

        defaultKurveConfig : KurveConfig
        defaultKurveConfig =
            defaultConfig.kurves
    in
    { defaultConfig
        | kurves =
            { defaultKurveConfig
                | speed = speed
            }
    }


draw : Char -> ( Int, Int ) -> ( Color.Color, DrawingPosition )
draw color ( x, y ) =
    ( charToColor color, { x = x, y = y } )


charToColor : Char -> Color.Color
charToColor x =
    case x of
        '🟥' ->
            Color.red

        '🟨' ->
            Color.yellow

        '🟧' ->
            Color.orange

        '🟩' ->
            Color.green

        '🟪' ->
            Color.purple

        '🟦' ->
            Color.blue

        '⬜' ->
            Color.white

        _ ->
            Debug.todo <| "Unsupported color character: " ++ String.fromChar x
