module Replay exposing (..)

import Holes exposing (Holiness)
import Types.PlayerId exposing (PlayerId)
import Types.Tickrate exposing (Tickrate)
import World exposing (DrawingPosition)


type alias Replay =
    { kurves : List ReplayKurve
    , tickrate : Tickrate
    , movesPerTick : Int
    }


type alias ReplayKurve =
    { initialDrawingPosition : DrawingPosition
    , playerId : PlayerId
    , moves : List Move
    }


type Move
    = NoMove
    | Move MoveData


type alias MoveData =
    { repetitions : Int
    , direction : Direction
    , holiness : Holiness
    }


type Direction
    = N
    | NE
    | E
    | SE
    | S
    | SW
    | W
    | W
