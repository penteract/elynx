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
import           Control.Monad.Trans.Class
import           Control.Monad.Trans.Reader

import           Concatenate.Options
import           Tools

import           ELynx.Data.Sequence.Sequence
import           ELynx.Export.Sequence.Fasta
import           ELynx.Tools.InputOutput

concatenateCmd :: Maybe FilePath -> Concatenate ()
concatenateCmd outFileBaseName = do
  $(logInfo) "Command: Concatenate sequences."
  ConcatenateArguments al fps <- lift ask
  sss <- mapM (readSeqs al . Just) fps
  let result      = sequencesToFasta $ concatenateSeqs sss
  let outFilePath = (++ ".fasta") <$> outFileBaseName
  io "concatenated multi sequence alignment " result outFilePath
