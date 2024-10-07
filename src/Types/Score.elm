module Types.Score exposing
    ( Score(..)
    , isAtLeast
    )


type Score
    = Score Int


isAtLeast : Score -> Score -> Bool
isAtLeast (Score threshold) (Score s) =
    s >= threshold
