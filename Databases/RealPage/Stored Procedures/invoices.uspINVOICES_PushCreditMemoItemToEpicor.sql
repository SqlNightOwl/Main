SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_PushCreditMemoItemToEpicor @IPVC_InvoiceID = 'I0901000009',
@IPVC_CreditMemoID ='R0902000010',@IPVC_EpicorBatchCode='ARB0016997'

*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_PushCreditMemoItemToEpicor
-- Description     : This procedure select relevant info of Invoice Line Items to push to Epicor
-- Input Parameters: @IPVC_InvoiceID,@IPVC_EpicorBatchCode              
-- OUTPUT          : None.
--  
--                   
-- Code Example    : exec INVOICES.dbo.uspINVOICES_PushCreditMemoItemToEpicor
-- Revision History:
-- Author          : SRS
-- 03/28/2007      : Stored Procedure Created.
-- 09/08/2009      : Shashi Bhushan		#6992 altered to select TaxableCountryCode column value
-- 04/27/2011	   : Surya Kondapalli	Task#388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_PushCreditMemoItemToEpicor] (@IPVC_InvoiceID         varchar(50),
                                                             @IPVC_CreditMemoID      varchar(50),
                                                             @IPVC_EpicorBatchCode   varchar(50)
                                                            )
as
BEGIN
  set nocount on
  -----------------------------------------------------------------  
  if exists (select top 1 1 from INVOICES.dbo.CreditMemo CM with (nolock)
             where CM.InvoiceIDSeq       = @IPVC_InvoiceID
             AND   CM.CreditMemoIDSeq    = @IPVC_CreditMemoID
             and   CM.EpicorBatchCode    = @IPVC_EpicorBatchCode
             and   CM.SentToEpicorStatus = 'EPICOR PUSH PENDING'             
             and   CM.SentToEpicorFlag   = 0  
             and   CM.CreditMemoReversalFlag = 0 --> This denotes it is CreditMemo
             and   CM.CreditStatusCode   = 'APPR' 
             )
  begin

-- Get Country Code to identify Currency Code
Declare @CountryCode Varchar(3) 

Select  Top 1 @CountryCode =AD.CountryCode 
From INVOICES.dbo.Invoice I With (nolock)  
Inner Join Invoices.dbo.InvoiceItem II with (nolock)  
      on     II.InvoiceIDSeq  = I.InvoiceIDSeq  
Inner Join CUSTOMERS.DBO.ADDRESS AD WITH (nolock)  
      On    AD.CompanyIDSeq    = I.CompanyIDSeq  
      And      AD.AddressTypeCode = I.BillToAddressTypeCode   
      And     
    (  
      (AD.AddressTypeCode = I.BillToAddressTypeCode And   
       AD.AddressTypeCode Like 'PB%'                 And   
       coalesce(AD.PropertyIDSeq,'') = coalesce(I.PropertyIDSeq,'')  
      )  
      Or  
      (AD.AddressTypeCode = I.BillToAddressTypeCode And   
       AD.AddressTypeCode Not Like 'PB%'    
      )  
     )  
Where  I.InvoiceIDSeq = @IPVC_InvoiceID

     select distinct
            @IPVC_EpicorBatchCode                       as EpicorBatchCode,            
            CMI.CreditMemoIDSeq                         as TransactionIDSeq,
            CMI.IDSeq                                   as TransactionItemIDSeq,
            CMI.InvoiceIDSeq                            as ApplyToInvoiceIDSeq,
            II.OrderItemIDSeq                           as OrderItemIDSeq,
            II.IDSeq                                    as ApplyToInvoiceItemIDSeq,
            'C'                                         as TransactionType, 
            P.DisplayName                               as ProductDisplayName,
            II.chargetypecode                           as chargetypecode,
            CMI.EffectiveQuantity                       as EffectiveQuantity,
            CMI.UnitCreditAmount                        as ChargeAmount,
            CMI.ExtCreditAmount                         as ExtChargeAmount,
            II.RevenueAccountCode                       as RevenueAccountCode,
            II.DeferredRevenueAccountCode               as DeferredRevenueAccountCode, 
            CMI.DiscountCreditAmount                    as DiscountAmount,            
            CMI.TaxAmount                               as TaxAmount, 
            CMI.NetCreditAmount                         as NetChargeAmount,
            -----------------------------------------------------------------         
            (Case when II.Measurecode = 'TRAN'
                    then convert(varchar(12),coalesce(II.TransactionDate,OI.ActivationStartDate),101)
              Else convert(varchar(12),OI.ActivationStartDate,101) 
             end)                                             as AccessStartDate, 
            (Case when II.Measurecode = 'TRAN'
                    then convert(varchar(12),coalesce(Dateadd(year,1,II.TransactionDate)-1,OI.ActivationEndDate),101)
              Else convert(varchar(12),OI.ActivationEndDate,101) 
             end)                                             as AccessEndDate,  
            -----------------------------------------------------------------
            II.RevenueRecognitionCode                   as RevenueRecognitionCode,
            II.ProductCode                              as ProductCode,
            II.RevenueTierCode                          as RevenueTierCode,
            -----------------------------------------------------------------
            convert(varchar(12),II.BillingPeriodFromDate,101) as BillingPeriodFromDate,
            convert(varchar(12),II.BillingPeriodToDate,101)   as BillingPeriodToDate,  
            -----------------------------------------------------------------  
            OILF.IDSeq                                  as ILFOrderItemIDSeq,
            II.InvoiceIDSeq                             as ApplyToInvoiceIDSeq,
            II.IDSeq                                    as ApplyToInvoiceItemIDSeq,
            ------------------------------------------------------------------
            CMI.CreditMemoReversalFlag                  as CreditMemoReversalFlag,
            ------------------------------------------------------------------
            P.Familycode                                as Familycode,
            II.TaxableState                             as TaxableState,
            II.TaxableCountryCode                       as TaxableCountryCode,
			case when P.Familycode = 'DCN' and @CountryCode = 'CAN' 
				 then 'CAD'
				 else 'USD'	
			end										    as CurrencyCode	
            -----------------------------------------------------------------
    from   INVOICES.dbo.InvoiceItem II with (nolock) 
    inner join ORDERS.dbo.ORDERITEM OI with (nolock)
    on    II.InvoiceIDSeq  = @IPVC_InvoiceID
    and   II.OrderIDSeq    = OI.OrderIDSeq
    and   II.OrderGroupIDSeq=OI.OrderGroupIDSeq 
    and   II.OrderItemIDSeq= OI.IDSeq
    and   II.ProductCode   = OI.ProductCode
    and   II.ChargeTypeCode= OI.ChargeTypeCode
    and   II.FrequencyCode = OI.FrequencyCode
    and   II.MeasureCode   = OI.MeasureCode 
    and   II.PriceVersion  = OI.PriceVersion 
    inner join  INVOICES.dbo.CreditMemoItem CMI with (nolock)      
    on    CMI.InvoiceIDSeq    = @IPVC_InvoiceID
    and   CMI.CreditMemoIDSeq = @IPVC_CreditMemoID
    and   II.InvoiceIDSeq     = CMI.InvoiceIDSeq 
    and   II.InvoiceIDSeq     = @IPVC_InvoiceID
    and   II.InvoiceGroupIDSeq= CMI.InvoiceGroupIDSeq
    and   II.IDSeq            = CMI.InvoiceItemIDSeq
    inner  Join
           PRODUCTS.dbo.Product P with (nolock)
    on     II.InvoiceIDSeq = @IPVC_InvoiceID
    and    II.Productcode  = P.Code
    and    II.PriceVersion = P.PriceVersion
    and    OI.ProductCode  = P.Code
    and    OI.PriceVersion = P.PriceVersion
    left outer join ORDERS.dbo.ORDERITEM OILF with (nolock)
    on    II.InvoiceIDSeq     = @IPVC_InvoiceID
    and   CMI.InvoiceIDSeq    = @IPVC_InvoiceID
    and   II.OrderIDSeq       = OILF.OrderIDSeq    
    and   II.OrderGroupIDSeq  = OILF.OrderGroupIDSeq     
    and   II.ProductCode      = OILF.ProductCode
    and   OILF.ChargeTypeCode = 'ILF' 
    /* 
    inner  Join
           PRODUCTS.dbo.Charge C with (nolock)
    on     C.ProductCode   = P.Code
    and    C.PriceVersion  = P.PriceVersion
    and    C.ProductCode   = II.ProductCode
    and    C.PriceVersion  = II.PriceVersion
    and    C.ChargeTypecode= II.ChargeTypeCode
    and    C.MeasureCode   = II.MeasureCode
    and    C.FrequencyCode = II.FrequencyCode 
    and    C.ProductCode   = OI.ProductCode
    and    C.PriceVersion  = OI.PriceVersion
    and    C.ChargeTypecode= OI.ChargeTypeCode
    and    C.MeasureCode   = OI.MeasureCode
    and    C.FrequencyCode = OI.FrequencyCode  
    and    C.PriceVersion  = OI.PriceVersion      
    */
  end
END
GO
