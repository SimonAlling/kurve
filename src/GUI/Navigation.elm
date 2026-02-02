module GUI.Navigation exposing (Entry, computeFirstColumnWidth, showEntry)


type alias Entry =
    ( String, String )


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
