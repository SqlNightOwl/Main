SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspCredits_Rep_GetCreditInfo]
-- Description     : Retrieves CreditMemo Details.
-- Input Parameters: @CreditMemoIDSeq varchar(50)
--                   
-- OUTPUT          : 
-- Code Example    : Exec INVOICES.dbo.[uspCredits_Rep_GetCreditInfo]   @CreditMemoIDSeq  = 177
--                                                             
-- Revision History:
-- Author          : Shashi Bhushan
-- 10/09/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspCredits_Rep_GetCreditInfo] (@CreditMemoIDSeq varchar(50))
AS
BEGIN
  set nocount on;
-------------------------------------------------------------------     
--Declaring local table variable          
--------------------------------------------------------------------------
Declare  @MemoInvItems table(Seq                bigint identity(1,1),
							 MemoItemID         bigint,
							 InvItemID          bigint,
							 chargeTypeCode     char(4) null,
							 ProductName        varchar(100),
							 BillingPeriod      varchar(30),
							 Quantity           Numeric(30,2) default 0.00,
							 NetPrice           Numeric(30,2),
							 CreditAmount       Numeric(30,2),
							 TaxAmount          Numeric(30,2),
							 TotalCreditAmount  Numeric(30,2),
							 ILFNetChargeAmount Numeric(30,2) default 0, 
							 ILFNetCreditAmount Numeric(30,2) default 0,
							 ACSNetChargeAmount Numeric(30,2) default 0, 
							 ACSNetCreditAmount Numeric(30,2) default 0)
-------------------------------------------------------------------------------     
--Inserting data into @MemoInvItems variable based on parameter CreditMemoIDSeq    
-------------------------------------------------------------------------------
Insert into @MemoInvItems (MemoItemID,InvItemID,chargeTypeCode,ProductName,BillingPeriod,Quantity,NetPrice,CreditAmount,TaxAmount,
                           TotalCreditAmount,ILFNetChargeAmount,ILFNetCreditAmount,ACSNetChargeAmount,ACSNetCreditAmount)
select distinct cmi.IDSEq,cmi.InvoiceItemIDSeq,invi.ChargeTypeCode,P.DisplayName,
   Case when invi.chargeTypeCode='ACS' then Convert(varchar(12),invi.BillingPeriodFromDate,101) + ' - ' + Convert(varchar(12),invi.BillingPeriodToDate,101)
	 else Convert(varchar(12),invi.BillingPeriodFromDate,101) end  as BillingPeriod,
   invi.Quantity,invi.NetChargeAmount,cmi.ExtCreditAmount,cmi.TaxAmount,(cmi.ExtCreditAmount+cmi.TaxAmount),
   Case when invi.chargeTypeCode='ILF' then InvI.NetChargeAmount
	  else 0 end,
   Case when invi.chargeTypeCode='ILF' then CmI.NetCreditAmount
	  else 0 end,
   Case when invi.chargeTypeCode='ACS' then InvI.NetChargeAmount
	  else 0 end,
   Case when invi.chargeTypeCode='ACS' then CmI.NetCreditAmount
	  else 0 end 
from  Invoices.dbo.creditmemoitem cmi with (nolock)
inner  Join  
      Invoices.dbo.InvoiceItem    invi with (nolock)
On    invi.IDSeq         = cmi.InvoiceItemIDSeq
and   invi.InvoiceIDSeq  = cmi.InvoiceIDSeq
and   cmi.CreditMemoIDSeq=@CreditMemoIDSeq
inner  Join 
      Products.dbo.Product P with (nolock) 
On    invi.ProductCode = P.Code
and   invi.PriceVersion= P.Priceversion
where cmi.CreditMemoIDSeq=@CreditMemoIDSeq
-------------------------------------------------------------------------------     
--Retrieving Final Data    
-------------------------------------------------------------------------------
select * from @MemoInvItems order by chargetypecode desc
END
GO
