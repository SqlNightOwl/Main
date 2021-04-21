use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[ScanDetail_upd]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[ScanDetail_upd]
GO
setuser N'risk'
GO
CREATE procedure risk.ScanDetail_upd
	@ScanId			smallint
,	@ScanDetailId	smallint
,	@DeviceId		int
,	@AssignedTo		int
,	@Status			varchar(10)
,	@Resolution		varchar(500)	= null
,	@ApprovedBy		int				= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil
Created  :	04/09/2009
Purpose  :	Updates the resolution notes and Scan assignmnent status
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@return	int
,	@rows	int

update	risk.ScanDetail
set		AssignedTo		= @AssignedTo
	,	Status			= nullif(rtrim(isnull(@Status		, Status))		, '')
	,	Resolution		= nullif(rtrim(isnull(@Resolution	, Resolution))	, '')
	,	ApprovedBy		= @ApprovedBy
	,	UpdatedBy		= tcu.fn_UserAudit()
	,	UpdatedOn		= getdate()
where	ScanId			= @ScanId
and		ScanDetailId	= @ScanDetailId

set	@return	= @@error;

PROC_EXIT:
if @return != 0
begin
	declare	@errorProc sysname;
	set	@errorProc = object_schema_name(@@procid) + '.' + object_name(@@procid);
	raiserror(N'An error occured while executing the procedure "%s"', 15, 1, @errorProc) with log;
end

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [risk].[ScanDetail_upd]  TO [wa_SecurityScan]
GO