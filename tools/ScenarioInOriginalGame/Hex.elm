module Hex exposing (hex, parseHex)

import Integer exposing (Integer)


{-| Same as `hex` in Python.
-}
hex : Integer -> String
hex =
    Integer.toHexString >> String.append "0x" >> String.toLower


{-| Same as `lambda x: int(x, 16)` in Python.
-}
parseHex : String -> Maybe Integer
parseHex =
    drop0xPrefixIfPresent >> Integer.fromHexString


drop0xPrefixIfPresent : String -> String
drop0xPrefixIfPresent s =
    case String.toList s of
        '0' :: 'x' :: rest ->
            String.fromList rest

        _ ->
            s
