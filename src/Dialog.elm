module Dialog exposing
    ( Option(..)
    , State(..)
    )


type State question
    = Open question Option
    | NotOpen


type Option
    = Confirm
    | Cancel
