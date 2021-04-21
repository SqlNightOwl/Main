use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[FlashFilePlayList_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[FlashFilePlayList_sav]
GO
setuser N'mkt'
GO
CREATE procedure mkt.FlashFilePlayList_sav
	@PlayListId		tinyint
,	@FlashFileId	int
,	@Sequence		tinyint
,	@IsEnabled		bit
,	@ReSequence		bit 							-- In case of inserting a new row at an existing sequence
,	@errmsg			varchar(255)	= null	output	-- in case of error
,	@debug			tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Biju Basheer
Created  :	11/06/2005
Purpose  :	Inserts/Updates a record in the mktFlashFilePlayList table based upon
			the primary key.
History  :
   Date		 Developer		 Modification
——————————	——————————————	————————————————————————————————————————————————————
01/28/2008	Fijula Kuniyil	Included the logic to reshuffle after inserting.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@method	varchar(6)
,	@proc	varchar(255)
,	@query	nvarchar (500)

set @method = 'update'
set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

if exists (	select  top 1 PlayListId from mkt.FlashFilePlayList
			where	Sequence	= @Sequence
			and		PlayListId	= @PlayListId	)	--Sequence already exists
begin
	if (@ReSequence = 1)
	begin
		--	resequence the play list if they are rearranging things
		update	mkt.FlashFilePlayList
		set		Sequence	=	Sequence + 1
		where	PlayListId	=	@PlayListId
		and		Sequence	>=	@Sequence

		-- now the sequence number is free, for new record to be inserted
		insert	mkt.FlashFilePlayList
			(	PlayListId
			,	Sequence
			,	FlashFileId
			,	IsEnabled
			,	CreatedOn
			,	CreatedBy
			)
		values
			(	@PlayListId
			,	@Sequence
			,	@FlashFileId
			,	@IsEnabled
			,	getdate()
			,	tcu.fn_UserAudit()
			)
	end
	else -- over write the fileid at specified sequence
	begin
		update	mkt.FlashFilePlayList
		set		FlashFileId	= isnull(@FlashFileId, FlashFileId)
			,	IsEnabled	= isnull(@IsEnabled, IsEnabled)
			,	UpdatedOn	= getdate()
			,	UpdatedBy	= tcu.fn_UserAudit()
		where	PlayListId	= @PlayListId
		and 	Sequence	= @Sequence

	end
	set	@error = @@error

end 
else
begin
	set @method = 'insert'

	insert	mkt.FlashFilePlayList
		(	PlayListId
		,	Sequence
		,	FlashFileId
		,	IsEnabled
		,	CreatedOn
		,	CreatedBy
		)
	values
		(	@PlayListId
		,	@Sequence
		,	@FlashFileId
		,	@IsEnabled
		,	getdate()
		,	tcu.fn_UserAudit()
		)

	select	@error	= @@error

end -- else (insert)

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
GRANT  EXECUTE  ON [mkt].[FlashFilePlayList_sav]  TO [wa_Marketing]
GO