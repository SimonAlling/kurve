module GUI.Navigation.Replay exposing (replayNavigation)

import Colors
import GUI.Navigation
import GUI.Text
import Html exposing (Html, div, p)
import Html.Attributes as Attr


replayNavigation : Html msg
replayNavigation =
    let
        navigationEntries : List GUI.Navigation.Entry
        navigationEntries =
            makeNavigationEntries

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


makeNavigationEntries : List GUI.Navigation.Entry
makeNavigationEntries =
    [ ( "Enter", "Pause/resume" )
    , ( "L.Arrow", "Back" )
    , ( "R.Arrow", "Forward" )
    , ( "E", "Step" )
    , ( "R", "Restart" )
    ]
