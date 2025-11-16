module ModMem exposing
    ( AbsoluteAddress(..)
    , ModMemCmd(..)
    , RelativeAddress(..)
    , parseAddress
    , resolveAddress
    , serializeAddress
    )

import Hex exposing (hex, parseHex)
import Integer exposing (Integer, add)


type AbsoluteAddress
    = AbsoluteAddress Integer -- Int is too small for the addresses we usually see.


type RelativeAddress
    = RelativeAddress Int -- Int is more than enough here because we're not exactly dealing with gigabytes of memory …


type ModMemCmd
    = ModifyMemory RelativeAddress Float


parseAddress : String -> Maybe AbsoluteAddress
parseAddress =
    parseHex >> Maybe.map AbsoluteAddress


serializeAddress : AbsoluteAddress -> String
serializeAddress (AbsoluteAddress address) =
    hex address


resolveAddress : AbsoluteAddress -> RelativeAddress -> AbsoluteAddress
resolveAddress (AbsoluteAddress base) (RelativeAddress relative) =
    AbsoluteAddress (add base (Integer.fromSafeInt relative))
