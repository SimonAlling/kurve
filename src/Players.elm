module Players exposing
    ( AllPlayers
    , ParticipatingPlayers
    , atLeastOneIsParticipating
    , everyoneLeaves
    , getAllPlayerButtons
    , handlePlayerJoiningOrLeaving
    , includeResultsFrom
    , initialPlayers
    , participating
    )

import Colors
import Dict exposing (Dict)
import Input exposing (Button(..))
import Round exposing (Round)
import Types.Player exposing (Player)
import Types.PlayerId exposing (PlayerId)
import Types.PlayerStatus exposing (PlayerStatus(..))
import Types.Score exposing (Score(..))


type alias AllPlayers =
    Dict PlayerId ( Player, PlayerStatus )


type alias ParticipatingPlayers =
    Dict PlayerId ( Player, Score )


handlePlayerJoiningOrLeaving : Bool -> Button -> AllPlayers -> AllPlayers
handlePlayerJoiningOrLeaving enableAlternativeControls button =
    Dict.map
        (\_ ( player, status ) ->
            let
                ( leftButtons, rightButtons ) =
                    player.controls |> Input.withOnlyPrimaryUnless enableAlternativeControls

                newStatus : PlayerStatus
                newStatus =
                    case ( List.member button leftButtons, List.member button rightButtons ) of
                        ( True, False ) ->
                            Participating (Score 0)

                        ( False, True ) ->
                            NotParticipating

                        _ ->
                            -- This case either represents that the pressed button isn't used by the player in question at all, or the absurd scenario that it's used by said player for turning _both_ left and right.
                            status
            in
            ( player, newStatus )
        )


everyoneLeaves : AllPlayers -> AllPlayers
everyoneLeaves =
    Dict.map (always (Tuple.mapSecond (always NotParticipating)))


participating : AllPlayers -> ParticipatingPlayers
participating =
    let
        includeIfParticipating : PlayerId -> ( Player, PlayerStatus ) -> ParticipatingPlayers -> ParticipatingPlayers
        includeIfParticipating id ( player, status ) =
            case status of
                Participating score ->
                    Dict.insert id ( player, score )

                NotParticipating ->
                    identity
    in
    Dict.foldl includeIfParticipating Dict.empty


atLeastOneIsParticipating : AllPlayers -> Bool
atLeastOneIsParticipating =
    participating >> Dict.isEmpty >> not


{-| Merges the results from the given (ongoing or finished) round with the existing ones. Players are assumed to be represented in both sets of results.
-}
includeResultsFrom : Round -> AllPlayers -> AllPlayers
includeResultsFrom round =
    Dict.map (\id -> Tuple.mapSecond (Dict.get id (Round.scores round) |> combineScores))


combineScores : Maybe Score -> PlayerStatus -> PlayerStatus
combineScores scoreInRound status =
    case ( status, scoreInRound ) of
        ( Participating (Score fromBefore), Just (Score inRound) ) ->
            Participating <| Score <| fromBefore + inRound

        _ ->
            NotParticipating


initialPlayers : AllPlayers
initialPlayers =
    players |> List.indexedMap (\id player -> ( id, ( player, NotParticipating ) )) |> Dict.fromList


players : List Player
players =
    let
        red : Player
        red =
            { color = Colors.red
            , controls = ( [ Key "Digit1" ], [ Key "KeyQ" ] )
            }

        yellow : Player
        yellow =
            { color = Colors.yellow
            , controls = ( [ Key "ControlLeft", Key "KeyZ" ], [ Key "AltLeft", Key "KeyX" ] )
            }

        orange : Player
        orange =
            { color = Colors.orange
            , controls = ( [ Key "KeyM" ], [ Key "Comma" ] )
            }

        green : Player
        green =
            { color = Colors.green
            , controls = ( [ Key "ArrowLeft" ], [ Key "ArrowDown", Key "ArrowRight" ] )
            }

        pink : Player
        pink =
            { color = Colors.pink
            , controls = ( [ Key "NumpadDivide", Key "End", Key "PageDown" ], [ Key "NumpadMultiply", Key "PageUp" ] )
            }

        blue : Player
        blue =
            { color = Colors.blue
            , controls = ( [ Mouse 0 ], [ Mouse 2 ] )
            }
    in
    [ red
    , yellow
    , orange
    , green
    , pink
    , blue
    ]


getAllPlayerButtons : AllPlayers -> List Button
getAllPlayerButtons =
    Dict.foldl (\_ ( player, _ ) acc -> buttonsFor player ++ acc) []


buttonsFor : Player -> List Button
buttonsFor player =
    let
        ( leftButtons, rightButtons ) =
            player.controls
    in
    leftButtons ++ rightButtons
