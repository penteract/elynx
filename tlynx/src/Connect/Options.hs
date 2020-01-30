{- |
Module      :  Connect.Options
Description :  Options for the connect subcommand
Copyright   :  (c) Dominik Schrempf 2019
License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

Creation date: Thu Sep 19 15:02:21 2019.

-}

module Connect.Options
  ( ConnectArguments (..)
  , Connect
  , connectArguments
  ) where

import           Control.Monad.Logger
import           Control.Monad.Trans.Reader
import           Options.Applicative

-- | Arguments of connect command.
data ConnectArguments = ConnectArguments
  { newickIqTreeFlag :: Bool
  , constraints      :: Maybe FilePath
  , inFileA          :: FilePath
  , inFileB          :: FilePath }

-- | Logger and reader data type.
type Connect = LoggingT (ReaderT ConnectArguments IO)

-- | Parse arguments of connect command.
connectArguments :: Parser ConnectArguments
connectArguments = ConnectArguments
  <$> newickIqTree
  <*> constraintsFile
  <*> fileA
  <*> fileB

newickIqTree :: Parser Bool
newickIqTree = switch $
  long "newick-iqtree"
  <> short 'i'
  <> help "Use IQ-TREE Newick format (internal node labels are branch support values)"

constraintsFile :: Parser (Maybe FilePath)
constraintsFile = optional $ strOption $
  metavar "CONSTRAINTS"
  <> short 'c'
  <> long "contraints"
  <> help "File containing one or more Newick trees to be used as constraints"

fileA :: Parser FilePath
fileA = strArgument $
  metavar "TREE-FILE-A"
  <> help "File containing the first Newick tree"

fileB :: Parser FilePath
fileB = strArgument $
  metavar "TREE-FILE-B"
  <> help "File containing the second Newick tree"