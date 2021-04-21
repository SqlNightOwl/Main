SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_ValidateInvoicesForEpicorPush
*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_ValidateInvoicesForEpicorPush
-- Description     : This procedure Validate if any invoices qualify for Epicor Push to get a 
--                      newly generated BatchCode from Epicor
-- Input Parameters:
-- OUTPUT          : 1 or 0.
--  
--                   
-- Code Example    : exec INVOICES.dbo.uspINVOICES_ValidateInvoicesForEpicorPush
-- Revision History:
-- Author          : SRS
-- 03/28/2007      : Stored Procedure Created.
-- 04/26/2011	   : Surya Kondapalli - Task# 388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_ValidateInvoicesForEpicorPush] 
AS
BEGIN
  Set NoCount On 
  ----------------------------------------------------------------------------
    Select	TotalInvoiceCount = CASE WHEN USAInvoiceCount = 0 AND CanadaInvoiceCount = 0
									 THEN 0 ELSE TotalInvoiceCount END
		 ,	USAInvoiceCount
		 ,	CanadaInvoiceCount
   From 
			(
			 Select Count(Distinct IC.InvoiceIdseq) As  CanadaInvoiceCount
			,1 AS 'RowNumber'
			 From INVOICES.dbo.Invoice IC With (nolock)
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
			 Where  IC.SentToEpicorStatus Is Null 
			 And    IC.PrintFlag = 1
			 And    IC.SentToEpicorFlag = 0
			 And    ADC.CountryCode = 'CAN'
			 And    PC.FamilyCode = 'DCN'
			 ) As CanadaInvoiceCount
	
		  Join
		   (
			  Select Count(Distinct IU.InvoiceIdseq) As USAInvoiceCount
			 ,1 AS 'RowNumber'
			 From INVOICES.dbo.Invoice IU With (nolock)
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
			 Where  IU.SentToEpicorStatus IS NULL 
			 And    IU.PrintFlag = 1
			 And    IU.SentToEpicorFlag = 0
			 And    PU.FamilyCode <> 'DCN'
			) As USAInvoiceCount On USAInvoiceCount.RowNumber = CanadaInvoiceCount.RowNumber
			
		Join	
		 (
			Select Count(1) As   TotalInvoiceCount 
		    ,1 AS 'RowNumber'
			 From INVOICES.dbo.Invoice I With (nolock)  
			 Where I.SentToEpicorStatus IS NULL 
			 And    I.PrintFlag = 1
			 And    I.SentToEpicorFlag = 0
		 ) As TotalInvoiceCount On TotalInvoiceCount.RowNumber = USAInvoiceCount.RowNumber
		          
END 
GO
