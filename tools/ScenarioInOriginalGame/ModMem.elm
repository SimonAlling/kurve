module ModMem exposing
    ( AbsoluteAddress(..)
    , ModMemCmd(..)
    , RelativeAddress(..)
    , parseAddress
    , resolveAddress
    , serializeAddress
    )

import Hex exposing (hex)
import Integer exposing (Integer, add)


type AbsoluteAddress
    = AbsoluteAddress Integer -- Int is too small for the addresses we usually see.


type RelativeAddress
    = RelativeAddress Int -- Int is more than enough here because we're not exactly dealing with gigabytes of memory …


type ModMemCmd
    = ModifyMemory RelativeAddress Float


parseAddress : String -> Maybe AbsoluteAddress
parseAddress =
    drop0xPrefixIfPresent >> Integer.fromHexString >> Maybe.map AbsoluteAddress


serializeAddress : AbsoluteAddress -> String
serializeAddress (AbsoluteAddress address) =
    hex address


resolveAddress : AbsoluteAddress -> RelativeAddress -> AbsoluteAddress
resolveAddress (AbsoluteAddress base) (RelativeAddress relative) =
    AbsoluteAddress <| add base (Integer.fromSafeInt relative)


drop0xPrefixIfPresent : String -> String
drop0xPrefixIfPresent s =
    case String.toList s of
        '0' :: 'x' :: rest ->
            String.fromList rest

        _ ->
            s
