port module Main exposing (main)

import Config
import Platform exposing (worker)
import Random
import Random.Extra as Random
import Set exposing (Set(..))
import Time
import Types.Angle as Angle exposing (Angle(..))
import Types.Distance as Distance exposing (Distance(..))
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
    { players : Players
    , occupiedPixels : Set Pixel
    , pressedKeys : Set String
    }


type alias Players =
    { alive : List Player
    , dead : List Player
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
            generateSpawnPosition |> Random.filter (isSafeNewPosition numberOfPlayers existingPositions)
    in
    Random.map2
        (\generatedPosition generatedAngle ->
            let
                generateHoleStatus =
                    Random.map (distanceToTicks Config.speed >> Player.Unholy) generateHoleSpacing

                ( generatedHoleStatus, steppedSeed ) =
                    Random.step generateHoleStatus <| Random.initialSeed 42
            in
            { config = config
            , position = generatedPosition
            , direction = generatedAngle
            , holeStatus = generatedHoleStatus
            , holeSeed = steppedSeed
            }
        )
        safeSpawnPosition
        generateSpawnAngle


init : () -> ( Model, Cmd Msg )
init _ =
    let
        thePlayers =
            Random.step (generatePlayers Config.players) (Random.initialSeed 1337) |> Tuple.first
    in
    ( { players = { alive = thePlayers, dead = [] }
      , pressedKeys = Set.empty
      , occupiedPixels = List.foldr (.position >> World.drawingPosition >> World.pixelsToOccupy >> Set.union) Set.empty thePlayers
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


generateSpawnPosition : Random.Generator Position
generateSpawnPosition =
    let
        ( ( left, top ), ( right, bottom ) ) =
            spawnArea
    in
    Random.pair (Random.float left right) (Random.float top bottom)


generateSpawnAngle : Random.Generator Angle
generateSpawnAngle =
    Random.float (-pi / 2) (pi / 2) |> Random.map Angle


generateHoleSpacing : Random.Generator Distance
generateHoleSpacing =
    Distance.generate Config.holes.minInterval Config.holes.maxInterval


generateHoleSize : Random.Generator Distance
generateHoleSize =
    Distance.generate Config.holes.minSize Config.holes.maxSize


type Msg
    = Tick Time.Posix
    | KeyWasPressed String
    | KeyWasReleased String


computedAngleChange : Angle
computedAngleChange =
    Angle (Speed.toFloat Config.speed / (Tickrate.toFloat Config.tickrate * Radius.toFloat Config.turningRadius))


distanceToTicks : Speed -> Distance -> Int
distanceToTicks speed distance =
    round <| Tickrate.toFloat Config.tickrate * Distance.toFloat distance / Speed.toFloat speed


evaluateMove : DrawingPosition -> List DrawingPosition -> Set Pixel -> Player.HoleStatus -> ( List DrawingPosition, Player.Fate )
evaluateMove startingPoint positionsToCheck occupiedPixels holeStatus =
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

                        thickness =
                            Thickness.toInt Config.thickness

                        drawsOutsideWorld =
                            List.any ((==) True)
                                [ current.leftEdge < 0
                                , current.topEdge < 0
                                , current.leftEdge > Config.worldWidth - thickness
                                , current.topEdge > Config.worldHeight - thickness
                                ]

                        dies =
                            drawsOutsideWorld || (not <| Set.isEmpty <| Set.intersect theHitbox occupiedPixels)
                    in
                    if dies then
                        ( checked, Player.Dies )

                    else
                        checkPositions (current :: checked) current rest

        isHoly =
            case holeStatus of
                Player.Holy _ ->
                    True

                Player.Unholy _ ->
                    False

        ( checkedPositionsReversed, evaluatedStatus ) =
            checkPositions [] startingPoint positionsToCheck

        positionsToDraw =
            if isHoly then
                case evaluatedStatus of
                    Player.Lives ->
                        []

                    Player.Dies ->
                        -- The player's head must always be drawn when they die, even if they are in the middle of a hole.
                        -- If the player couldn't draw at all in this tick, then the last position where the player could draw before dying (and therefore the one to draw to represent the player's death) is this tick's starting point.
                        -- Otherwise, the last position where the player could draw is the last checked position before death occurred.
                        List.singleton <| Maybe.withDefault startingPoint <| List.head checkedPositionsReversed

            else
                checkedPositionsReversed
    in
    ( positionsToDraw |> List.reverse, evaluatedStatus )


updatePlayer : Set String -> Set Pixel -> Player -> ( List DrawingPosition, Player, Player.Fate )
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
                player.holeStatus

        ( newHoleStatus, newSeed ) =
            updateHoleStatus Config.speed player.holeSeed player.holeStatus
    in
    ( confirmedDrawingPositions
    , { player
        | position = newPosition
        , direction = newDirection
        , holeStatus = newHoleStatus
        , holeSeed = newSeed
      }
    , fate
    )


updateHoleStatus : Speed -> Random.Seed -> Player.HoleStatus -> ( Player.HoleStatus, Random.Seed )
updateHoleStatus speed seed holeStatus =
    case holeStatus of
        Player.Holy 0 ->
            let
                ( distanceToNextHole, newSeed ) =
                    Random.step generateHoleSpacing seed
            in
            ( Player.Unholy (distanceToTicks speed distanceToNextHole), newSeed )

        Player.Holy ticksLeft ->
            ( Player.Holy (ticksLeft - 1), seed )

        Player.Unholy 0 ->
            let
                ( holeSize, newSeed ) =
                    Random.step generateHoleSize seed
            in
            ( Player.Holy (distanceToTicks speed holeSize), newSeed )

        Player.Unholy ticksLeft ->
            ( Player.Unholy (ticksLeft - 1), seed )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick _ ->
            let
                checkIndividualPlayer :
                    Player
                    -> ( Players, Set World.Pixel, List ( String, DrawingPosition ) )
                    ->
                        ( Players
                        , Set World.Pixel
                        , List ( String, DrawingPosition )
                        )
                checkIndividualPlayer player ( checkedPlayers, occupiedPixels, coloredDrawingPositions ) =
                    let
                        ( newPlayerDrawingPositions, checkedPlayer, fate ) =
                            updatePlayer model.pressedKeys occupiedPixels player

                        occupiedPixelsAfterCheckingThisPlayer =
                            List.foldr
                                (World.pixelsToOccupy >> Set.union)
                                occupiedPixels
                                newPlayerDrawingPositions

                        coloredDrawingPositionsAfterCheckingThisPlayer =
                            coloredDrawingPositions ++ List.map (Tuple.pair player.config.color) newPlayerDrawingPositions

                        playersAfterCheckingThisPlayer : Players
                        playersAfterCheckingThisPlayer =
                            case fate of
                                Player.Dies ->
                                    { checkedPlayers | dead = checkedPlayer :: checkedPlayers.dead }

                                Player.Lives ->
                                    { checkedPlayers | alive = checkedPlayer :: checkedPlayers.alive }
                    in
                    ( playersAfterCheckingThisPlayer
                    , occupiedPixelsAfterCheckingThisPlayer
                    , coloredDrawingPositionsAfterCheckingThisPlayer
                    )

                ( newPlayers, newOccupiedPixels, newColoredDrawingPositions ) =
                    List.foldr
                        checkIndividualPlayer
                        ( { alive = [] -- We start with the empty list because the new one we'll create may not include all the players from the old one.
                          , dead = model.players.dead -- Dead players, however, will not spring to life again.
                          }
                        , model.occupiedPixels
                        , []
                        )
                        model.players.alive
            in
            ( { players = newPlayers
              , occupiedPixels = newOccupiedPixels
              , pressedKeys = model.pressedKeys
              }
            , newColoredDrawingPositions
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
