SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_CheckInvoiceCountry
*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_CheckInvoiceCountry
-- Description     : This procedure returns the country of representation for the Invoice
-- Input Parameters:
-- OUTPUT          : CountryCode (USA Or CAN).
--  
--                   
-- Code Example    : exec INVOICES.dbo.uspINVOICES_CheckInvoiceCountry 'I1011010847'
-- Revision History:
-- Author          : Surya Kondapalli
-- 05/10/2011      : Stored Procedure Created.
-- 05/10/2011	   : Surya Kondapalli - Task# 388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_CheckInvoiceCountry]
(
	@IPVC_InvoiceID   VARCHAR(50) =''	
)
AS
BEGIN
  Set NoCount On 
  ----------------------------------------------------------------------------
    		Select Distinct Case When ADC.CountryCode = 'CAN' And PC.FamilyCode = 'DCN'
								 Then ADC.CountryCode 
						    Else 'USA' End As CountryCode
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
			 Where IC.InvoiceIDSeq = @IPVC_InvoiceID
			 		          
END 
GO
