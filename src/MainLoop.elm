module MainLoop exposing (consumeFrameTime, noLeftoverTime)

import Config exposing (Config)
import Game exposing (MidRoundState, TickResult(..))
import Types.FrameTime exposing (FrameTime, LeftoverFrameTime)
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate


consumeFrameTime : Config -> FrameTime -> Tick -> ( LeftoverFrameTime, MidRoundState ) -> ( TickResult ( LeftoverFrameTime, MidRoundState ), Cmd msg )
consumeFrameTime config delta lastTick ( leftoverTimeFromPreviousFrame, midRoundState ) =
    let
        timeToConsume : FrameTime
        timeToConsume =
            delta + leftoverTimeFromPreviousFrame

        timestep : FrameTime
        timestep =
            1000 / Tickrate.toFloat config.kurves.tickrate

        recurse : Tick -> ( LeftoverFrameTime, MidRoundState ) -> Cmd msg -> ( TickResult ( LeftoverFrameTime, MidRoundState ), Cmd msg )
        recurse lastTickReactedTo ( timeLeftToConsume, midRoundStateSoFar ) cmdSoFar =
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
                    RoundKeepsGoing _ newMidRoundState ->
                        recurse incrementedTick ( timeLeftToConsume - timestep, newMidRoundState ) newCmd

                    RoundEnds finishedRound ->
                        ( RoundEnds finishedRound
                        , newCmd
                        )

            else
                ( RoundKeepsGoing lastTickReactedTo ( timeLeftToConsume, midRoundStateSoFar )
                , cmdSoFar
                )
    in
    recurse lastTick ( timeToConsume, midRoundState ) Cmd.none


noLeftoverTime : LeftoverFrameTime
noLeftoverTime =
    0
