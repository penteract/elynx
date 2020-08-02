-- |
-- Module      :  ELynx.Data.MarkovProcess.AminoAcidSpec
-- Copyright   :  (c) Dominik Schrempf 2020
-- License     :  GPL-3.0-or-later
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  unstable
-- Portability :  portable
--
-- Creation date: Tue Jan 29 10:47:40 2019.
module ELynx.Data.MarkovProcess.AminoAcidSpec
  ( spec,
  )
where

import ELynx.Data.MarkovProcess.AminoAcid
import qualified ELynx.Data.MarkovProcess.RateMatrix as R
import qualified ELynx.Data.MarkovProcess.SubstitutionModel as S
import Numeric.LinearAlgebra
import Test.Hspec

statDistLGPython :: R.StationaryDistribution
statDistLGPython =
  normalizeSumVec 1.0 $
    fromList
      [ 0.079066,
        0.012937,
        0.053052,
        0.071586,
        0.042302,
        0.057337,
        0.022355,
        0.062157,
        0.064600,
        0.099081,
        0.022951,
        0.041977,
        0.044040,
        0.040767,
        0.055941,
        0.061197,
        0.053287,
        0.069147,
        0.012066,
        0.034155
      ]

exchLGPython :: R.ExchangeabilityMatrix
exchLGPython =
  fromLists
    [ [ 0.0000000e+00,
        2.4890840e+00,
        3.9514400e-01,
        1.0385450e+00,
        2.5370100e-01,
        2.0660400e+00,
        3.5885800e-01,
        1.4983000e-01,
        5.3651800e-01,
        3.9533700e-01,
        1.1240350e+00,
        2.7681800e-01,
        1.1776510e+00,
        9.6989400e-01,
        4.2509300e-01,
        4.7271820e+00,
        2.1395010e+00,
        2.5478700e+00,
        1.8071700e-01,
        2.1895900e-01
      ],
      [ 2.4890840e+00,
        0.0000000e+00,
        6.2556000e-02,
        3.4990000e-03,
        1.1052510e+00,
        5.6926500e-01,
        6.4054300e-01,
        3.2062700e-01,
        1.3266000e-02,
        5.9400700e-01,
        8.9368000e-01,
        5.2876800e-01,
        7.5382000e-02,
        8.4808000e-02,
        5.3455100e-01,
        2.7844780e+00,
        1.1434800e+00,
        1.9592910e+00,
        6.7012800e-01,
        1.1655320e+00
      ],
      [ 3.9514400e-01,
        6.2556000e-02,
        0.0000000e+00,
        5.2438700e+00,
        1.7416000e-02,
        8.4492600e-01,
        9.2711400e-01,
        1.0690000e-02,
        2.8295900e-01,
        1.5076000e-02,
        2.5548000e-02,
        5.0761490e+00,
        3.9445600e-01,
        5.2338600e-01,
        1.2395400e-01,
        1.2402750e+00,
        4.2586000e-01,
        3.7967000e-02,
        2.9890000e-02,
        1.3510700e-01
      ],
      [ 1.0385450e+00,
        3.4990000e-03,
        5.2438700e+00,
        0.0000000e+00,
        1.8811000e-02,
        3.4884700e-01,
        4.2388100e-01,
        4.4265000e-02,
        1.8071770e+00,
        6.9673000e-02,
        1.7373500e-01,
        5.4171200e-01,
        4.1940900e-01,
        4.1285910e+00,
        3.6397000e-01,
        6.1197300e-01,
        6.0454500e-01,
        2.4503400e-01,
        7.7852000e-02,
        1.2003700e-01
      ],
      [ 2.5370100e-01,
        1.1052510e+00,
        1.7416000e-02,
        1.8811000e-02,
        0.0000000e+00,
        8.9586000e-02,
        6.8213900e-01,
        1.1127270e+00,
        2.3918000e-02,
        2.5926920e+00,
        1.7988530e+00,
        8.9525000e-02,
        9.4464000e-02,
        3.5855000e-02,
        5.2722000e-02,
        3.6181900e-01,
        1.6500100e-01,
        6.5468300e-01,
        2.4571210e+00,
        7.8039020e+00
      ],
      [ 2.0660400e+00,
        5.6926500e-01,
        8.4492600e-01,
        3.4884700e-01,
        8.9586000e-02,
        0.0000000e+00,
        3.1148400e-01,
        8.7050000e-03,
        2.9663600e-01,
        4.4261000e-02,
        1.3953800e-01,
        1.4376450e+00,
        1.9696100e-01,
        2.6795900e-01,
        3.9019200e-01,
        1.7399900e+00,
        1.2983600e-01,
        7.6701000e-02,
        2.6849100e-01,
        5.4679000e-02
      ],
      [ 3.5885800e-01,
        6.4054300e-01,
        9.2711400e-01,
        4.2388100e-01,
        6.8213900e-01,
        3.1148400e-01,
        0.0000000e+00,
        1.0888200e-01,
        6.9726400e-01,
        3.6631700e-01,
        4.4247200e-01,
        4.5092380e+00,
        5.0885100e-01,
        4.8135050e+00,
        2.4266010e+00,
        9.9001200e-01,
        5.8426200e-01,
        1.1901300e-01,
        5.9705400e-01,
        5.3068340e+00
      ],
      [ 1.4983000e-01,
        3.2062700e-01,
        1.0690000e-02,
        4.4265000e-02,
        1.1127270e+00,
        8.7050000e-03,
        1.0888200e-01,
        0.0000000e+00,
        1.5906900e-01,
        4.1450670e+00,
        4.2736070e+00,
        1.9150300e-01,
        7.8281000e-02,
        7.2854000e-02,
        1.2699100e-01,
        6.4105000e-02,
        1.0337390e+00,
        1.0649107e+01,
        1.1166000e-01,
        2.3252300e-01
      ],
      [ 5.3651800e-01,
        1.3266000e-02,
        2.8295900e-01,
        1.8071770e+00,
        2.3918000e-02,
        2.9663600e-01,
        6.9726400e-01,
        1.5906900e-01,
        0.0000000e+00,
        1.3750000e-01,
        6.5660400e-01,
        2.1450780e+00,
        3.9032200e-01,
        3.2342940e+00,
        6.3260670e+00,
        7.4868300e-01,
        1.1368630e+00,
        1.8520200e-01,
        4.9906000e-02,
        1.3193200e-01
      ],
      [ 3.9533700e-01,
        5.9400700e-01,
        1.5076000e-02,
        6.9673000e-02,
        2.5926920e+00,
        4.4261000e-02,
        3.6631700e-01,
        4.1450670e+00,
        1.3750000e-01,
        0.0000000e+00,
        6.3123580e+00,
        6.8427000e-02,
        2.4906000e-01,
        5.8245700e-01,
        3.0184800e-01,
        1.8228700e-01,
        3.0293600e-01,
        1.7027450e+00,
        6.1963200e-01,
        2.9964800e-01
      ],
      [ 1.1240350e+00,
        8.9368000e-01,
        2.5548000e-02,
        1.7373500e-01,
        1.7988530e+00,
        1.3953800e-01,
        4.4247200e-01,
        4.2736070e+00,
        6.5660400e-01,
        6.3123580e+00,
        0.0000000e+00,
        3.7100400e-01,
        9.9849000e-02,
        1.6725690e+00,
        4.8413300e-01,
        3.4696000e-01,
        2.0203660e+00,
        1.8987180e+00,
        6.9617500e-01,
        4.8130600e-01
      ],
      [ 2.7681800e-01,
        5.2876800e-01,
        5.0761490e+00,
        5.4171200e-01,
        8.9525000e-02,
        1.4376450e+00,
        4.5092380e+00,
        1.9150300e-01,
        2.1450780e+00,
        6.8427000e-02,
        3.7100400e-01,
        0.0000000e+00,
        1.6178700e-01,
        1.6957520e+00,
        7.5187800e-01,
        4.0083580e+00,
        2.0006790e+00,
        8.3688000e-02,
        4.5376000e-02,
        6.1202500e-01
      ],
      [ 1.1776510e+00,
        7.5382000e-02,
        3.9445600e-01,
        4.1940900e-01,
        9.4464000e-02,
        1.9696100e-01,
        5.0885100e-01,
        7.8281000e-02,
        3.9032200e-01,
        2.4906000e-01,
        9.9849000e-02,
        1.6178700e-01,
        0.0000000e+00,
        6.2429400e-01,
        3.3253300e-01,
        1.3381320e+00,
        5.7146800e-01,
        2.9650100e-01,
        9.5131000e-02,
        8.9613000e-02
      ],
      [ 9.6989400e-01,
        8.4808000e-02,
        5.2338600e-01,
        4.1285910e+00,
        3.5855000e-02,
        2.6795900e-01,
        4.8135050e+00,
        7.2854000e-02,
        3.2342940e+00,
        5.8245700e-01,
        1.6725690e+00,
        1.6957520e+00,
        6.2429400e-01,
        0.0000000e+00,
        2.8079080e+00,
        1.2238280e+00,
        1.0801360e+00,
        2.1033200e-01,
        2.3619900e-01,
        2.5733600e-01
      ],
      [ 4.2509300e-01,
        5.3455100e-01,
        1.2395400e-01,
        3.6397000e-01,
        5.2722000e-02,
        3.9019200e-01,
        2.4266010e+00,
        1.2699100e-01,
        6.3260670e+00,
        3.0184800e-01,
        4.8413300e-01,
        7.5187800e-01,
        3.3253300e-01,
        2.8079080e+00,
        0.0000000e+00,
        8.5815100e-01,
        5.7898700e-01,
        1.7088700e-01,
        5.9360700e-01,
        3.1444000e-01
      ],
      [ 4.7271820e+00,
        2.7844780e+00,
        1.2402750e+00,
        6.1197300e-01,
        3.6181900e-01,
        1.7399900e+00,
        9.9001200e-01,
        6.4105000e-02,
        7.4868300e-01,
        1.8228700e-01,
        3.4696000e-01,
        4.0083580e+00,
        1.3381320e+00,
        1.2238280e+00,
        8.5815100e-01,
        0.0000000e+00,
        6.4722790e+00,
        9.8369000e-02,
        2.4886200e-01,
        4.0054700e-01
      ],
      [ 2.1395010e+00,
        1.1434800e+00,
        4.2586000e-01,
        6.0454500e-01,
        1.6500100e-01,
        1.2983600e-01,
        5.8426200e-01,
        1.0337390e+00,
        1.1368630e+00,
        3.0293600e-01,
        2.0203660e+00,
        2.0006790e+00,
        5.7146800e-01,
        1.0801360e+00,
        5.7898700e-01,
        6.4722790e+00,
        0.0000000e+00,
        2.1881580e+00,
        1.4082500e-01,
        2.4584100e-01
      ],
      [ 2.5478700e+00,
        1.9592910e+00,
        3.7967000e-02,
        2.4503400e-01,
        6.5468300e-01,
        7.6701000e-02,
        1.1901300e-01,
        1.0649107e+01,
        1.8520200e-01,
        1.7027450e+00,
        1.8987180e+00,
        8.3688000e-02,
        2.9650100e-01,
        2.1033200e-01,
        1.7088700e-01,
        9.8369000e-02,
        2.1881580e+00,
        0.0000000e+00,
        1.8951000e-01,
        2.4931300e-01
      ],
      [ 1.8071700e-01,
        6.7012800e-01,
        2.9890000e-02,
        7.7852000e-02,
        2.4571210e+00,
        2.6849100e-01,
        5.9705400e-01,
        1.1166000e-01,
        4.9906000e-02,
        6.1963200e-01,
        6.9617500e-01,
        4.5376000e-02,
        9.5131000e-02,
        2.3619900e-01,
        5.9360700e-01,
        2.4886200e-01,
        1.4082500e-01,
        1.8951000e-01,
        0.0000000e+00,
        3.1518150e+00
      ],
      [ 2.1895900e-01,
        1.1655320e+00,
        1.3510700e-01,
        1.2003700e-01,
        7.8039020e+00,
        5.4679000e-02,
        5.3068340e+00,
        2.3252300e-01,
        1.3193200e-01,
        2.9964800e-01,
        4.8130600e-01,
        6.1202500e-01,
        8.9613000e-02,
        2.5733600e-01,
        3.1444000e-01,
        4.0054700e-01,
        2.4584100e-01,
        2.4931300e-01,
        3.1518150e+00,
        0.0000000e+00
      ]
    ]

statDistUniform :: R.StationaryDistribution
statDistUniform = vector $ replicate 20 0.05

statDistLG :: R.StationaryDistribution
statDistLG = S.stationaryDistribution lg

exchLG :: R.ExchangeabilityMatrix
exchLG = S.exchangeabilityMatrix lg

rmLG :: R.RateMatrix
rmLG = S.rateMatrix lg

spec :: Spec
spec = do
  describe "statDistLG" $
    it "matches distribution from python library" $
      statDistLG
        `nearlyEqVec` statDistLGPython
        `shouldBe` True
  describe "exchLG" $
    it "matches exchangeability matrix from python library" $
      do
        exchLG `shouldSatisfy` nearlyEqMatWith 1e-4 exchLGPython
        exchLG `nearlyEqMat` rmLG `shouldBe` False
  describe "lg" $
    it "stationary distribution can be extracted" $
      nearlyEqVecWith 1e-4 (R.getStationaryDistribution rmLG) statDistLG
        `shouldBe` True
  describe "lgCustom" $
    it "stationary distribution can be recovered" $ do
      let f =
            R.getStationaryDistribution $
              S.rateMatrix $
                lgCustom
                  Nothing
                  statDistUniform
      f `nearlyEqVec` statDistUniform `shouldBe` True
  describe "poisson" $
    it "stationary distribution is uniform 1/20" $
      R.getStationaryDistribution (S.rateMatrix poisson)
        `nearlyEqVec` statDistUniform
        `shouldBe` True
  describe "poissonCustom" $
    it "stationary distribution can be recovered" $ do
      let f =
            R.getStationaryDistribution $
              S.rateMatrix $
                poissonCustom
                  Nothing
                  statDistLGPython
      f `nearlyEqVec` statDistLGPython `shouldBe` True
