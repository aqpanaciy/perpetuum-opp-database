USE perpetuumsa;
GO

UPDATE entitydefault SET quantity = 10, tiertype = NULL, tierlevel = NULL where definitionname = 'def_standard_hunter_drone_rcu_pve'
UPDATE entitydefault SET quantity = 1, tiertype = NULL, tierlevel = NULL where definitionname = 'def_standard_hunter_drone_rcu_pve_cprg'
UPDATE entitydefault SET quantity = 10, tiertype = NULL, tierlevel = NULL where definitionname = 'def_standard_hunter_drone_rcu_pvp'
UPDATE entitydefault SET quantity = 1, tiertype = NULL, tierlevel = NULL where definitionname = 'def_standard_hunter_drone_rcu_pvp_cprg'

GO