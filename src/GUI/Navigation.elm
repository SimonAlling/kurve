module GUI.Navigation exposing (Entry, maxButtonLength, showEntry)


type alias Entry =
    ( String, String )


showEntry : Int -> Entry -> String
showEntry firstColumnWidth ( button, description ) =
    String.padRight (firstColumnWidth + columnSpacing) ' ' button
        ++ description


maxButtonLength : List Entry -> Int
maxButtonLength buttonsAndDescriptions =
    buttonsAndDescriptions
        |> List.map (Tuple.first >> String.length)
        |> List.maximum
        |> Maybe.withDefault 0


columnSpacing : Int
columnSpacing =
    2
