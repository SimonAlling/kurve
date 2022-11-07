module Turning exposing (TurningState(..), computeAngleChange, computeTurningState)

import Config exposing (Config)
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


computeAngleChange : Config -> TurningState -> Angle
computeAngleChange config turningState =
    case turningState of
        TurningLeft ->
            computedAngleChange config

        TurningRight ->
            Angle.negate <| computedAngleChange config

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


computedAngleChange : Config -> Angle
computedAngleChange config =
    Angle (Speed.toFloat config.speed / (Tickrate.toFloat config.tickrate * Radius.toFloat config.turningRadius))
