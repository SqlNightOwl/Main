SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_PushCreditReversalHeaderToEpicor @IPVC_InvoiceID = 'I0000000002',@IPVC_EpicorBatchCode=100

*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_PushCreditReversalHeaderToEpicor
-- Description     : This procedure select relevant info of Invoice Line Items to push to Epicor
-- Input Parameters: @IPVC_InvoiceID,@IPVC_EpicorBatchCode              
-- OUTPUT          : None.
--  
--                   
-- Code Example    : exec INVOICES.dbo.uspINVOICES_PushCreditMemoHeaderToEpicor 
--                         @IPVC_InvoiceID = 'I0000000002',@IPVC_EpicorBatchCode=100
-- Revision History:
-- Author          : Surya Kiran
-- 01/25/2010      : Stored Procedure Created.
-- 02/10/2011	   : Surya Kiran - Defect# 8783: Create the Epicor integration for Credit Reversals
--					 ApplyToInvoiceIDseq should be sent as blank to Epicor.
-- 05/26/2011	   : Surya Kondapalli Task# 335	 - Create the Epicor integration for Credit Reversals
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_PushCreditReversalHeaderToEpicor] (@IPVC_InvoiceID         varchar(50),
                                                               @IPVC_CreditMemoID      varchar(50),
                                                               @IPVC_EpicorBatchCode   varchar(50)
                                                              )
as
BEGIN
  set nocount on  
  -----------------------------------------------------------------
  --Final Select For Credit Memo Header  
  ----------------------------------------------------------------
  select @IPVC_EpicorBatchCode                     as EpicorBatchCode,
         CM.CreditMemoIDSeq                        as TransactionIDSeq, 
         ''				                           as ApplyToInvoiceIDSeq, 
         'R'                                       as TransactionType,
         convert(varchar(12),CM.CreatedDate,101)   as TransactionCreatedDate,
         convert(varchar(12),CM.ApprovedDate,101)  as DocumentDate,
         convert(varchar(12),I.InvoiceDueDate,101) as InvoiceDueDate, -- This is not applicable for credits in epicor
         I.EpicorCustomerCode                      as EpicorCustomerCode,
         case CM.CreditTypeCode
          when 'PARC' then 'PC'
          when 'FULC' then 'FC'
          when 'TAXC' then 'TC' 
         end                                       as TransactionSubType,
         I.InvoiceTerms                            as InvoiceTerms,
         CM.TotalNetCreditAmount                   as ILFChargeAmount,
         0                                         as AccessChargeAmount,
         0                                         as TransactionChargeAmount,
         CM.ShippingAndHandlingCreditAmount       as ShippingandHandlingAmount,
         CM.TaxAmount                             as TaxAmount, 
         I.BillToAccountName                      as BillToAccountName,
         I.BillToAddressLine1                     as BillToAddressLine1,
         I.BillToAddressLine2                     as BillToAddressLine2,
         I.BillToCity                             as BillToCity,
         I.BillToState                            as BillToState,
         I.BillToZip                              as BillToZipcode,
         I.BillToCountry                          as BillToCountry,
         I.BillToCountryCode                      as BillToCountryCode,
         I.ShipToAccountName                      as ShipToAccountName,
         I.ShipToAddressLine1                     as ShipToAddressLine1,
         I.ShipToAddressLine2                     as ShipToAddressLine2,
         I.ShipToCity                             as ShipToCity,
         I.ShipToState                            as ShipToState,
         I.ShipToZip                              as ShipToZipcode,
         I.ShipToCountry                          as ShipToCountry,
         I.ShipToCountryCode                      as ShipToCountryCode,
         CM.CreditMemoReversalFlag                as CreditMemoReversalFlag,
         CM.EpicorPostingCode                     as EpicorPostingCode,
         CM.TaxwareCompanyCode                    as TaxwareCompanyCode,
		 case	when P.Familycode = 'DCN' and ADR.CountryCode = 'CAN'   
				then 'CAD'  
				else 'USD' end					   as CurrencyCode
  from   INVOICES.dbo.CreditMemo CM with (nolock)  
  Inner Join
         Invoices.dbo.Invoice  I with (nolock)
	   On     CM.InvoiceIDSeq       = @IPVC_InvoiceID
  Inner Join Invoices.dbo.InvoiceItem II with (nolock)  
       On     II.InvoiceIDSeq  = I.InvoiceIDSeq  
  Inner Join Products.dbo.Product P with (nolock)  
       On     II.ProductCode = P.Code  
       And    II.PriceVersion= P.PriceVersion  
  Inner Join CUSTOMERS.DBO.ADDRESS ADR WITH (nolock)  
       On    ADR.CompanyIDSeq    = I.CompanyIDSeq  
       And      ADR.AddressTypeCode = I.BillToAddressTypeCode   
       And		(  
				   (ADR.AddressTypeCode = I.BillToAddressTypeCode And   
						ADR.AddressTypeCode Like 'PB%'                 And   
						coalesce(ADR.PropertyIDSeq,'') = coalesce(I.PropertyIDSeq,'')  
				   )  
				   Or  
				   (	ADR.AddressTypeCode = I.BillToAddressTypeCode And   
						ADR.AddressTypeCode Not Like 'PB%'    
				   )  
				 )  
  
  Where  CM.InvoiceIDSeq       = I.InvoiceIDSeq
  And    I.InvoiceIDSeq        = @IPVC_InvoiceID
  And    CM.CreditMemoIDSeq    = @IPVC_CreditMemoID
  And    CM.SentToEpicorStatus = 'EPICOR PUSH PENDING'  
  And    CM.SentToEpicorFlag   = 0 
  And    CM.CreditMemoReversalFlag = 1 --> This denotes it is Credit Reversal
  And    CM.CreditStatusCode   = 'APPR' 

END
GO
