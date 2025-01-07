module Types.FrameTime exposing (FrameTime, LeftoverFrameTime, WithLeftoverFrameTime(..))


type alias FrameTime =
    Float


type alias LeftoverFrameTime =
    FrameTime


type WithLeftoverFrameTime a
    = WithLeftoverFrameTime LeftoverFrameTime a
