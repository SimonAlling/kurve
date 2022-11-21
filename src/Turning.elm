module Turning exposing (computeAngleChange, computeTurningState, turningStateFromHistory)

import Config exposing (KurveConfig)
import Set exposing (Set)
import Types.Angle as Angle exposing (Angle(..))
import Types.Player exposing (Player, UserInteraction(..))
import Types.Radius as Radius
import Types.Speed as Speed
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Types.TurningState exposing (TurningState(..))


computeAngleChange : KurveConfig -> TurningState -> Angle
computeAngleChange kurveConfig turningState =
    case turningState of
        TurningLeft ->
            computedAngleChange kurveConfig

        TurningRight ->
            Angle.negate <| computedAngleChange kurveConfig

        NotTurning ->
            Angle 0


computeTurningState : Set String -> Player -> TurningState
computeTurningState pressedButtons player =
    let
        ( leftButtons, rightButtons ) =
            player.controls

        someIsPressed : Set String -> Bool
        someIsPressed =
            Set.intersect pressedButtons >> Set.isEmpty >> not
    in
    case ( someIsPressed leftButtons, someIsPressed rightButtons ) of
        ( True, False ) ->
            TurningLeft

        ( False, True ) ->
            TurningRight

        _ ->
            -- Turning left and right at the same time cancel each other out, just like in the original game.
            NotTurning


computedAngleChange : KurveConfig -> Angle
computedAngleChange { tickrate, turningRadius, speed } =
    Angle (Speed.toFloat speed / (Tickrate.toFloat tickrate * Radius.toFloat turningRadius))


turningStateFromHistory : Tick -> Player -> TurningState
turningStateFromHistory currentTick player =
    newestFromBefore currentTick player.reversedInteractions


newestFromBefore : Tick -> List UserInteraction -> TurningState
newestFromBefore currentTick reversedInteractions =
    case reversedInteractions of
        [] ->
            NotTurning

        (HappenedBefore tick turningState) :: rest ->
            if Tick.toInt tick <= Tick.toInt currentTick then
                turningState

            else
                newestFromBefore currentTick rest
