use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Location_getZipCodes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Location_getZipCodes]
GO
setuser N'tcu'
GO
create procedure tcu.Location_getZipCodes
	@ZipCodeList	varchar(8000)	output
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/03/2005
Purpose  :	Retrieves the distinct ZipCodes for the branches.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

set	@ZipCodeList = ''

select	@ZipCodeList = @ZipCodeList + ZipCode + ','
from	tcu.Location
where	LocationType	= 'Branch'
and		ZipCode			is not null
group by ZipCode
order by ZipCode

set @ZipCodeList = left(@ZipCodeList, len(@ZipCodeList) -1)
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO