module Turning exposing (TurningState(..), computeAngleChange, computeTurningState)

import Config
import Set exposing (Set(..))
import Types.Angle as Angle exposing (Angle(..))
import Types.Player exposing (Player)
import Types.Radius as Radius exposing (Radius(..))
import Types.Speed as Speed exposing (Speed(..))
import Types.Tickrate as Tickrate exposing (Tickrate(..))


type TurningState
    = TurningLeft
    | TurningRight
    | NotTurning


computeAngleChange : TurningState -> Angle
computeAngleChange turningState =
    case turningState of
        TurningLeft ->
            computedAngleChange

        TurningRight ->
            Angle.negate computedAngleChange

        NotTurning ->
            Angle 0


computeTurningState : Set String -> Player -> TurningState
computeTurningState pressedButtons player =
    let
        ( leftButtons, rightButtons ) =
            player.controls

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


computedAngleChange : Angle
computedAngleChange =
    Angle (Speed.toFloat Config.speed / (Tickrate.toFloat Config.tickrate * Radius.toFloat Config.turningRadius))
