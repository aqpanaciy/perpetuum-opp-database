-- Perpetuum.AdminTool generated script
-- Generated: 2026-05-11 08:57:39 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] packages: insert 'Syndicate_Season1_Tier1' with 3 item(s)
DECLARE @pkgId_cad52be9 INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Tier1');
SET @pkgId_cad52be9 = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_cad52be9, 2437, 10000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_cad52be9, 5924, 10000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_cad52be9, 2436, 10000);

-- [2] packages: insert 'Syndicate_Season1_Tier2' with 8 item(s)
DECLARE @pkgId_0b54b751 INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Tier2');
SET @pkgId_0b54b751 = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_0b54b751, 5504, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_0b54b751, 770, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_0b54b751, 797, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_0b54b751, 935, 2);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_0b54b751, 842, 4);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_0b54b751, 695, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_0b54b751, 8796, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_0b54b751, 686, 1);

-- [3] packages: insert 'Syndicate_Season1_Tier3' with 5 item(s)
DECLARE @pkgId_52591016 INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Tier3');
SET @pkgId_52591016 = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_52591016, 2437, 10000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_52591016, 5924, 10000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_52591016, 2436, 10000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_52591016, 8308, 5);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_52591016, 8318, 1);

-- [4] packages: insert 'Syndicate_Season1_Tier_4' with 9 item(s)
DECLARE @pkgId_1f01e1bc INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Tier_4');
SET @pkgId_1f01e1bc = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_1f01e1bc, 5512, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_1f01e1bc, 770, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_1f01e1bc, 797, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_1f01e1bc, 935, 2);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_1f01e1bc, 788, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_1f01e1bc, 842, 5);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_1f01e1bc, 695, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_1f01e1bc, 8796, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_1f01e1bc, 686, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_1f01e1bc, 2567, 1);

-- [5] packages: insert 'Syndicate_Season1_Tier5' with 5 item(s)
DECLARE @pkgId_e9ad6510 INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Tier5');
SET @pkgId_e9ad6510 = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_e9ad6510, 2438, 10000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_e9ad6510, 2440, 10000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_e9ad6510, 5927, 10000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_e9ad6510, 8310, 5);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_e9ad6510, 3384, 1);

-- [6] packages: insert 'Syndicate_Season1_Tier6' with 11 item(s)
DECLARE @pkgId_569d2474 INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Tier6');
SET @pkgId_569d2474 = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_569d2474, 5516, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_569d2474, 770, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_569d2474, 797, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_569d2474, 935, 2);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_569d2474, 788, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_569d2474, 845, 4);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_569d2474, 1032, 4);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_569d2474, 698, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_569d2474, 2567, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_569d2474, 8796, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_569d2474, 689, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_569d2474, 956, 1);

-- [7] packages: insert 'Syndicate_Season1_Tier7' with 5 item(s)
DECLARE @pkgId_deca41c1 INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Tier7');
SET @pkgId_deca41c1 = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_deca41c1, 2438, 10000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_deca41c1, 2440, 10000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_deca41c1, 5927, 10000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_deca41c1, 8312, 5);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_deca41c1, 1404, 1);

-- [8] packages: insert 'Syndicate_Season1_Tier8' with 13 item(s)
DECLARE @pkgId_570e4442 INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Tier8');
SET @pkgId_570e4442 = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 5524, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 8565, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 770, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 797, 2);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 935, 2);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 845, 6);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 1032, 6);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 698, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 8796, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 2567, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 689, 2);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 3384, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_570e4442, 8598, 5);

-- [9] packages: insert 'Syndicate_Season1_Tier9' with 2 item(s)
DECLARE @pkgId_60d32333 INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Tier9');
SET @pkgId_60d32333 = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_60d32333, 268, 20000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_60d32333, 8894, 20000);

-- [10] packages: insert 'Syndicate_Season1_Tier10' with 12 item(s)
DECLARE @pkgId_7cea479b INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Tier10');
SET @pkgId_7cea479b = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_7cea479b, 8888, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_7cea479b, 8807, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_7cea479b, 770, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_7cea479b, 797, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_7cea479b, 938, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_7cea479b, 935, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_7cea479b, 1035, 6);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_7cea479b, 845, 6);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_7cea479b, 701, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_7cea479b, 8796, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_7cea479b, 3384, 1);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_7cea479b, 692, 2);

-- [11] packages: insert 'Syndicate_Season1_Leadership1' with 3 item(s)
DECLARE @pkgId_c3d2e824 INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Leadership1');
SET @pkgId_c3d2e824 = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_c3d2e824, 3271, 500000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_c3d2e824, 8545, 3);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_c3d2e824, 6057, 1);

-- [12] packages: insert 'Syndicate_Season1_Leadership2' with 2 item(s)
DECLARE @pkgId_42657757 INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Leadership2');
SET @pkgId_42657757 = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_42657757, 3271, 300000);
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_42657757, 6056, 1);

-- [13] packages: insert 'Syndicate_Season1_Leadership3' with 1 item(s)
DECLARE @pkgId_31372936 INT;
INSERT INTO packages (name) VALUES (N'Syndicate_Season1_Leadership3');
SET @pkgId_31372936 = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_31372936, 3271, 100000);

COMMIT TRANSACTION;
