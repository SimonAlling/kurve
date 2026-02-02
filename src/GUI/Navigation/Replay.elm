module GUI.Navigation.Replay exposing
    ( whenActive
    , whenRoundOver
    )

import Colors
import GUI.Navigation
import GUI.Text
import Html exposing (Html, div, p)
import Html.Attributes as Attr


whenActive : Html msg
whenActive =
    replayNavigation PausesOrResumes


whenRoundOver : Html msg
whenRoundOver =
    replayNavigation ProceedsToNextRound


replayNavigation : WhatSpaceDoes -> Html msg
replayNavigation whatSpaceDoes =
    let
        navigationEntries : List GUI.Navigation.Entry
        navigationEntries =
            makeNavigationEntries whatSpaceDoes

        firstColumnWidth : Int
        firstColumnWidth =
            GUI.Navigation.computeFirstColumnWidth navigationEntries
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


type WhatSpaceDoes
    = PausesOrResumes
    | ProceedsToNextRound


makeNavigationEntries : WhatSpaceDoes -> List GUI.Navigation.Entry
makeNavigationEntries whatSpaceDoes =
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
