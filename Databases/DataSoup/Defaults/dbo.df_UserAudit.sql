create default dbo.df_UserAudit as (substring(suser_sname(), charindex('\', suser_sname()) + 1, 25));
GO