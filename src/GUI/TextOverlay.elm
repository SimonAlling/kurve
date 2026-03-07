module GUI.TextOverlay exposing (textOverlay)

import Base64
import Bytes
import Bytes.Decode
import Bytes.Encode
import Colors
import Flate
import GUI.Hints exposing (Hint(..))
import GUI.Navigation.Replay
import GUI.Text
import Game exposing (GameState(..), LiveOrReplay(..), PausedOrNot(..))
import Html exposing (Html, div, p)
import Html.Attributes as Attr
import Movie
import Overlay
import Round
import Types.Kurve exposing (Kurve)


textOverlay : GameState -> Html msg
textOverlay gameState =
    div
        [ Attr.class "overlay"
        , Attr.class "textOverlay"
        ]
        (content gameState)


content : GameState -> List (Html msg)
content gameState =
    case gameState of
        Active (Live _) Paused _ ->
            [ pressSpaceToContinue ]

        Active (Live _) NotPaused _ ->
            []

        Active (Replay overlayState _) Paused _ ->
            -- Hint on how to continue deliberately omitted here. See the PR/commit that added this comment for details.
            Overlay.ifVisible overlayState [ replayIndicator, GUI.Navigation.Replay.replayNavigation ]

        Active (Replay overlayState _) NotPaused _ ->
            Overlay.ifVisible overlayState [ replayIndicator, GUI.Navigation.Replay.replayNavigation ]

        RoundOver (Live finishedRound) _ _ _ ->
            let
                round =
                    Round.unpackFinished finishedRound

                theKurves : List Kurve
                theKurves =
                    round.kurves.alive ++ round.kurves.dead

                movie =
                    Movie.fromKurves theKurves

                bytes =
                    Bytes.Encode.encode (Movie.encoder movie)

                -- TODO: If we’re gonna do compression, I guess it should be behind the version number so we have the opportunity to improve or fix it in the future?
                compressedBytes =
                    Flate.deflate bytes

                string =
                    Base64.fromBytes compressedBytes |> Maybe.withDefault ""

                maybeDecodedMovie =
                    Base64.toBytes string
                        |> Maybe.andThen Flate.inflate
                        |> Maybe.andThen (Bytes.Decode.decode Movie.decoder)
            in
            [ GUI.Hints.render HowToReplay
            , Html.a [ Attr.href ("?replay=" ++ string) ]
                [ Html.text "Movie link"
                , Html.text " ("
                , if Just (Debug.log "movie" movie) == Debug.log "maybeDecodedMovie" maybeDecodedMovie then
                    Html.text "OK"

                  else
                    Html.text "not equal"
                , Html.text ", "
                , Html.text (String.fromInt (Bytes.width bytes))
                , Html.text ", "
                , Html.text (String.fromInt (Bytes.width compressedBytes))
                , Html.text ", "
                , Html.text (String.fromInt (String.length string))
                , Html.text ")"
                ]
            ]

        RoundOver (Replay overlayState _) _ _ _ ->
            Overlay.ifVisible overlayState [ replayIndicator, GUI.Navigation.Replay.replayNavigation ]


pressSpaceToContinue : Html msg
pressSpaceToContinue =
    p [] <| GUI.Text.string (GUI.Text.Size 2) Colors.white "Press Space to continue"


replayIndicator : Html msg
replayIndicator =
    p
        [ Attr.class "textInUpperLeftCorner"
        ]
        (GUI.Text.string (GUI.Text.Size 2) Colors.white "R")
