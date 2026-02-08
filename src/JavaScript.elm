module JavaScript exposing (magicClassNameToPreventUnload)

{-| The JavaScript code should look for elements with this class name to determine whether to prevent unload.
-}


magicClassNameToPreventUnload : String
magicClassNameToPreventUnload =
    "magic-class-name-to-prevent-unload"
