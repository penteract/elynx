{- |
Module      :  EvoMod.Import.MarkovProcess.EDMModelPhylobayes
Description :  Import stationary distributions from Phylobayes format.
Copyright   :  (c) Dominik Schrempf 2019
License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

Creation date: Tue Jan 29 12:12:55 2019.

-}

module EvoMod.Import.MarkovProcess.EDMModelPhylobayes
  ( Parser
  , EDMComponent
  , phylobayes
  ) where

import           Control.Monad
import qualified Data.ByteString.Lazy.Char8 as B
import           Data.Void
import           Numeric.LinearAlgebra      (R, Vector, vector)
import           Text.Megaparsec
import           Text.Megaparsec.Byte
import           Text.Megaparsec.Byte.Lexer

import           EvoMod.Tools.ByteString    (c2w)

-- | Shortcut.
type Parser = Parsec Void B.ByteString

-- | An empirical mixture model component has a weight and a stationary
-- distribution.
type EDMComponent = (Double, Vector R)

-- | Parse stationary distributions from Phylobayes format.
phylobayes :: Parser [EDMComponent]
phylobayes = do
  n <- headerLine
  k <- kComponentsLine
  cs <- count k $ dataLine n
  _ <- many newline *> eof
    <?> "phylobayes"
  return cs

horizontalSpace :: Parser ()
horizontalSpace = skipMany $ char (c2w ' ') <|> tab

headerLine :: Parser Int
headerLine = do
  n <- decimal
  _ <- horizontalSpace
  _ <- chunk (B.pack "A C D E F G H I K L M N P Q R S T V W Y")
  _ <- many newline
    <?> "headerLine"
  return n

kComponentsLine :: Parser Int
kComponentsLine = decimal <* newline <?> "kComponentsLine"

dataLine :: Int -> Parser EDMComponent
dataLine n = do
  weight <- float
  _ <- horizontalSpace
  vals <- float `sepBy` horizontalSpace
  when (length vals /= n) (error "Did not find correct number of entries.")
  _ <- many newline
    <?> "dataLine"
  return (weight, vector vals)
