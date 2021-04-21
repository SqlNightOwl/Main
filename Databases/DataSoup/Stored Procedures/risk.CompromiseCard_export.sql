use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[CompromiseCard_export]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[CompromiseCard_export]
GO
setuser N'risk'
GO
CREATE procedure risk.CompromiseCard_export
	@RunId			int
,	@ProcessId		smallint
,	@ScheduleId		tinyint
,	@LoadedOn		datetime	= null
,	@CompromiseId	int			= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/18/2009
Purpose  :	Exports the Compromised Card file for the specified load date or
			compromise.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	nvarchar(750)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@lastColumn	smallint
,	@message	varchar(4000)
,	@result		int
,	@rowTypes	varchar(255)
,	@type		varchar(50)

--	initialize the process parameters
select	@actionCmd	= db_name() + '.' + f.FileName
	,	@actionFile	= p.SQLFolder + f.TargetFile
	,	@message	= p.MessageBody
	,	@detail		= ''
	,	@result		= 0
	,	@rowTypes	= ''
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId
and		f.ApplName	= N'Target';

--	make sure the criteria is in sync...
if @LoadedOn is not null
begin
	select	@CompromiseId	= 0
		,	@type			= 'file(s) loaded on ' + convert(char(10), @LoadedOn, 101);
end
if nullif(@CompromiseId, 0) is not null
begin
	select	@type		= Compromise + ' compromise'
		,	@LoadedOn	= 0
	from	risk.Compromise
	where	CompromiseId = @CompromiseId;
end

--	collect the specific alerts from the database
select	@rowTypes = @rowTypes + cast(AlertId as varchar(10)) + ','
from	risk.CompromiseAlert
where	LoadedOn	= @LoadedOn		or @LoadedOn	 is null
	or	CompromiseId= @CompromiseId	or @CompromiseId is null
order by AlertId

if len(@rowTypes) > 0 
begin
	--	alerts are stored in the RowType column so add "0" to get the header row
	set @rowTypes = @rowTypes + '0'	

	--	update the card status from OSI before producing the file
	exec risk.CompromiseCardHolder_updCardStatus

	--	determine what the last column of the queried columns is...
	select	@lastColumn = column_id from sys.columns
	where	[object_id] = object_id(ltrim(@actionCmd))
	and		name != 'RowType';

	--	build a sql string for the target command...
	select	@actionCmd	=	case column_id
							when 1 then 'select ' + name + ', '
							when @lastColumn then name + ' from '
							else name + ', '
							end + @actionCmd
	from	sys.columns
	where	[object_id] =	object_id(ltrim(@actionCmd))
	and		name		!=	'RowType'
	order by column_id desc;

	--	add the where clause for exporting the detail...
	set @actionCmd	= @actionCmd
					+ ' where	RowType	in (' + @rowTypes	--	these are the alerts + the header row
					+ ') order by RowType, case RowType when 0 then 0 else cast(CardId as int) end;';

	--	export the detail...
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail	output;

	--	substitute the message for the detail if no error occur...
	if @result = 0 and len(@detail) = 0
	begin
		set	@detail = replace(@message, '#TARGET_FILE#', @actionFile);
		set	@detail	= replace(@message, '#COMPROMISE#', @actionFile);
	end
	else	--	report any errors...
	begin	
		set	@result = 3;	--	warning
	end

	exec tcu.ProcessNotification_send	@ProcessId	= @ProcessId
									,	@Result		= @result
									,	@Details	= @detail;

end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO