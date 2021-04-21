use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[NetLendLog_ins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [lnd].[NetLendLog_ins]
GO
setuser N'lnd'
GO
create procedure lnd.NetLendLog_ins
	@MemberNumber	bigint
,	@SSN			varchar(11)
,	@Success		bit
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	08/17/2007
Purpose  :	Records an instance of requesting Member information for for the
			NetLend PreFill process.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

insert	lnd.NetLendLog
	(	MemberNumber
	,	SSN
	,	Success
	,	RecordedOn	)
values
	(	isnull(@MemberNumber, 0)
	,	isnull(@SSN, '')
	,	isnull(@Success, 0)
	,	getdate()	)

return @@error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO