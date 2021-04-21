use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[PurgeActivity_report]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[PurgeActivity_report]
GO
setuser N'osi'
GO
CREATE procedure osi.PurgeActivity_report
	@BeginOn	datetime
,	@EndOn		datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huter
Created  :	12/19/2008
Purpose  :	Extracts OSI Activity of Org/Pers records marked for purge between
			the dates specified.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd	nvarchar(2100)
,	@start	char(10)
,	@stop	char(10)

--	setup the string values for the begin/end dates
set	@start	= convert(char(10), @BeginOn, 101)
set	@stop	= convert(char(10), @EndOn	, 101)

--	create the extract query with column headers
set	@cmd = '
select	cast(''ActvNbr''		as varchar(20))	as ActvNbr
	,	cast(''ActvCatCd''		as varchar(10))	as ActvCatCd
	,	cast(''ActvTypCd''		as varchar(10))	as ActvTypCd
	,	cast(''ActvDateTime''	as varchar(20))	as ActvDateTime
	,	cast(''CustNbr''		as varchar(20))	as CustNbr
	,	cast(''CustType''		as varchar(10))	as CustType
	,	cast(''EmployeeName''	as varchar(50))	as EmployeeName
	,	cast(''DatabaseActvCd''	as varchar(15))	as DatabaseActvCd
	,	cast(''ActvSubNbr''		as varchar(20))	as ActvSubNbr
	,	cast(''ValueChanged''	as varchar(50))	as ValueChanged
	,	cast(''OldValue''		as varchar(50))	as OldValue
	,	cast(''NewValue''		as varchar(50))	as NewValue
union all
select	cast(ActvNbr as varchar(20))
	,	ActvCatCd
	,	ActvTypCd
	,	convert(varchar(19), ActvDateTime, 120)
	,	cast(CustNbr as varchar(10))
	,	CustType
	,	EmployeeName
	,	DatabaseActvCd
	,	cast(ActvSubNbr as varchar(20))
	,	ValueChanged
	,	OldValue
	,	NewValue
from	openquery(OSI, ''
		select	a.ActvNbr
			,	a.ActvCatCd
			,	a.ActvTypCd
			,	a.ActvDateTime
			,	nvl(a.SubjPersNbr, a.SubjOrgNbr)		as CustNbr
			,	decode(	coalesce(a.SubjPersNbr, a.SubjOrgNbr, a.SubjAcctNbr)
					,	a.SubjPersNbr, ''''PERS''''
					,	a.SubjOrgNbr , ''''ORG'''')		as CustType
			,	e.FirstName ||'''' ''''|| e.LastName	as EmployeeName
			,	s.DatabaseActvCd
			,	s.ActvSubNbr
			,	s.TableId ||''''.''''|| s.ColumnId		as ValueChanged
			,	s.OldValue
			,	s.NewValue
		from	osiBank.Actv		a
		join	osiBank.ActvSubActv	s
				on	a.ActvNbr = s.ActvNbr
		join	osiBank.Pers		e
				on	a.RespPersNbr = e.PersNbr
		where	a.ActvCatCd			in (''''OMNT'''',''''PMNT'''')
		and		a.ActvTypCd			in (''''ORG'''',''''PERS'''')
		and		s.DatabaseActvCd	=	''''DEL''''
		and		s.TableId			in (''''ORG'''',''''PERS'''')
		and		trunc(a.PostDate)	between to_date(''''' + @start	+ ''''', ''''mm/dd/yyyy'''' )
										and to_date(''''' + @stop	+ ''''', ''''mm/dd/yyyy'''' )'');';

--	if a string is built then execute it.
if len(isnull(@cmd, '')) > 0
begin
	exec sp_executesql @cmd;

	return @@error;
end;
else
begin
	--	return failure...
	return 1;
end;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO