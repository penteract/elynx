{- |
Module      :  OptionsTreeDist
Description :  Options of tree-dist
Copyright   :  (c) Dominik Schrempf 2019
License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

Creation date: Thu Aug 29 13:02:22 2019.

-}

module OptionsTreeDist
  ( Args (..)
  , Distance (..)
  , parseArgs
  ) where

import           Data.Void
import           Options.Applicative
import           Text.Megaparsec      (Parsec, try)
import           Text.Megaparsec.Char (char, string)
import           Text.Megaparsec.Char.Lexer (float)

import           EvoMod.Tools.Options

data Distance = Symmetric | IncompatibleSplit Double
  deriving (Show, Read)

data Args = Args
  { argsOutFileBaseName :: Maybe FilePath
  , argsVerbosity       :: Verbosity
  , argsInFilePaths     :: [FilePath]
  , argsDistance        :: Distance
  , argsAverage         :: Bool
  }

args :: Parser Args
args = Args <$>
  optional outFileBaseNameOpt <*>
  verbosityOpt <*>
  some filePathArg <*>
  distanceOpt <*>
  averageSwitch

filePathArg :: Parser FilePath
filePathArg = strArgument $
  metavar "INPUT-FILES" <>
  help "Read tree(s) from INPUT-FILES; if more files are given, one tree is expected per file"

symmetric :: Parsec Void String Distance
symmetric = do
  _ <- string "symmetric"
  pure Symmetric

incompatibleSplit :: Parsec Void String Distance
incompatibleSplit = do
  _ <- string "incompatible-split"
  _ <- char '['
  f <- float
  _ <- char ']'
  if (0 < f) && (f < 1)
    then pure $ IncompatibleSplit f
    else error "Branch support has to be between 0 and 1."

distanceParser :: Parsec Void String Distance
distanceParser = try symmetric <|> incompatibleSplit

distanceOpt :: Parser Distance
distanceOpt = option (megaReadM distanceParser) $
  long "distance" <>
  short 'd' <>
  -- TODO: Put available distances into footer.
  help "Type of distance to calculate; avilable distances: symmetric, incompatible-split[VAL] where branches with support below 0.0<VAL<1.0 are collaped"

averageSwitch :: Parser Bool
averageSwitch = switch $
  long "average" <>
  short 'a' <>
  help "Compute average of pairwise distances only"

desc :: [String]
desc = [ "Compute distances between phylogenetic trees." ]

parseArgs :: IO Args
parseArgs = parseArgsWith desc [] args
