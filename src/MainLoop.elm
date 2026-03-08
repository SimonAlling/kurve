module MainLoop exposing (TickResultMovie(..), consumeAnimationFrame, consumeMovieAnimationFrame, noLeftoverFrameTime, withFloatingPointRoundingErrorCompensation)

{-| Based on Isaac Sukin's `MainLoop.js`.

  - <https://github.com/IceCreamYou/MainLoop.js/tree/247e7c41fe4bfa7e15ff4cc524d56056feffd306>
  - <http://www.isaacsukin.com/news/2015/01/detailed-explanation-javascript-game-loops-and-timing>

-}

import App exposing (Move(..), PlayingMovie, PlayingMovieKurve)
import Config exposing (Config)
import Drawing exposing (DrawingAccumulator, WhatToDraw)
import Game exposing (TickResult(..))
import Holes exposing (Holiness(..))
import Movie exposing (Direction(..), Movie, MovieKurve)
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


type TickResultMovie
    = MovieKeepsGoing PlayingMovie
    | MovieEnds PlayingMovie


consumeMovieAnimationFrame :
    Config
    -> FrameTime
    -> PlayingMovie
    -> ( TickResultMovie, Maybe WhatToDraw )
consumeMovieAnimationFrame config delta movie =
    let
        timeToConsume : FrameTime
        timeToConsume =
            delta + movie.leftoverTimeFromPreviousFrame

        timestep : FrameTime
        timestep =
            1000 / Tickrate.toFloat config.kurves.tickrate

        recurse :
            PlayingMovie
            -> DrawingAccumulator
            -> ( TickResultMovie, DrawingAccumulator )
        recurse movieSoFar drawingAccumulator =
            if movieSoFar.leftoverTimeFromPreviousFrame >= timestep then
                let
                    incrementedTick : Tick
                    incrementedTick =
                        Tick.succ movieSoFar.lastTick

                    ( newKurves, newColoredDrawingPositions, headDraws ) =
                        movieSoFar.kurves
                            |> List.foldl
                                (\kurve ( accKurves, accDrawing, accHeadDraws ) ->
                                    let
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
                                                                        applyMove move accKurve.drawingPosition
                                                                in
                                                                ( { accKurve
                                                                    | moves = rest
                                                                    , drawingPosition = drawingPosition
                                                                  }
                                                                , case accKurve.holiness of
                                                                    Solid ->
                                                                        ( accKurve.color, drawingPosition ) :: accDrawing_

                                                                    Holy ->
                                                                        accDrawing_
                                                                )
                                                    )
                                                    ( applyHolinessChange incrementedTick kurve, accDrawing )

                                        newAccHeadDraws =
                                            if List.isEmpty newKurve.moves then
                                                accHeadDraws

                                            else
                                                ( newKurve.color, newKurve.drawingPosition ) :: accHeadDraws
                                    in
                                    ( newKurve :: accKurves, newAccDrawing, newAccHeadDraws )
                                )
                                ( [], [], [] )

                    newMovie : PlayingMovie
                    newMovie =
                        { movieSoFar
                            | kurves = List.reverse newKurves
                            , lastTick = incrementedTick
                            , leftoverTimeFromPreviousFrame = movieSoFar.leftoverTimeFromPreviousFrame - timestep
                        }

                    tickResult =
                        if List.isEmpty headDraws then
                            MovieEnds { newMovie | isPlaying = False }

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
                        recurse newMovie_ newDrawingAccumulator

                    MovieEnds finishedMovie ->
                        ( MovieEnds finishedMovie, newDrawingAccumulator )

            else
                ( MovieKeepsGoing movieSoFar
                , drawingAccumulator
                )
    in
    recurse { movie | leftoverTimeFromPreviousFrame = timeToConsume } Drawing.initialize |> Tuple.mapSecond Drawing.finalize


applyHolinessChange : Tick -> PlayingMovieKurve -> PlayingMovieKurve
applyHolinessChange tick kurve =
    case kurve.holinessChanges of
        [] ->
            kurve

        next :: rest ->
            if next == tick then
                { kurve
                    | holinessChanges = rest
                    , holiness = flipHoliness kurve.holiness
                }

            else
                kurve


applyMove : Move -> DrawingPosition -> DrawingPosition
applyMove move { x, y } =
    case move of
        NoMove ->
            { x = x, y = y }

        MoveDirection direction ->
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
