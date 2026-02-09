module MainLoop exposing (consumeAnimationFrame, consumeAnimationFrame_Spawning, noLeftoverFrameTime, withFloatingPointRoundingErrorCompensation)

{-| Based on Isaac Sukin's `MainLoop.js`.

  - <https://github.com/IceCreamYou/MainLoop.js/tree/247e7c41fe4bfa7e15ff4cc524d56056feffd306>
  - <http://www.isaacsukin.com/news/2015/01/detailed-explanation-javascript-game-loops-and-timing>

-}

import Config exposing (Config)
import Drawing exposing (DrawingAccumulator, WhatToDraw)
import Game exposing (TickResult(..))
import Round exposing (Round)
import Spawn exposing (SpawnState, flickerFrequencyToTicksPerSecond, stepSpawnState)
import Types.FrameTime exposing (FrameTime, LeftoverFrameTime)
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate


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
            1000 / flickerFrequencyToTicksPerSecond config.spawn.flickerFrequency

        recurse :
            LeftoverFrameTime
            -> SpawnState
            -> DrawingAccumulator
            -> ( ( LeftoverFrameTime, Maybe SpawnState ), DrawingAccumulator )
        recurse timeLeftToConsume spawnStateSoFar drawingAccumulator =
            if timeLeftToConsume >= timestep then
                let
                    ( maybeSpawnState, whatToDrawForThisTick ) =
                        stepSpawnState spawnStateSoFar

                    newDrawingAccumulator : DrawingAccumulator
                    newDrawingAccumulator =
                        Drawing.accumulate drawingAccumulator whatToDrawForThisTick
                in
                case maybeSpawnState of
                    Just newSpawnState ->
                        recurse (timeLeftToConsume - timestep) newSpawnState newDrawingAccumulator

                    Nothing ->
                        ( ( timeLeftToConsume, Nothing )
                        , newDrawingAccumulator
                        )

            else
                ( ( timeLeftToConsume, Just spawnStateSoFar )
                , drawingAccumulator
                )
    in
    recurse timeToConsume ogSpawnState Drawing.initialize |> Tuple.mapSecond Drawing.finalize


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
            -> DrawingAccumulator
            -> ( TickResult ( LeftoverFrameTime, Tick, Round ), DrawingAccumulator )
        recurse timeLeftToConsume lastTickReactedTo midRoundStateSoFar drawingAccumulator =
            if timeLeftToConsume >= timestep then
                let
                    incrementedTick : Tick
                    incrementedTick =
                        Tick.succ lastTickReactedTo

                    ( tickResult, whatToDrawForThisTick ) =
                        Game.reactToTick config incrementedTick midRoundStateSoFar

                    newDrawingAccumulator : DrawingAccumulator
                    newDrawingAccumulator =
                        Drawing.accumulate drawingAccumulator whatToDrawForThisTick
                in
                case tickResult of
                    RoundKeepsGoing newMidRoundState ->
                        recurse (timeLeftToConsume - timestep) incrementedTick newMidRoundState newDrawingAccumulator

                    RoundEnds tickThatEndedIt finishedRound ->
                        ( RoundEnds tickThatEndedIt finishedRound
                        , newDrawingAccumulator
                        )

            else
                ( RoundKeepsGoing ( timeLeftToConsume, lastTickReactedTo, midRoundStateSoFar )
                , drawingAccumulator
                )
    in
    recurse timeToConsume lastTick midRoundState Drawing.initialize |> Tuple.mapSecond Drawing.finalize


noLeftoverFrameTime : LeftoverFrameTime
noLeftoverFrameTime =
    0


withFloatingPointRoundingErrorCompensation : Float -> Float
withFloatingPointRoundingErrorCompensation skipStepInMs =
    skipStepInMs + 1
