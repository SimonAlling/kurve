module MemoryLayout exposing (StateComponent(..), relativeAddressFor)

import ModMem exposing (RelativeAddress(..))
import OriginalGamePlayers exposing (PlayerId, numberOfPlayers, playerIndex)


type StateComponent
    = X
    | Y
    | Dir


relativeAddressFor : PlayerId -> StateComponent -> RelativeAddress
relativeAddressFor playerId stateComponent =
    let
        (RelativeAddress arrayStart) =
            case stateComponent of
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
