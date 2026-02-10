module GUI.Navigation exposing (Entry, entries)

import Colors
import GUI.Text
import Html exposing (p)


type alias Entry =
    ( String, String )


entries : List Entry -> List (Html.Html msg)
entries navigationEntries =
    let
        firstColumnWidth : Int
        firstColumnWidth =
            computeFirstColumnWidth navigationEntries
    in
    navigationEntries
        |> List.map
            (\entry ->
                p
                    []
                    (GUI.Text.string
                        (GUI.Text.Size 1)
                        Colors.white
                        (showEntry firstColumnWidth entry)
                    )
            )


showEntry : Int -> Entry -> String
showEntry firstColumnWidth ( button, description ) =
    String.padRight (firstColumnWidth + columnSpacing) ' ' button
        ++ description


computeFirstColumnWidth : List Entry -> Int
computeFirstColumnWidth buttonsAndDescriptions =
    buttonsAndDescriptions
        |> List.map (Tuple.first >> String.length)
        |> List.maximum
        |> Maybe.withDefault 0


columnSpacing : Int
columnSpacing =
    2
