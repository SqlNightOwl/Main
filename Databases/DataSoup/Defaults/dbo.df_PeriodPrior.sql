create default dbo.df_PeriodPrior as (cast(convert(char(6), dateadd(month, -1, getdate()), 112) as int))
GO