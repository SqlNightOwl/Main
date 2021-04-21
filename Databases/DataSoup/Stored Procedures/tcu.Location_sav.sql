use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Location_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Location_sav]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Location_sav
	@LocationId			int				= null	output
,	@Location			varchar(50)
,	@LocationType		varchar(10)		= null
,	@LocationSubType	varchar(10)		= null
,	@LocationCode		varchar(10)		= null
,	@OrgNbr				int				= null
,	@AddressCode		varchar(10)		= null
,	@Address1			varchar(100)	= null
,	@Address2			varchar(100)	= null
,	@City				varchar(100)	= null
,	@State				char(2)			= null
,	@ZipCode			varchar(9)		= null
,	@Phone				varchar(15)		= null
,	@Fax				varchar(15)		= null
,	@ParentId			int				= null
,	@ManagerId			int				= null
,	@DepartmentCode		varchar(10)		= null
,	@PlayListId			tinyint			= null
,	@Region				varchar(50)		= null
,	@Directions			varchar(500)	= null
,	@WebNotice			nvarchar(1000)	= null
,	@Latitude			decimal(9, 6)	= null
,	@Longitude			decimal(9, 6)	= null
,	@CashBox			int				= null
,	@DirectPostAcctNbr	bigint			= null
,	@IsActive			bit				= null
,	@HasPublicAccess	bit				= null
as
/*
»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
			© 2000-09 - Texans Credit Union - All Rights Reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/19/2008
Purpose  :	Saves (update/insert) records in the tcu.Location table.
History  :
   Date		Developer		Description
——————————  ——————————————  ————————————————————————————————————————————————————
««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
*/

set nocount on;

declare
	@error	int
,	@proc	sysname 
,	@rows	int;

set	@proc	= db_name() + '.' + schema_name() + '.' + object_name(@@procid);

update	tcu.Location
set		Location			= @Location
	,	LocationType		= @LocationType
	,	LocationSubType		= nullif(rtrim(isnull(@LocationSubType, LocationSubType)), '')
	,	LocationCode		= @LocationCode
	,	OrgNbr				= @OrgNbr
	,	AddressCode			= nullif(rtrim(isnull(@AddressCode, AddressCode)), '')
	,	Address1			= @Address1
	,	Address2			= nullif(rtrim(isnull(@Address2, Address2)), '')
	,	City				= @City
	,	State				= @State
	,	ZipCode				= @ZipCode
	,	Phone				= nullif(rtrim(isnull(@Phone, Phone)), '')
	,	Fax					= nullif(rtrim(isnull(@Fax, Fax)), '')
	,	ParentId			= isnull(@ParentId, ParentId)
	,	ManagerId			= isnull(@ManagerId, ManagerId)
	,	DepartmentCode		= nullif(rtrim(isnull(@DepartmentCode, DepartmentCode)), '')
	,	PlayListId			= @PlayListId
	,	Region				= nullif(rtrim(isnull(@Region, Region)), '')
	,	Directions			= nullif(rtrim(isnull(@Directions, Directions)), '')
	,	WebNotice			= nullif(rtrim(isnull(@WebNotice, WebNotice)), '')
	,	Latitude			= @Latitude
	,	Longitude			= @Longitude
	,	CashBox				= isnull(@CashBox, CashBox)
	,	DirectPostAcctNbr	= isnull(@DirectPostAcctNbr, DirectPostAcctNbr)
	,	IsActive			= @IsActive
	,	HasPublicAccess		= @HasPublicAccess
	,	UpdatedBy			= tcu.fn_UserAudit()
	,	UpdatedOn			= getdate()
where	LocationId			= @LocationId;

select	@error	= @@error
	,	@rows	= @@rowcount;

--	if no errors happened and no rows were affected then perform the insert
if @rows = 0 and @error = 0
begin
	insert	tcu.Location
		(	Location
		,	LocationType
		,	LocationSubType
		,	LocationCode
		,	OrgNbr
		,	AddressCode
		,	Address1
		,	Address2
		,	City
		,	State
		,	ZipCode
		,	Phone
		,	Fax
		,	ParentId
		,	ManagerId
		,	DepartmentCode
		,	PlayListId
		,	Region
		,	Directions
		,	WebNotice
		,	Latitude
		,	Longitude
		,	CashBox
		,	DirectPostAcctNbr
		,	IsActive
		,	HasPublicAccess
		,	CreatedBy
		,	CreatedOn
		)
	values
		(	@Location
		,	@LocationType
		,	@LocationSubType
		,	@LocationCode
		,	@OrgNbr
		,	@AddressCode
		,	@Address1
		,	@Address2
		,	@City
		,	@State
		,	@ZipCode
		,	@Phone
		,	@Fax
		,	@ParentId
		,	@ManagerId
		,	@DepartmentCode
		,	@PlayListId
		,	@Region
		,	@Directions
		,	@WebNotice
		,	@Latitude
		,	@Longitude
		,	isnull(@CashBox, 0)
		,	isnull(@DirectPostAcctNbr, 0)
		,	@IsActive
		,	@HasPublicAccess
		,	tcu.fn_UserAudit()
		,	getdate()
		);

	select	@LocationId	= scope_identity()
		,	@error		= @@error;

end;

PROC_EXIT:
if @error != 0
begin
	raiserror('An error occured while executing the procedure "%s"', 15, 1, @proc) with log;
end;

return @error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO