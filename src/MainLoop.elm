module MainLoop exposing (consumeAnimationFrame, noLeftoverFrameTime)

{-| Based on Isaac Sukin's `MainLoop.js`.

  - <https://github.com/IceCreamYou/MainLoop.js/tree/247e7c41fe4bfa7e15ff4cc524d56056feffd306>
  - <http://www.isaacsukin.com/news/2015/01/detailed-explanation-javascript-game-loops-and-timing>

-}

import Config exposing (Config)
import Drawing exposing (RenderAction, draw, mergeRenderAction, nothingToDraw)
import Game exposing (TickResult(..))
import Round exposing (Round)
import Types.FrameTime exposing (FrameTime, LeftoverFrameTime)
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate


consumeAnimationFrame :
    Config
    -> FrameTime
    -> LeftoverFrameTime
    -> Tick
    -> Round
    -> ( TickResult ( LeftoverFrameTime, Tick, Round ), RenderAction )
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
            -> RenderAction
            -> ( TickResult ( LeftoverFrameTime, Tick, Round ), RenderAction )
        recurse timeLeftToConsume lastTickReactedTo midRoundStateSoFar renderActionSoFar =
            if timeLeftToConsume >= timestep then
                let
                    incrementedTick : Tick
                    incrementedTick =
                        Tick.succ lastTickReactedTo

                    ( tickResult, whatToDrawForThisTick ) =
                        Game.reactToTick config incrementedTick midRoundStateSoFar

                    newRenderAction : RenderAction
                    newRenderAction =
                        mergeRenderAction renderActionSoFar (draw whatToDrawForThisTick)
                in
                case tickResult of
                    RoundKeepsGoing newMidRoundState ->
                        recurse (timeLeftToConsume - timestep) incrementedTick newMidRoundState newRenderAction

                    RoundEnds finishedRound ->
                        ( RoundEnds finishedRound
                        , newRenderAction
                        )

            else
                ( RoundKeepsGoing ( timeLeftToConsume, lastTickReactedTo, midRoundStateSoFar )
                , renderActionSoFar
                )
    in
    recurse timeToConsume lastTick midRoundState nothingToDraw


noLeftoverFrameTime : LeftoverFrameTime
noLeftoverFrameTime =
    0
