{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

-- |
-- Module      :  TLynx.Compare.Compare
-- Description :  Compare two phylogenies
-- Copyright   :  (c) Dominik Schrempf 2020
-- License     :  GPL-3.0-or-later
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  unstable
-- Portability :  portable
--
-- Creation date: Thu Sep 19 15:01:52 2019.
module TLynx.Compare.Compare
  ( compareCmd,
  )
where

import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.Logger
import Control.Monad.Trans.Reader (ask)
import qualified Data.ByteString.Char8 as BS
import qualified Data.ByteString.Lazy.Char8 as BL
import Data.List (intercalate)
import qualified Data.Map as M
import qualified Data.Set as S
import qualified Data.Text as T
import qualified Data.Text.Encoding as E
import qualified Data.Text.IO as T
import ELynx.Tools
  ( Arguments (..),
    ELynx,
    GlobalArguments (..),
    outHandle,
    parseFileWith,
  )
import ELynx.Tree
import Graphics.Gnuplot.Simple
import System.IO
import TLynx.Compare.Options
import Text.Printf

treesOneFile ::
  FilePath ->
  ELynx
    CompareArguments
    (Tree PhyloExplicit BS.ByteString, Tree PhyloExplicit BS.ByteString)
treesOneFile tf = do
  nwF <- argsNewickFormat . local <$> ask
  $(logInfo) $ T.pack $ "Parse file '" ++ tf ++ "'."
  ts <- liftIO $ parseFileWith (someNewick nwF) tf
  let n = length ts
  case compare n 2 of
    LT -> error "Not enough trees in file."
    GT -> error "Too many trees in file."
    EQ ->
      return
        ( either error id $ toExplicitTree $ head ts,
          either error id $ toExplicitTree $ head . tail $ ts
        )

treesTwoFiles ::
  FilePath ->
  FilePath ->
  ELynx
    CompareArguments
    (Tree PhyloExplicit BS.ByteString, Tree PhyloExplicit BS.ByteString)
treesTwoFiles tf1 tf2 = do
  nwF <- argsNewickFormat . local <$> ask
  $(logInfo) $ T.pack $ "Parse first tree file '" ++ tf1 ++ "'."
  t1 <- liftIO $ parseFileWith (oneNewick nwF) tf1
  $(logInfo) $ T.pack $ "Parse second tree file '" ++ tf2 ++ "'."
  t2 <- liftIO $ parseFileWith (oneNewick nwF) tf2
  return (either error id $ toExplicitTree t1, either error id $ toExplicitTree t2)

-- | More detailed comparison of two trees.
compareCmd :: ELynx CompareArguments ()
compareCmd = do
  l <- local <$> ask
  -- Determine output handle (stdout or file).
  outH <- outHandle "results" ".out"
  -- Read input.
  let inFiles = argsInFiles l
      nFiles = length inFiles
  (tr1, tr2) <- case nFiles of
    1 -> treesOneFile (head inFiles)
    2 -> treesTwoFiles (head inFiles) (head . tail $ inFiles)
    _ ->
      error
        "Need two input files with one tree each or one input file with two trees."
  liftIO $ hPutStrLn outH "Tree 1:"
  liftIO $ BL.hPutStrLn outH $ toNewick $ toPhyloTree tr1
  liftIO $ hPutStrLn outH "Tree 2:"
  liftIO $ BL.hPutStrLn outH $ toNewick $ toPhyloTree tr2
  liftIO $ hPutStrLn outH ""
  -- Intersect trees.
  (t1, t2) <-
    if argsIntersect l
      then do
        let [x, y] = either error id $ intersect [tr1, tr2]
        liftIO $ hPutStrLn outH "Intersected trees are:"
        liftIO $ BL.hPutStrLn outH $ toNewick $ toPhyloTree x
        liftIO $ BL.hPutStrLn outH $ toNewick $ toPhyloTree y
        return (x, y)
      else return (tr1, tr2)
  -- Check input (moved to library functions).
  -- let lvs1  = leaves t1
  --     lvs2  = leaves t2
  --     lfns1 = map getName lvs1
  --     lfns2 = map getName lvs2
  --     s1    = S.fromList lfns1
  --     s2    = S.fromList lfns2
  -- if s1 == s2
  --   then liftIO $ hPutStrLn outH "Trees have the same set of leaf names."
  --   else error "Trees do not have the same set of leaf names."
  -- liftIO $ hPutStrLn outH ""

  -- Distances.
  let formatD str val = T.justifyLeft 25 ' ' str <> "  " <> val
  liftIO $ hPutStrLn outH "Distances."
  liftIO $
    T.hPutStrLn outH $
      formatD
        "Symmetric"
        (T.pack $ show $ symmetric t1 t2)
  liftIO $
    T.hPutStrLn outH $
      formatD
        "Branch score"
        (T.pack $ show $ branchScore t1 t2)
  let t1' = normalizeBranchSupport t1
      t2' = normalizeBranchSupport t2
  $(logDebug) "Trees with normalized branch support values:"
  $(logDebug) $ E.decodeUtf8 $ BL.toStrict $ toNewick $ toPhyloTree t1'
  $(logDebug) $ E.decodeUtf8 $ BL.toStrict $ toNewick $ toPhyloTree t2'
  liftIO $
    T.hPutStrLn outH $
      formatD
        "Incompatible split"
        (T.pack $ show $ incompatibleSplits t1' t2')
  liftIO $
    T.hPutStrLn outH $
      formatD
        "Incompatible split (0.10)"
        (T.pack $ show $ incompatibleSplits (collapse 0.1 t1') (collapse 0.1 t2'))
  liftIO $
    T.hPutStrLn outH $
      formatD
        "Incompatible split (0.50)"
        (T.pack $ show $ incompatibleSplits (collapse 0.5 t1') (collapse 0.5 t2'))
  -- liftIO $ T.hPutStrLn outH $ formatD "Incompatible split (0.60)"
  --   (T.pack $ show $ incompatibleSplits (collapse 0.6 t1') (collapse 0.6 t2'))
  -- liftIO $ T.hPutStrLn outH $ formatD "Incompatible split (0.70)"
  --   (T.pack $ show $ incompatibleSplits (collapse 0.7 t1') (collapse 0.7 t2'))
  liftIO $
    T.hPutStrLn outH $
      formatD
        "Incompatible split (0.80)"
        (T.pack $ show $ incompatibleSplits (collapse 0.8 t1') (collapse 0.8 t2'))
  liftIO $
    T.hPutStrLn outH $
      formatD
        "Incompatible split (0.90)"
        (T.pack $ show $ incompatibleSplits (collapse 0.9 t1') (collapse 0.9 t2'))
  -- liftIO $ T.hPutStrLn outH $ formatD "Incompatible split (1.01)"
  --   (T.pack $ show $ incompatibleSplits (collapse 1.01 t1') (collapse 1.01 t2'))
  -- liftIO $ BL.hPutStrLn outH $ toNewick (collapse 1.01 t1')

  -- Bipartitions.
  when
    (argsBipartitions l)
    ( do
        let bp1 = either error id $ bipartitions t1
            bp2 = either error id $ bipartitions t2
            bp1Only = bp1 S.\\ bp2
            bp2Only = bp2 S.\\ bp1
        unless
          (S.null bp1Only)
          ( do
              liftIO $ hPutStrLn outH ""
              liftIO $
                hPutStrLn outH "Bipartitions in Tree 1 that are not in Tree 2."
              -- let bp1Strs = map (bphuman BL.unpack . bpmap getName) (S.toList bp1Only)
              forM_ bp1Only (liftIO . hPutStrLn outH . bpHuman)
          )
        -- let bp1Strs = map (bphuman BL.unpack) (S.toList bp1Only)
        -- liftIO $ hPutStrLn outH $ intercalate "\n" bp1Strs)
        unless
          (S.null bp2Only)
          ( do
              liftIO $ hPutStrLn outH ""
              liftIO $
                hPutStrLn outH "Bipartitions in Tree 2 that are not in Tree 1."
              forM_ bp2Only (liftIO . hPutStrLn outH . bpHuman)
          )
        -- Common bipartitions and their respective differences in branch lengths.
        liftIO $ hPutStrLn outH ""
        let bpCommon = bp1 `S.intersection` bp2
        if S.null bpCommon
          then do
            liftIO $ hPutStrLn outH "There are no common bipartitions."
            liftIO $ hPutStrLn outH "No plots have been generated."
          else do
            let bpToBrLen1 = M.map getLen $ either error id $ bipartitionToBranch t1
                bpToBrLen2 = M.map getLen $ either error id $ bipartitionToBranch t2
            liftIO $
              hPutStrLn
                outH
                "Common bipartitions and their respective differences in branch lengths."
            -- Header.
            liftIO $ hPutStrLn outH header
            forM_
              bpCommon
              ( liftIO
                  . hPutStrLn outH
                  . getCommonBpStr bpToBrLen1 bpToBrLen2
              )
            -- XXX: This circumvents the extension checking, and hash creation for
            -- elynx files.
            bn <- outFileBaseName . global <$> ask
            case bn of
              Nothing ->
                $(logInfo) "No output file name provided. Do not generate plots."
              Just fn -> do
                let compareCommonBps =
                      [ (bpToBrLen1 M.! b, bpToBrLen2 M.! b)
                        | b <- S.toList bpCommon
                      ]
                liftIO $ epspdfPlot fn (plotBps compareCommonBps)
                $(logInfo)
                  "Comparison of branch lengths plot generated (EPS and PDF)"
    )
  liftIO $ hClose outH

header :: String
header = intercalate "  " $ cols ++ ["Bipartition"]
  where
    cols =
      map
        (T.unpack . T.justifyRight 12 ' ')
        ["Length 1", "Length 2", "Delta", "Relative [%]"]

getCommonBpStr ::
  (Ord a, Show a, Fractional b, PrintfArg b) =>
  M.Map (Bipartition a) b ->
  M.Map (Bipartition a) b ->
  Bipartition a ->
  String
getCommonBpStr m1 m2 p =
  intercalate
    "  "
    [ printf "% 12.7f" l1,
      printf "% 12.7f" l2,
      printf "% 12.7f" d,
      printf "% 12.7f" rd,
      s
    ]
  where
    l1 = m1 M.! p
    l2 = m2 M.! p
    d = l1 - l2
    rd = 2 * d / (l1 + l2)
    s = bpHuman p

plotBps :: [(Double, Double)] -> [Attribute] -> IO ()
plotBps xs as = plotPathsStyle as' [(ps1, xs), (ps2, line)]
  where
    as' =
      as
        ++ [ Title "Comparison of branch lengths of common branches",
             XLabel "Branch lengths, tree 1",
             YLabel "Branch lengths, tree 2"
           ]
    ps1 = PlotStyle Points (DefaultStyle 1)
    m = maximum $ map fst xs ++ map snd xs
    line = [(0, 0), (m, m)]
    ps2 = PlotStyle Lines (DefaultStyle 1)
