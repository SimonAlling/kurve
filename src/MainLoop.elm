module MainLoop exposing (consumeAnimationFrame, noLeftoverFrameTime)

{-| Based on Isaac Sukin's `MainLoop.js`.

  - <https://github.com/IceCreamYou/MainLoop.js/tree/247e7c41fe4bfa7e15ff4cc524d56056feffd306>
  - <http://www.isaacsukin.com/news/2015/01/detailed-explanation-javascript-game-loops-and-timing>

-}

import Config exposing (Config)
import Game exposing (MidRoundState, TickResult(..))
import Types.FrameTime exposing (FrameTime, LeftoverFrameTime)
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate


consumeAnimationFrame :
    Config
    -> FrameTime
    -> LeftoverFrameTime
    -> Tick
    -> MidRoundState
    -> ( TickResult ( Tick, LeftoverFrameTime, MidRoundState ), Cmd msg )
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
            -> MidRoundState
            -> Cmd msg
            -> ( TickResult ( Tick, LeftoverFrameTime, MidRoundState ), Cmd msg )
        recurse timeLeftToConsume lastTickReactedTo midRoundStateSoFar cmdSoFar =
            if timeLeftToConsume >= timestep then
                let
                    incrementedTick : Tick
                    incrementedTick =
                        Tick.succ lastTickReactedTo

                    ( tickResult, cmdForThisTick ) =
                        Game.reactToTick config incrementedTick midRoundStateSoFar

                    newCmd : Cmd msg
                    newCmd =
                        Cmd.batch [ cmdSoFar, cmdForThisTick ]
                in
                case tickResult of
                    RoundKeepsGoing newMidRoundState ->
                        recurse (timeLeftToConsume - timestep) incrementedTick newMidRoundState newCmd

                    RoundEnds finishedRound ->
                        ( RoundEnds finishedRound
                        , newCmd
                        )

            else
                ( RoundKeepsGoing ( lastTickReactedTo, timeLeftToConsume, midRoundStateSoFar )
                , cmdSoFar
                )
    in
    recurse timeToConsume lastTick midRoundState Cmd.none


noLeftoverFrameTime : LeftoverFrameTime
noLeftoverFrameTime =
    0
