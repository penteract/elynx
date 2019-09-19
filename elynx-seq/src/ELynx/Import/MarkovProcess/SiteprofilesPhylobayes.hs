{- |
Module      :  ELynx.Import.MarkovProcess.SiteprofilesPhylobayes
Description :  Import site profiles in Phylobayes format
Copyright   :  (c) Dominik Schrempf 2019
License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

Creation date: Tue Jan 29 12:12:55 2019.

For now I just try to go with a huge empirical distribution mixture model. Let's
see if performance is good enough.

-}

module ELynx.Import.MarkovProcess.SiteprofilesPhylobayes
  ( Parser
  , EDMComponent
  , siteprofiles
  ) where

import           Control.Monad
import qualified Data.ByteString.Lazy.Char8        as L
import           Data.List                         (nub)
import qualified Data.Vector.Storable              as V
import           Data.Void
import           Text.Megaparsec
import           Text.Megaparsec.Byte
import           Text.Megaparsec.Byte.Lexer

import           ELynx.Data.MarkovProcess.EDMModel
import           ELynx.Tools.ByteString            (c2w)

-- | Shortcut.
type Parser = Parsec Void L.ByteString

-- | Parse stationary distributions from Phylobayes format.
siteprofiles :: Parser [EDMComponent]
siteprofiles = do
  _  <- headerLines
  cs <- many dataLine
  _  <- many newline *> eof
     <?> "phylobayes siteprofiles"
  let ls = map length cs
      nLs = length $ nub ls
  when (nLs /= 1) (error "The site profiles have a different number of entries.")
  return cs

horizontalSpace :: Parser ()
horizontalSpace = skipMany $ char (c2w ' ') <|> tab

line :: Parser ()
line = do
  _ <- many $ noneOf [c2w '\n']
  pure ()

-- For now, just ignore the header.
headerLines :: Parser ()
headerLines = do
  _ <- line
  _ <- many newline
    <?> "headerLine"
  pure ()

dataLine :: Parser EDMComponent
dataLine = do
  -- Ignore site number.
  _ <- decimal :: Parser Integer
  _ <- horizontalSpace
  vals <- float `sepBy` horizontalSpace
  _ <- many newline
    <?> "dataLine"
  -- Set the weight to 1.0 for all sites.
  return (1.0, V.fromList vals)