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
    div
        [ Attr.class "replayNavigation"
        ]
        (replayButtonsAndDescriptions whatSpaceDoes
            |> List.map
                (\buttonAndDescription ->
                    p
                        []
                        (GUI.Text.string
                            (GUI.Text.Size 1)
                            Colors.white
                            (replayNavigationLine buttonAndDescription)
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
    (case whatSpaceDoes of
        PausesOrResumes ->
            "Pause/resume"

        ProceedsToNextRound ->
            "Next round"
    )
        -- They must have the same length so that the layout isn't affected when the string is changed.
        |> String.padRight 12 ' '


type WhatSpaceDoes
    = PausesOrResumes
    | ProceedsToNextRound


replayNavigationLine : ButtonAndDescription -> String
replayNavigationLine ( button, description ) =
    String.padRight (maxButtonLength + columnSpacing) ' ' button
        ++ description


columnSpacing : Int
columnSpacing =
    2


maxButtonLength : Int
maxButtonLength =
    replayButtonsAndDescriptions PausesOrResumes
        |> List.map (Tuple.first >> String.length)
        |> List.maximum
        |> Maybe.withDefault 0
