use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[SqlDrive_upd]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[SqlDrive_upd]
GO
setuser N'ops'
GO
create procedure ops.SqlDrive_upd
as 
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/07/2009
Purpose  :	Procedure to update ops.SqlDrive table usinf sp_OACreate, sp_OAMethod,
			sp_OAGetProperty and sp_OADestroy system stored procedures to create
			the FileSystemObject Ole Automation object to collect the stats on
			the attached drives.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd		nvarchar(130)
,	@drive		char(1)
,	@freeMb		int 
,	@hResult	int
,	@hWnd		int
,	@MB			int
,	@oDrive		int
,	@totalSize	bigint

declare @drives table
(	Drive	char(1)	not null primary key
,	FreeMb	int		not null
,	TotalMb	int		not null default (0)
);

--	initialize the variables
set @drive	= '';
set @MB		= 1048576;	-- conversion ratio for bytes to megabytes

--	collect the attached Drives and FreeSpace
insert @drives(Drive, FreeMb) exec master.dbo.xp_fixeddrives ;

--	build the command to allow the creation/use of the FileSystemObject...
set	@cmd	= '
exec sp_configure ''show advanced options'', 1;
reconfigure;
exec sp_configure ''Ole Automation Procedures'', 1;
reconfigure;'
exec sp_executeSql @cmd;

--	create the FileSystemObject
exec @hResult = sp_OACreate 'Scripting.FileSystemObject', @hWnd out;

--	proceed if sucessful creating the OLE Object...
if @hResult = 0
begin
	--	loop thru the drives and retrieve the total size...
	while exists (	select	top 1 * from @drives
					where	Drive > @drive	)
	begin
		--	retrieve the next available drive...
		select	top 1
				@drive	= Drive
			,	@freeMb	= FreeMb 
		from	@drives
		where	Drive	> @drive
		order by Drive;

		--	get the Drive object and then read the TotalSize (in bytes) property
		exec @hResult = sp_OAMethod @hWnd, 'GetDrive', @oDrive out, @drive;
		exec @hResult = sp_OAGetProperty @oDrive, 'TotalSize', @totalSize out;

		--	update the drive...
		update	@drives
		set		TotalMb = @totalSize / @MB
		where	Drive	= @drive;

	end;

	--	destroy the FileSystemObject object...
	exec sp_OADestroy @hWnd;

	--	update the fixed table...
	update	d
	set		MbTotal		= t.TotalMb
		,	MbFree		= t.FreeMb
		,	UpdatedOn	= getdate()
	from	ops.SqlDrive	d
	join	@drives			t
			on	d.Drive = t.Drive;
end;

--	disable OLE Automation...
set	@cmd	= '
exec sp_configure ''Ole Automation Procedures'', 0;
reconfigure;
exec sp_configure ''show advanced options'', 0;
reconfigure;'

exec sp_executeSql @cmd;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO