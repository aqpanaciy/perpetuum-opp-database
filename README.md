<span style="display:block;text-align:center">![opp-database](opp-database.jpeg)

# OPDB
This is the database patch repository for the Open Perpetuum Server.  

This repository is developed under the direction of the [Open Perpetuum Project](https://openperpetuum.com) game design and development team; a 100% volunteer opensource player development and persistant Perpetuum Server hosting project.

To join the Team, find our call for volunteers on our website [here!](https://openperpetuum.com/volunteer-tech)
Where you will also find our [Volunteer Survey](https://forms.gle/V7B5zNAFCFmSLLxt6).
If you have any questions about joining the team hit us up on [discord](https://discord.gg/e4gH9Ff)!

To see what we are working on acquaint yourself with our:
 - Website [https://openperpetuum.com](https://openperpetuum.com)
 - Project Kanban [Board](https://github.com/OpenPerpetuum/OP-Project)
 - [Discord](https://discord.gg/e4gH9Ff)

To contribute: join the team and we will get you up and running.  
Or show us your moxie and submit a pull request!

## Local setup

`apply_all.bat` assumes a specific layout. Matching it exactly means no local edits to the scripts, and so no environment-specific paths committed by accident.

- **Server location** — install the server at exactly `C:\PerpetuumServer`. `apply_all.bat` copies patch data to `C:\PerpetuumServer\data`, and `Tools/restore_DB_to_original_state.sql` reads and writes `C:\PerpetuumServer\data\database\`. Both paths are hardcoded.
- **SQL Server instance** — a named instance `PERPSQL` on the local machine. `apply_all.bat` connects to `%computername%\PERPSQL` with Windows authentication.
- **Instance language must be `us_english`** — some archived patches contain date literals whose meaning depends on `DATEFORMAT`. On an instance whose language orders dates day-month-year they fail with `Msg 242, Conversion failed when converting date and/or time from character string`:

```sql
EXEC sp_configure 'default language', 0;
RECONFIGURE WITH OVERRIDE;
ALTER LOGIN [<host>\<user>] WITH DEFAULT_LANGUAGE = us_english;
```

**`apply_all.bat` is destructive.** Its first action runs `Tools/restore_DB_to_original_state.sql`, which puts `perpetuumsa` into single-user mode with `ROLLBACK IMMEDIATE` and restores over it with `REPLACE`. An existing `perpetuumsa` database is discarded without any prompt.

Note:
This is a divergent fork and changes within may not be generally applicable outside of the Open Perpetuum Project.  

Open Perpetuum does not provide technical support.  
**Use at your own risk.**  See LICENSE for details.  