module Dialog exposing
    ( Option(..)
    , State(..)
    )


type State
    = Open Option
    | NotOpen


type Option
    = Confirm
    | Cancel
