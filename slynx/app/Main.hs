{- |
Module      :  Main
Description :  Work with molecular sequence data
Copyright   :  (c) Dominik Schrempf 2019
License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

Creation date: Thu Sep  5 21:53:07 2019.

-}

module Main where

import           Control.Monad.Trans.Reader

import           Options

import           Concatenate.Concatenate
import           Examine.Examine
import           Filter.Filter
import           Simulate.Simulate
import           SubSample.SubSample
import           Translate.Translate

import           ELynx.Tools.Logger
import           ELynx.Tools.Options

-- TODO: put logHeader and logFooter into main (for all programs).
main :: IO ()
main = do
  Arguments g c <- parseArguments
  let fn = outFileBaseName g
  let lf = (++ ".log") <$> fn
  case c of
    Concatenate a -> runReaderT (runELynxLoggingT lf $ concatenateCmd fn) a
    Examine a -> runReaderT (runELynxLoggingT lf $ examineCmd fn) a
    FilterRows a -> runReaderT (runELynxLoggingT lf $ filterRowsCmd fn) a
    FilterColumns a -> runReaderT (runELynxLoggingT lf $ filterColumnsCmd fn) a
    Simulate a -> runReaderT (runELynxLoggingT lf $ simulateCmd fn) a
    SubSample a -> runReaderT (runELynxLoggingT lf $ subSampleCmd fn) a
    Translate a -> runReaderT (runELynxLoggingT lf $ translateCmd fn) a