module ScenarioInOriginalGameTest exposing (tests)

import CompileScenario exposing (CompilationResult(..), compileScenario)
import Expect
import OriginalGamePlayers exposing (PlayerId(..))
import ScenarioCore exposing (Scenario)
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "Scenario compilation"
        [ test "Scenario with Red and Green in parallel" <|
            \_ ->
                compileScenario
                    [ "EXAMPLE_BASE_ADDRESS_PLACEHOLDER" ]
                    scenario_RedAndGreenInParallel
                    |> Expect.equal expectedResult_RedAndGreenInParallel
        , test "Scenario with all players" <|
            \_ ->
                compileScenario
                    [ "VERY_COOL_BASE_ADDRESS_PLACEHOLDER" ]
                    scenario_AllPlayers
                    |> Expect.equal expectedResult_AllPlayers
        , test "Empty base address placeholder" <|
            \_ ->
                compileScenario
                    [ "" ]
                    scenario_Empty
                    |> Expect.equal (CompilationFailure "Base address placeholder cannot be empty or consist only of whitespace.")
        , test "Whitespace-only base address placeholder" <|
            \_ ->
                compileScenario
                    [ "   " ]
                    scenario_Empty
                    |> Expect.equal (CompilationFailure "Base address placeholder cannot be empty or consist only of whitespace.")
        , test "Too few arguments" <|
            \_ ->
                compileScenario
                    []
                    scenario_Empty
                    |> Expect.equal (CompilationFailure "Unexpected number of arguments. Expected 1, but got 0.")
        , test "Too many arguments" <|
            \_ ->
                compileScenario
                    [ "foo", "bar" ]
                    scenario_Empty
                    |> Expect.equal (CompilationFailure "Unexpected number of arguments. Expected 1, but got 2.")
        , test "No players" <|
            \_ ->
                compileScenario
                    [ "EXAMPLE_BASE_ADDRESS_PLACEHOLDER" ]
                    scenario_Empty
                    |> Expect.equal (CompilationFailure "Scenario must have at least 2 players, but had 0.")
        , test "Only one player" <|
            \_ ->
                compileScenario
                    [ "EXAMPLE_BASE_ADDRESS_PLACEHOLDER" ]
                    scenario_OnlyOnePlayer
                    |> Expect.equal (CompilationFailure "Scenario must have at least 2 players, but had 1.")
        , test "Duplicate player" <|
            \_ ->
                compileScenario
                    [ "EXAMPLE_BASE_ADDRESS_PLACEHOLDER" ]
                    scenario_DuplicatePlayer
                    |> Expect.equal (CompilationFailure "Red specified more than once.")
        , test "Players in wrong order" <|
            \_ ->
                compileScenario
                    [ "EXAMPLE_BASE_ADDRESS_PLACEHOLDER" ]
                    scenario_WrongOrder
                    |> Expect.equal (CompilationFailure "Players must be specified in this order: Red, Yellow, Orange, Green, Pink, Blue.")
        ]


scenario_Empty : Scenario
scenario_Empty =
    []


scenario_OnlyOnePlayer : Scenario
scenario_OnlyOnePlayer =
    [ ( Red
      , { x = 0
        , y = 0
        , direction = 0
        }
      )
    ]


scenario_DuplicatePlayer : Scenario
scenario_DuplicatePlayer =
    [ ( Red
      , { x = 0
        , y = 0
        , direction = 0
        }
      )
    , ( Red
      , { x = 5
        , y = 5
        , direction = 5
        }
      )
    ]


scenario_WrongOrder : Scenario
scenario_WrongOrder =
    [ ( Red
      , { x = 0
        , y = 0
        , direction = 0
        }
      )
    , ( Green
      , { x = 5
        , y = 5
        , direction = 5
        }
      )
    , ( Yellow
      , { x = 10
        , y = 10
        , direction = 10
        }
      )
    ]


scenario_RedAndGreenInParallel : Scenario
scenario_RedAndGreenInParallel =
    [ ( Red
      , { x = 10
        , y = 10
        , direction = pi / 2
        }
      )
    , ( Green
      , { x = 200
        , y = 150
        , direction = pi / 2
        }
      )
    ]


expectedResult_RedAndGreenInParallel : CompilationResult
expectedResult_RedAndGreenInParallel =
    CompilationSuccess
        { participating = [ Red, Green ]
        , compiledProgram =
            String.trim <|
                """
set $theBaseAddress = EXAMPLE_BASE_ADDRESS_PLACEHOLDER
set pagination off
set logging file gdb-log.txt
set logging overwrite on
set logging enabled on

print "⏳ 🟥 Set Red's x"
watch *(float*)($theBaseAddress + 0)
commands
set {float}($theBaseAddress + 0) = 10
delete $bpnum
print "✅ 🟥 Set Red's x"

print "⏳ 🔧 Ignore bogus write to Red's y"
watch *(float*)($theBaseAddress + 24)
commands
x/4bx ($theBaseAddress + 24)
delete $bpnum
print "✅ 🔧 Ignore bogus write to Red's y"

print "⏳ 🔧 Ignore bogus write to Red's y"
watch *(float*)($theBaseAddress + 24)
commands
x/4bx ($theBaseAddress + 24)
delete $bpnum
print "✅ 🔧 Ignore bogus write to Red's y"

print "⏳ 🟥 Set Red's y"
watch *(float*)($theBaseAddress + 24)
commands
set {float}($theBaseAddress + 24) = 10
delete $bpnum
print "✅ 🟥 Set Red's y"

print "⏳ 🟥 Set Red's direction"
watch *(float*)($theBaseAddress + 48)
commands
set {float}($theBaseAddress + 48) = 1.5707963267948966
delete $bpnum
print "✅ 🟥 Set Red's direction"

print "⏳ 🟩 Set Green's x"
watch *(float*)($theBaseAddress + 12)
commands
set {float}($theBaseAddress + 12) = 200
delete $bpnum
print "✅ 🟩 Set Green's x"

print "⏳ 🟩 Set Green's y"
watch *(float*)($theBaseAddress + 36)
commands
set {float}($theBaseAddress + 36) = 150
delete $bpnum
print "✅ 🟩 Set Green's y"

print "⏳ 🟩 Set Green's direction"
watch *(float*)($theBaseAddress + 60)
commands
set {float}($theBaseAddress + 60) = 1.5707963267948966
delete $bpnum
print "✅ 🟩 Set Green's direction"
exit
continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
                """
        }


scenario_AllPlayers : Scenario
scenario_AllPlayers =
    [ ( Red
      , { x = 10
        , y = 10
        , direction = pi / 2
        }
      )
    , ( Yellow
      , { x = 10
        , y = 50
        , direction = 0
        }
      )
    , ( Orange
      , { x = 200
        , y = 200
        , direction = 2.5
        }
      )
    , ( Green
      , { x = 200
        , y = 250
        , direction = 3 * pi / 4
        }
      )
    , ( Pink
      , { x = 500
        , y = 477
        , direction = -pi / 2
        }
      )
    , ( Blue
      , { x = 400
        , y = 234.5
        , direction = 0.01
        }
      )
    ]


expectedResult_AllPlayers : CompilationResult
expectedResult_AllPlayers =
    CompilationSuccess
        { participating = [ Red, Yellow, Orange, Green, Pink, Blue ]
        , compiledProgram =
            String.trim <|
                """
set $theBaseAddress = VERY_COOL_BASE_ADDRESS_PLACEHOLDER
set pagination off
set logging file gdb-log.txt
set logging overwrite on
set logging enabled on

print "⏳ 🟥 Set Red's x"
watch *(float*)($theBaseAddress + 0)
commands
set {float}($theBaseAddress + 0) = 10
delete $bpnum
print "✅ 🟥 Set Red's x"

print "⏳ 🔧 Ignore bogus write to Red's y"
watch *(float*)($theBaseAddress + 24)
commands
x/4bx ($theBaseAddress + 24)
delete $bpnum
print "✅ 🔧 Ignore bogus write to Red's y"

print "⏳ 🔧 Ignore bogus write to Red's y"
watch *(float*)($theBaseAddress + 24)
commands
x/4bx ($theBaseAddress + 24)
delete $bpnum
print "✅ 🔧 Ignore bogus write to Red's y"

print "⏳ 🟥 Set Red's y"
watch *(float*)($theBaseAddress + 24)
commands
set {float}($theBaseAddress + 24) = 10
delete $bpnum
print "✅ 🟥 Set Red's y"

print "⏳ 🟥 Set Red's direction"
watch *(float*)($theBaseAddress + 48)
commands
set {float}($theBaseAddress + 48) = 1.5707963267948966
delete $bpnum
print "✅ 🟥 Set Red's direction"

print "⏳ 🟨 Set Yellow's x"
watch *(float*)($theBaseAddress + 4)
commands
set {float}($theBaseAddress + 4) = 10
delete $bpnum
print "✅ 🟨 Set Yellow's x"

print "⏳ 🟨 Set Yellow's y"
watch *(float*)($theBaseAddress + 28)
commands
set {float}($theBaseAddress + 28) = 50
delete $bpnum
print "✅ 🟨 Set Yellow's y"

print "⏳ 🟨 Set Yellow's direction"
watch *(float*)($theBaseAddress + 52)
commands
set {float}($theBaseAddress + 52) = 0
delete $bpnum
print "✅ 🟨 Set Yellow's direction"

print "⏳ 🟧 Set Orange's x"
watch *(float*)($theBaseAddress + 8)
commands
set {float}($theBaseAddress + 8) = 200
delete $bpnum
print "✅ 🟧 Set Orange's x"

print "⏳ 🟧 Set Orange's y"
watch *(float*)($theBaseAddress + 32)
commands
set {float}($theBaseAddress + 32) = 200
delete $bpnum
print "✅ 🟧 Set Orange's y"

print "⏳ 🟧 Set Orange's direction"
watch *(float*)($theBaseAddress + 56)
commands
set {float}($theBaseAddress + 56) = 2.5
delete $bpnum
print "✅ 🟧 Set Orange's direction"

print "⏳ 🟩 Set Green's x"
watch *(float*)($theBaseAddress + 12)
commands
set {float}($theBaseAddress + 12) = 200
delete $bpnum
print "✅ 🟩 Set Green's x"

print "⏳ 🟩 Set Green's y"
watch *(float*)($theBaseAddress + 36)
commands
set {float}($theBaseAddress + 36) = 250
delete $bpnum
print "✅ 🟩 Set Green's y"

print "⏳ 🟩 Set Green's direction"
watch *(float*)($theBaseAddress + 60)
commands
set {float}($theBaseAddress + 60) = 2.356194490192345
delete $bpnum
print "✅ 🟩 Set Green's direction"

print "⏳ 🟪 Set Pink's x"
watch *(float*)($theBaseAddress + 16)
commands
set {float}($theBaseAddress + 16) = 500
delete $bpnum
print "✅ 🟪 Set Pink's x"

print "⏳ 🟪 Set Pink's y"
watch *(float*)($theBaseAddress + 40)
commands
set {float}($theBaseAddress + 40) = 477
delete $bpnum
print "✅ 🟪 Set Pink's y"

print "⏳ 🟪 Set Pink's direction"
watch *(float*)($theBaseAddress + 64)
commands
set {float}($theBaseAddress + 64) = -1.5707963267948966
delete $bpnum
print "✅ 🟪 Set Pink's direction"

print "⏳ 🟦 Set Blue's x"
watch *(float*)($theBaseAddress + 20)
commands
set {float}($theBaseAddress + 20) = 400
delete $bpnum
print "✅ 🟦 Set Blue's x"

print "⏳ 🟦 Set Blue's y"
watch *(float*)($theBaseAddress + 44)
commands
set {float}($theBaseAddress + 44) = 234.5
delete $bpnum
print "✅ 🟦 Set Blue's y"

print "⏳ 🟦 Set Blue's direction"
watch *(float*)($theBaseAddress + 68)
commands
set {float}($theBaseAddress + 68) = 0.01
delete $bpnum
print "✅ 🟦 Set Blue's direction"
exit
continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
end

continue
                """
        }
