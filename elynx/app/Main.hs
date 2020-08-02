{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- |
-- Module      :  Main
-- Description :  Validate elynx file
-- Copyright   :  (c) Dominik Schrempf 2020
-- License     :  GPL-3.0-or-later
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  unstable
-- Portability :  portable
--
-- Creation date: Wed Apr 22 21:08:25 2020.
module Main
  ( main,
  )
where

import Control.Monad
import Data.Aeson
import qualified Data.Aeson.Types as J
import qualified Data.ByteString.Char8 as BS
import Data.Maybe
import Data.Version (Version)
import ELynx.Tools
import Options
import Options.Applicative
import qualified SLynx.Options as S
import SLynx.SLynx (slynx)
import System.Environment
  ( withArgs,
    withProgName,
  )
import qualified TLynx.Options as T
import TLynx.TLynx (tlynx)

parseProgName :: Value -> J.Parser String
parseProgName = withObject "progName" $ \o -> o .: "progName"

-- TODO: Declaring program names here should not be necessary.
parseAllR :: String -> Value -> J.Parser AllReproductions
parseAllR "slynx" v =
  S <$> (parseJSON v :: J.Parser (Reproduction (Arguments S.CommandArguments)))
parseAllR "tlynx" v =
  T <$> (parseJSON v :: J.Parser (Reproduction (Arguments T.CommandArguments)))
parseAllR p _ =
  let err =
        unlines
          [ "Could not parse program name:",
            p,
            "Do you use the correct ELynx version?"
          ]
   in error err

parse :: Show a => [String] -> Parser a -> a
parse s p =
  fromMaybe
    (error $ "parse: could not parse command line arguments: " ++ show s)
    (getParseResult res)
  where
    res = execParserPure defaultPrefs (info p briefDesc) s

-- Does the command line fit the saved arguments?
checkArgs ::
  forall a.
  (Eq a, Show a, Reproducible a) =>
  Reproduction a ->
  IO (Either String ())
checkArgs s = do
  let r = reproducible s
      p = parser @a
      as = argsStr s
      res = parse as p
  return $
    if res /= reproducible s
      then
        Left $
          unlines
            ["Command line string and command arguments do not fit:", show as, show r]
      else Right ()

-- Does the file match the base 16 checksum?
checkFile :: FilePath -> BS.ByteString -> IO (Either String ())
checkFile fp h = do
  h' <- hashFile fp
  return $
    if h' == h
      then Right ()
      else
        Left $
          unlines
            [ "SHA256 sum does not match for a file:",
              fp ++ " has check sum " ++ BS.unpack h',
              "Stored check sum is " ++ BS.unpack h
            ]

checkVersion :: Version -> Either String ()
checkVersion v =
  if v == version
    then Right ()
    else
      Left $
        unlines
          [ "Versions differ:",
            "Version in ELynx reproduction file: " ++ show v,
            "Version of current executable: " ++ show version
          ]

checkHash :: Reproducible a => Reproduction a -> Either String ()
checkHash r =
  if h == h'
    then Right ()
    else
      Left $
        unlines
          [ "ELynx reproduction file has been changed:",
            "Hash saved in file:        " ++ show h,
            "Hash calculated from file: " ++ show h'
          ]
  where
    h = rHash r
    h' = Just $ getReproductionHash r

-- Check if command line arguments and files check sums are matching.
validate ::
  (Eq a, Show a, Reproducible a) => Reproduction a -> IO (Either String ())
validate s = do
  chA <- checkArgs s
  let chV = checkVersion (rVersion s)
      chH = checkHash s
  chFs <- zipWithM checkFile (files s) (map BS.pack $ checkSums s)
  return $ sequence_ (chA : chV : chH : chFs)

validateAllReproductions :: AllReproductions -> IO (Either String ())
validateAllReproductions (S x) = validate x
validateAllReproductions (T x) = validate x

getAllR :: FilePath -> IO AllReproductions
getAllR fp = do
  eELynx <- eitherDecodeFileStrict fp :: IO (Either String Value)
  elynx <- case eELynx of
    Left err -> do
      putStrLn "Failed decoding the ELynx reproduction file."
      putStrLn "The following error occurred:"
      error err
    Right val -> return val
  prog <- case J.parseEither parseProgName elynx of
    Left err -> do
      putStrLn "Failed getting command hash from ELynx reproduction file."
      putStrLn "The following error occurred:"
      error err
    Right prog -> return prog
  case J.parseEither (parseAllR prog) elynx of
    Left err -> do
      putStrLn "Failed parsing the ELynx reproduction file."
      putStrLn "The following error occurred:"
      error err
    Right repr -> return repr

-- Read and validate ELynx reproduction file. Check consistency of arguments and
-- input files.
runValidate :: ValidateArguments -> IO ()
runValidate a = do
  let fp = vElynxFile a
  repr <- getAllR fp
  val <- validateAllReproductions repr
  case val of
    Left err -> do
      putStrLn "Failed validating the ELynx reproduction file."
      putStrLn "The following error occurred:"
      error err
    Right () -> putStrLn "Validation successful!"

runRedo :: RedoArguments -> IO ()
runRedo a = do
  let fp = rElynxFile a
  let f = rForce a
  when (f == Force False) $ do
    putStrLn "Validate ELynx reproduction file before reanalysis."
    putStrLn "Use the --force (-f) option to skip this test."
    runValidate (ValidateArguments fp)
  repr <- getAllR fp
  let as = getArgs repr
  as' <-
    if "-f" `notElem` as && "--force" `notElem` as
      then do
        putStrLn
          "Force option required to redo analysis. Add -f (force) to arguments."
        return $ "-f" : as
      else return as
  withProgName (getProgName repr) $ withArgs as' $ redo repr

setForce :: Arguments a -> Arguments a
setForce (Arguments g l) = Arguments g {forceReanalysis = Force True} l

redo :: AllReproductions -> IO ()
redo (S x) = slynx $ setForce $ reproducible x
redo (T x) = tlynx $ setForce $ reproducible x

main :: IO ()
main = do
  g <- execParser commandArguments
  case g of
    Validate a -> runValidate a
    Redo a -> runRedo a
