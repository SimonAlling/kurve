module Players exposing (AllPlayers, ParticipatingPlayers, initialPlayers, participating)

import Color exposing (Color)
import Dict exposing (Dict)
import Input exposing (Button(..))
import Types.Player exposing (Player)
import Types.PlayerId exposing (PlayerId)
import Types.PlayerStatus exposing (PlayerStatus(..))


type alias AllPlayers =
    Dict PlayerId ( Player, PlayerStatus )


type alias ParticipatingPlayers =
    Dict PlayerId Player


participating : AllPlayers -> ParticipatingPlayers
participating =
    let
        includeIfParticipating : PlayerId -> ( Player, PlayerStatus ) -> ParticipatingPlayers -> ParticipatingPlayers
        includeIfParticipating id ( player, status ) =
            case status of
                Participating ->
                    Dict.insert id player

                NotParticipating ->
                    identity
    in
    Dict.foldl includeIfParticipating Dict.empty


initialPlayers : AllPlayers
initialPlayers =
    players |> List.indexedMap (\id player -> ( id, ( player, Participating ) )) |> Dict.fromList


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
