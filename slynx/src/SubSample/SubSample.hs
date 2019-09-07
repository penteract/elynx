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

module SubSample.SubSample
  ( subSampleCmd
  )
where

import           Control.Monad
import           Control.Monad.IO.Class
import           Control.Monad.Logger
import           Control.Monad.Trans.Class
import qualified Data.Text                                  as T
import qualified Data.Text.Lazy                             as LT
import qualified Data.Text.Lazy.Builder                     as LT
import qualified Data.Text.Lazy.Builder.Int                 as LT
import qualified Data.Vector                                as V
import           Data.Word
import           System.Random.MWC

import           SubSample.Options
import           Tools

import           ELynx.Data.Alphabet.Alphabet
import           ELynx.Data.Sequence.MultiSequenceAlignment
import           ELynx.Export.Sequence.Fasta
import           ELynx.Tools.InputOutput

-- | Get a given number of output file names with provided suffix.
--
-- > getOutFilePaths "BasePath" 11 "fasta"
--
-- Will result in @BasePath.00.fasta@ up to @BasePath.10.fasta@.
getOutFilePaths :: String -> Int -> String -> [FilePath]
getOutFilePaths file n suffix = [ file ++ "." ++ digitStr i ++ "." ++ suffix
                                | i <- [0 .. n-1] ]
  where nDigits    = ceiling $ logBase (10 :: Double) (fromIntegral n)
        digitStr i = T.unpack $ T.justifyRight nDigits '0' (LT.toStrict $ LT.toLazyText $ LT.decimal i)

-- TODO: Actually use the reader. Think about removing alphabet. Everything but
-- infile and outfile should be in the reader.
subSampleCmd :: Alphabet
             -> Int
             -> Int
             -> Maybe [Word32]  -- ^ Seed
             -> Maybe FilePath  -- ^ Input file name
             -> Maybe FilePath  -- ^ Output file base name
             -> Seq ()
subSampleCmd al nSites nAlignments seed inFile outFileBaseName = do
  $(logInfo) "Command: Sub sample from a multi sequence alignment."
  $(logInfo) $ T.pack $ "  Sample " <> show nSites <> " sites."
  $(logInfo) $ T.pack $ "  Sample " <> show nAlignments <> " multi sequence alignments."
  ss <- readSeqs al inFile
  gen <- liftIO $ maybe createSystemRandom (initialize . V.fromList) seed
  let msa = either error id (fromSequenceList ss)
  samples <- lift $ replicateM nAlignments $ randomSubSample nSites msa gen
  let results = map (sequencesToFasta . toSequenceList) samples
  outFilePaths <- case outFileBaseName of
    Nothing -> return $ repeat Nothing
    Just fn -> return $ Just <$> getOutFilePaths fn nAlignments "fasta"
  zipWithM_ (io "sub sampled multi sequence alignments") results outFilePaths

