{- |
Module      :  Concatenate.Options
Description :  ELynxSeq argument parsing
Copyright   :  (c) Dominik Schrempf 2018
License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

Creation date: Sun Oct  7 17:29:45 2018.

-}

module Concatenate.Options
  ( ConcatenateArguments (..)
  , concatenateArguments
  ) where

import           Control.Applicative
import           Options.Applicative

import           Tools

import           ELynx.Data.Alphabet.Alphabet
import           ELynx.Tools.Reproduction

-- | Arguments needed to concatenate multi sequence alignments.
data ConcatenateArguments = ConcatenateArguments
    { ccAlphabet :: Alphabet
    , ccInFiles  :: [FilePath] }

instance Reproducible ConcatenateArguments where
  inFiles  = ccInFiles
  parser _ = concatenateArguments

-- | Command line parser.
concatenateArguments :: Parser ConcatenateArguments
concatenateArguments = ConcatenateArguments
               <$> alphabetOpt
               <*> some inFileArg

inFileArg :: Parser FilePath
inFileArg = strArgument $
  metavar "INPUT-FILE" <>
  help "Read sequences from INPUT-FILE"
