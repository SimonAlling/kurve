module MainLoop exposing (consumeAnimationFrame, consumeAnimationFrame_Spawning, noLeftoverFrameTime)

{-| Based on Isaac Sukin's `MainLoop.js`.

  - <https://github.com/IceCreamYou/MainLoop.js/tree/247e7c41fe4bfa7e15ff4cc524d56056feffd306>
  - <http://www.isaacsukin.com/news/2015/01/detailed-explanation-javascript-game-loops-and-timing>

-}

import Config exposing (Config)
import Drawing exposing (WhatToDraw, drawSpawnIfAndOnlyIf, drawSpawnsPermanently, mergeWhatToDraw)
import Game exposing (SpawnState, TickResult(..))
import Round exposing (Round)
import Types.FrameTime exposing (FrameTime, LeftoverFrameTime)
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Util exposing (isEven)


consumeAnimationFrame_Spawning :
    Config
    -> FrameTime
    -> LeftoverFrameTime
    -> SpawnState
    -> ( ( LeftoverFrameTime, Maybe SpawnState ), Maybe WhatToDraw )
consumeAnimationFrame_Spawning config delta leftoverTimeFromPreviousFrame ogSpawnState =
    let
        timeToConsume : FrameTime
        timeToConsume =
            delta + leftoverTimeFromPreviousFrame

        timestep : FrameTime
        timestep =
            1000 / config.spawn.flickerTicksPerSecond

        recurse :
            LeftoverFrameTime
            -> SpawnState
            -> Maybe WhatToDraw
            -> ( ( LeftoverFrameTime, Maybe SpawnState ), Maybe WhatToDraw )
        recurse timeLeftToConsume spawnStateSoFar whatToDrawSoFar =
            if timeLeftToConsume >= timestep then
                let
                    ( maybeSpawnState, whatToDrawForThisTick ) =
                        stepSpawnState config spawnStateSoFar

                    newWhatToDraw : WhatToDraw
                    newWhatToDraw =
                        mergeWhatToDraw whatToDrawSoFar whatToDrawForThisTick
                in
                case maybeSpawnState of
                    Just newSpawnState ->
                        recurse (timeLeftToConsume - timestep) newSpawnState (Just newWhatToDraw)

                    Nothing ->
                        ( ( timeLeftToConsume, Nothing )
                        , Just newWhatToDraw
                        )

            else
                ( ( timeLeftToConsume, Just spawnStateSoFar )
                , whatToDrawSoFar
                )
    in
    recurse timeToConsume ogSpawnState Nothing


consumeAnimationFrame :
    Config
    -> FrameTime
    -> LeftoverFrameTime
    -> Tick
    -> Round
    -> ( TickResult ( LeftoverFrameTime, Tick, Round ), Maybe WhatToDraw )
consumeAnimationFrame config delta leftoverTimeFromPreviousFrame lastTick midRoundState =
    let
        timeToConsume : FrameTime
        timeToConsume =
            delta + leftoverTimeFromPreviousFrame

        timestep : FrameTime
        timestep =
            1000 / Tickrate.toFloat config.kurves.tickrate

        recurse :
            LeftoverFrameTime
            -> Tick
            -> Round
            -> Maybe WhatToDraw
            -> ( TickResult ( LeftoverFrameTime, Tick, Round ), Maybe WhatToDraw )
        recurse timeLeftToConsume lastTickReactedTo midRoundStateSoFar whatToDrawSoFar =
            if timeLeftToConsume >= timestep then
                let
                    incrementedTick : Tick
                    incrementedTick =
                        Tick.succ lastTickReactedTo

                    ( tickResult, whatToDrawForThisTick ) =
                        Game.reactToTick config incrementedTick midRoundStateSoFar

                    newWhatToDraw : WhatToDraw
                    newWhatToDraw =
                        mergeWhatToDraw whatToDrawSoFar whatToDrawForThisTick
                in
                case tickResult of
                    RoundKeepsGoing newMidRoundState ->
                        recurse (timeLeftToConsume - timestep) incrementedTick newMidRoundState (Just newWhatToDraw)

                    RoundEnds finishedRound ->
                        ( RoundEnds finishedRound
                        , Just newWhatToDraw
                        )

            else
                ( RoundKeepsGoing ( timeLeftToConsume, lastTickReactedTo, midRoundStateSoFar )
                , whatToDrawSoFar
                )
    in
    recurse timeToConsume lastTick midRoundState Nothing


noLeftoverFrameTime : LeftoverFrameTime
noLeftoverFrameTime =
    0


stepSpawnState : Config -> SpawnState -> ( Maybe SpawnState, WhatToDraw )
stepSpawnState config { kurvesLeft, alreadySpawnedKurves, ticksLeft } =
    case kurvesLeft of
        [] ->
            -- All Kurves have spawned.
            ( Nothing, drawSpawnsPermanently alreadySpawnedKurves )

        spawning :: waiting ->
            let
                newSpawnState : SpawnState
                newSpawnState =
                    if ticksLeft == 0 then
                        { kurvesLeft = waiting, alreadySpawnedKurves = spawning :: alreadySpawnedKurves, ticksLeft = config.spawn.numberOfFlickerTicks }

                    else
                        { kurvesLeft = spawning :: waiting, alreadySpawnedKurves = alreadySpawnedKurves, ticksLeft = ticksLeft - 1 }
            in
            ( Just newSpawnState, drawSpawnIfAndOnlyIf (isEven ticksLeft) spawning alreadySpawnedKurves )
