port module Main exposing (main)

import Config
import Platform exposing (worker)
import Random
import Random.Extra as Random
import Set exposing (Set(..))
import Time
import Types.Angle as Angle exposing (Angle(..))
import Types.Player as Player exposing (Player)
import Types.Radius as Radius exposing (Radius(..))
import Types.Speed as Speed exposing (Speed(..))
import Types.Thickness as Thickness exposing (Thickness(..))
import Types.Tickrate as Tickrate exposing (Tickrate(..))
import World exposing (DrawingPosition, Pixel, Position)


port render : { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port onKeydown : (String -> msg) -> Sub msg


port onKeyup : (String -> msg) -> Sub msg


type alias Model =
    { players : List Player
    , occupiedPixels : Set Pixel
    , pressedKeys : Set String
    }


generatePlayers : List Config.PlayerConfig -> Random.Generator (List Player)
generatePlayers configs =
    let
        numberOfPlayers =
            List.length configs

        generateNewAndPrepend : Config.PlayerConfig -> List Player -> Random.Generator (List Player)
        generateNewAndPrepend config precedingPlayers =
            generatePlayer numberOfPlayers (List.map .position precedingPlayers) config
                |> Random.map (\player -> player :: precedingPlayers)

        generateReversedPlayers =
            List.foldl
                (Random.andThen << generateNewAndPrepend)
                (Random.constant [])
                configs
    in
    generateReversedPlayers |> Random.map List.reverse


isSafeNewPosition : Int -> List Position -> Position -> Bool
isSafeNewPosition numberOfPlayers existingPositions newPosition =
    List.all (not << isTooCloseFor numberOfPlayers newPosition) existingPositions


isTooCloseFor : Int -> Position -> Position -> Bool
isTooCloseFor numberOfPlayers ( x1, y1 ) ( x2, y2 ) =
    let
        desiredMinimumDistance =
            toFloat (Thickness.toInt Config.thickness) + Radius.toFloat Config.turningRadius * Config.desiredMinimumSpawnDistanceTurningRadiusFactor

        ( ( left, top ), ( right, bottom ) ) =
            spawnArea

        availableArea =
            (right - left) * (bottom - top)

        -- Derived from:
        -- audacity × total available area > number of players × ( max allowed minimum distance / 2 )² × pi
        maxAllowedMinimumDistance =
            2 * sqrt (Config.spawnProtectionAudacity * availableArea / (toFloat numberOfPlayers * pi))

        distance =
            sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
    in
    distance < min desiredMinimumDistance maxAllowedMinimumDistance


generatePlayer : Int -> List Position -> Config.PlayerConfig -> Random.Generator Player
generatePlayer numberOfPlayers existingPositions config =
    let
        safeSpawnPosition =
            spawnPosition |> Random.filter (isSafeNewPosition numberOfPlayers existingPositions)
    in
    Random.map2
        (\generatedPosition generatedAngle ->
            { config = config
            , position = generatedPosition
            , direction = generatedAngle
            , fate = Player.Lives
            }
        )
        safeSpawnPosition
        spawnAngle


init : () -> ( Model, Cmd Msg )
init _ =
    let
        thePlayers =
            Random.step (generatePlayers Config.players) (Random.initialSeed 1337) |> Tuple.first
    in
    ( { players = thePlayers
      , pressedKeys = Set.empty
      , occupiedPixels = List.foldr (.position >> World.drawingPosition >> World.pixels >> Set.union) Set.empty thePlayers
      }
    , thePlayers
        |> List.map
            (\player ->
                render
                    { position = World.drawingPosition player.position
                    , thickness = Thickness.toInt Config.thickness
                    , color = player.config.color
                    }
            )
        |> Cmd.batch
    )


spawnArea : ( Position, Position )
spawnArea =
    let
        topLeft =
            ( Config.spawnMargin
            , Config.spawnMargin
            )

        bottomRight =
            ( toFloat Config.worldWidth - Config.spawnMargin
            , toFloat Config.worldHeight - Config.spawnMargin
            )
    in
    ( topLeft, bottomRight )


spawnPosition : Random.Generator Position
spawnPosition =
    let
        ( ( left, top ), ( right, bottom ) ) =
            spawnArea
    in
    Random.pair (Random.float left right) (Random.float top bottom)


spawnAngle : Random.Generator Angle
spawnAngle =
    Random.float (-pi / 2) (pi / 2) |> Random.map Angle


type Msg
    = Tick Time.Posix
    | KeyWasPressed String
    | KeyWasReleased String


computedAngleChange : Angle
computedAngleChange =
    Angle (Speed.toFloat Config.speed / (Tickrate.toFloat Config.tickrate * Radius.toFloat Config.turningRadius))


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
            Speed.toFloat Config.speed / Tickrate.toFloat Config.tickrate

        ( leftKeys, rightKeys ) =
            player.config.controls

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
                            , coloredDrawingPositions ++ List.map (Tuple.pair player.config.color) newPlayerDrawingPositions
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
                            , thickness = Thickness.toInt Config.thickness
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
        [ Time.every (1000 / Tickrate.toFloat Config.tickrate) Tick
        , onKeydown KeyWasPressed
        , onKeyup KeyWasReleased
        ]


main =
    worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
