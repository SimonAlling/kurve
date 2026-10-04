module ModMem exposing
    ( AbsoluteAddress(..)
    , ModMemCmd(..)
    , RelativeAddress(..)
    , parseAddress
    , serializeAddress
    )

import Hex exposing (hex, parseHex)
import Integer exposing (Integer)


type AbsoluteAddress
    = AbsoluteAddress Integer -- Int is too small for the addresses we usually see.


type RelativeAddress
    = RelativeAddress Int -- Int is more than enough here because we're not exactly dealing with gigabytes of memory …


type ModMemCmd
    = ModifyMemory Description RelativeAddress Float


type alias Description =
    String


parseAddress : String -> Maybe AbsoluteAddress
parseAddress =
    parseHex >> Maybe.map AbsoluteAddress


serializeAddress : AbsoluteAddress -> String
serializeAddress (AbsoluteAddress address) =
    hex address
