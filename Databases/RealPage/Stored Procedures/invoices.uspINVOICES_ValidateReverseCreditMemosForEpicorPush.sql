SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_ValidateReverseCreditMemosForEpicorPush
*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_ValidateReverseCreditMemosForEpicorPush
-- Description     : This procedure Validate if any Reverse Credit Memos qualify for Epicor Push to get a 
--                      newly generated BatchCode from Epicor
-- Input Parameters:
-- OUTPUT          : count of credit ID's.
--  
--                   
-- Code Example    : exec INVOICES.dbo.uspINVOICES_ValidateReverseCreditMemosForEpicorPush
-- Revision History:
-- Author          : ShashiBhushan
-- 08/02/2010      : Stored Procedure Created.
-- 08/05/2010      : Shashi Bhushan -	Defect#7952 - Credit Reversals in OMS
-- 05/26/2011      : Surya Kondapalli -	Task# 335	 - Create the Epicor integration for Credit Reversals
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_ValidateReverseCreditMemosForEpicorPush] 
AS
BEGIN
  set nocount on 
  ----------------------------------------------------------------------------

  Select	TotalCreditReversalCount = CASE WHEN USACreditReversalCount = 0 AND CanadaCreditReversalCount = 0
									 THEN 0 ELSE TotalCreditReversalCount END
		 ,	USACreditReversalCount
		 ,	CanadaCreditReversalCount
   From 
			(
			 Select Count(Distinct IC.InvoiceIdseq) As  CanadaCreditReversalCount
			,1 AS 'RowNumber'
			 From CreditMemo CMC with (nolock)
			 Inner Join INVOICES.dbo.Invoice IC With (nolock)
				on CMC.InvoiceIDSeq = IC.InvoiceIDSeq
			 Inner Join Invoices.dbo.InvoiceItem IIC with (nolock)
						 on     IIC.InvoiceIDSeq  = IC.InvoiceIDSeq
			 Inner Join Products.dbo.Product PC with (nolock)
						 on     IIC.ProductCode = PC.Code
						 And    IIC.PriceVersion= PC.PriceVersion
			 Inner Join CUSTOMERS.DBO.ADDRESS ADC WITH (nolock)
				   On    ADC.CompanyIDSeq    = IC.CompanyIDSeq
				   And      ADC.AddressTypeCode = IC.BillToAddressTypeCode 
				   And     (
							(ADC.AddressTypeCode = IC.BillToAddressTypeCode And 
							 ADC.AddressTypeCode Like 'PB%'                 And 
							 coalesce(ADC.PropertyIDSeq,'') = coalesce(IC.PropertyIDSeq,'')
							)
							  Or
						   (ADC.AddressTypeCode = IC.BillToAddressTypeCode And 
							ADC.AddressTypeCode Not Like 'PB%'  
						   )
						  )
			 Where  CMC.CreditStatusCode = 'APPR'
			 And    CMC.SentToEpicorStatus is null 
			 And    CMC.SentToEpicorFlag       = 0
			 And    CMC.CreditMemoReversalFlag = 1
			 And    ADC.CountryCode = 'CAN'
			 And    PC.FamilyCode = 'DCN'
			 ) As CanadaCreditReversalCount
	
		  Join
		   (
			  Select Count(Distinct IU.InvoiceIdseq) As USACreditReversalCount
			 ,1 AS 'RowNumber'
			 From CreditMemo CMU with (nolock)
			 Inner Join INVOICES.dbo.Invoice IU With (nolock)
				on CMU.InvoiceIDSeq = IU.InvoiceIDSeq
			 Inner Join Invoices.dbo.InvoiceItem IIU with (nolock)
						 on     IIU.InvoiceIDSeq  = IU.InvoiceIDSeq
			 Inner Join Products.dbo.Product PU with (nolock)
						 on     IIU.ProductCode = PU.Code
						 And    IIU.PriceVersion= PU.PriceVersion
			 Inner Join CUSTOMERS.DBO.ADDRESS ADU WITH (nolock)
				   On    ADU.CompanyIDSeq    = IU.CompanyIDSeq
				   And      ADU.AddressTypeCode = IU.BillToAddressTypeCode 
				   And     (
							(ADU.AddressTypeCode = IU.BillToAddressTypeCode And 
							 ADU.AddressTypeCode Like 'PB%'                 And 
							 Coalesce(ADU.PropertyIDSeq,'') = Coalesce(IU.PropertyIDSeq,'')
							)
							  Or
						   (ADU.AddressTypeCode = IU.BillToAddressTypeCode And 
							ADU.AddressTypeCode Not Like 'PB%'  
						   )
						  )
			 Where  CMU.CreditStatusCode = 'APPR'
			 And    CMU.SentToEpicorStatus is null 
			 And    CMU.SentToEpicorFlag       = 0
			 And    CMU.CreditMemoReversalFlag = 1
			 And    PU.FamilyCode <> 'DCN'
			) As USACreditReversalCount On USACreditReversalCount.RowNumber = CanadaCreditReversalCount.RowNumber
			
		Join	
		 (
		  select count(CM.CreditMemoIDSeq) as TotalCreditReversalCount
		  ,1 AS 'RowNumber'
		  from   INVOICES.dbo.CreditMemo CM With (nolock)
		  where  CM.CreditStatusCode = 'APPR'
		  And    CM.SentToEpicorStatus is null 
		  And    CM.SentToEpicorFlag       = 0
		  And    CM.CreditMemoReversalFlag = 1
		 ) As TotalCreditReversalCount On TotalCreditReversalCount.RowNumber = USACreditReversalCount.RowNumber


END
GO
