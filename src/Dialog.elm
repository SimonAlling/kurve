module Dialog exposing (OpenState, Option(..), State(..))

import Cycle exposing (Cycle)


type State
    = Open OpenState
    | NotOpen


type alias OpenState =
    Cycle Option


type Option
    = Confirm
    | Cancel
