create default dbo.df_PeriodCurrent as (cast(convert(char(6), getdate(), 112) as int))
GO