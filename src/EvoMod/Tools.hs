{- |
Module      :  EvoMod.Tools
Description :  Auxiliary tools.
Copyright   :  (c) Dominik Schrempf 2018
License     :  GPL-3

Maintainer  :  dominik.schrempf@gmail.com
Stability   :  unstable
Portability :  portable

Indispensable tools.

-}


module EvoMod.Tools
  ( alignRight
  , alignLeft
  , allEqual
  , c2w
  , w2c
  , readGZFile
  , writeGZFile
  , runParserOnFile
  , parseFileWith
  , parseByteStringWith
  -- , showWithoutQuotes
  , summarizeByteString
  , compose
  , allValues
  , matrixSetDiagToZero
  , nearlyEq
  , nearlyEqVec
  ) where

import           Codec.Compression.GZip     (compress, decompress)
import           Data.ByteString.Internal   (c2w, w2c)
import qualified Data.ByteString.Lazy.Char8 as B
import           Data.List                  (isSuffixOf)
import qualified Data.Vector.Generic        as V
import           Numeric.LinearAlgebra      hiding ((<>))
import           Text.Megaparsec

import           EvoMod.Definitions

-- | For a given width, align string to the right; trim on the left if string is
-- longer.
alignRight :: Int -> B.ByteString -> B.ByteString
alignRight n s = B.replicate (fromIntegral n - l) ' ' <> B.take (fromIntegral n) s
  where l = B.length s

-- | For a given width, align string to the left; trim on the right if string is
-- longer.
alignLeft :: Int -> B.ByteString -> B.ByteString
alignLeft n s = B.replicate (fromIntegral n - l) ' ' <> B.take (fromIntegral n) s
  where l = B.length s

-- -- | For a given width, align string to the right; trim on the left if string is
-- -- longer.
-- alignRightTrim :: Int -> String -> String
-- alignRightTrim n s = reverse . take n . reverse $ alignRight n s

-- -- | For a given width, align string to the left; trim on the right if string is
-- -- longer.
-- alignLeftTrim :: Int -> String -> String
-- alignLeftTrim n s = take n $ alignLeft n s

-- | Test if all elements of a list are equal.
allEqual :: Eq a => [a] -> Bool
allEqual xs = all (== head xs) (tail xs)

-- | Read file. If file path ends with ".gz", assume gzipped file and decompress
-- before read.
readGZFile :: FilePath -> IO B.ByteString
readGZFile f | ".gz" `isSuffixOf` f = decompress <$> B.readFile f
             | otherwise            = B.readFile f

-- | Write file. If file path ends with ".gz", assume gzipped file and compress
-- before write.
writeGZFile :: FilePath -> B.ByteString -> IO ()
writeGZFile f | ".gz" `isSuffixOf` f = B.writeFile f . compress
              | otherwise            = B.writeFile f

-- | Parse a possibly gzipped file.
runParserOnFile :: Parsec e B.ByteString a -> FilePath -> IO (Either (ParseErrorBundle B.ByteString e) a)
runParserOnFile p f = parse p f <$> readGZFile f

-- | Parse a possibly gzipped file and extract the result.
parseFileWith :: (ShowErrorComponent e) => Parsec e B.ByteString a -> FilePath -> IO a
parseFileWith p f = do res <- runParserOnFile p f
                       case res of
                         Left  err -> error $ errorBundlePretty err
                         Right val -> return val

-- | Parse a 'B.ByteString' and extract the result.
parseByteStringWith :: (ShowErrorComponent e) => Parsec e B.ByteString a -> B.ByteString -> a
parseByteStringWith p f = case parse p "" f of
                            Left  err -> error $ errorBundlePretty err
                            Right val -> val

-- | If a string is longer than a given value, trim it and add some dots.
summarizeByteString :: Int -> B.ByteString -> B.ByteString
summarizeByteString l s | B.length s >= fromIntegral l = B.take (fromIntegral l) s <> B.pack "..."
                        | otherwise = s

-- | See https://wiki.haskell.org/Compose.
compose :: [a -> a] -> a -> a
compose = foldl (flip (.)) id

-- | Get all values of a bounded enumerated type.
allValues :: (Bounded a, Enum a) => [a]
allValues = [minBound..]

-- -- | Get all values of a bounded enumerated type.
-- allValues :: (Bounded a, Enum a) => [a]
-- allValues = [minBound..]

-- -- | Calculate the nth harmonic number.
-- harmonic :: Int -> Double
-- harmonic 1 = 1.0
-- harmonic n = 1.0 / fromIntegral n + harmonic (n-1)

-- -- | Separate a square matrix into a symmetric and a skew-symmetric matrix.
-- matrixSeparateSymSkew :: Matrix R -> (Matrix R, Matrix R)
-- matrixSeparateSymSkew m = (mSym, mSkew)
--   where trM = tr m
--         mSym  = scale 0.5 $ m + trM
--         mSkew = scale 0.5 $ m - trM

-- | Set the diagonal entries of a matrix to zero.
matrixSetDiagToZero :: Matrix R -> Matrix R
matrixSetDiagToZero m = m - diag (takeDiag m)

-- | Test for equality with given tolerance (needed because of machine precision).
nearlyEqWith :: Double -> Double -> Double -> Bool
nearlyEqWith tol a b = tol > abs (a-b)

-- | Test for equality with predefined tolerance (needed because of machine precision).
nearlyEq :: Double -> Double -> Bool
nearlyEq = nearlyEqWith eps

-- | Test if the given number is nearly equal to all elements of a vector.
nearlyEqValVec :: Double -> Vector R -> Bool
nearlyEqValVec a = V.all (nearlyEq a)

-- | Test if two vectors are nearly equal.
nearlyEqVec :: Vector R -> Vector R -> Bool
nearlyEqVec a b = nearlyEqValVec 0 (a - b)
