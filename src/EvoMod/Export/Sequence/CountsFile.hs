{- |
Description :  Write a counts file
Copyright   :  (c) Dominik Schrempf 2017
License     :  GPLv3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  non-portable (not tested)

* The Counts Format

The input of PoMo is allele frequency data.  Especially, when
populations have many individuals it is preferable to count the
number of bases at each position.  This decreases file size and speeds
up the parser.

Counts files contain:

- One headerline that specifies the file as counts file and states the
  number of populations as well as the number of sites (separated by
  white space).

- A second headerline with white space separated headers: CRHOM
  (chromosome), POS (position) and sequence names.

- Many lines with counts of A, C, G and T bases and their respective
  positions.

Comments:

- Lines starting with # before the first headerline are treated as
  comments.

A toy example:

@
    COUNTSFILE  NPOP 5   NSITES N
    CHROM  POS  Sheep    BlackSheep  RedSheep  Wolf     RedWolf
    1      1    0,0,1,0  0,0,1,0     0,0,1,0   0,0,5,0  0,0,0,1
    1      2    0,0,0,1  0,0,0,1     0,0,0,1   0,0,0,5  0,0,0,1
    .
    .
    .
    9      8373 0,0,0,1  1,0,0,0     0,1,0,0   0,1,4,0  0,0,1,0
    .
    .
    .
    Y      9999 0,0,0,1  0,1,0,0     0,1,0,0   0,5,0,0  0,0,1,0
@

-}

module EvoMod.Export.Sequence.CountsFile
  ( DataOneSite
  , PopulationNames
  , toCountsFile
  ) where

import qualified Data.ByteString.Lazy.Char8                 as B
import           Data.Maybe                                 (fromMaybe)

import           EvoMod.Data.Alphabet.BoundaryMutationModel
import           EvoMod.Tools                               (alignLeft,
                                                             alignRight)

-- | The number of sites that will be printed.
type NSites = Int

-- | The names of the populations.
type PopulationNames = [B.ByteString]

-- Desired column width of the counts file.
colW :: Int
colW = 11

-- | Compose the header using the number of sites and the population names.
header :: NSites -> PopulationNames -> B.ByteString
header nSites popNames = B.unlines [lineOne, lineTwo]
  where nPop = length popNames
        lineOne = B.pack $ "COUNTSFILE NPOP " ++ show nPop ++ " NSITES " ++ show nSites
        lineTwo = B.unwords $
          [ alignLeft colW $ B.pack "CHROM"
          , alignRight colW $ B.pack "POS" ]
          ++ map (alignLeft colW) popNames

-- | The chromosome name.
type Chrom = B.ByteString

-- | The position on the chromosome.
type Pos   = Int

-- | The set of boundary states for one site.
type DataOneSite = [State]

-- | Get a data line in the counts file.
dataLine :: Maybe Chrom -> Maybe Pos -> DataOneSite -> B.ByteString
dataLine chrom mPos bstates = B.unwords $
  [ alignLeft colW (fromMaybe (B.pack "NA") chrom)
  , alignRight colW (B.pack (maybe "NaN" show mPos)) ]
  ++ map (alignRight colW . showCounts) bstates

-- | Convert data to a counts file.
toCountsFile :: PopulationNames -> [(Maybe Chrom, Maybe Pos, DataOneSite)] -> B.ByteString
toCountsFile ns d = B.unlines $ header l ns : zipWith3 dataLine cs ps ds
  where l            = length d
        (cs, ps, ds) = unzip3 d
