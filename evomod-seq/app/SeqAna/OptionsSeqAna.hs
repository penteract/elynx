{- |
Module      :  OptionsSeqAna
Description :  EvoModSeq argument parsing.
Copyright   :  (c) Dominik Schrempf 2018
License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

Creation date: Sun Oct  7 17:29:45 2018.

-}

module OptionsSeqAna
  ( Args (..)
  , Command (..)
  , parseArgs
  ) where

import           Control.Applicative
import           Options.Applicative

import           EvoMod.Options
import           EvoMod.Data.Alphabet.Alphabet

data Command = Summarize
             | Concatenate
             | Filter { longer  :: Maybe Int
                      , shorter :: Maybe Int}
             | Analyze { drop :: Bool }

data Args = Args
  {
    argsCode             :: Code
  , argsMaybeFileNameOut :: Maybe FilePath
  , argsVerbosity        :: Verbosity
  , argsCommand          :: Command
  , argsFileNames        :: [FilePath]
  }

args :: Parser Args
args = Args
  <$> alphabetOpt
  <*> optional fileNameOutOpt
  <*> verbosityOpt
  <*> commandArg
  <*> some fileNameArg

commandArg :: Parser Command
commandArg = hsubparser $
  summarizeCommand <>
  concatenateCommand <>
  filterCommand <>
  analyzeCommand

summarizeCommand :: Mod CommandFields Command
summarizeCommand = command "summarize" $
  info (pure Summarize) (progDesc "Summarize sequences found in input files")

concatenateCommand :: Mod CommandFields Command
concatenateCommand = command "concatenate" $
  info (pure Concatenate) (progDesc "Concatenate sequences found in input files")

filterCommand :: Mod CommandFields Command
filterCommand = command "filter" $
  info (Filter <$> filterLongerThanOpt
         <*> filterShorterThanOpt)
  (progDesc "Filter sequences found in input files")

filterLongerThanOpt :: Parser (Maybe Int)
filterLongerThanOpt = optional $ option auto
  ( long "longer-than"
    <> metavar "LENGTH"
    <> help "Only keep sequences longer than LENGTH" )

filterShorterThanOpt :: Parser (Maybe Int)
filterShorterThanOpt = optional $ option auto
  ( long "shorter-than"
    <> metavar "LENGTH"
    <> help "Only keep sequences shorter than LENGTH" )

analyzeCommand :: Mod CommandFields Command
analyzeCommand = command "analyze" $
  info (Analyze <$> analyzeDropNonStandard)
  (progDesc "Analyze multi sequence alignments (error if sequences have different length)")

analyzeDropNonStandard :: Parser Bool
analyzeDropNonStandard = switch
  ( long "drop-non-standard"
    <> help "Drop columns in alignment that contain non-standard characters such as gaps or IUPAC codes")

alphabetOpt :: Parser Code
alphabetOpt = option auto
  ( long "alphabet"
    <> short 'a'
    <> metavar "NAME"
    <> help "Specify alphabet type NAME" )

fileNameArg :: Parser FilePath
fileNameArg = argument str
  ( metavar "INPUT-FILE-NAMES"
    <> help "Read sequences from INPUT-FILE-NAMES" )

parseArgs :: IO Args
parseArgs = parseArgsWith Nothing (Just ftr) args

ftr :: [String]
ftr = [ "File formats:" ] ++ fs ++
      [ "", "Alphabet types:" ] ++ as
  where
    toListItem = ("  - " ++)
    fs = map toListItem ["FASTA"]
    as = map (toListItem . codeNameVerbose) [(minBound :: Code) ..]