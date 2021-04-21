SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : uspINVOICES_GetInvoiceDocumentPath   
-- Description     : This procedure  .
-- Input Parameters: @IPVC_InvoiceString varchar(8000)
--                     
-- Code Example    : Exec Invoices.dbo.uspINVOICES_GetInvoiceDocumentPath(@IPVC_InvoiceString)
--   
-- Revision History:  
-- Author          : Shashi Bhushan  
-- 01/03/2008      : Stored Procedure Created.  
--  
------------------------------------------------------------------------------------------------------ 
CREATE PROCEDURE [invoices].[uspINVOICES_GetInvoiceDocumentPath] ( @IPVC_InvoiceString varchar(8000))
AS
BEGIN
-----------------------------
-- Declaring Local Variables
-----------------------------
  declare @LI_Min int
  declare @LI_Max int
  Declare @LVC_InvoiceIDSeq varchar(22)
-----------------------------------
-- Declaring Local Table Variables
-----------------------------------
   Declare @LT_FinalData table (
                             InvoiceID          varchar(22),
                             BillingName        varchar(255),
                             BillToAddressLine1 varchar(255),
                             BillToAddressLine2 varchar(255),
                             BillToCity         varchar(70),
                             BillToState        varchar(2),
                             BillToZip          varchar(10),
                             CompanyIDSeq       varchar(11),
                             DocumentIDSeq      varchar(22),
                             DocumentPath       varchar(255)
							)


  
       Insert into @LT_FinalData (
                                  InvoiceID,
                                  BillingName,
                                  BillToAddressLine1,
                                  BillToAddressLine2,
                                  BillToCity,
                                  BillToState,
                                  BillToZip,
                                  CompanyIDSeq,
                                  DocumentIDSeq,
                                  DocumentPath
						 	     )
		select Inv.InvoiceIDSeq,
         isnull(Inv.PropertyName,Inv.CompanyName),
			   Inv.BillToAddressLine1,
			   Inv.BillToAddressLine2,
			   Inv.BillToCity,
			   Inv.BillToState,
			   Inv.BillToZip,
			   Doc.CompanyIDSeq,Doc.DocumentIDSeq,Doc.DocumentPath--,count(Inv.InvoiceIDSeq) 
		from Invoices.dbo.Invoice Inv (nolock)
		 Inner Join Documents.dbo.[Document] Doc (nolock) On Inv.InvoiceIDSeq=Doc.InvoiceIDSeq
		  and Doc.CompanyIDSeq is not null 
		  and Doc.InvoiceIDSeq is not null
		  and Doc.PrintOnInvoiceFlag = 1
      and Doc.ActiveFlag = 1
--		  and Doc.[Name] = 'Invoice' 
      and Inv.PrintBatchID is null
		where Inv.InvoiceIDSeq in (select SplitString from INVOICES.dbo.[fnGenericSplitString] (@IPVC_InvoiceString))
		group by Inv.BillToAddressLine1,Inv.BillToAddressLine2,Inv.InvoiceIDSeq,Inv.AccountIDSeq,Inv.BillToCity,Inv.BillToState,
				 Inv.BillToZip,Doc.CompanyIDSeq,Doc.DocumentIDSeq,Doc.DocumentPath,Inv.PropertyName,Inv.CompanyName 
		order by Inv.BillToAddressLine1

 
------------------------
-- The Final Select
------------------------
  select * from @LT_FinalData
  order by BillToAddressLine1, BillToAddressLine2, BillToCity, BillToState, BillToZip

  select count(*) as InvoiceCount, BillToAddressLine1, BillToAddressLine2, BillToCity, BillToState, BillToZip
  from @LT_FinalData
  group by BillToAddressLine1, BillToAddressLine2, BillToCity, BillToState, BillToZip
  order by BillToAddressLine1, BillToAddressLine2, BillToCity, BillToState, BillToZip

End
------------------------
-- For debuggin purpose
------------------------
--Declare @IPVC_InvoiceString varchar(8000)
--set @IPVC_InvoiceString = 'I0711000050|I0709000147|I0711000067|I0709000179|I0711000032|I0711000068|I0711000069|I0712000005|I0712000007|I0711000063|I0711000064|'
--Exec Invoices.dbo.uspINVOICES_GetInvoiceDocumentPath @IPVC_InvoiceString='I0711000050|I0709000147|I0711000067|I0709000179|I0711000032|I0711000068|I0711000069|I0712000005|I0712000007|I0711000063|I0801000027|'
GO
