module Main exposing (main)

import Canvas exposing (bodyDrawingCmds, clearCanvasAndDrawSpawns, clearOverlay, headDrawingCmds)
import Color exposing (Color)
import Config
import Input exposing (Button(..), ButtonDirection(..), UserInteraction, inputSubscriptions, updatePressedButtons)
import Platform exposing (worker)
import Random
import Random.Extra as Random
import Set exposing (Set(..))
import Spawn exposing (generateHoleSize, generateHoleSpacing, generatePlayers)
import Time
import Types.Angle as Angle exposing (Angle(..))
import Types.Distance as Distance exposing (Distance(..))
import Types.Player as Player exposing (Player)
import Types.Radius as Radius exposing (Radius(..))
import Types.Speed as Speed exposing (Speed(..))
import Types.Thickness as Thickness exposing (Thickness(..))
import Types.Tickrate as Tickrate exposing (Tickrate(..))
import World exposing (DrawingPosition, Pixel, distanceToTicks)


type alias Model =
    { pressedButtons : Set String
    , playerConfigs : List Config.PlayerConfig
    , gameState : GameState
    , seed : Random.Seed
    }


type alias Round =
    { players : Players
    , occupiedPixels : Set Pixel
    , history : RoundHistory
    , tick : Int
    }


type GameState
    = MidRound MidRoundState
    | PostRound Round


type MidRoundState
    = Live Round
    | Replay { emulatedPressedButtons : Set String } Round


type alias RoundInitialState =
    { seed : Random.Seed
    , pressedButtons : Set String
    }


type alias RoundHistory =
    { initialState : RoundInitialState
    , reversedUserInteractions : List UserInteraction
    }


type alias Players =
    { alive : List Player
    , dead : List Player
    }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        ( ( gameState, cmd ), seed ) =
            Tuple.mapFirst newRoundGameStateAndCmd <| prepareLiveRound Config.players (Random.initialSeed 1337) Set.empty
    in
    ( { pressedButtons = Set.empty
      , playerConfigs = Config.players
      , gameState = gameState
      , seed = seed
      }
    , cmd
    )


startRound : Model -> ( MidRoundState, Random.Seed ) -> ( Model, Cmd msg )
startRound model midRoundStateAndSeed =
    let
        ( ( gameState, cmd ), seed ) =
            Tuple.mapFirst newRoundGameStateAndCmd midRoundStateAndSeed
    in
    ( { model | gameState = gameState, seed = seed }, cmd )


newRoundGameStateAndCmd : MidRoundState -> ( GameState, Cmd msg )
newRoundGameStateAndCmd midRoundState =
    ( MidRound midRoundState
    , extractRound midRoundState |> .players |> .alive |> clearCanvasAndDrawSpawns
    )


prepareLiveRound : List Config.PlayerConfig -> Random.Seed -> Set String -> ( MidRoundState, Random.Seed )
prepareLiveRound playerConfigs seed pressedButtons =
    prepareRoundHelper playerConfigs { seed = seed, pressedButtons = pressedButtons } [] |> Tuple.mapFirst Live


prepareReplayRound : List Config.PlayerConfig -> RoundInitialState -> List UserInteraction -> ( MidRoundState, Random.Seed )
prepareReplayRound playerConfigs initialState reversedUserInteractions =
    prepareRoundHelper playerConfigs initialState reversedUserInteractions |> Tuple.mapFirst (Replay { emulatedPressedButtons = initialState.pressedButtons })


prepareRoundHelper : List Config.PlayerConfig -> RoundInitialState -> List UserInteraction -> ( Round, Random.Seed )
prepareRoundHelper playerConfigs initialState reversedUserInteractions =
    let
        ( thePlayers, newSeed ) =
            Random.step (generatePlayers playerConfigs) initialState.seed

        thickness =
            Config.thickness

        round =
            { players = { alive = thePlayers, dead = [] }
            , occupiedPixels = List.foldr (.position >> World.drawingPosition thickness >> World.pixelsToOccupy thickness >> Set.union) Set.empty thePlayers
            , history =
                { initialState = initialState
                , reversedUserInteractions = reversedUserInteractions
                }
            , tick = 0
            }
    in
    ( round, newSeed )


{-| Takes the distance between the _edges_ of two drawn squares and returns the distance between their _centers_.
-}
computeDistanceBetweenCenters : Distance -> Distance
computeDistanceBetweenCenters distanceBetweenEdges =
    Distance <| Distance.toFloat distanceBetweenEdges + toFloat (Thickness.toInt Config.thickness)


type Msg
    = Tick MidRoundState
    | ButtonUsed ButtonDirection Button


type TurningState
    = TurningLeft
    | TurningRight
    | NotTurning


computeAngleChange : TurningState -> Angle
computeAngleChange turningState =
    case turningState of
        TurningLeft ->
            computedAngleChange

        TurningRight ->
            Angle.negate computedAngleChange

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


computedAngleChange : Angle
computedAngleChange =
    Angle (Speed.toFloat Config.speed / (Tickrate.toFloat Config.tickrate * Radius.toFloat Config.turningRadius))


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
                            World.hitbox Config.thickness lastChecked current

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
updatePlayer pressedButtons occupiedPixels player =
    let
        distanceTraveledSinceLastTick =
            Speed.toFloat Config.speed / Tickrate.toFloat Config.tickrate

        newDirection =
            Angle.add player.direction <| computeAngleChange <| computeTurningState pressedButtons player

        ( x, y ) =
            player.position

        newPosition =
            ( x + distanceTraveledSinceLastTick * Angle.cos newDirection
            , -- The coordinate system is traditionally "flipped" (wrt standard math) such that the Y axis points downwards.
              -- Therefore, we have to use minus instead of plus for the Y-axis calculation.
              y - distanceTraveledSinceLastTick * Angle.sin newDirection
            )

        thickness =
            Config.thickness

        ( confirmedDrawingPositions, fate ) =
            evaluateMove
                (World.drawingPosition thickness player.position)
                (World.desiredDrawingPositions thickness player.position newPosition)
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


considerRecentButtonPresses : RoundHistory -> Int -> Set String -> Set String
considerRecentButtonPresses history previousTick previousPressedButtons =
    history.reversedUserInteractions
        |> List.filter (\k -> k.happenedAfterTick == previousTick)
        |> List.foldr (\k -> updatePressedButtons k.direction k.button) previousPressedButtons


extractRound : MidRoundState -> Round
extractRound s =
    case s of
        Live round ->
            round

        Replay _ round ->
            round


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ pressedButtons } as model) =
    case msg of
        Tick midRoundState ->
            let
                currentRound =
                    extractRound midRoundState

                effectivePressedButtons =
                    case midRoundState of
                        Replay { emulatedPressedButtons } _ ->
                            considerRecentButtonPresses currentRound.history currentRound.tick emulatedPressedButtons

                        _ ->
                            pressedButtons

                checkIndividualPlayer :
                    Player
                    -> ( Random.Generator Players, Set World.Pixel, List ( Color, DrawingPosition ) )
                    ->
                        ( Random.Generator Players
                        , Set World.Pixel
                        , List ( Color, DrawingPosition )
                        )
                checkIndividualPlayer player ( checkedPlayersGenerator, occupiedPixels, coloredDrawingPositions ) =
                    let
                        ( newPlayerDrawingPositions, checkedPlayerGenerator, fate ) =
                            updatePlayer effectivePressedButtons occupiedPixels player

                        occupiedPixelsAfterCheckingThisPlayer =
                            List.foldr
                                (World.pixelsToOccupy Config.thickness >> Set.union)
                                occupiedPixels
                                newPlayerDrawingPositions

                        coloredDrawingPositionsAfterCheckingThisPlayer =
                            coloredDrawingPositions ++ List.map (Tuple.pair player.color) newPlayerDrawingPositions

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

                newCurrentRound =
                    { players = newPlayers
                    , occupiedPixels = newOccupiedPixels
                    , history = currentRound.history
                    , tick = currentRound.tick + 1
                    }

                newGameState =
                    if roundIsOver newPlayers then
                        PostRound newCurrentRound

                    else
                        case midRoundState of
                            Live _ ->
                                MidRound <| Live newCurrentRound

                            Replay _ _ ->
                                MidRound <| Replay { emulatedPressedButtons = effectivePressedButtons } newCurrentRound
            in
            ( { model
                | gameState = newGameState
                , seed = newSeed
              }
            , clearOverlay { width = Config.worldWidth, height = Config.worldHeight }
                :: headDrawingCmds newPlayers.alive
                ++ bodyDrawingCmds newColoredDrawingPositions
                |> Cmd.batch
            )

        ButtonUsed Down button ->
            case model.gameState of
                PostRound finishedRound ->
                    case button of
                        Key "Space" ->
                            startRound model <|
                                prepareLiveRound
                                    model.playerConfigs
                                    model.seed
                                    pressedButtons

                        Key "KeyR" ->
                            startRound model <|
                                prepareReplayRound
                                    model.playerConfigs
                                    finishedRound.history.initialState
                                    finishedRound.history.reversedUserInteractions

                        _ ->
                            ( handleUserInteraction Down button model, Cmd.none )

                _ ->
                    ( handleUserInteraction Down button model, Cmd.none )

        ButtonUsed Up key ->
            ( handleUserInteraction Up key model, Cmd.none )


handleUserInteraction : ButtonDirection -> Button -> Model -> Model
handleUserInteraction direction button model =
    let
        modelWithNewPressedButtons =
            { model | pressedButtons = updatePressedButtons direction button model.pressedButtons }
    in
    case model.gameState of
        MidRound midRoundState ->
            case midRoundState of
                Replay _ _ ->
                    modelWithNewPressedButtons

                Live currentRound ->
                    { modelWithNewPressedButtons | gameState = MidRound (Live <| recordUserInteraction direction button currentRound) }

        PostRound _ ->
            modelWithNewPressedButtons


recordUserInteraction : ButtonDirection -> Button -> Round -> Round
recordUserInteraction direction button ({ history } as currentRound) =
    { currentRound
        | history =
            { history
                | reversedUserInteractions =
                    { happenedAfterTick = currentRound.tick
                    , direction = direction
                    , button = button
                    }
                        :: history.reversedUserInteractions
            }
    }


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
    Sub.batch <|
        (case model.gameState of
            PostRound _ ->
                Sub.none

            MidRound midRoundState ->
                Time.every (1000 / Tickrate.toFloat Config.tickrate) (always <| Tick midRoundState)
        )
            :: inputSubscriptions ButtonUsed


main : Program () Model Msg
main =
    worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
