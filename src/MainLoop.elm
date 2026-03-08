module MainLoop exposing (TickResultMovie(..), consumeAnimationFrame, consumeMovieAnimationFrame, noLeftoverFrameTime, withFloatingPointRoundingErrorCompensation)

{-| Based on Isaac Sukin's `MainLoop.js`.

  - <https://github.com/IceCreamYou/MainLoop.js/tree/247e7c41fe4bfa7e15ff4cc524d56056feffd306>
  - <http://www.isaacsukin.com/news/2015/01/detailed-explanation-javascript-game-loops-and-timing>

-}

import Colors
import Config exposing (Config)
import Dict
import Drawing exposing (DrawingAccumulator, WhatToDraw)
import Game exposing (TickResult(..))
import Holes exposing (Holiness(..))
import Movie exposing (Direction(..), Movie, MovieKurve)
import Players
import Round exposing (Round)
import Types.FrameTime exposing (FrameTime, LeftoverFrameTime)
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import World exposing (DrawingPosition)


consumeAnimationFrame :
    Config
    -> FrameTime
    -> LeftoverFrameTime
    -> Tick
    -> Round
    -> ( TickResult ( LeftoverFrameTime, Tick, Round ), Maybe WhatToDraw )
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
            -> DrawingAccumulator
            -> ( TickResult ( LeftoverFrameTime, Tick, Round ), DrawingAccumulator )
        recurse timeLeftToConsume lastTickReactedTo midRoundStateSoFar drawingAccumulator =
            if timeLeftToConsume >= timestep then
                let
                    incrementedTick : Tick
                    incrementedTick =
                        Tick.succ lastTickReactedTo

                    ( tickResult, whatToDrawForThisTick ) =
                        Game.reactToTick config incrementedTick midRoundStateSoFar

                    newDrawingAccumulator : DrawingAccumulator
                    newDrawingAccumulator =
                        Drawing.accumulate drawingAccumulator whatToDrawForThisTick
                in
                case tickResult of
                    RoundKeepsGoing newMidRoundState ->
                        recurse (timeLeftToConsume - timestep) incrementedTick newMidRoundState newDrawingAccumulator

                    RoundEnds tickThatEndedIt finishedRound ->
                        ( RoundEnds tickThatEndedIt finishedRound
                        , newDrawingAccumulator
                        )

            else
                ( RoundKeepsGoing ( timeLeftToConsume, lastTickReactedTo, midRoundStateSoFar )
                , drawingAccumulator
                )
    in
    recurse timeToConsume lastTick midRoundState Drawing.initialize |> Tuple.mapSecond Drawing.finalize


type TickResultMovie a
    = MovieKeepsGoing a
    | MovieEnds Tick Movie


consumeMovieAnimationFrame :
    Config
    -> FrameTime
    -> LeftoverFrameTime
    -> Tick
    -> Movie
    -> ( TickResultMovie ( LeftoverFrameTime, Tick, Movie ), Maybe WhatToDraw )
consumeMovieAnimationFrame config delta leftoverTimeFromPreviousFrame lastTick movie =
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
            -> Movie
            -> DrawingAccumulator
            -> ( TickResultMovie ( LeftoverFrameTime, Tick, Movie ), DrawingAccumulator )
        recurse timeLeftToConsume lastTickReactedTo movieSoFar drawingAccumulator =
            if timeLeftToConsume >= timestep then
                let
                    incrementedTick : Tick
                    incrementedTick =
                        Tick.succ lastTickReactedTo

                    ( newKurves, newColoredDrawingPositions, headDraws ) =
                        movieSoFar.kurves
                            |> List.foldl
                                (\kurve ( accKurves, accDrawing, accHeadDraws ) ->
                                    let
                                        color =
                                            Players.initialPlayers
                                                |> Dict.get kurve.playerId
                                                |> Maybe.map (Tuple.first >> .color)
                                                |> Maybe.withDefault Colors.red

                                        ( newKurve, newAccDrawing ) =
                                            List.repeat movieSoFar.movesPerTick ()
                                                |> List.foldl
                                                    (\() ( accKurve, accDrawing_ ) ->
                                                        case accKurve.moves of
                                                            [] ->
                                                                ( accKurve, accDrawing_ )

                                                            move :: rest ->
                                                                let
                                                                    drawingPosition =
                                                                        applyMove move accKurve.initialDrawingPosition
                                                                in
                                                                ( { accKurve
                                                                    | moves = rest
                                                                    , initialDrawingPosition = drawingPosition
                                                                  }
                                                                , case accKurve.initialHoliness of
                                                                    Solid ->
                                                                        ( color, drawingPosition ) :: accDrawing_

                                                                    Holy ->
                                                                        accDrawing_
                                                                )
                                                    )
                                                    ( applyHolinessChange incrementedTick kurve, accDrawing )

                                        newAccHeadDraws =
                                            if List.isEmpty newKurve.moves then
                                                accHeadDraws

                                            else
                                                ( color, newKurve.initialDrawingPosition ) :: accHeadDraws
                                    in
                                    ( newKurve :: accKurves, newAccDrawing, newAccHeadDraws )
                                )
                                ( [], [], [] )

                    newMovie =
                        { movieSoFar | kurves = List.reverse newKurves }

                    tickResult =
                        if List.isEmpty headDraws then
                            MovieEnds incrementedTick newMovie

                        else
                            MovieKeepsGoing newMovie

                    whatToDrawForThisTick : WhatToDraw
                    whatToDrawForThisTick =
                        { headDrawing = headDraws
                        , bodyDrawing = newColoredDrawingPositions
                        }

                    newDrawingAccumulator : DrawingAccumulator
                    newDrawingAccumulator =
                        Drawing.accumulate drawingAccumulator whatToDrawForThisTick
                in
                case tickResult of
                    MovieKeepsGoing newMovie_ ->
                        recurse (timeLeftToConsume - timestep) incrementedTick newMovie_ newDrawingAccumulator

                    MovieEnds tickThatEndedIt finishedMovie ->
                        ( MovieEnds tickThatEndedIt finishedMovie
                        , newDrawingAccumulator
                        )

            else
                ( MovieKeepsGoing ( timeLeftToConsume, lastTickReactedTo, movieSoFar )
                , drawingAccumulator
                )
    in
    recurse timeToConsume lastTick movie Drawing.initialize |> Tuple.mapSecond Drawing.finalize


applyHolinessChange : Tick -> MovieKurve -> MovieKurve
applyHolinessChange tick kurve =
    case kurve.holinessChanges of
        [] ->
            kurve

        next :: rest ->
            if next == tick then
                { kurve
                    | holinessChanges = rest
                    , initialHoliness = flipHoliness kurve.initialHoliness
                }

            else
                kurve


applyMove : Movie.Direction -> DrawingPosition -> DrawingPosition
applyMove direction { x, y } =
    case direction of
        N ->
            { x = x, y = y - 1 }

        NE ->
            { x = x + 1, y = y - 1 }

        E ->
            { x = x + 1, y = y }

        SE ->
            { x = x + 1, y = y + 1 }

        S ->
            { x = x, y = y + 1 }

        SW ->
            { x = x - 1, y = y + 1 }

        W ->
            { x = x - 1, y = y }

        NW ->
            { x = x - 1, y = y - 1 }


flipHoliness : Holiness -> Holiness
flipHoliness holiness =
    case holiness of
        Holy ->
            Solid

        Solid ->
            Holy


noLeftoverFrameTime : LeftoverFrameTime
noLeftoverFrameTime =
    0


withFloatingPointRoundingErrorCompensation : Float -> Float
withFloatingPointRoundingErrorCompensation skipStepInMs =
    skipStepInMs + 1
