module MemoryLayout exposing (PlayerProp(..), relativeAddressFor)

import ModMem exposing (RelativeAddress(..))
import OriginalGamePlayers exposing (PlayerId, playerIndex)


type PlayerProp
    = X
    | Y
    | Dir


relativeAddressFor : PlayerId -> PlayerProp -> RelativeAddress
relativeAddressFor playerId property =
    let
        (RelativeAddress arrayStart) =
            case property of
                X ->
                    xsAddress

                Y ->
                    ysAddress

                Dir ->
                    directionsAddress

        index : Int
        index =
            playerIndex playerId
    in
    RelativeAddress (arrayStart + index * sizeOfFloat)


{-| There are 6 players in the original game.
-}
numberOfPlayers : Int
numberOfPlayers =
    6


{-| The x coordinates are stored first.
-}
xsAddress : RelativeAddress
xsAddress =
    RelativeAddress 0


{-| The y coordinates are stored after the x coordinates.
-}
ysAddress : RelativeAddress
ysAddress =
    let
        (RelativeAddress xStart) =
            xsAddress
    in
    RelativeAddress (xStart + spaceForXs)


{-| The directions are stored after the y coordinates.
-}
directionsAddress : RelativeAddress
directionsAddress =
    let
        (RelativeAddress yStart) =
            ysAddress
    in
    RelativeAddress (yStart + spaceForYs)


spaceForXs : Int
spaceForXs =
    numberOfPlayers * sizeOfFloat


spaceForYs : Int
spaceForYs =
    numberOfPlayers * sizeOfFloat


sizeOfFloat : Int
sizeOfFloat =
    4
