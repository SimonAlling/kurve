module ScenarioInOriginalGameTest exposing (tests)

import CompileScenario exposing (CompilationResult(..), compileWithArgs)
import Expect
import OriginalGamePlayers exposing (PlayerId(..))
import ScenarioCore exposing (Scenario)
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "Scenario compilation"
        [ test "Scenario with Red and Green in parallel on my laptop" <|
            \_ ->
                compileWithArgs
                    [ "7fffd8010ff6" ]
                    scenario_RedAndGreenInParallel
                    |> Expect.equal expectedResult_RedAndGreenInParallel
        , test "Scenario with all players in WSL on my main PC" <|
            \_ ->
                compileWithArgs
                    [ "7fffc1c65ff6" ]
                    scenario_AllPlayers
                    |> Expect.equal expectedResult_AllPlayers
        , test "Base address with '0x' prefix and capital letters" <|
            \_ ->
                compileWithArgs
                    [ "0x7FFFD8010FF6" ]
                    scenario_RedAndGreenInParallel
                    |> Expect.equal expectedResult_RedAndGreenInParallel
        , test "Invalid base address" <|
            \_ ->
                compileWithArgs
                    [ "LOL" ]
                    []
                    |> Expect.equal (CompilationFailure "Cannot parse base address: LOL (must be hexadecimal, with or without '0x' prefix).")
        , test "Too few arguments" <|
            \_ ->
                compileWithArgs
                    []
                    []
                    |> Expect.equal (CompilationFailure "Unexpected number of arguments. Expected 1, but got 0.")
        , test "Too many arguments" <|
            \_ ->
                compileWithArgs
                    [ "foo", "bar" ]
                    []
                    |> Expect.equal (CompilationFailure "Unexpected number of arguments. Expected 1, but got 2.")
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
        , compiledProgram = "option endianness 1;write float32 0x7fffd8010ff6 10;write float32 0x7fffd801100e 10;write float32 0x7fffd8011026 1.5707963267948966;write float32 0x7fffd8011002 200;write float32 0x7fffd801101a 150;write float32 0x7fffd8011032 1.5707963267948966;exit"
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
        , compiledProgram = "option endianness 1;write float32 0x7fffc1c65ff6 10;write float32 0x7fffc1c6600e 10;write float32 0x7fffc1c66026 1.5707963267948966;write float32 0x7fffc1c65ffa 10;write float32 0x7fffc1c66012 50;write float32 0x7fffc1c6602a 0;write float32 0x7fffc1c65ffe 200;write float32 0x7fffc1c66016 200;write float32 0x7fffc1c6602e 2.5;write float32 0x7fffc1c66002 200;write float32 0x7fffc1c6601a 250;write float32 0x7fffc1c66032 2.356194490192345;write float32 0x7fffc1c66006 500;write float32 0x7fffc1c6601e 477;write float32 0x7fffc1c66036 -1.5707963267948966;write float32 0x7fffc1c6600a 400;write float32 0x7fffc1c66022 234.5;write float32 0x7fffc1c6603a 0.01;exit"
        }
