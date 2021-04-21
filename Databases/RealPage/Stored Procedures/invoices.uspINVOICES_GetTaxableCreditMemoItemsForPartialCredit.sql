SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_GetTaxableCreditMemoItemsForPartialCredit
-- Description     : This procedure gets the invoices that haven't been printed
--Exec INVOICES.dbo.uspINVOICES_GetTaxableCreditMemoItemsForPartialCredit @IPVC_CreditMemoID = 'R1108000171'
--Exec INVOICES.dbo.uspINVOICES_GetTaxableCreditMemoItemsForPartialCredit @IPVC_CreditMemoID = 'R1108000178' 


-- Revision History:
-- Author          : DC
-- 4/11/2007       : Stored Procedure Created.
-- 03/24/2008	   : Naval Kishore Modified to get CountryCode
-- 02/22/2010      : Naval Kishore Modified to add TaxwareCompanyCode.
-- 06/15/2011      : TFS 725 CalculateTaxFlag Enhancement.
-- 08/09/2011	   : Surya Kondapalli - Task # 918: Issue with the Credit Memo tab when full tax credit has been applied
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetTaxableCreditMemoItemsForPartialCredit] (@IPVC_CreditMemoID  varchar(50)
                                                                               )
AS
BEGIN 
  set nocount on;
  declare @LVC_InvoiceIDSeq       varchar(50);  
  ----------------------------------------------------------
  --If Credit memo  is not Partial Credit then Return
  ----------------------------------------------------------
  if (select Top 1 CreditTypeCode 
      from   INVOICES.dbo.CreditMemo with (nolock)
      where  CreditMemoIDSeq = @IPVC_CreditMemoID
     ) <> 'PARC'
  begin
    RETURN;
  end
  ----------------------------------------------------------
  select Top 1 @LVC_InvoiceIDSeq = InvoiceIDSeq 
  from   INVOICES.dbo.CreditMemo with (nolock)
  where  CreditMemoIDSeq = @IPVC_CreditMemoID;
  ----------------------------------------------------------
  ;With CTE_PreviousApprovedCMI (InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,CustomBundleNameEnabledFlag,
                                 NetCreditAmount,NetCreditTaxAmount
                                )
        as (select CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag,
                   Sum(CMI.NetCreditAmount) as NetCreditAmount,
                   Sum(CMI.TaxAmount)       as NetCreditTaxAmount
            from   INVOICES.dbo.CreditMemo     CM with (nolock)
            inner Join
                   INVOICES.dbo.CreditMemoItem CMI with (nolock)
            on     CM.CreditMemoIDSeq = CMI.CreditMemoIDSeq
            and    CM.InvoiceIDSeq    = CMI.InvoiceIDSeq
            and    CM.InvoiceIDSeq    = @LVC_InvoiceIDSeq
            and    CM.CreditStatusCode= 'APPR'
            group by CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag
           )
  -----------------------------
  SELECT II.TaxableAddressLine1                                                        as AddressLine1,
         II.TaxableAddressLine2                                                        as AddressLine2,
         II.TaxableCity                                                                as City,
         II.TaxableState                                                               as State,
         II.TaxableZip                                                                 as Zip,
         II.TaxableCountryCode                                                         as CountryCode,
         I.AccountIDSeq                                                                as CustomerNumber,
         ------------------------
         CI.IDSeq                                                                      as CreditMemoItemID,
         CI.CreditMemoIDSeq                                                            as CreditMemoID,
         CI.InvoiceIDSeq                                                               as InvoiceID,
         II.TaxWareCode                                                                as TaxWareCode,         
         convert(nvarchar,II.CreatedDate,101)                                          as CreatedDate,
         CI.ShippingAndHandlingCreditAmount				               as FreightCreditAmount,
         convert(nvarchar,II.CreatedDate,101)                                          as CreatedDate,
         (Case when ( 
                      (II.TaxAmount)
                         -
                      (coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    ) > 0
               then CI.NetCreditAmount
         else 0.00
         end)									       as NetCreditAmount,
         II.TaxableCounty                                                              as Taxablecounty,
         II.TaxableAddressTypeCode                                                     as TaxableAddressTypeCode,
         II.TaxAmount                                                                  as InvoiceTaxAmount,
         I.TaxwareCompanyCode                                                          as TaxwareCompanyCode,
         II.TaxableCountryCode                                                         as TaxableCountryCode,
         Coalesce(TC.CalculateTaxFlag,0)                                               as CalculateTaxFlag
         ------------------------
  FROM  Invoices.dbo.Invoice I with (nolock)
  INNER JOIN
        Invoices.dbo.InvoiceItem II with (nolock)
  ON    II.Invoiceidseq  = I.InvoiceIdSeq  
  and   I.InvoiceIDSeq   = @LVC_InvoiceIDSeq
  and   II.InvoiceIDSeq  = @LVC_InvoiceIDSeq
  inner Join
        Invoices.dbo.CreditMemoItem CI with (nolock)
  on    CI.InvoiceIDSeq      = II.InvoiceIDSeq
  and   CI.InvoiceGroupIDSeq = II.InvoiceGroupIDSeq
  and   CI.Invoiceitemidseq  = II.idseq
  and   CI.InvoiceIDSeq      = I.InvoiceIDSeq
  and   CI.CreditMemoIDSeq   = @IPVC_CreditMemoID    
  and   CI.InvoiceIDseq      = @LVC_InvoiceIDSeq
  and   I.InvoiceIDSeq       = @LVC_InvoiceIDSeq
  and   II.InvoiceIDSeq      = @LVC_InvoiceIDSeq
  left outer Join
        CTE_PreviousApprovedCMI  CTE_PACMI
  on    CI.InvoiceIDSeq      = CTE_PACMI.InvoiceIDSeq
  and   II.InvoiceIDSeq      = CTE_PACMI.InvoiceIDSeq
  and   CI.InvoiceGroupIDSeq = CTE_PACMI.InvoiceGroupIDSeq
  and   II.InvoiceGroupIDSeq = CTE_PACMI.InvoiceGroupIDSeq
  and   CI.Invoiceitemidseq  = CTE_PACMI.Invoiceitemidseq
  and   II.idseq             = CTE_PACMI.Invoiceitemidseq
  and   CTE_PACMI.InvoiceIDSeq = @LVC_InvoiceIDSeq
  LEFT OUTER JOIN
        PRODUCTS.dbo.TaxableCountry TC with (nolock)
  ON    I.TaxwareCompanyCode   = TC.TaxwareCompanyCode
  and   II.TaxableCountryCode  = TC.TaxableCountryCode       
  WHERE CI.CreditMemoIDSeq     = @IPVC_CreditMemoID    
  and   CI.InvoiceIDseq        = @LVC_InvoiceIDSeq
  and   I.InvoiceIDSeq         = @LVC_InvoiceIDSeq
  and   II.InvoiceIDSeq        = @LVC_InvoiceIDSeq
END
GO
