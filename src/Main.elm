port module Main exposing (main)

import List.Cartesian
import Platform exposing (worker)
import RasterShapes
import Set exposing (Set(..))
import Time
import Types.Angle as Angle exposing (Angle(..))
import Types.Radius as Radius exposing (Radius(..))
import Types.Speed as Speed exposing (Speed(..))
import Types.Thickness as Thickness exposing (Thickness(..))
import Types.Tickrate as Tickrate exposing (Tickrate(..))


port render : { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port onKeydown : (String -> msg) -> Sub msg


port onKeyup : (String -> msg) -> Sub msg


type alias Model =
    { players : List Player
    , occupiedPixels : Set Pixel
    , pressedKeys : Set String
    }


type alias Player =
    { color : String
    , controls : ( Set String, Set String )
    , position : Position
    , direction : Angle
    , fate : Fate
    }


type alias Pixel =
    ( Int, Int )


init : () -> ( Model, Cmd Msg )
init _ =
    ( { players = thePlayers
      , pressedKeys = Set.empty
      , occupiedPixels = List.foldr (.position >> drawingPosition >> pixels >> Set.union) Set.empty thePlayers
      }
    , thePlayers
        |> List.map
            (\player ->
                render
                    { position = drawingPosition player.position
                    , thickness = Thickness.toInt theThickness
                    , color = player.color
                    }
            )
        |> Cmd.batch
    )


thePlayers : List Player
thePlayers =
    [ { color = "red"
      , controls = ( Set.fromList [ "1" ], Set.fromList [ "q" ] )
      , position = ( 100, 100 )
      , direction = Angle 0.1
      , fate = Lives
      }
    , { color = "green"
      , controls = ( Set.fromList [ "ArrowLeft" ], Set.fromList [ "ArrowDown" ] )
      , position = ( 100, 300 )
      , direction = Angle -0.1
      , fate = Lives
      }
    ]


type Msg
    = Tick Time.Posix
    | KeyWasPressed String
    | KeyWasReleased String


theTickrate : Tickrate
theTickrate =
    Tickrate 60


theTurningRadius : Radius
theTurningRadius =
    Radius 28.5


theSpeed : Speed
theSpeed =
    Speed 60


theThickness : Thickness
theThickness =
    Thickness 3


theAngleChange : Angle
theAngleChange =
    Angle (Speed.toFloat theSpeed / (Tickrate.toFloat theTickrate * Radius.toFloat theTurningRadius))


pixels : DrawingPosition -> Set Pixel
pixels { leftEdge, topEdge } =
    let
        rangeFrom start =
            List.range start (start + Thickness.toInt theThickness - 1)

        xs =
            rangeFrom leftEdge

        ys =
            rangeFrom topEdge
    in
    List.Cartesian.map2 Tuple.pair xs ys
        |> Set.fromList


type alias Position =
    ( Float, Float )


type alias DrawingPosition =
    { leftEdge : Int, topEdge : Int }


toBresenham : DrawingPosition -> RasterShapes.Position
toBresenham { leftEdge, topEdge } =
    { x = leftEdge, y = topEdge }


fromBresenham : RasterShapes.Position -> DrawingPosition
fromBresenham { x, y } =
    { leftEdge = x, topEdge = y }


desiredDrawingPositions : Position -> Position -> List DrawingPosition
desiredDrawingPositions position1 position2 =
    RasterShapes.line (drawingPosition position1 |> toBresenham) (drawingPosition position2 |> toBresenham)
        -- The RasterShapes library returns the positions in reverse order.
        |> List.reverse
        -- The first element in the list is the starting position, which is assumed to already have been drawn.
        |> List.drop 1
        |> List.map fromBresenham


edgeOfSquare : Float -> Int
edgeOfSquare xOrY =
    round (xOrY - (toFloat (Thickness.toInt theThickness) / 2))


drawingPosition : Position -> DrawingPosition
drawingPosition ( x, y ) =
    { leftEdge = edgeOfSquare x, topEdge = edgeOfSquare y }


type Fate
    = Lives
    | Dies


hitbox : DrawingPosition -> DrawingPosition -> Set Pixel
hitbox oldPosition newPosition =
    let
        is45DegreeDraw =
            oldPosition.leftEdge /= newPosition.leftEdge && oldPosition.topEdge /= newPosition.topEdge

        oldPixels =
            pixels oldPosition

        newPixels =
            pixels newPosition
    in
    if is45DegreeDraw then
        let
            oldXs =
                Set.map Tuple.first oldPixels

            oldYs =
                Set.map Tuple.second oldPixels
        in
        Set.filter (\( x, y ) -> not (Set.member x oldXs) && not (Set.member y oldYs)) newPixels

    else
        Set.diff newPixels oldPixels


evaluateMove : DrawingPosition -> List DrawingPosition -> Set Pixel -> ( List DrawingPosition, Fate )
evaluateMove startingPoint positionsToCheck occupiedPixels =
    let
        checkPositions : List DrawingPosition -> DrawingPosition -> List DrawingPosition -> ( List DrawingPosition, Fate )
        checkPositions checked lastChecked remaining =
            case remaining of
                [] ->
                    ( checked, Lives )

                current :: rest ->
                    let
                        theHitbox =
                            hitbox lastChecked current

                        dies =
                            not <| Set.isEmpty <| Set.intersect theHitbox occupiedPixels
                    in
                    if dies then
                        ( checked, Dies )

                    else
                        checkPositions (current :: checked) current rest
    in
    checkPositions [] startingPoint positionsToCheck
        -- The list was built in reverse order.
        |> Tuple.mapFirst List.reverse


updatePlayer : Set String -> Set Pixel -> Player -> ( List DrawingPosition, Player )
updatePlayer pressedKeys occupiedPixels player =
    let
        distanceTraveledSinceLastTick =
            Speed.toFloat theSpeed / Tickrate.toFloat theTickrate

        ( leftKeys, rightKeys ) =
            player.controls

        someIsPressed =
            Set.intersect pressedKeys >> Set.isEmpty >> not

        angleChangeLeft =
            if someIsPressed leftKeys then
                theAngleChange

            else
                Angle 0

        angleChangeRight =
            if someIsPressed rightKeys then
                Angle.negate theAngleChange

            else
                Angle 0

        newDirection =
            -- Turning left and right at the same time cancel each other out, just like in the original game.
            Angle.add player.direction (Angle.add angleChangeLeft angleChangeRight)

        ( x, y ) =
            player.position

        newPosition =
            ( x + distanceTraveledSinceLastTick * Angle.cos newDirection
            , -- The coordinate system is traditionally "flipped" (wrt standard math) such that the Y axis points downwards.
              -- Therefore, we have to use minus instead of plus for the Y-axis calculation.
              y - distanceTraveledSinceLastTick * Angle.sin newDirection
            )

        ( confirmedDrawingPositions, fate ) =
            evaluateMove
                (drawingPosition player.position)
                (desiredDrawingPositions player.position newPosition)
                occupiedPixels
    in
    ( confirmedDrawingPositions
    , { player
        | position = newPosition
        , direction = newDirection
        , fate = fate
      }
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick _ ->
            let
                ( newPlayers, newOccupiedPixels, newDrawingPositions ) =
                    List.foldr
                        (\player ( players, updatedPixels, coloredDrawingPositions ) ->
                            let
                                ( newPlayerDrawingPositions, newPlayer ) =
                                    case player.fate of
                                        Lives ->
                                            updatePlayer model.pressedKeys updatedPixels player

                                        Dies ->
                                            ( [], player )
                            in
                            ( newPlayer :: players
                            , List.foldr
                                (pixels >> Set.union)
                                updatedPixels
                                newPlayerDrawingPositions
                            , coloredDrawingPositions ++ List.map (Tuple.pair player.color) newPlayerDrawingPositions
                            )
                        )
                        ( [], model.occupiedPixels, [] )
                        model.players
            in
            ( { players = newPlayers
              , occupiedPixels = newOccupiedPixels
              , pressedKeys = model.pressedKeys
              }
            , newDrawingPositions
                |> List.map
                    (\( color, position ) ->
                        render
                            { position = position
                            , thickness = Thickness.toInt theThickness
                            , color = color
                            }
                    )
                |> Cmd.batch
            )

        KeyWasPressed key ->
            ( { model | pressedKeys = Set.insert key model.pressedKeys }
            , Cmd.none
            )

        KeyWasReleased key ->
            ( { model | pressedKeys = Set.remove key model.pressedKeys }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Time.every (1000 / Tickrate.toFloat theTickrate) Tick
        , onKeydown KeyWasPressed
        , onKeyup KeyWasReleased
        ]


main =
    worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
