module GUI.Navigation.Replay exposing (replayNavigation)

import GUI.Navigation
import Html exposing (Html, div)
import Html.Attributes as Attr


replayNavigation : Html msg
replayNavigation =
    let
        navigationEntries : List GUI.Navigation.Entry
        navigationEntries =
            makeNavigationEntries
    in
    div
        [ Attr.class "replayNavigation"
        ]
        (GUI.Navigation.entries navigationEntries)


makeNavigationEntries : List GUI.Navigation.Entry
makeNavigationEntries =
    [ ( "Enter", "Pause" )
    , ( "Arrows", "Seek" )
    , ( "E", "Step" )
    , ( "R", "Restart" )
    , ( "O", "Overlay" )
    ]
