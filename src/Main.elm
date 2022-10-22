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


port clear : { width : Int, height : Int } -> Cmd msg


port renderOverlay : { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clearOverlay : { width : Int, height : Int } -> Cmd msg


port onKeydown : (String -> msg) -> Sub msg


port onKeyup : (String -> msg) -> Sub msg


type alias Model =
    { currentRound : Round
    , mode : Mode
    , seed : Random.Seed
    }


type alias Round =
    { players : Players
    , occupiedPixels : Set Pixel
    , history : RoundHistory
    , tick : Int
    }


type Mode
    = Live { pressedKeys : Set String }
    | Replay { emulatedPressedKeys : Set String }
    | BetweenRounds { pressedKeys : Set String }


type alias RoundInitialState =
    { seed : Random.Seed
    , pressedKeys : Set String
    }


type alias RoundHistory =
    { initialState : RoundInitialState
    , reversedKeyboardInteractions : List KeyboardInteraction
    }


type alias Players =
    { alive : List Player
    , dead : List Player
    }


type alias KeyboardInteraction =
    { happenedAfterTick : Int
    , direction : KeyDirection
    , key : String
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
isTooCloseFor numberOfPlayers point1 point2 =
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
    in
    Distance.toFloat (distanceBetween point1 point2) < min desiredMinimumDistance maxAllowedMinimumDistance


distanceBetween : Position -> Position -> Distance
distanceBetween ( x1, y1 ) ( x2, y2 ) =
    Distance <| sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)


generatePlayer : Int -> List Position -> Config.PlayerConfig -> Random.Generator Player
generatePlayer numberOfPlayers existingPositions config =
    let
        safeSpawnPosition =
            generateSpawnPosition |> Random.filter (isSafeNewPosition numberOfPlayers existingPositions)
    in
    Random.map3
        (\generatedPosition generatedAngle generatedHoleStatus ->
            { config = config
            , position = generatedPosition
            , direction = generatedAngle
            , holeStatus = generatedHoleStatus
            }
        )
        safeSpawnPosition
        generateSpawnAngle
        generateInitialHoleStatus


init : () -> ( Model, Cmd Msg )
init _ =
    startLiveRound (Random.initialSeed 1337) Set.empty


startLiveRound : Random.Seed -> Set String -> ( Model, Cmd Msg )
startLiveRound seed pressedKeys =
    startRoundHelper seed (Live { pressedKeys = pressedKeys }) pressedKeys []


startReplayRound : Random.Seed -> Set String -> List KeyboardInteraction -> ( Model, Cmd Msg )
startReplayRound seed emulatedPressedKeys reversedKeyboardInteractions =
    startRoundHelper seed (Replay { emulatedPressedKeys = emulatedPressedKeys }) emulatedPressedKeys reversedKeyboardInteractions


startRoundHelper : Random.Seed -> Mode -> Set String -> List KeyboardInteraction -> ( Model, Cmd msg )
startRoundHelper seed mode pressedKeys reversedKeyboardInteractions =
    let
        ( thePlayers, newSeed ) =
            Random.step (generatePlayers Config.players) seed
    in
    ( { currentRound =
            { players = { alive = thePlayers, dead = [] }
            , occupiedPixels = List.foldr (.position >> World.drawingPosition >> World.pixelsToOccupy >> Set.union) Set.empty thePlayers
            , history =
                { initialState =
                    { seed = seed
                    , pressedKeys = pressedKeys
                    }
                , reversedKeyboardInteractions = reversedKeyboardInteractions
                }
            , tick = 0
            }
      , mode = mode
      , seed = newSeed
      }
    , clearOverlay { width = Config.worldWidth, height = Config.worldHeight }
        :: clear { width = Config.worldWidth, height = Config.worldHeight }
        :: (thePlayers
                |> List.map
                    (\player ->
                        render
                            { position = World.drawingPosition player.position
                            , thickness = Thickness.toInt Config.thickness
                            , color = player.config.color
                            }
                    )
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


generateInitialHoleStatus : Random.Generator Player.HoleStatus
generateInitialHoleStatus =
    generateHoleSpacing |> Random.map (distanceToTicks Config.speed >> Player.Unholy)


{-| Takes the distance between the _edges_ of two drawn squares and returns the distance between their _centers_.
-}
computeDistanceBetweenCenters : Distance -> Distance
computeDistanceBetweenCenters distanceBetweenEdges =
    Distance <| Distance.toFloat distanceBetweenEdges + toFloat (Thickness.toInt Config.thickness)


type Msg
    = Tick
    | KeyboardUsed KeyDirection String


type KeyDirection
    = Up
    | Down


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


updatePlayer : Set String -> Set Pixel -> Player -> ( List DrawingPosition, Random.Generator Player, Player.Fate )
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

        newHoleStatusGenerator =
            updateHoleStatus Config.speed player.holeStatus

        newPlayer =
            newHoleStatusGenerator
                |> Random.map
                    (\newHoleStatus ->
                        { player
                            | position = newPosition
                            , direction = newDirection
                            , holeStatus = newHoleStatus
                        }
                    )
    in
    ( confirmedDrawingPositions
    , newPlayer
    , fate
    )


updateHoleStatus : Speed -> Player.HoleStatus -> Random.Generator Player.HoleStatus
updateHoleStatus speed holeStatus =
    case holeStatus of
        Player.Holy 0 ->
            generateHoleSpacing |> Random.map (distanceToTicks speed >> Player.Unholy)

        Player.Holy ticksLeft ->
            Random.constant <| Player.Holy (ticksLeft - 1)

        Player.Unholy 0 ->
            generateHoleSize |> Random.map (computeDistanceBetweenCenters >> distanceToTicks speed >> Player.Holy)

        Player.Unholy ticksLeft ->
            Random.constant <| Player.Unholy (ticksLeft - 1)


considerRecentKeyPresses : RoundHistory -> Int -> Set String -> Set String
considerRecentKeyPresses history previousTick previousPressedKeys =
    history.reversedKeyboardInteractions
        |> List.filter (\k -> k.happenedAfterTick == previousTick)
        |> List.foldr (\k -> updatePressedKeys k.direction k.key) previousPressedKeys


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ currentRound } as model) =
    case msg of
        Tick ->
            let
                effectivePressedKeys =
                    case model.mode of
                        Live { pressedKeys } ->
                            pressedKeys

                        Replay { emulatedPressedKeys } ->
                            considerRecentKeyPresses currentRound.history currentRound.tick emulatedPressedKeys

                        BetweenRounds { pressedKeys } ->
                            pressedKeys

                checkIndividualPlayer :
                    Player
                    -> ( Random.Generator Players, Set World.Pixel, List ( String, DrawingPosition ) )
                    ->
                        ( Random.Generator Players
                        , Set World.Pixel
                        , List ( String, DrawingPosition )
                        )
                checkIndividualPlayer player ( checkedPlayersGenerator, occupiedPixels, coloredDrawingPositions ) =
                    let
                        ( newPlayerDrawingPositions, checkedPlayerGenerator, fate ) =
                            updatePlayer effectivePressedKeys occupiedPixels player

                        occupiedPixelsAfterCheckingThisPlayer =
                            List.foldr
                                (World.pixelsToOccupy >> Set.union)
                                occupiedPixels
                                newPlayerDrawingPositions

                        coloredDrawingPositionsAfterCheckingThisPlayer =
                            coloredDrawingPositions ++ List.map (Tuple.pair player.config.color) newPlayerDrawingPositions

                        playersAfterCheckingThisPlayer : Player -> Players -> Players
                        playersAfterCheckingThisPlayer checkedPlayer checkedPlayers =
                            case fate of
                                Player.Dies ->
                                    { checkedPlayers | dead = checkedPlayer :: checkedPlayers.dead }

                                Player.Lives ->
                                    { checkedPlayers | alive = checkedPlayer :: checkedPlayers.alive }
                    in
                    ( Random.map2 playersAfterCheckingThisPlayer checkedPlayerGenerator checkedPlayersGenerator
                    , occupiedPixelsAfterCheckingThisPlayer
                    , coloredDrawingPositionsAfterCheckingThisPlayer
                    )

                ( newPlayersGenerator, newOccupiedPixels, newColoredDrawingPositions ) =
                    List.foldr
                        checkIndividualPlayer
                        ( Random.constant
                            { alive = [] -- We start with the empty list because the new one we'll create may not include all the players from the old one.
                            , dead = currentRound.players.dead -- Dead players, however, will not spring to life again.
                            }
                        , currentRound.occupiedPixels
                        , []
                        )
                        currentRound.players.alive

                ( newPlayers, newSeed ) =
                    Random.step newPlayersGenerator model.seed

                bodyDrawingCmds =
                    newColoredDrawingPositions
                        |> List.map
                            (\( color, position ) ->
                                render
                                    { position = position
                                    , thickness = Thickness.toInt Config.thickness
                                    , color = color
                                    }
                            )

                headDrawingCmds =
                    model.currentRound.players.alive
                        |> List.map
                            (\player ->
                                renderOverlay
                                    { position = World.drawingPosition player.position
                                    , thickness = Thickness.toInt Config.thickness
                                    , color = player.config.color
                                    }
                            )
            in
            ( { currentRound =
                    { players = newPlayers
                    , occupiedPixels = newOccupiedPixels
                    , history = model.currentRound.history
                    , tick = model.currentRound.tick + 1
                    }
              , mode =
                    case model.mode of
                        Live { pressedKeys } ->
                            if roundIsOver newPlayers then
                                BetweenRounds { pressedKeys = pressedKeys }

                            else
                                model.mode

                        Replay _ ->
                            if roundIsOver newPlayers then
                                BetweenRounds { pressedKeys = Set.empty }

                            else
                                Replay { emulatedPressedKeys = effectivePressedKeys }

                        BetweenRounds _ ->
                            model.mode
              , seed = newSeed
              }
            , clearOverlay { width = Config.worldWidth, height = Config.worldHeight }
                :: headDrawingCmds
                ++ bodyDrawingCmds
                |> Cmd.batch
            )

        KeyboardUsed Down key ->
            case model.mode of
                BetweenRounds { pressedKeys } ->
                    case key of
                        "Space" ->
                            startLiveRound model.seed pressedKeys

                        "KeyR" ->
                            startReplayRound
                                currentRound.history.initialState.seed
                                currentRound.history.initialState.pressedKeys
                                currentRound.history.reversedKeyboardInteractions

                        _ ->
                            ( handleKeyboardInteraction Down key model, Cmd.none )

                _ ->
                    ( handleKeyboardInteraction Down key model, Cmd.none )

        KeyboardUsed Up key ->
            ( handleKeyboardInteraction Up key model, Cmd.none )


updatePressedKeys : KeyDirection -> String -> Set String -> Set String
updatePressedKeys direction =
    case direction of
        Down ->
            Set.insert

        Up ->
            Set.remove


handleKeyboardInteraction : KeyDirection -> String -> Model -> Model
handleKeyboardInteraction direction key ({ currentRound } as model) =
    case model.mode of
        Replay _ ->
            model

        Live { pressedKeys } ->
            let
                { history } =
                    currentRound
            in
            { model
                | mode = Live { pressedKeys = updatePressedKeys direction key pressedKeys }
                , currentRound =
                    { currentRound
                        | history =
                            { history
                                | reversedKeyboardInteractions =
                                    { happenedAfterTick = currentRound.tick
                                    , direction = direction
                                    , key = key
                                    }
                                        :: history.reversedKeyboardInteractions
                            }
                    }
            }

        BetweenRounds { pressedKeys } ->
            { model | mode = BetweenRounds { pressedKeys = updatePressedKeys direction key pressedKeys } }


roundIsOver : Players -> Bool
roundIsOver players =
    let
        someoneHasWonInMultiPlayer =
            List.length players.alive == 1 && not (List.isEmpty players.dead)

        playerHasDiedInSinglePlayer =
            List.isEmpty players.alive
    in
    someoneHasWonInMultiPlayer || playerHasDiedInSinglePlayer


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ case model.mode of
            BetweenRounds _ ->
                Sub.none

            _ ->
                Time.every (1000 / Tickrate.toFloat Config.tickrate) (always Tick)
        , onKeydown (KeyboardUsed Down)
        , onKeyup (KeyboardUsed Up)
        ]


main =
    worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
