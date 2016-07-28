__precompile__()
module TinySegmenter

export tokenize

# make a tuple of Char from a string
macro c_str(s)
  tuple(s...)
end

# make a tuple of UInt8s from an ASCII string
macro i_str(s)
  tuple(UInt8[UInt8(c) for c in s]...)
end

# make a Dict{UInt8,Int} from Char=>Int pairs
dict_c2i(p::Pair{Char,Int}...) = Dict{UInt8,Int}(map(p -> Pair(UInt8(p[1]),p[2]), p))

# Use out of range of Unicode code point. See also: https://en.wikipedia.org/wiki/Code_point
const B1 = Char(0x110001)
const B2 = Char(0x110002)
const B3 = Char(0x110003)
const E1 = Char(0x110004)
const E2 = Char(0x110005)

const BIAS = -332

const BC1 = Dict{Tuple{UInt8,UInt8},Int}(i"HH" => 6, i"II" => 2461, i"KH" => 406, i"OH" => -1378)
const BC2 = Dict{Tuple{UInt8,UInt8},Int}(i"AA" => -3267, i"AI" => 2744, i"AN" => -878, i"HH" => -4070, i"HM" => -1711, i"HN" => 4012, i"HO" => 3761, i"IA" => 1327, i"IH" => -1184, i"II" => -1332, i"IK" => 1721, i"IO" => 5492, i"KI" => 3831, i"KK" => -8741, i"MH" => -3132, i"MK" => 3334, i"OO" => -2920)
const BC3 = Dict{Tuple{UInt8,UInt8},Int}(i"HH" => 996, i"HI" => 626, i"HK" => -721, i"HN" => -1307, i"HO" => -836, i"IH" => -301, i"KK" => 2762, i"MK" => 1079, i"MM" => 4034, i"OA" => -1652, i"OH" => 266)
const BP1 = Dict{Tuple{UInt8,UInt8},Int}(i"BB" => 295, i"OB" => 304, i"OO" => -125, i"UB" => 352)
const BP2 = Dict{Tuple{UInt8,UInt8},Int}(i"BO" => 60, i"OO" => -1762)
const BQ1 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(i"BHH" => 1150, i"BHM" => 1521, i"BII" => -1158, i"BIM" => 886, i"BMH" => 1208, i"BNH" => 449, i"BOH" => -91, i"BOO" => -2597, i"OHI" => 451, i"OIH" => -296, i"OKA" => 1851, i"OKH" => -1020, i"OKK" => 904, i"OOO" => 2965)
const BQ2 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(i"BHH" => 118, i"BHI" => -1159, i"BHM" => 466, i"BIH" => -919, i"BKK" => -1720, i"BKO" => 864, i"OHH" => -1139, i"OHM" => -181, i"OIH" => 153, i"UHI" => -1146)
const BQ3 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(i"BHH" => -792, i"BHI" => 2664, i"BII" => -299, i"BKI" => 419, i"BMH" => 937, i"BMM" => 8335, i"BNN" => 998, i"BOH" => 775, i"OHH" => 2174, i"OHM" => 439, i"OII" => 280, i"OKH" => 1798, i"OKI" => -793, i"OKO" => -2242, i"OMH" => -2402, i"OOO" => 11699)
const BQ4 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(i"BHH" => -3895, i"BIH" => 3761, i"BII" => -4654, i"BIK" => 1348, i"BKK" => -1806, i"BMI" => -3385, i"BOO" => -12396, i"OAH" => 926, i"OHH" => 266, i"OHK" => -2036, i"ONN" => -973)
const BW1 = Dict{Tuple{Char,Char},Int}(c",と" => 660, c",同" => 727, (B1,'あ') => 1404, (B1,'同') => 542, c"、と" => 660, c"、同" => 727, c"」と" => 1682, c"あっ" => 1505, c"いう" => 1743, c"いっ" => -2055, c"いる" => 672, c"うし" => -4817, c"うん" => 665, c"から" => 3472, c"がら" => 600, c"こう" => -790, c"こと" => 2083, c"こん" => -1262, c"さら" => -4143, c"さん" => 4573, c"した" => 2641, c"して" => 1104, c"すで" => -3399, c"そこ" => 1977, c"それ" => -871, c"たち" => 1122, c"ため" => 601, c"った" => 3463, c"つい" => -802, c"てい" => 805, c"てき" => 1249, c"でき" => 1127, c"です" => 3445, c"では" => 844, c"とい" => -4915, c"とみ" => 1922, c"どこ" => 3887, c"ない" => 5713, c"なっ" => 3015, c"など" => 7379, c"なん" => -1113, c"にし" => 2468, c"には" => 1498, c"にも" => 1671, c"に対" => -912, c"の一" => -501, c"の中" => 741, c"ませ" => 2448, c"まで" => 1711, c"まま" => 2600, c"まる" => -2155, c"やむ" => -1947, c"よっ" => -2565, c"れた" => 2369, c"れで" => -913, c"をし" => 1860, c"を見" => 731, c"亡く" => -1886, c"京都" => 2558, c"取り" => -2784, c"大き" => -2604, c"大阪" => 1497, c"平方" => -2314, c"引き" => -1336, c"日本" => -195, c"本当" => -2423, c"毎日" => -2113, c"目指" => -724, (B1,'あ') => 1404, (B1,'同') => 542, c"｣と" => 1682)
const BW2 = Dict{Tuple{Char,Char},Int}(c".." => -11822, c"11" => -669, c"――" => -5730, c"−−" => -13175, c"いう" => -1609, c"うか" => 2490, c"かし" => -1350, c"かも" => -602, c"から" => -7194, c"かれ" => 4612, c"がい" => 853, c"がら" => -3198, c"きた" => 1941, c"くな" => -1597, c"こと" => -8392, c"この" => -4193, c"させ" => 4533, c"され" => 13168, c"さん" => -3977, c"しい" => -1819, c"しか" => -545, c"した" => 5078, c"して" => 972, c"しな" => 939, c"その" => -3744, c"たい" => -1253, c"たた" => -662, c"ただ" => -3857, c"たち" => -786, c"たと" => 1224, c"たは" => -939, c"った" => 4589, c"って" => 1647, c"っと" => -2094, c"てい" => 6144, c"てき" => 3640, c"てく" => 2551, c"ては" => -3110, c"ても" => -3065, c"でい" => 2666, c"でき" => -1528, c"でし" => -3828, c"です" => -4761, c"でも" => -4203, c"とい" => 1890, c"とこ" => -1746, c"とと" => -2279, c"との" => 720, c"とみ" => 5168, c"とも" => -3941, c"ない" => -2488, c"なが" => -1313, c"など" => -6509, c"なの" => 2614, c"なん" => 3099, c"にお" => -1615, c"にし" => 2748, c"にな" => 2454, c"によ" => -7236, c"に対" => -14943, c"に従" => -4688, c"に関" => -11388, c"のか" => 2093, c"ので" => -7059, c"のに" => -6041, c"のの" => -6125, c"はい" => 1073, c"はが" => -1033, c"はず" => -2532, c"ばれ" => 1813, c"まし" => -1316, c"まで" => -6621, c"まれ" => 5409, c"めて" => -3153, c"もい" => 2230, c"もの" => -10713, c"らか" => -944, c"らし" => -1611, c"らに" => -1897, c"りし" => 651, c"りま" => 1620, c"れた" => 4270, c"れて" => 849, c"れば" => 4114, c"ろう" => 6067, c"われ" => 7901, c"を通" => -11877, c"んだ" => 728, c"んな" => -4115, c"一人" => 602, c"一方" => -1375, c"一日" => 970, c"一部" => -1051, c"上が" => -4479, c"会社" => -1116, c"出て" => 2163, c"分の" => -7758, c"同党" => 970, c"同日" => -913, c"大阪" => -2471, c"委員" => -1250, c"少な" => -1050, c"年度" => -8669, c"年間" => -1626, c"府県" => -2363, c"手権" => -1982, c"新聞" => -4066, c"日新" => -722, c"日本" => -7068, c"日米" => 3372, c"曜日" => -601, c"朝鮮" => -2355, c"本人" => -2697, c"東京" => -1543, c"然と" => -1384, c"社会" => -1276, c"立て" => -990, c"第に" => -1612, c"米国" => -4268, c"１１" => -669, c"ｸﾞ" => 1319)
const BW3 = Dict{Tuple{Char,Char},Int}(c"あた" => -2194, c"あり" => 719, c"ある" => 3846, c"い." => -1185, c"い。" => -1185, c"いい" => 5308, c"いえ" => 2079, c"いく" => 3029, c"いた" => 2056, c"いっ" => 1883, c"いる" => 5600, c"いわ" => 1527, c"うち" => 1117, c"うと" => 4798, c"えと" => 1454, c"か." => 2857, c"か。" => 2857, c"かけ" => -743, c"かっ" => -4098, c"かに" => -669, c"から" => 6520, c"かり" => -2670, c"が," => 1816, c"が、" => 1816, c"がき" => -4855, c"がけ" => -1127, c"がっ" => -913, c"がら" => -4977, c"がり" => -2064, c"きた" => 1645, c"けど" => 1374, c"こと" => 7397, c"この" => 1542, c"ころ" => -2757, c"さい" => -714, c"さを" => 976, c"し," => 1557, c"し、" => 1557, c"しい" => -3714, c"した" => 3562, c"して" => 1449, c"しな" => 2608, c"しま" => 1200, c"す." => -1310, c"す。" => -1310, c"する" => 6521, c"ず," => 3426, c"ず、" => 3426, c"ずに" => 841, c"そう" => 428, c"た." => 8875, c"た。" => 8875, c"たい" => -594, c"たの" => 812, c"たり" => -1183, c"たる" => -853, c"だ." => 4098, c"だ。" => 4098, c"だっ" => 1004, c"った" => -4748, c"って" => 300, c"てい" => 6240, c"てお" => 855, c"ても" => 302, c"です" => 1437, c"でに" => -1482, c"では" => 2295, c"とう" => -1387, c"とし" => 2266, c"との" => 541, c"とも" => -3543, c"どう" => 4664, c"ない" => 1796, c"なく" => -903, c"など" => 2135, c"に," => -1021, c"に、" => -1021, c"にし" => 1771, c"にな" => 1906, c"には" => 2644, c"の," => -724, c"の、" => -724, c"の子" => -1000, c"は," => 1337, c"は、" => 1337, c"べき" => 2181, c"まし" => 1113, c"ます" => 6943, c"まっ" => -1549, c"まで" => 6154, c"まれ" => -793, c"らし" => 1479, c"られ" => 6820, c"るる" => 3818, c"れ," => 854, c"れ、" => 854, c"れた" => 1850, c"れて" => 1375, c"れば" => -3246, c"れる" => 1091, c"われ" => -605, c"んだ" => 606, c"んで" => 798, c"カ月" => 990, c"会議" => 860, c"入り" => 1232, c"大会" => 2217, c"始め" => 1681, c"市 " => 965, c"新聞" => -5055, c"日," => 974, c"日、" => 974, c"社会" => 2024, c"ｶ月" => 990)
const TC1 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(i"AAA" => 1093, i"HHH" => 1029, i"HHM" => 580, i"HII" => 998, i"HOH" => -390, i"HOM" => -331, i"IHI" => 1169, i"IOH" => -142, i"IOI" => -1015, i"IOM" => 467, i"MMH" => 187, i"OOI" => -1832)
const TC2 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(i"HHO" => 2088, i"HII" => -1023, i"HMM" => -1154, i"IHI" => -1965, i"KKH" => 703, i"OII" => -2649)
const TC3 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(i"AAA" => -294, i"HHH" => 346, i"HHI" => -341, i"HII" => -1088, i"HIK" => 731, i"HOH" => -1486, i"IHH" => 128, i"IHI" => -3041, i"IHO" => -1935, i"IIH" => -825, i"IIM" => -1035, i"IOI" => -542, i"KHH" => -1216, i"KKA" => 491, i"KKH" => -1217, i"KOK" => -1009, i"MHH" => -2694, i"MHM" => -457, i"MHO" => 123, i"MMH" => -471, i"NNH" => -1689, i"NNO" => 662, i"OHO" => -3393)
const TC4 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(i"HHH" => -203, i"HHI" => 1344, i"HHK" => 365, i"HHM" => -122, i"HHN" => 182, i"HHO" => 669, i"HIH" => 804, i"HII" => 679, i"HOH" => 446, i"IHH" => 695, i"IHO" => -2324, i"IIH" => 321, i"III" => 1497, i"IIO" => 656, i"IOO" => 54, i"KAK" => 4845, i"KKA" => 3386, i"KKK" => 3065, i"MHH" => -405, i"MHI" => 201, i"MMH" => -241, i"MMM" => 661, i"MOM" => 841)
const TQ1 = Dict{Tuple{UInt8,UInt8,UInt8,UInt8},Int}(i"BHHH" => -227, i"BHHI" => 316, i"BHIH" => -132, i"BIHH" => 60, i"BIII" => 1595, i"BNHH" => -744, i"BOHH" => 225, i"BOOO" => -908, i"OAKK" => 482, i"OHHH" => 281, i"OHIH" => 249, i"OIHI" => 200, i"OIIH" => -68)
const TQ2 = Dict{Tuple{UInt8,UInt8,UInt8,UInt8},Int}(i"BIHH" => -1401, i"BIII" => -1033, i"BKAK" => -543, i"BOOO" => -5591)
const TQ3 = Dict{Tuple{UInt8,UInt8,UInt8,UInt8},Int}(i"BHHH" => 478, i"BHHM" => -1073, i"BHIH" => 222, i"BHII" => -504, i"BIIH" => -116, i"BIII" => -105, i"BMHI" => -863, i"BMHM" => -464, i"BOMH" => 620, i"OHHH" => 346, i"OHHI" => 1729, i"OHII" => 997, i"OHMH" => 481, i"OIHH" => 623, i"OIIH" => 1344, i"OKAK" => 2792, i"OKHH" => 587, i"OKKA" => 679, i"OOHH" => 110, i"OOII" => -685)
const TQ4 = Dict{Tuple{UInt8,UInt8,UInt8,UInt8},Int}(i"BHHH" => -721, i"BHHM" => -3604, i"BHII" => -966, i"BIIH" => -607, i"BIII" => -2181, i"OAAA" => -2763, i"OAKK" => 180, i"OHHH" => -294, i"OHHI" => 2446, i"OHHO" => 480, i"OHIH" => -1573, i"OIHH" => 1935, i"OIHI" => -493, i"OIIH" => 626, i"OIII" => -4007, i"OKAK" => -8156)
const TW1 = Dict{Tuple{Char,Char,Char},Int}(c"につい" => -4681, c"東京都" => 2026)
const TW2 = Dict{Tuple{Char,Char,Char},Int}(c"ある程" => -2049, c"いった" => -1256, c"ころが" => -2434, c"しょう" => 3873, c"その後" => -4430, c"だって" => -1049, c"ていた" => 1833, c"として" => -4657, c"ともに" => -4517, c"もので" => 1882, c"一気に" => -792, c"初めて" => -1512, c"同時に" => -8097, c"大きな" => -1255, c"対して" => -2721, c"社会党" => -3216)
const TW3 = Dict{Tuple{Char,Char,Char},Int}(c"いただ" => -1734, c"してい" => 1314, c"として" => -4314, c"につい" => -5483, c"にとっ" => -5989, c"に当た" => -6247, c"ので," => -727, c"ので、" => -727, c"のもの" => -600, c"れから" => -3752, c"十二月" => -2287)
const TW4 = Dict{Tuple{Char,Char,Char},Int}(c"いう." => 8576, c"いう。" => 8576, c"からな" => -2348, c"してい" => 2958, c"たが," => 1516, c"たが、" => 1516, c"ている" => 1538, c"という" => 1349, c"ました" => 5543, c"ません" => 1097, c"ようと" => -4258, c"よると" => 5865)
const UC1 = dict_c2i('A' => 484, 'K' => 93, 'M' => 645, 'O' => -505)
const UC2 = dict_c2i('A' => 819, 'H' => 1059, 'I' => 409, 'M' => 3987, 'N' => 5775, 'O' => 646)
const UC3 = dict_c2i('A' => -1370, 'I' => 2311)
const UC4 = dict_c2i('A' => -2643, 'H' => 1809, 'I' => -1032, 'K' => -3450, 'M' => 3565, 'N' => 3876, 'O' => 6646)
const UC5 = dict_c2i('H' => 313, 'I' => -1238, 'K' => -799, 'M' => 539, 'O' => -831)
const UC6 = dict_c2i('H' => -506, 'I' => -253, 'K' => 87, 'M' => 247, 'O' => -387)
const UP1 = dict_c2i('O' => -214)
const UP2 = dict_c2i('B' => 69, 'O' => 935)
const UP3 = dict_c2i('B' => 189)
const UQ1 = Dict{Tuple{UInt8,UInt8},Int}(i"BH" => 21, i"BI" => -12, i"BK" => -99, i"BN" => 142, i"BO" => -56, i"OH" => -95, i"OI" => 477, i"OK" => 410, i"OO" => -2422)
const UQ2 = Dict{Tuple{UInt8,UInt8},Int}(i"BH" => 216, i"BI" => 113, i"OK" => 1759)
const UQ3 = Dict{Tuple{UInt8,UInt8},Int}(i"BA" => -479, i"BH" => 42, i"BI" => 1913, i"BK" => -7198, i"BM" => 3160, i"BN" => 6427, i"BO" => 14761, i"OI" => -827, i"ON" => -3212)
const UW1 = Dict{Char,Int}(',' => 156, '、' => 156, '「' => -463, 'あ' => -941, 'う' => -127, 'が' => -553, 'き' => 121, 'こ' => 505, 'で' => -201, 'と' => -547, 'ど' => -123, 'に' => -789, 'の' => -185, 'は' => -847, 'も' => -466, 'や' => -470, 'よ' => 182, 'ら' => -292, 'り' => 208, 'れ' => 169, 'を' => -446, 'ん' => -137, '・' => -135, '主' => -402, '京' => -268, '区' => -912, '午' => 871, '国' => -460, '大' => 561, '委' => 729, '市' => -411, '日' => -141, '理' => 361, '生' => -408, '県' => -386, '都' => -718, '｢' => -463, '･' => -135)
const UW2 = Dict{Char,Int}(',' => -829, '、' => -829, '〇' => 892, '「' => -645, '」' => 3145, 'あ' => -538, 'い' => 505, 'う' => 134, 'お' => -502, 'か' => 1454, 'が' => -856, 'く' => -412, 'こ' => 1141, 'さ' => 878, 'ざ' => 540, 'し' => 1529, 'す' => -675, 'せ' => 300, 'そ' => -1011, 'た' => 188, 'だ' => 1837, 'つ' => -949, 'て' => -291, 'で' => -268, 'と' => -981, 'ど' => 1273, 'な' => 1063, 'に' => -1764, 'の' => 130, 'は' => -409, 'ひ' => -1273, 'べ' => 1261, 'ま' => 600, 'も' => -1263, 'や' => -402, 'よ' => 1639, 'り' => -579, 'る' => -694, 'れ' => 571, 'を' => -2516, 'ん' => 2095, 'ア' => -587, 'カ' => 306, 'キ' => 568, 'ッ' => 831, '三' => -758, '不' => -2150, '世' => -302, '中' => -968, '主' => -861, '事' => 492, '人' => -123, '会' => 978, '保' => 362, '入' => 548, '初' => -3025, '副' => -1566, '北' => -3414, '区' => -422, '大' => -1769, '天' => -865, '太' => -483, '子' => -1519, '学' => 760, '実' => 1023, '小' => -2009, '市' => -813, '年' => -1060, '強' => 1067, '手' => -1519, '揺' => -1033, '政' => 1522, '文' => -1355, '新' => -1682, '日' => -1815, '明' => -1462, '最' => -630, '朝' => -1843, '本' => -1650, '東' => -931, '果' => -665, '次' => -2378, '民' => -180, '気' => -1740, '理' => 752, '発' => 529, '目' => -1584, '相' => -242, '県' => -1165, '立' => -763, '第' => 810, '米' => 509, '自' => -1353, '行' => 838, '西' => -744, '見' => -3874, '調' => 1010, '議' => 1198, '込' => 3041, '開' => 1758, '間' => -1257, '｢' => -645, '｣' => 3145, 'ｯ' => 831, 'ｱ' => -587, 'ｶ' => 306, 'ｷ' => 568)
const UW3 = Dict{Char,Int}(',' => 4889, '1' => -800, '−' => -1723, '、' => 4889, '々' => -2311, '〇' => 5827, '」' => 2670, '〓' => -3573, 'あ' => -2696, 'い' => 1006, 'う' => 2342, 'え' => 1983, 'お' => -4864, 'か' => -1163, 'が' => 3271, 'く' => 1004, 'け' => 388, 'げ' => 401, 'こ' => -3552, 'ご' => -3116, 'さ' => -1058, 'し' => -395, 'す' => 584, 'せ' => 3685, 'そ' => -5228, 'た' => 842, 'ち' => -521, 'っ' => -1444, 'つ' => -1081, 'て' => 6167, 'で' => 2318, 'と' => 1691, 'ど' => -899, 'な' => -2788, 'に' => 2745, 'の' => 4056, 'は' => 4555, 'ひ' => -2171, 'ふ' => -1798, 'へ' => 1199, 'ほ' => -5516, 'ま' => -4384, 'み' => -120, 'め' => 1205, 'も' => 2323, 'や' => -788, 'よ' => -202, 'ら' => 727, 'り' => 649, 'る' => 5905, 'れ' => 2773, 'わ' => -1207, 'を' => 6620, 'ん' => -518, 'ア' => 551, 'グ' => 1319, 'ス' => 874, 'ッ' => -1350, 'ト' => 521, 'ム' => 1109, 'ル' => 1591, 'ロ' => 2201, 'ン' => 278, '・' => -3794, '一' => -1619, '下' => -1759, '世' => -2087, '両' => 3815, '中' => 653, '主' => -758, '予' => -1193, '二' => 974, '人' => 2742, '今' => 792, '他' => 1889, '以' => -1368, '低' => 811, '何' => 4265, '作' => -361, '保' => -2439, '元' => 4858, '党' => 3593, '全' => 1574, '公' => -3030, '六' => 755, '共' => -1880, '円' => 5807, '再' => 3095, '分' => 457, '初' => 2475, '別' => 1129, '前' => 2286, '副' => 4437, '力' => 365, '動' => -949, '務' => -1872, '化' => 1327, '北' => -1038, '区' => 4646, '千' => -2309, '午' => -783, '協' => -1006, '口' => 483, '右' => 1233, '各' => 3588, '合' => -241, '同' => 3906, '和' => -837, '員' => 4513, '国' => 642, '型' => 1389, '場' => 1219, '外' => -241, '妻' => 2016, '学' => -1356, '安' => -423, '実' => -1008, '家' => 1078, '小' => -513, '少' => -3102, '州' => 1155, '市' => 3197, '平' => -1804, '年' => 2416, '広' => -1030, '府' => 1605, '度' => 1452, '建' => -2352, '当' => -3885, '得' => 1905, '思' => -1291, '性' => 1822, '戸' => -488, '指' => -3973, '政' => -2013, '教' => -1479, '数' => 3222, '文' => -1489, '新' => 1764, '日' => 2099, '旧' => 5792, '昨' => -661, '時' => -1248, '曜' => -951, '最' => -937, '月' => 4125, '期' => 360, '李' => 3094, '村' => 364, '東' => -805, '核' => 5156, '森' => 2438, '業' => 484, '氏' => 2613, '民' => -1694, '決' => -1073, '法' => 1868, '海' => -495, '無' => 979, '物' => 461, '特' => -3850, '生' => -273, '用' => 914, '町' => 1215, '的' => 7313, '直' => -1835, '省' => 792, '県' => 6293, '知' => -1528, '私' => 4231, '税' => 401, '立' => -960, '第' => 1201, '米' => 7767, '系' => 3066, '約' => 3663, '級' => 1384, '統' => -4229, '総' => 1163, '線' => 1255, '者' => 6457, '能' => 725, '自' => -2869, '英' => 785, '見' => 1044, '調' => -562, '財' => -733, '費' => 1777, '車' => 1835, '軍' => 1375, '込' => -1504, '通' => -1136, '選' => -681, '郎' => 1026, '郡' => 4404, '部' => 1200, '金' => 2163, '長' => 421, '開' => -1432, '間' => 1302, '関' => -1282, '雨' => 2009, '電' => -1045, '非' => 2066, '駅' => 1620, '１' => -800, '｣' => 2670, '･' => -3794, 'ｯ' => -1350, 'ｱ' => 551, 'ｽ' => 874, 'ﾄ' => 521, 'ﾑ' => 1109, 'ﾙ' => 1591, 'ﾛ' => 2201, 'ﾝ' => 278)
const UW4 = Dict{Char,Int}(',' => 3930, '.' => 3508, '―' => -4841, '、' => 3930, '。' => 3508, '〇' => 4999, '「' => 1895, '」' => 3798, '〓' => -5156, 'あ' => 4752, 'い' => -3435, 'う' => -640, 'え' => -2514, 'お' => 2405, 'か' => 530, 'が' => 6006, 'き' => -4482, 'ぎ' => -3821, 'く' => -3788, 'け' => -4376, 'げ' => -4734, 'こ' => 2255, 'ご' => 1979, 'さ' => 2864, 'し' => -843, 'じ' => -2506, 'す' => -731, 'ず' => 1251, 'せ' => 181, 'そ' => 4091, 'た' => 5034, 'だ' => 5408, 'ち' => -3654, 'っ' => -5882, 'つ' => -1659, 'て' => 3994, 'で' => 7410, 'と' => 4547, 'な' => 5433, 'に' => 6499, 'ぬ' => 1853, 'ね' => 1413, 'の' => 7396, 'は' => 8578, 'ば' => 1940, 'ひ' => 4249, 'び' => -4134, 'ふ' => 1345, 'へ' => 6665, 'べ' => -744, 'ほ' => 1464, 'ま' => 1051, 'み' => -2082, 'む' => -882, 'め' => -5046, 'も' => 4169, 'ゃ' => -2666, 'や' => 2795, 'ょ' => -1544, 'よ' => 3351, 'ら' => -2922, 'り' => -9726, 'る' => -14896, 'れ' => -2613, 'ろ' => -4570, 'わ' => -1783, 'を' => 13150, 'ん' => -2352, 'カ' => 2145, 'コ' => 1789, 'セ' => 1287, 'ッ' => -724, 'ト' => -403, 'メ' => -1635, 'ラ' => -881, 'リ' => -541, 'ル' => -856, 'ン' => -3637, '・' => -4371, 'ー' => -11870, '一' => -2069, '中' => 2210, '予' => 782, '事' => -190, '井' => -1768, '人' => 1036, '以' => 544, '会' => 950, '体' => -1286, '作' => 530, '側' => 4292, '先' => 601, '党' => -2006, '共' => -1212, '内' => 584, '円' => 788, '初' => 1347, '前' => 1623, '副' => 3879, '力' => -302, '動' => -740, '務' => -2715, '化' => 776, '区' => 4517, '協' => 1013, '参' => 1555, '合' => -1834, '和' => -681, '員' => -910, '器' => -851, '回' => 1500, '国' => -619, '園' => -1200, '地' => 866, '場' => -1410, '塁' => -2094, '士' => -1413, '多' => 1067, '大' => 571, '子' => -4802, '学' => -1397, '定' => -1057, '寺' => -809, '小' => 1910, '屋' => -1328, '山' => -1500, '島' => -2056, '川' => -2667, '市' => 2771, '年' => 374, '庁' => -4556, '後' => 456, '性' => 553, '感' => 916, '所' => -1566, '支' => 856, '改' => 787, '政' => 2182, '教' => 704, '文' => 522, '方' => -856, '日' => 1798, '時' => 1829, '最' => 845, '月' => -9066, '木' => -485, '来' => -442, '校' => -360, '業' => -1043, '氏' => 5388, '民' => -2716, '気' => -910, '沢' => -939, '済' => -543, '物' => -735, '率' => 672, '球' => -1267, '生' => -1286, '産' => -1101, '田' => -2900, '町' => 1826, '的' => 2586, '目' => 922, '省' => -3485, '県' => 2997, '空' => -867, '立' => -2112, '第' => 788, '米' => 2937, '系' => 786, '約' => 2171, '経' => 1146, '統' => -1169, '総' => 940, '線' => -994, '署' => 749, '者' => 2145, '能' => -730, '般' => -852, '行' => -792, '規' => 792, '警' => -1184, '議' => -244, '谷' => -1000, '賞' => 730, '車' => -1481, '軍' => 1158, '輪' => -1433, '込' => -3370, '近' => 929, '道' => -1291, '選' => 2596, '郎' => -4866, '都' => 1192, '野' => -1100, '銀' => -2213, '長' => 357, '間' => -2344, '院' => -2297, '際' => -2604, '電' => -878, '領' => -1659, '題' => -792, '館' => -1984, '首' => 1749, '高' => 2120, '｢' => 1895, '｣' => 3798, '･' => -4371, 'ｯ' => -724, 'ｰ' => -11870, 'ｶ' => 2145, 'ｺ' => 1789, 'ｾ' => 1287, 'ﾄ' => -403, 'ﾒ' => -1635, 'ﾗ' => -881, 'ﾘ' => -541, 'ﾙ' => -856, 'ﾝ' => -3637)
const UW5 = Dict{Char,Int}(',' => 465, '.' => -299, '1' => -514, E2 => -32768, ']' => -2762, '、' => 465, '。' => -299, '「' => 363, 'あ' => 1655, 'い' => 331, 'う' => -503, 'え' => 1199, 'お' => 527, 'か' => 647, 'が' => -421, 'き' => 1624, 'ぎ' => 1971, 'く' => 312, 'げ' => -983, 'さ' => -1537, 'し' => -1371, 'す' => -852, 'だ' => -1186, 'ち' => 1093, 'っ' => 52, 'つ' => 921, 'て' => -18, 'で' => -850, 'と' => -127, 'ど' => 1682, 'な' => -787, 'に' => -1224, 'の' => -635, 'は' => -578, 'べ' => 1001, 'み' => 502, 'め' => 865, 'ゃ' => 3350, 'ょ' => 854, 'り' => -208, 'る' => 429, 'れ' => 504, 'わ' => 419, 'を' => -1264, 'ん' => 327, 'イ' => 241, 'ル' => 451, 'ン' => -343, '中' => -871, '京' => 722, '会' => -1153, '党' => -654, '務' => 3519, '区' => -901, '告' => 848, '員' => 2104, '大' => -1296, '学' => -548, '定' => 1785, '嵐' => -1304, '市' => -2991, '席' => 921, '年' => 1763, '思' => 872, '所' => -814, '挙' => 1618, '新' => -1682, '日' => 218, '月' => -4353, '査' => 932, '格' => 1356, '機' => -1508, '氏' => -1347, '田' => 240, '町' => -3912, '的' => -3149, '相' => 1319, '省' => -1052, '県' => -4003, '研' => -997, '社' => -278, '空' => -813, '統' => 1955, '者' => -2233, '表' => 663, '語' => -1073, '議' => 1219, '選' => -1018, '郎' => -368, '長' => 786, '間' => 1191, '題' => 2368, '館' => -689, '１' => -514, E2 => -32768, '｢' => 363, 'ｲ' => 241, 'ﾙ' => 451, 'ﾝ' => -343)
const UW6 = Dict{Char,Int}(',' => 227, '.' => 808, '1' => -270, E1 => 306, '、' => 227, '。' => 808, 'あ' => -307, 'う' => 189, 'か' => 241, 'が' => -73, 'く' => -121, 'こ' => -200, 'じ' => 1782, 'す' => 383, 'た' => -428, 'っ' => 573, 'て' => -1014, 'で' => 101, 'と' => -105, 'な' => -253, 'に' => -149, 'の' => -417, 'は' => -236, 'も' => -206, 'り' => 187, 'る' => -135, 'を' => 195, 'ル' => -673, 'ン' => -496, '一' => -277, '中' => 201, '件' => -800, '会' => 624, '前' => 302, '区' => 1792, '員' => -1212, '委' => 798, '学' => -960, '市' => 887, '広' => -695, '後' => 535, '業' => -697, '相' => 753, '社' => -507, '福' => 974, '空' => -822, '者' => 1811, '連' => 463, '郎' => 1082, '１' => -270, E1 => 306, 'ﾙ' => -673, 'ﾝ' => -496)

const CHARDICT = Dict{Char, UInt8}()
for (chars,cat) in (
    ("一二三四五六七八九十百千万億兆",'M'),
    ("々〆ヵヶ", 'H'),
    ('ぁ':'ん','I'),
    ('ァ':'ヴ','K'),
    ("ーｰ\uff9e",'K'),
    ('ｱ':'ﾝ','K'),
    (['a':'z';'A':'Z';'ａ':'ｚ';'Ａ':'Ｚ'],'A'),
    (['0':'9';'０':'９'],'N')
  )
  for c in chars
      CHARDICT[c] = cat
  end
end
const Achar = UInt8('A')
const Ichar = UInt8('I')
const Hchar = UInt8('H')
const Ochar = UInt8('O')
const Uchar = UInt8('U')
const Bchar = UInt8('B')
function ctype(c::Char)
  return get(CHARDICT, c, '一' <= c <= '龠' ? Hchar : Ochar)
end

"""
    tokenize(text::AbstractString)

Given a `text` string, `tokenize` attempts to segment it into a list
of words, and in particular tries to segment Japanese text
into words ("tokens" or "segments"), using the TinySegmenter algorithm.
It returns an array of substrings consisting of the guessed tokens in
`text`, in the order that they appear.
"""
function tokenize{T<:AbstractString}(text::T)
  result = SubString{T}[]
  isempty(text) && return result

  wordstart = start(text)
  pos = wordstart

  p1 = Uchar
  p2 = Uchar
  p3 = Uchar
  w1, w2, w3 = B3, B2, B1
  c1, c2, c3 = Ochar, Ochar, Ochar
  w4 = text[pos]
  c4 = ctype(w4)

  pos1 = nextind(text, pos) # pos + 1 character
  pos2 = nextind(text, pos1) # pos + 2 characters
  if pos == endof(text)
    w5, w6 = E1, E2
    c5, c6 = Ochar, Ochar
  else
    w5 = text[pos1]
    c5 = ctype(w5)
    if pos1 == endof(text)
      w6 = E1
      c6 = Ochar
    else
      w6 = text[pos2]
      c6 = ctype(w6)
    end
  end

  while pos < endof(text)
    score = BIAS
    w1,w2,w3,w4,w5 = w2,w3,w4,w5,w6
    c1,c2,c3,c4,c5 = c2,c3,c4,c5,c6
    pos3 = nextind(text, pos2) # pos + 3
    if pos3 <= endof(text)
      w6 = text[pos3]
      c6 = ctype(w6)
    elseif pos2 == endof(text)
      w6 = E1
      c6 = Ochar
    else # pos1 == endof(text)
      w6 = E2
      c6 = Ochar
    end

    if p1 == Ochar; score += -214; end # score += get(UP1, p1, 0)
    if p2 == Bchar; score += 69; elseif p2 == Ochar; score += 935; end # score += get(UP2, p2, 0)
    if p3 == Bchar; score += 189; end # score += get(UP3, p3, 0)
    score += get(BP1, (p1, p2), 0)
    score += get(BP2, (p2, p3), 0)
    score += get(UW1, w1, 0)
    score += get(UW2, w2, 0)
    score += get(UW3, w3, 0)
    score += get(UW4, w4, 0)
    score += get(UW5, w5, 0)
    score += get(UW6, w6, 0)
    score += get(BW1, (w2, w3), 0)
    score += get(BW2, (w3, w4), 0)
    score += get(BW3, (w4, w5), 0)
    score += get(TW1, (w1, w2, w3), 0)
    score += get(TW2, (w2, w3, w4), 0)
    score += get(TW3, (w3, w4, w5), 0)
    score += get(TW4, (w4, w5, w6), 0)
    score += get(UC1, c1, 0)
    score += get(UC2, c2, 0)
    if c3 == Achar; score += -1370; elseif c3 == Ichar; score += 2311; end # score += get(UC3, c3, 0)
    score += get(UC4, c4, 0)
    score += get(UC5, c5, 0)
    score += get(UC6, c6, 0)
    score += get(BC1, (c2, c3), 0)
    score += get(BC2, (c3, c4), 0)
    score += get(BC3, (c4, c5), 0)
    score += get(TC1, (c1, c2, c3), 0)
    score += get(TC2, (c2, c3, c4), 0)
    score += get(TC3, (c3, c4, c5), 0)
    score += get(TC4, (c4, c5, c6), 0)
    score += get(UQ1, (p1, c1), 0)
    score += get(UQ2, (p2, c2), 0)
    score += get(UQ3, (p3, c3), 0)
    score += get(BQ1, (p2, c2, c3), 0)
    score += get(BQ2, (p2, c3, c4), 0)
    score += get(BQ3, (p3, c2, c3), 0)
    score += get(BQ4, (p3, c3, c4), 0)
    score += get(TQ1, (p2, c1, c2, c3), 0)
    score += get(TQ2, (p2, c2, c3, c4), 0)
    score += get(TQ3, (p3, c1, c2, c3), 0)
    score += get(TQ4, (p3, c2, c3, c4), 0)

    p = Ochar
    if score > 0
      push!(result, SubString(text, wordstart, pos))
      wordstart = pos1
      p = Bchar
    end

    p1 = p2
    p2 = p3
    p3 = p
    pos = pos1
    pos1 = pos2
    pos2 = pos3
  end

  push!(result, SubString(text, wordstart, pos))
  return result
end

end # module
