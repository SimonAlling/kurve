module Hex exposing (hex)

import Integer exposing (Integer)


{-| Same as `hex` in Python.
-}
hex : Integer -> String
hex =
    Integer.toHexString >> String.append "0x" >> String.toLower
