create default dbo.df_Today as cast(convert(char(10), getdate(), 121) as datetime)
GO