{-# LANGUAGE OverloadedStrings #-}

-- |
-- Module      :  ELynx.Import.Nexus
-- Description :  Nexus types and classes
-- Copyright   :  (c) Dominik Schrempf 2020
-- License     :  GPL-3
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  unstable
-- Portability :  portable
--
-- Creation date: Tue Apr 28 17:10:05 2020.
module ELynx.Import.Nexus
  ( Block (..),
    nexus,
  )
where

import Data.Attoparsec.ByteString.Char8
import qualified Data.ByteString.Char8 as BS

-- | A Nexus block has a name (e.g., TREES), and parser for the entry.
data Block a = Block
  { name :: BS.ByteString,
    parser :: Parser a
  }

-- This has to be refined. Like this, only one block can be parsed, and the
-- block type has to be known beforehand.

-- | Parse a Nexus file with a given 'Block'.
nexus :: Block a -> Parser a
nexus b = start *> block b <* endOfInput <?> "nexus"

start :: Parser ()
start = (<?> "start") $ do
  _ <- string "#NEXUS"
  _ <- skipWhile isSpace
  return ()

block :: Block a -> Parser a
block b = beginB (name b) *> parser b <* endB <?> "block"

beginB :: BS.ByteString -> Parser ()
beginB n = (<?> "begin") $ do
  _ <- string "BEGIN"
  _ <- skipWhile isSpace
  _ <- string n
  _ <- char ';'
  _ <- skipWhile isSpace
  return ()

endB :: Parser ()
endB = (<?> "end") $ do
  _ <- string "END;"
  _ <- skipWhile isSpace
  return ()
