{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}

{- |
Module      :  EvoMod.Data.NucleotideX
Description :  Extended nucleotides including gaps and unknowns
Copyright   :  (c) Dominik Schrempf 2018

License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

See header of 'EvoMod.Data.Alphabet'.

Extended nucleotides with gaps and unknowns. See also
https://www.bioinformatics.org/sms/iupac.html or
https://en.wikipedia.org/wiki/International_Union_of_Pure_and_Applied_Chemistry.

@
Symbol  Description  Bases represented  Complement
------  -----------  -----------------  ----------
A       Adenine      A                  T
C       Cytosine        C               G
G       Guanine            G            C
T       Thymine               T         A
------  -----------  -----------------  ----------
- or .  Gap (Zero)                      -
@


-}

module EvoMod.Data.Alphabet.NucleotideX
  ( NucleotideX (..)
  ) where

import           Data.Vector.Unboxed.Deriving
import           Data.Word8

import qualified EvoMod.Data.Character.Character as C
import           EvoMod.Tools.ByteString        (c2w, w2c)

-- | Extended nucleotides.
data NucleotideX = A | C | G | T
                 | N | Gap
  deriving (Show, Read, Eq, Ord, Enum, Bounded)

toWord :: NucleotideX -> Word8
toWord A   = c2w 'A'
toWord C   = c2w 'C'
toWord G   = c2w 'G'
toWord T   = c2w 'T'
toWord N   = c2w 'N'
toWord Gap = c2w  '-'

fromWord :: Word8 -> NucleotideX
fromWord w = case w2c w of
               'A' ->   A
               'C' ->   C
               'G' ->   G
               'T' ->   T
               'N' ->   N
               '-' ->   Gap
               '.' ->   Gap
               _   -> error "fromWord: cannot convert to NucleotideX."

derivingUnbox "NucleotideX"
    [t| NucleotideX -> Word8 |]
    [| toWord |]
    [| fromWord |]

instance C.Character NucleotideX where
  toWord   = toWord
  fromWord = fromWord

instance C.CharacterX NucleotideX where
  gap        = Gap