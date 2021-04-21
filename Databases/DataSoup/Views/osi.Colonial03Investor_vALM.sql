use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Colonial03Investor_vALM]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[Colonial03Investor_vALM]
GO
setuser N'osi'
GO
CREATE view osi.Colonial03Investor_vALM
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/27/2007
Purpose  :	Used for generating the monthly FTI ALM file from Colonial Loans
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
07/14/2008	Paul Hunter		Disply the decimal for the Payment, Principal and
							Interest Rate fields.
————————————————————————————————————————————————————————————————————————————————
*/

select 	Record	= cl.CategoyNum								+ ' '
				+ right(replicate('0', 10) + cast(cl.TotalPaymentAmount	as varchar), 10)	+ ' '
				+ right(replicate('0', 14) + cast(cl.PrincipalBalance	as varchar), 14)	+ ' '
				+ right(replicate('0', 10) + cast(cast(cl.InterestRate	as decimal(9,3)) as varchar), 10) + ' '
				+ isnull(cl.MaturityDate	, '00000000')	+ ' '
				+ isnull(cl.DueDate			, '00000000')	+ ' '
				+ '1 '			--	InputNumber
				+ isnull(cl.OriginalLoanDate,'00000000')	+ ' '
				+ tcu.fn_ZeroPad(cm.MemberNumber, 13)
				+ cl.ColonialLoanNum						+ ' '
				+ cl.LoanType
				+ ' 000052'		--	Branch
from	osi.Colonial03Investor	cl
join	osi.ColonialMember		cm
		on	cl.colonialLoanNum = cm.ColonialLoanNum
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO