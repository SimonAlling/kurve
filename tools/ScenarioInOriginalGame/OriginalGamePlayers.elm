module OriginalGamePlayers exposing (PlayerId(..), playerIndex)


type PlayerId
    = Red
    | Yellow
    | Orange
    | Green
    | Pink
    | Blue


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
