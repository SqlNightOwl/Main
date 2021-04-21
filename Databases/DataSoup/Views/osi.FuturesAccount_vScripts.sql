use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[FuturesAccount_vScripts]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[FuturesAccount_vScripts]
GO
setuser N'osi'
GO
CREATE view osi.FuturesAccount_vScripts
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/09/2008
Purpose  :	Provides SQL scripts that will convert Future Account accounts 
			to a regular checking account based on:
			•	Member still has an "Active" "Futures Account" minor
			•	Member is over 24 years old at the end of the preceeding month
					(12 * 24) + 2 = 290 months
			•	Member is not purged
			•	Member mail type code is not "Hold"
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/06/2009	Paul Hunter		Added the update to AcctMiAcctHist
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	'update osiBank.Acct '				+
		'set CurrMiAcctTypCd = ''CFC'''		+
		', DateLastMaint = sysdate '		+
		'where AcctNbr = ' + AcctNbr + ';'		as ChangeMinorType_SQL
	,	'update osiBank.AcctUserField '		+
		'set Value = ''Y'''					+
		', DateLastMaint = sysdate '		+
		'where AcctNbr = ' + AcctNbr		+
		' and UserFieldCd = ''PSMX'';'			as UserFieldPSMX_SQL
	,	'update osiBank.AcctUserField '		+
		'set Value = ''1'''					+
		', DateLastMaint = sysdate '		+
		'where AcctNbr = ' + AcctNbr		+
		' and UserFieldCd = ''PSOD'';'			as UserFieldPSOD_SQL
	,	'update osiBank.AcctMemoBalTyp '	+
		'set BalAmt = 500'					+
		', DateLastMaint = sysdate '		+
		'where AcctNbr = ' + AcctNbr		+
		' and MemoBalTypCd = ''MOVD'';'			as OverDraftAmt_SQL
	,	'update osiBank.AcctMiAcctHist '	+
		'set MiAcctTypCd = ''CFC'''			+
		', DateLastMaint = sysdate '		+
		'where AcctNbr = ' + AcctNbr + ';'		as UpdateMiHist_SQL
from	openquery(OSI, '
		select	cast(a.AcctNbr as varchar(22)) as AcctNbr
		from	osiBank.Acct				a
		join	osiBank.Pers				p
				on	p.PersNbr = a.TaxRptForPersNbr
		join	texans.CustomerAddress_vw	ca
				on	p.PersNbr = ca.PersNbr
		where	a.CurrAcctStatCd	=	''ACT''
		and		a.MjAcctTypCd		=	''CK''
		and		a.CurrMiAcctTypCd	=	''CFY''
		and		a.MailTypCd			!=	''HOLD''
		and		p.PurgeYN			=	''N''
		and		p.DateBirth			<	pkg_Date.LastDay_Months((25 * -12) - 2)	--	25 years of age (24 * 12) + 2
		and		ca.AddrUseCd		=	''PRI''
		and		ca.ZipCd			!=	''99999''');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO