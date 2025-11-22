module OriginalGamePlayers exposing (PlayerId(..), numberOfPlayers, playerIndex, playerName)


type PlayerId
    = Red
    | Yellow
    | Orange
    | Green
    | Pink
    | Blue


numberOfPlayers : Int
numberOfPlayers =
    6


playerIndex : PlayerId -> Int
playerIndex playerId =
    case playerId of
        Red ->
            0

        Yellow ->
            1

        Orange ->
            2

        Green ->
            3

        Pink ->
            4

        Blue ->
            5


playerName : PlayerId -> String
playerName playerId =
    case playerId of
        Red ->
            "Red"

        Yellow ->
            "Yellow"

        Orange ->
            "Orange"

        Green ->
            "Green"

        Pink ->
            "Pink"

        Blue ->
            "Blue"
