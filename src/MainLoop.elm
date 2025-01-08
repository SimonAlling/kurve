module MainLoop exposing (consumeFrameTime, noLeftoverTime)

import Config exposing (Config)
import Game exposing (MidRoundState, TickResult(..))
import Types.FrameTime exposing (FrameTime, LeftoverFrameTime, WithLeftoverFrameTime(..))
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate


consumeFrameTime : Config -> FrameTime -> Tick -> WithLeftoverFrameTime MidRoundState -> ( TickResult (WithLeftoverFrameTime MidRoundState), Cmd msg )
consumeFrameTime config delta lastTick (WithLeftoverFrameTime leftoverTimeFromPreviousFrame midRoundState) =
    let
        timeToConsume : FrameTime
        timeToConsume =
            delta + leftoverTimeFromPreviousFrame

        timestep : FrameTime
        timestep =
            1000 / Tickrate.toFloat config.kurves.tickrate

        recurse : Tick -> WithLeftoverFrameTime MidRoundState -> Cmd msg -> ( TickResult (WithLeftoverFrameTime MidRoundState), Cmd msg )
        recurse lastTickReactedTo (WithLeftoverFrameTime timeLeftToConsume midRoundStateSoFar) cmdSoFar =
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
                        recurse incrementedTick (WithLeftoverFrameTime (timeLeftToConsume - timestep) newMidRoundState) newCmd

                    RoundEnds finishedRound ->
                        ( RoundEnds finishedRound
                        , newCmd
                        )

            else
                ( RoundKeepsGoing lastTickReactedTo (WithLeftoverFrameTime timeLeftToConsume midRoundStateSoFar)
                , cmdSoFar
                )
    in
    recurse lastTick (WithLeftoverFrameTime timeToConsume midRoundState) Cmd.none


noLeftoverTime : LeftoverFrameTime
noLeftoverTime =
    0
