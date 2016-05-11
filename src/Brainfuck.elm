module Brainfuck (..) where

import String
import Char
import Dict exposing (Dict)
import Parser exposing (..)
import Tape exposing (..)
import Utils exposing (ensureJust)


type alias Model =
  { commands : List Command
  , loops : Dict Int Int
  , tape : Tape
  , current : Int
  , input : List Char
  , output : List Char
  }


init : Program -> List Char -> Model
init { commands, loops } input =
  { commands = commands
  , loops = loops
  , tape = Tape.empty
  , current = 0
  , input = input
  , output = []
  }


run : String -> String -> String
run instructions input =
  let
    program =
      parse instructions
  in
    init program (String.toList input)
      |> step
      |> .output
      |> List.reverse
      |> String.fromList


step : Model -> Model
step model =
  if (List.length model.commands) == model.current then
    model
  else
    case ensureJust "Error" (List.head (List.drop model.current model.commands)) of
      Next ->
        step
          { model
            | current = model.current + 1
            , tape = Tape.next model.tape
          }

      Prev ->
        step
          { model
            | current = model.current + 1
            , tape = Tape.prev model.tape
          }

      Inc ->
        step
          { model
            | current = model.current + 1
            , tape = Tape.increment model.tape
          }

      Dec ->
        step
          { model
            | current = model.current + 1
            , tape = Tape.decrement model.tape
          }

      Read ->
        step
          { model
            | current = model.current + 1
            , tape = Tape.set (Char.toCode (ensureJust "Missing input" (List.head model.input))) model.tape
            , input = Maybe.withDefault [] (List.tail model.input)
          }

      Write ->
        step
          { model
            | current = model.current + 1
            , output = (Char.fromCode (Tape.get model.tape)) :: model.output
          }

      LoopStart ->
        if (Tape.get model.tape) == 0 then
          step
            { model
              | current = ensureJust "Invalid brackets" (Dict.get model.current model.loops)
            }
        else
          step { model | current = model.current + 1 }

      LoopEnd ->
        if (Tape.get model.tape) /= 0 then
          step
            { model
              | current = ensureJust "Invalid brackets" (Dict.get model.current model.loops)
            }
        else
          step { model | current = model.current + 1 }