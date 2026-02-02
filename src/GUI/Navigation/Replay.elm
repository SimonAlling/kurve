module GUI.Navigation.Replay exposing
    ( replayNavigationWhenActive
    , replayNavigationWhenRoundOver
    )

import Colors
import GUI.Navigation exposing (Entry)
import GUI.Text
import Html exposing (Html, div, p)
import Html.Attributes as Attr


replayNavigationWhenActive : Html msg
replayNavigationWhenActive =
    replayNavigation PausesOrResumes


replayNavigationWhenRoundOver : Html msg
replayNavigationWhenRoundOver =
    replayNavigation ProceedsToNextRound


replayNavigation : WhatSpaceDoes -> Html msg
replayNavigation whatSpaceDoes =
    let
        navigationEntries : List Entry
        navigationEntries =
            replayButtonsAndDescriptions whatSpaceDoes

        firstColumnWidth : Int
        firstColumnWidth =
            GUI.Navigation.maxButtonLength navigationEntries
    in
    div
        [ Attr.class "replayNavigation"
        ]
        (navigationEntries
            |> List.map
                (\entry ->
                    p
                        []
                        (GUI.Text.string
                            (GUI.Text.Size 1)
                            Colors.white
                            (GUI.Navigation.showEntry firstColumnWidth entry)
                        )
                )
        )


replayButtonsAndDescriptions : WhatSpaceDoes -> List Entry
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
