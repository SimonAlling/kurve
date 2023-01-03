module Players exposing (AllPlayers, ParticipatingPlayers, atLeastOneIsParticipating, handlePlayerJoiningOrLeaving, includeResultsFrom, initialPlayers, participating)

import Color exposing (Color)
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


handlePlayerJoiningOrLeaving : Button -> AllPlayers -> AllPlayers
handlePlayerJoiningOrLeaving button =
    Dict.map
        (\_ ( player, status ) ->
            let
                ( leftButtons, rightButtons ) =
                    player.controls

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
        rgb : Int -> Int -> Int -> Color
        rgb =
            Color.rgb255
    in
    [ { color = rgb 255 40 0
      , controls = ( [ Key "Digit1" ], [ Key "KeyQ" ] )
      }
    , { color = rgb 195 195 0
      , controls = ( [ Key "ControlLeft", Key "KeyZ" ], [ Key "AltLeft", Key "KeyX" ] )
      }
    , { color = rgb 255 121 0
      , controls = ( [ Key "KeyM" ], [ Key "Comma" ] )
      }
    , { color = rgb 0 203 0
      , controls = ( [ Key "ArrowLeft" ], [ Key "ArrowDown" ] )
      }
    , { color = rgb 223 81 182
      , controls = ( [ Key "NumpadDivide", Key "End", Key "PageDown" ], [ Key "NumpadMultiply", Key "PageUp" ] )
      }
    , { color = rgb 0 162 203
      , controls = ( [ Mouse 0 ], [ Mouse 2 ] )
      }
    ]
