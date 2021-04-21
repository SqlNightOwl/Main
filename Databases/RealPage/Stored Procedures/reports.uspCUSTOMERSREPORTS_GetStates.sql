SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [reports].[uspCUSTOMERSREPORTS_GetStates]
AS
BEGIN
 Declare @States table (Sno int identity(1,1),[Name] varchar(100))

Insert into @States 
select distinct state 
from CUSTOMERS.dbo.Address  with (nolock) 
where State <> '' and State is not null and countrycode = 'USA' order by state asc
--=============
Insert into @States
select distinct state 
from CUSTOMERS.dbo.Address  with (nolock) 
where State <> '' and State is not null and countrycode = 'CAN' order by state asc


select * FROM @States

END

GO
