module MainLoop exposing (consumeFrameTime, noLeftoverTime)

import Config exposing (Config)
import Game exposing (MidRoundState, TickResult(..))
import Types.FrameTime exposing (FrameTime, LeftoverFrameTime)
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate


consumeFrameTime : Config -> FrameTime -> LeftoverFrameTime -> Tick -> MidRoundState -> ( LeftoverFrameTime, TickResult, Cmd msg )
consumeFrameTime config delta leftoverTimeFromPreviousFrame lastTick midRoundState =
    let
        timeToConsume : FrameTime
        timeToConsume =
            delta + leftoverTimeFromPreviousFrame

        timestep : FrameTime
        timestep =
            1000 / Tickrate.toFloat config.kurves.tickrate

        recurse : FrameTime -> Tick -> MidRoundState -> Cmd msg -> ( LeftoverFrameTime, TickResult, Cmd msg )
        recurse timeLeftToConsume someTick midRoundStateSoFar cmdSoFar =
            if timeLeftToConsume >= timestep then
                let
                    nextTick : Tick
                    nextTick =
                        Tick.succ someTick

                    ( tickResult, cmdForThisTick ) =
                        Game.reactToTick config nextTick midRoundStateSoFar

                    newCmd : Cmd msg
                    newCmd =
                        Cmd.batch [ cmdSoFar, cmdForThisTick ]
                in
                case tickResult of
                    RoundKeepsGoing _ newMidRoundState ->
                        recurse (timeLeftToConsume - timestep) nextTick newMidRoundState newCmd

                    RoundEnds finishedRound ->
                        ( 0, RoundEnds finishedRound, newCmd )

            else
                ( timeLeftToConsume
                , RoundKeepsGoing someTick midRoundStateSoFar
                , cmdSoFar
                )
    in
    recurse timeToConsume lastTick midRoundState Cmd.none


noLeftoverTime : LeftoverFrameTime
noLeftoverTime =
    0
