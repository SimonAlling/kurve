module App exposing
    ( AppState(..)
    , Move(..)
    , PlayingMovie
    , PlayingMovieKurve
    , modifyGameState
    , toPlayingMovie
    )

import Color exposing (Color)
import Dict
import Game exposing (GameState)
import Holes exposing (Holiness)
import Menu exposing (MenuState)
import Movie exposing (Movie, MovieKurve)
import Players
import Random
import Types.FrameTime exposing (LeftoverFrameTime)
import Types.Tick as Tick exposing (Tick)
import World exposing (DrawingPosition)


type AppState
    = InMenu MenuState Random.Seed
    | InGame GameState
    | InMovie PlayingMovie


type alias PlayingMovie =
    { movesPerTick : Int
    , kurves : List PlayingMovieKurve
    , leftoverTimeFromPreviousFrame : LeftoverFrameTime
    , lastTick : Tick
    , isPlaying : Bool
    }


type alias PlayingMovieKurve =
    { color : Color
    , drawingPosition : DrawingPosition
    , holiness : Holiness
    , holinessChanges : List Tick
    , moves : List Move
    }


type Move
    = NoMove
    | MoveDirection Movie.Direction


toPlayingMovie : Movie -> PlayingMovie
toPlayingMovie movie =
    { movesPerTick = movie.movesPerTick
    , kurves = movie.kurves |> List.filterMap toPlayingMovieKurve
    , leftoverTimeFromPreviousFrame = 0
    , lastTick = Tick.genesis
    , isPlaying = True
    }


toPlayingMovieKurve : MovieKurve -> Maybe PlayingMovieKurve
toPlayingMovieKurve kurve =
    let
        maybeColor =
            Players.initialPlayers
                |> Dict.get kurve.playerId
                |> Maybe.map (Tuple.first >> .color)
    in
    case ( maybeColor, kurve.moves ) of
        ( Just color, firstMove :: rest ) ->
            Just
                { color = color
                , drawingPosition = kurve.initialDrawingPosition
                , holiness = kurve.initialHoliness
                , holinessChanges = kurve.holinessChanges
                , moves = MoveDirection firstMove :: directionsToMoves firstMove rest
                }

        _ ->
            Nothing


directionsToMoves firstMove =
    List.foldl
        (\direction ( acc, previousDirection ) ->
            if direction == Movie.opposite previousDirection then
                ( NoMove :: acc, previousDirection )

            else
                ( MoveDirection direction :: acc, direction )
        )
        ( [], firstMove )
        >> Tuple.first
        >> List.reverse


modifyGameState : (GameState -> GameState) -> AppState -> AppState
modifyGameState f appState =
    case appState of
        InGame gameState ->
            InGame <| f gameState

        _ ->
            appState
