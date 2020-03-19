{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}

{- |
Module      :  Analyze.Analyze
Description :  Parse sequence file formats and analyze them
Copyright   :  (c) Dominik Schrempf 2018
License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

Creation date: Fri Oct  5 08:41:05 2018.

-}

module Concatenate.Concatenate
  ( concatenateCmd
  )
where

import           Control.Monad.Logger
import           Control.Monad.Trans.Reader     ( ask )

import           Concatenate.Options
import           Tools

import qualified ELynx.Data.Sequence.Sequence  as S
import           ELynx.Export.Sequence.Fasta
import           ELynx.Tools.InputOutput
import           ELynx.Tools.Reproduction       ( ELynx
                                                , Arguments(..)
                                                )

-- | Concatenate sequences.
concatenateCmd :: ELynx ConcatenateArguments ()
concatenateCmd = do
  (ConcatenateArguments al fps) <- local <$> ask
  $(logInfo) "Command: Concatenate sequences."
  sss <- mapM (readSeqs al) fps
  let result = sequencesToFasta $ S.concatSequences sss
  fn <- getOutFilePath ".fasta"
  out "concatenated multi sequence alignment " result fn
