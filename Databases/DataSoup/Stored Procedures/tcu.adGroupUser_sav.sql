use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[adGroupUser_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[adGroupUser_sav]
GO
setuser N'tcu'
GO
CREATE procedure tcu.adGroupUser_sav
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/17/2007
Purpose  :	Used to load/synchronize the ad_GroupUser table from the extra file.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@userName	varchar(25)

set	@userName = tcu.fn_UserAudit();

--	make sure the table exitst first
if exists (	select	* from sys.objects
			where	[object_id]	= object_id(N'[tcu].[adGroupUser_load]')
			and		1			= objectproperty([object_id], N'IsUserTable')	)
begin

	--	make sure there are records in the table
	if exists (	select	top 1 * from tcu.adGroupUser_load	)
	begin

		--	add new GroupUser records
		insert	tcu.adGroupUser
			(	samGroupName
			,	samUserName
			,	EmployeeNumber
			,	IsActive
			,	CreatedOn
			,	CreatedBy	)
		select	distinct
				l.samGroupName
			,	l.samUserName
			,	EmployeeNumber	=	case isnumeric(substring(l.samUserName, 2, 10))
									when 1 then cast(substring(l.samUserName, 2, 10) as int)
									else 0 end
			,	IsActive		=	1
			,	CreatedOn		=	getdate()
			,	CreatedBy		=	'System'
		from	tcu.adGroupUser_load	l
		left join	tcu.adGroupUser		u
				on	l.samGroupName	= u.samGroupName
				and	l.samUserName	= u.samUserName
		where	u.samGroupName is null;

		-- update inactive GroupUser records
		update	u
		set		IsActive	= 0
			,	UpdatedOn	= getdate()
			,	UpdatedBy	= @userName
		from	tcu.adGroupUser_load	l
		right join	tcu.adGroupUser		u
				on	l.samGroupName	= u.samGroupName
				and	l.samUserName	= u.samUserName
		where	l.samGroupName	is null
		and		u.IsActive		= 1;

		-- update GroupUser records for the terminated Users
		update	gu
		set		IsActive	= 0
			,	UpdatedOn	= getdate()
			,	UpdatedBy	= @userName
		from	tcu.adUser_v		u
		join	tcu.adGroupUser	gu
				on	u.samUserName	= gu.samUserName
		where	u.IsTerminated	= 1;

	end

	drop table tcu.adGroupUser_load;

end;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO