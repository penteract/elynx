-- |
-- Module      :  ELynx.Import.MarkovProcess.EDMModelPhylobayesSpec
-- Copyright   :  (c) Dominik Schrempf 2020
-- License     :  GPL-3.0-or-later
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  unstable
-- Portability :  portable
--
-- Creation date: Tue Jan 29 12:26:49 2019.
module ELynx.Import.MarkovProcess.EDMModelPhylobayesSpec
  ( spec,
  )
where

import ELynx.Import.MarkovProcess.EDMModelPhylobayes
import Numeric.LinearAlgebra (fromList)
import Test.Hspec

componentsFilePhylobayes :: FilePath
componentsFilePhylobayes = "data/EDMDistsPhylobayes.txt"

testComponents :: [EDMComponent]
testComponents =
  [ ( 0.3690726059430788,
      fromList
        [ 0.0746116859730418,
          0.0069967050701822,
          0.0792378063875672,
          0.1103113280153337,
          0.0084753541579630,
          0.0420976864270153,
          0.0359995156499732,
          0.0176053658394712,
          0.1140305648643406,
          0.0306656386818212,
          0.0143923751236750,
          0.0805907035564168,
          0.0136556223619922,
          0.0854829959418090,
          0.0907856579607629,
          0.0955855590305961,
          0.0585231905811694,
          0.0276404860443685,
          0.0024024774767569,
          0.0109092808557433
        ]
    ),
    ( 0.28019163862430846,
      fromList
        [ 0.0379912838025543,
          0.0085917039746034,
          0.0016977963056655,
          0.0029780993213938,
          0.0369086689176780,
          0.0051768704164023,
          0.0027496797757250,
          0.2650202435999584,
          0.0035114356263963,
          0.2705514660371282,
          0.0634852940497682,
          0.0036512748214048,
          0.0030666766077233,
          0.0046946399741140,
          0.0039700770877914,
          0.0137110414055372,
          0.0286159990065166,
          0.2351259204392804,
          0.0018121721806795,
          0.0066896566496796
        ]
    ),
    ( 0.23699880225859807,
      fromList
        [ 0.2699288544670601,
          0.0262695884363299,
          0.0119030286238640,
          0.0143694121662917,
          0.0113341089668980,
          0.1028437949687162,
          0.0097376980401260,
          0.0250662077996463,
          0.0137176088824149,
          0.0302792626622677,
          0.0151697996735645,
          0.0255041240872322,
          0.0194279535358810,
          0.0155053062932145,
          0.0146597721555602,
          0.2261838872893110,
          0.1040919090386891,
          0.0534187313840882,
          0.0024899475832214,
          0.0080990039456234
        ]
    ),
    ( 0.11373695317401472,
      fromList
        [ 0.0325183213724537,
          0.0153142424565790,
          0.0072297704620506,
          0.0101526783552517,
          0.2682049848838039,
          0.0107298905683658,
          0.0420960604309369,
          0.0414751553493385,
          0.0131985876449809,
          0.1152120909184748,
          0.0300072241461393,
          0.0173787316286536,
          0.0062421326435569,
          0.0173124967325860,
          0.0181776303531701,
          0.0328778350287987,
          0.0250382111285986,
          0.0437257936268565,
          0.0258103804738129,
          0.2272977817955918
        ]
    )
  ]

spec :: Spec
spec =
  describe "phylobayes" $
    it "parses a text file with stationary distributions in phylobayes format" $
      do
        cs <- parseFileWith phylobayes componentsFilePhylobayes
        cs `shouldBe` testComponents
