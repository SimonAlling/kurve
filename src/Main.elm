port module Main exposing (main)

import Config exposing (theSpeed, theThickness, theTickrate, theTurningRadius)
import Platform exposing (worker)
import Set exposing (Set(..))
import Time
import Types.Angle as Angle exposing (Angle(..))
import Types.Player as Player exposing (Player)
import Types.Radius as Radius exposing (Radius(..))
import Types.Speed as Speed exposing (Speed(..))
import Types.Thickness as Thickness exposing (Thickness(..))
import Types.Tickrate as Tickrate exposing (Tickrate(..))
import World exposing (DrawingPosition, Pixel)


port render : { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port onKeydown : (String -> msg) -> Sub msg


port onKeyup : (String -> msg) -> Sub msg


type alias Model =
    { players : List Player
    , occupiedPixels : Set Pixel
    , pressedKeys : Set String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { players = thePlayers
      , pressedKeys = Set.empty
      , occupiedPixels = List.foldr (.position >> World.drawingPosition >> World.pixels >> Set.union) Set.empty thePlayers
      }
    , thePlayers
        |> List.map
            (\player ->
                render
                    { position = World.drawingPosition player.position
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
      , fate = Player.Lives
      }
    , { color = "green"
      , controls = ( Set.fromList [ "ArrowLeft" ], Set.fromList [ "ArrowDown" ] )
      , position = ( 100, 300 )
      , direction = Angle -0.1
      , fate = Player.Lives
      }
    ]


type Msg
    = Tick Time.Posix
    | KeyWasPressed String
    | KeyWasReleased String


computedAngleChange : Angle
computedAngleChange =
    Angle (Speed.toFloat theSpeed / (Tickrate.toFloat theTickrate * Radius.toFloat theTurningRadius))


evaluateMove : DrawingPosition -> List DrawingPosition -> Set Pixel -> ( List DrawingPosition, Player.Fate )
evaluateMove startingPoint positionsToCheck occupiedPixels =
    let
        checkPositions : List DrawingPosition -> DrawingPosition -> List DrawingPosition -> ( List DrawingPosition, Player.Fate )
        checkPositions checked lastChecked remaining =
            case remaining of
                [] ->
                    ( checked, Player.Lives )

                current :: rest ->
                    let
                        theHitbox =
                            World.hitbox lastChecked current

                        dies =
                            not <| Set.isEmpty <| Set.intersect theHitbox occupiedPixels
                    in
                    if dies then
                        ( checked, Player.Dies )

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
                computedAngleChange

            else
                Angle 0

        angleChangeRight =
            if someIsPressed rightKeys then
                Angle.negate computedAngleChange

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
                (World.drawingPosition player.position)
                (World.desiredDrawingPositions player.position newPosition)
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
                                        Player.Lives ->
                                            updatePlayer model.pressedKeys updatedPixels player

                                        Player.Dies ->
                                            ( [], player )
                            in
                            ( newPlayer :: players
                            , List.foldr
                                (World.pixels >> Set.union)
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
