-- |
-- Module      :  ELynx.Data.Tree.Bipartition
-- Description :  Bipartitions on trees
-- Copyright   :  (c) Dominik Schrempf 2020
-- License     :  GPL-3.0-or-later
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  unstable
-- Portability :  portable
--
-- Creation date: Fri Aug 30 15:28:17 2019.
--
-- 'Bipartition's are weird in that
-- > Bipartition x y == Bipartition y x
-- is True.
--
-- Also,
-- > Bipartition x y > Bipartition y x
-- is False, even when @x > y@.
--
-- That's why we have to make sure that for
-- > Bipartition x y
-- we always have @x >= y@.
module ELynx.Data.Tree.Bipartition
  ( groups,

    -- * Data type
    Bipartition (fromBipartition),
    bp,
    bpUnsafe,
    toSet,
    bpHuman,

    -- * Work with 'Bipartition's
    bipartition,
    bipartitions,
    getComplementaryLeaves,
    bipartitionToBranch,
    rootAt,
  )
where

import Control.Comonad
import Data.List hiding (partition)
import qualified Data.Map as M
import Data.Map (Map)
import Data.Set (Set)
import qualified Data.Set as S
import ELynx.Data.Tree.Phylogeny
import ELynx.Data.Tree.Rooted

-- | Each node of a tree is root of an induced subtree. Set the node labels to
-- the leaves of the induced subtrees.
groups :: Tree e a -> Tree e [a]
-- I am proud of this awesome 'Comonad' usage here :).
groups = extend leaves

-- | Each branch of a tree partitions the leaves of the tree into two subsets,
-- or a bipartition.
--
-- The order of the two subsets of a 'Bipartition' is meaningless. We ensure by
-- construction that the smaller subset comes first, and hence, that equality
-- checks are meaningful.
newtype Bipartition a = Bipartition
  { fromBipartition :: (Set a, Set a)
  }
  deriving (Eq, Ord, Show, Read)

-- | Create a bipartition from two sets.
--
-- Ensure that the smaller set comes first.
--
-- Return 'Left' if one set is empty.
bp :: Ord a => Set a -> Set a -> Either String (Bipartition a)
bp xs ys
  | S.null xs = Left "bp: Left set empty."
  | S.null ys = Left "bp: Right set empty."
  | otherwise = Right $ bpUnsafe xs ys

-- | Create a bipartition from two sets.
--
-- Ensure that the smaller set comes first.
bpUnsafe :: Ord a => Set a -> Set a -> Bipartition a
bpUnsafe xs ys = if xs >= ys then Bipartition (xs, ys) else Bipartition (ys, xs)

-- | Conversion to a set containing both partitions.
toSet :: Ord a => Bipartition a -> Set a
toSet (Bipartition (x, y)) = S.union x y

-- I decided not to provide a human readable show instance because I need the
-- following identity to hold:
--
-- > read . show = id
--
-- This identity is met by the derived instance anyways. A more human readable
-- instance would most likely violate the identity.

-- | Show a bipartition in a human readable format. Use a provided function to
-- extract information of interest.
bpHuman :: Show a => Bipartition a -> String
bpHuman (Bipartition (x, y)) = "(" ++ setShow x ++ "|" ++ setShow y ++ ")"

-- Show the elements of a set in a human readable format.
setShow :: Show a => Set a -> String
setShow = intercalate "," . map show . S.toList

-- -- | Map a function over all elements in the 'Bipartition'.
-- bpMap :: Ord b => (a -> b) -> Bipartition a -> Bipartition b
-- bpMap f (Bipartition (x, y)) = bp (S.map f x) (S.map f y)

-- | For a bifurcating root, get the bipartition induced by the root node.
--
-- Return 'Left' if
-- - the root node is not bifurcating;
-- - a leave set is empty.
bipartition :: Ord a => Tree e a -> Either String (Bipartition a)
bipartition (Node _ _ [x, y]) = bp (S.fromList $ leaves x) (S.fromList $ leaves y)
bipartition _ = Left "bipartition: Root node is not bifurcating."

-- | Get all bipartitions of the tree.
--
-- Return 'Left' if the tree contains duplicate leaves.
bipartitions :: Ord a => Tree e a -> Either String (Set (Bipartition a))
bipartitions t
  | valid t = Right $ bipartitions' S.empty $ S.fromList <$> groups t
  | otherwise = Left "bipartitions: Tree contains duplicate leaves."

-- | Report the complementary leaves for each child.
getComplementaryLeaves ::
  (Ord a) =>
  -- Complementary leaves.
  Set a ->
  -- Tree with node labels storing leaves.
  Tree e (Set a) ->
  [Set a]
getComplementaryLeaves p (Node _ _ ts) =
  [ S.unions $ p : take i lvsChildren ++ drop (i + 1) lvsChildren
    | i <- [0 .. (n -1)]
  ]
  where
    n = length ts
    lvsChildren = map label ts

-- See 'bipartitions', but do not check if leaves are unique, nor if
-- bipartitions are valid.
bipartitions' :: Ord a => Set a -> Tree e (Set a) -> Set (Bipartition a)
bipartitions' p (Node _ p' []) = either (const S.empty) S.singleton $ bp p p'
bipartitions' p t@(Node _ p' ts) =
  S.unions $
    either (const S.empty) S.singleton (bp p p') :
      [bipartitions' c s | (c, s) <- zip cs ts]
  where
    cs = getComplementaryLeaves p t

-- TODO: Unrooted? See module comment of Distance.hs.

-- | Convert a tree into a 'Map' from each 'Bipartition' to the branch inducing
-- the respective 'Bipartition'.
--
-- Since the induced bipartitions of the daughter branches of a bifurcating root
-- node are equal, the branches leading to the root have to be combined in this
-- case. See http://evolution.genetics.washington.edu/phylip/doc/treedist.html
-- and how unrooted trees should be handled.
--
-- Further, branches connected to degree two nodes also induce the same
-- bipartitions and have to be combined.
--
-- For combining branches, a binary function is required. This requirement is
-- encoded in the 'Semigroup' type class constraint (see 'prune').
--
-- Return 'Left' if the tree contains duplicate leaves.
bipartitionToBranch ::
  (Semigroup e, Ord a) =>
  Tree e a ->
  Either String (Map (Bipartition a) e)
bipartitionToBranch t
  | valid t = Right $ bipartitionToBranch' S.empty pTree
  | otherwise = Left "bipartitionToBranch: Tree contains duplicate leaves."
  where
    pTree = S.fromList <$> groups t

-- When calculating the map, branches separated by various degree two nodes have
-- to be combined. Hence, not only the complementary leaves, but also the branch
-- label itself have to be passed along.
bipartitionToBranch' ::
  (Semigroup e, Ord a) =>
  -- Complementary leaves.
  Set a ->
  -- Partition tree.
  Tree e (Set a) ->
  Map (Bipartition a) e
bipartitionToBranch' p t@(Node b p' ts) =
  M.unionsWith (<>) $
    either (const M.empty) (`M.singleton` b) (bp p p') :
      [bipartitionToBranch' c s | (c, s) <- zip cs ts]
  where
    cs = getComplementaryLeaves p t

-- | Root a tree.
--
-- Root the tree at the branch defined by the given bipartition. The original
-- root node is moved to the new position. See also
-- 'ELynx.Data.Tree.Rooted.roots'.
--
-- Branch labels are not handled.
--
-- Return 'Left', if:
-- - the tree is not bifurcating;
-- - the tree has duplicate leaves;
-- - the bipartition does not match the leaves of the tree.
rootAt :: Ord a => Bipartition a -> Tree () a -> Either String (Tree () a)
rootAt b t
  -- Tree is checked for being bifurcating in 'roots'.
  -- Do not use 'valid' here, because we also need to compare the leaf set with the bipartition.
  | length lvLst /= S.size lvSet = Left "rootAt: Leaves of tree are not unique."
  | toSet b /= lvSet = Left "rootAt: Bipartition does not match leaves of tree."
  | otherwise = rootAt' b t
  where
    lvLst = leaves t
    lvSet = S.fromList $ leaves t

-- Assume the leaves of the tree are unique.
rootAt' :: (Eq a, Ord a) => Bipartition a -> Tree () a -> Either String (Tree () a)
rootAt' b t = do
  ts <- roots t
  case find (\x -> Right b == bipartition x) ts of
    Nothing -> Left "rootAt': Bipartition not found on tree."
    Just t' -> Right t'
