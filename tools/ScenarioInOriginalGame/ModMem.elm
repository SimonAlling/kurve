module ModMem exposing
    ( ModMemCmd(..)
    , RelativeAddress(..)
    )


type RelativeAddress
    = RelativeAddress Int -- Int is more than enough here because we're not exactly dealing with gigabytes of memory …


type ModMemCmd
    = ModifyMemory Description RelativeAddress Float


type alias Description =
    String
