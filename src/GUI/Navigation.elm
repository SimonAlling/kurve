module GUI.Navigation exposing
    ( replayNavigationWhenActive
    , replayNavigationWhenRoundOver
    )

import Colors
import GUI.Text
import Html exposing (Html, div, p)
import Html.Attributes as Attr


type alias ButtonAndDescription =
    ( String, String )


replayNavigationWhenActive : Html msg
replayNavigationWhenActive =
    replayNavigation PausesOrResumes


replayNavigationWhenRoundOver : Html msg
replayNavigationWhenRoundOver =
    replayNavigation ProceedsToNextRound


replayNavigation : WhatSpaceDoes -> Html msg
replayNavigation whatSpaceDoes =
    let
        buttonsAndDescriptions : List ButtonAndDescription
        buttonsAndDescriptions =
            replayButtonsAndDescriptions whatSpaceDoes

        firstColumnWidth : Int
        firstColumnWidth =
            maxButtonLength buttonsAndDescriptions
    in
    div
        [ Attr.class "replayNavigation"
        ]
        (buttonsAndDescriptions
            |> List.map
                (\buttonAndDescription ->
                    p
                        []
                        (GUI.Text.string
                            (GUI.Text.Size 1)
                            Colors.white
                            (replayNavigationLine firstColumnWidth buttonAndDescription)
                        )
                )
        )


replayButtonsAndDescriptions : WhatSpaceDoes -> List ButtonAndDescription
replayButtonsAndDescriptions whatSpaceDoes =
    [ ( "Space", showWhatSpaceDoes whatSpaceDoes )
    , ( "L.Arrow", "Back" )
    , ( "R.Arrow", "Forward" )
    , ( "E", "Step" )
    , ( "R", "Restart" )
    ]


showWhatSpaceDoes : WhatSpaceDoes -> String
showWhatSpaceDoes whatSpaceDoes =
    case whatSpaceDoes of
        PausesOrResumes ->
            "Pause/resume"

        ProceedsToNextRound ->
            "Next round"


type WhatSpaceDoes
    = PausesOrResumes
    | ProceedsToNextRound


replayNavigationLine : Int -> ButtonAndDescription -> String
replayNavigationLine firstColumnWidth ( button, description ) =
    String.padRight (firstColumnWidth + columnSpacing) ' ' button
        ++ description


columnSpacing : Int
columnSpacing =
    2


maxButtonLength : List ButtonAndDescription -> Int
maxButtonLength buttonsAndDescriptions =
    buttonsAndDescriptions
        |> List.map (Tuple.first >> String.length)
        |> List.maximum
        |> Maybe.withDefault 0
