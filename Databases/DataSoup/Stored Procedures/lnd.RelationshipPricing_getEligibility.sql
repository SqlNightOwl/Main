use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[RelationshipPricing_getEligibility]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [lnd].[RelationshipPricing_getEligibility]
GO
setuser N'lnd'
GO
CREATE procedure lnd.RelationshipPricing_getEligibility
	@MemberNumber	bigint	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/16/2008
Purpose  :	Retrieves the Relationship Pricing data from OSI for use by Lending
			based on either the Member Number or Tax Id (SSN).
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
12/10/2009	Paul Hunter		Changed to use MemberNumber parameter.
							Added try..catch logic.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd	nvarchar(1000)
,	@detail	varchar(4000)
,	@nbr	int
,	@result	int

select	@nbr	= 0
	,	@result	= 0

begin try

	if isnull(@MemberNumber, 0) > 0
	begin
		--	retrieve the person number matching the member number...
		select	@nbr = PRIMARYPERSNBR
		from	OSI..OSIBANK.MEMBERAGREEMENT
		where	MEMBERAGREENBR = @MemberNumber;
	end;

	--	if the information can be matched to a person....
	if isnull(@nbr, 0) > 0
	begin
		--	build the command to retrieve their eligibility...
		set	@cmd = '
		select	cast(MemberAgreeNbr as bigint)	as MemberAgreeNbr
			,	cast(PersNbr as int)			as PersNbr
			,	SHR
			,	DDA
			,	MMA
			,	CD
			,	IRA
			,	LN
			,	SDB
			,	CRD
			,	DQ
			,	case
				when DQ		= 1 then ''NO''
				when SHR 
				   + DDA 
				   + MMA 
				   + CD 
				   + IRA 
				   + LN 
				   + SDB 
				   + CRD	> 3 then ''YES''
				else ''NO''
				end		as Qualified
		from	openquery(OSI, ''
		select	MemberAgreeNbr
			,	PersNbr
			,	cast(SHR	as number(3)) as SHR
			,	cast(DDA	as number(3)) as DDA
			,	cast(MMA	as number(3)) as MMA
			,	cast(CD		as number(3)) as CD
			,	cast(IRA	as number(3)) as IRA
			,	cast(LN		as number(3)) as LN
			,	cast(SDB	as number(3)) as SDB
			,	cast(CRD	as number(3)) as CRD
			,	cast(DQ		as number(3)) as DQ
		from	texans.lnd_RelationshipPricing_vw
		where	PersNbr = ' + cast(@nbr as varchar(22)) + ''')';

		exec sp_executesql @cmd;

		set @result = @@error;
	end;
	else	--	could not be matched to a person...
	begin
		--	return a "dummy" recordset...
		select	cast(null as bigint)	as MemberAgreeNbr
			,	cast(null as int)		as PersNbr
			,	cast(null as smallint)	as SHR
			,	cast(null as smallint)	as DDA
			,	cast(null as smallint)	as MMA
			,	cast(null as smallint)	as CD
			,	cast(null as smallint)	as IRA
			,	cast(null as smallint)	as LN
			,	cast(null as smallint)	as SDB
			,	cast(null as smallint)	as CRD
			,	cast(null as smallint)	as DQ
			,	'N/A'					as Qualified

		set	@result = 1;
	end;
end try
begin catch
	--	capture the results and return a "dummy" recordset...
	exec tcu.ErrorDetail_get @detail out;

	select	cast(null as bigint)	as MemberAgreeNbr
		,	cast(null as int)		as PersNbr
		,	cast(null as smallint)	as SHR
		,	cast(null as smallint)	as DDA
		,	cast(null as smallint)	as MMA
		,	cast(null as smallint)	as CD
		,	cast(null as smallint)	as IRA
		,	cast(null as smallint)	as LN
		,	cast(null as smallint)	as SDB
		,	cast(null as smallint)	as CRD
		,	cast(null as smallint)	as DQ
		,	@detail					as Qualified

	set @result = 1;

end catch;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [lnd].[RelationshipPricing_getEligibility]  TO [wa_Services]
GO
GRANT  EXECUTE  ON [lnd].[RelationshipPricing_getEligibility]  TO [wa_Lending]
GO