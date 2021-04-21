use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[FlashFile_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[FlashFile_sav]
GO
setuser N'mkt'
GO
CREATE procedure mkt.FlashFile_sav
	@FlashFileId	int						output
,	@FlashFile		varchar(255)	= null
,	@RunLength		int				= null
,	@Description	varchar(255)	= null
,	@EffectiveOn	datetime		= null
,	@ExpiresOn		datetime		= null
,	@IsAvailable	bit				= null
,	@AspectRatio	decimal(3,1)	= null
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Neelima Ganapathineedi
Created  :	08/21/2006
Purpose  :	Inserts/Updates a record in the mktFlashFile table.
History  :
   Date		 Developer		 Modification
——————————	——————————————	————————————————————————————————————————————————————
02/26/2007	Paul Hunter		Added EffectiveOn and ExpiresOn coulumns
11/01/2007	Biju Basheer	Added AspectRatio coulumn
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@method	varchar(6)
,	@proc	varchar(255)
,	@rows	int

set	@method	= 'update'
set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

update	mkt.FlashFile
set		FlashFile		= isnull(@FlashFile, FlashFile)
	,	RunLength		= isnull(@RunLength, RunLength)
	,	Description		= isnull(@Description, Description)
	,	EffectiveOn		= @EffectiveOn
	,	ExpiresOn		= @ExpiresOn
	,	IsAvailable		= isnull(@IsAvailable, IsAvailable)
	,	AspectRatio		= isnull(@AspectRatio, AspectRatio)
	,	UpdatedOn		= getdate()
	,	UpdatedBy		= tcu.fn_UserAudit()
where	FlashFileId		= @FlashFileId

--	collect the errors and rowcount for reporting
select	@error	= @@error
	,	@rows	= @@rowcount

--	if no rows were updated and no errors occured then insert
if @rows = 0 and @error = 0
begin
	set @method = 'insert'

	insert	mkt.FlashFile
		(	FlashFile
		,	RunLength
		,	Description
		,	EffectiveOn
		,	ExpiresOn
		,	IsAvailable
		,	AspectRatio
		,	CreatedOn
		,	CreatedBy	)
	values
		(	@FlashFile
		,	@RunLength
		,	@Description
		,	@EffectiveOn
		,	@ExpiresOn
		,	@IsAvailable
		,	@AspectRatio
		,	getdate()
		,	tcu.fn_UserAudit()	)

	select	@FlashFileId	= scope_identity()
		,	@error			= @@error

end --	update

PROC_EXIT:
if @error != 0
	set	@errmsg = @proc + @method

return @error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[FlashFile_sav]  TO [wa_Marketing]
GO