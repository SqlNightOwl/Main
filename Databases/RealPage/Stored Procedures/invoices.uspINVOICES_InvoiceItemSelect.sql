SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_InvoiceItemSelect
-- Description     : This procedure gets the list of Credit Invoice Items for the list of ID's passed.
-- Input Parameters: 1. @IPVC_InvoiceIDSeq   as varchar(50)
--                   
-- OUTPUT          : 3 RecordSets 
--
--                   
-- Code Example    : 
/*
Exec Invoices.dbo.uspINVOICES_InvoiceItemSelect 'I1109030451','FullCredit'
Exec Invoices.dbo.uspINVOICES_InvoiceItemSelect 'I1109030451','FullTax'
Exec Invoices.dbo.uspINVOICES_InvoiceItemSelect 'I1109030451','PartialCredit'
*/
-- Revision History:
-- Revision History:
-- Author          : SRS : Task # 918: 
-- 09/28/2011      : 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_InvoiceItemSelect] (@IPVC_InvoiceIDSeq    varchar(50),     --> Mandatory : This is the InvoiceIDSeq for which FullCredit or TaxCredit or PartialCredit are intiated by User.
                                                        @IPVC_CreditType      varchar(50)      --> Mandatory : This is the Credit Type. 
                                                                                               --  For this proc, only FullCredit or (TaxCredit or FullTax) or PartialCredit are acceptable values.
                                                       )
as
BEGIN ----> Main BEGIN
  set nocount on;
  -----------------------------------------------------------------------------------------------------------------
  --Local Variables declaration
  Create table #LT_InvoiceCreditSummary        (sortseq                     int not null identity(1,1) Primary Key,
                                                InvoiceIDSeq                varchar(50),
                                                InvoiceGroupIDSeq           bigint,
                                                InvoiceItemIDSeq            bigint,
                                                CustomBundleNameEnabledFlag bit, --> Looks like UI is expecting a Boolean instead of int.
                                                OrderIDSeq                  varchar(50),
                                                OrderGroupIDSeq             bigint,
                                                RenewalCount                bigint,
                                                BillingPeriodFromDate       datetime,
                                                BillingPeriodToDate         datetime,
                                                ReportingTypeCode           varchar(10),
                                                ProductCode                 varchar(50),
                                                ChargeTypeCode              varchar(10),
                                                ProductName                 varchar(500),
                                                -----------------------
                                                NetIIChargeAmount                            money,
                                                NetIITaxAmount                               money,
                                                IITaxPercent                                 numeric(18,5),
                                                NetIIShippingAndHandlingAmount               money,
                                                ----------------------
                                                NetPreviousCreditAmount                      money,
                                                NetPreviousCreditTaxAmount                   money,
                                                NetPreviousShippingAndHandlingCreditAmount   money,
                                                ----------------------
                                                NetAvailableCreditAmount                     money,
                                                NetAvailableCreditTaxAmount                  money,
                                                NetAvailableShippingAndHandlingCreditAmount  money,
                                                -----------------------
                                                SortOrder                  int    
                                               );

  -----------------------------------------------------------------------------------------------------------------
  ;With CTE_PreviousApprovedCMI (InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,CustomBundleNameEnabledFlag,
                                 NetPreviousCreditAmount,NetPreviousCreditTaxAmount,NetPreviousShippingAndHandlingCreditAmount
                                )
   as (select CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag,
              Sum(CMI.NetCreditAmount)                 as NetPreviousCreditAmount,
              Sum(CMI.TaxAmount)                       as NetPreviousCreditTaxAmount,
              sum(CMI.ShippingAndHandlingCreditAmount) as NetPreviousShippingAndHandlingCreditAmount
       from   INVOICES.dbo.CreditMemo     CM with (nolock)
       inner Join
              INVOICES.dbo.CreditMemoItem CMI with (nolock)
       on     CM.CreditMemoIDSeq = CMI.CreditMemoIDSeq
       and    CM.InvoiceIDSeq    = CMI.InvoiceIDSeq
       and    CM.InvoiceIDSeq    = @IPVC_InvoiceIDSeq
       and    CM.CreditStatusCode= 'APPR'
       group by CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag
      )   
  -------------------
  ,CTE_ExistingInvoiceItem (InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,CustomBundleNameEnabledFlag,
                            OrderIDSeq,OrderGroupIDSeq,RenewalCount,
                            BillingPeriodFromDate,BillingPeriodToDate,ReportingTypeCode,
                            ProductCode,ChargeTypeCode,ProductName,
                            NetIIChargeAmount,NetIITaxAmount,IITaxPercent,NetIIShippingAndHandlingAmount,
                            NetPreviousCreditAmount,NetPreviousCreditTaxAmount,NetPreviousShippingAndHandlingCreditAmount,
                            NetAvailableCreditAmount,NetAvailableCreditTaxAmount,NetAvailableShippingAndHandlingCreditAmount,
                            SortOrder
                           )
  as (Select
          II.InvoiceIDSeq                                            as InvoiceIDSeq
         ,II.InvoiceGroupIDSeq                                       as InvoiceGroupIDSeq
         ,(case when (convert(int,IG.CustomBundleNameEnabledFlag) = 1)
                  then -999
                else II.IDSeq
          end)                                                       as InvoiceItemIDSeq
         ,convert(int,IG.CustomBundleNameEnabledFlag)                as CustomBundleNameEnabledFlag
         ,II.OrderIDSeq                                              as OrderIDSeq
         ,II.OrderGroupIDSeq                                         as OrderGroupIDSeq
         ,II.OrderItemRenewalCount                                   as OrderItemRenewalCount
         ,II.BillingPeriodFromDate                                   as BillingPeriodFromDate
         ,II.BillingPeriodToDate                                     as BillingPeriodToDate
         ,II.ReportingTypeCode                                       as ReportingTypeCode
         ------------------------------------
         ,Max((case when (convert(int,IG.CustomBundleNameEnabledFlag) = 1)
                      then NULL
                    else II.ProductCode  
               end)
             )                                                       as ProductCode
         ----------------
         ,II.ChargeTypeCode                                          as ChargeTypeCode
         ----------------
         ,Max((case when (II.MeasureCode = 'TRAN' and
                          II.OrderItemTransactionIDSeq is not null
                         )
                      then II.TransactionItemName
                    when (convert(int,IG.CustomBundleNameEnabledFlag) = 1)
                      then IG.Name
                    else  
                       P.DisplayName
               end)
             )                                                       as ProductName
         ------------------------------------
         ,Sum(II.NetChargeAmount)                                    as NetIIChargeAmount
         ,Sum(II.TaxAmount)                                          as NetIITaxAmount
         ,Max(II.TaxPercent)                                         as IITaxPercent
         ,Sum(II.ShippingAndHandlingAmount)                          as NetIIShippingAndHandlingAmount
         ------------------------------------
         ,Sum(coalesce(CTE_PACMI.NetPreviousCreditAmount,0))                                 as NetPreviousCreditAmount
         ,Sum(coalesce(CTE_PACMI.NetPreviousCreditTaxAmount,0))                              as NetPreviousCreditTaxAmount
         ,Sum(coalesce(CTE_PACMI.NetPreviousShippingAndHandlingCreditAmount,0))              as NetPreviousShippingAndHandlingCreditAmount
         ------------------------------------
         ,(Sum(II.NetChargeAmount) - Sum(coalesce(CTE_PACMI.NetPreviousCreditAmount,0)))         as NetAvailableCreditAmount
         ,(Sum(II.TaxAmount) - Sum(coalesce(CTE_PACMI.NetPreviousCreditTaxAmount,0)))            as NetAvailableCreditTaxAmount
         ,(Sum(II.ShippingAndHandlingAmount) - Sum(coalesce(CTE_PACMI.NetPreviousShippingAndHandlingCreditAmount,0))) 
                                                                                                 as NetAvailableShippingAndHandlingCreditAmount
         ------------------------------------
         ,(case when II.ReportingTypeCode = 'ILFF' then 1
                when II.ReportingTypeCode = 'ACSF' then 2
                when II.ReportingTypeCode = 'ANCF' then 3
           else 4
          end)                                                                                   as SortOrder
      from    Invoices.dbo.InvoiceItem  II with (NOLOCK)
      inner join
              Products.dbo.Product      P  with (nolock)
      on      II.ProductCode       = P.Code
      and     II.Priceversion      = P.Priceversion
      and     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
      inner join 
              Invoices.dbo.InvoiceGroup IG with (NOLOCK)
      ON      IG.InvoiceIDSeq      = II.InvoiceIDSeq
      and     IG.IDSeq             = II.InvoiceGroupIDSeq
      and     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
      and     IG.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
      and     IG.orderidseq        = II.orderidseq  
      and     IG.ordergroupidseq   = II.ordergroupidseq
      left outer Join
              CTE_PreviousApprovedCMI  CTE_PACMI
      on     II.InvoiceIDSeq         = CTE_PACMI.InvoiceIDSeq
      and    IG.InvoiceIDSeq         = CTE_PACMI.InvoiceIDSeq
      and    IG.IDSeq                = CTE_PACMI.InvoiceGroupIDSeq
      and    II.InvoiceGroupIDSeq    = CTE_PACMI.InvoiceGroupIDSeq
      and    II.idseq                = CTE_PACMI.Invoiceitemidseq
      and    IG.CustomBundleNameEnabledFlag = CTE_PACMI.CustomBundleNameEnabledFlag
      and    CTE_PACMI.InvoiceIDSeq  = @IPVC_InvoiceIDSeq   
      where   II.InvoiceIDSeq        = @IPVC_InvoiceIDSeq
      and     IG.InvoiceIDSeq        = @IPVC_InvoiceIDSeq
      group by II.InvoiceIDSeq,II.InvoiceGroupIDSeq,
               (case when (convert(int,IG.CustomBundleNameEnabledFlag) = 1)
                      then -999
                    else II.IDSeq
              end)
             ,convert(int,IG.CustomBundleNameEnabledFlag)
             ,II.OrderIDSeq
             ,II.OrderGroupIDSeq
             ,II.OrderItemRenewalCount
             ,II.BillingPeriodFromDate
             ,II.BillingPeriodToDate
             ,II.ReportingTypeCode
             ,II.ChargeTypeCode
  )
  --------------------------------------------------------------------------------
  insert into #LT_InvoiceCreditSummary(InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,CustomBundleNameEnabledFlag,
                                       OrderIDSeq,OrderGroupIDSeq,RenewalCount,
                                       BillingPeriodFromDate,BillingPeriodToDate,ReportingTypeCode,
                                       ProductCode,ChargeTypeCode,ProductName,
                                       NetIIChargeAmount,NetIITaxAmount,IITaxPercent,NetIIShippingAndHandlingAmount,
                                       NetPreviousCreditAmount,NetPreviousCreditTaxAmount,NetPreviousShippingAndHandlingCreditAmount,
                                       NetAvailableCreditAmount,NetAvailableCreditTaxAmount,NetAvailableShippingAndHandlingCreditAmount,
                                       SortOrder
                                      )
  select  CTEExistII.InvoiceIDSeq                              as InvoiceIDSeq
         ,CTEExistII.InvoiceGroupIDSeq                         as InvoiceGroupIDSeq
         ,CTEExistII.InvoiceItemIDSeq                          as InvoiceItemIDSeq
         ,CTEExistII.CustomBundleNameEnabledFlag               as CustomBundleNameEnabledFlag
         ,CTEExistII.OrderIDSeq                                as OrderIDSeq
         ,CTEExistII.OrderGroupIDSeq                           as OrderGroupIDSeq
         ,CTEExistII.RenewalCount                              as RenewalCount
         ,CTEExistII.BillingPeriodFromDate                     as BillingPeriodFromDate            
         ,CTEExistII.BillingPeriodToDate                       as BillingPeriodToDate
         ,CTEExistII.ReportingTypeCode                         as ReportingTypeCode
         ,CTEExistII.ProductCode                               as ProductCode
         ,CTEExistII.ChargeTypeCode                            as ChargeTypeCode
         ,CTEExistII.ProductName                               as ProductName
         --------------------------
         ,CTEExistII.NetIIChargeAmount                         as NetIIChargeAmount
         ,CTEExistII.NetIITaxAmount                            as NetIITaxAmount
         ,CTEExistII.IITaxPercent                              as IITaxPercent
         ,CTEExistII.NetIIShippingAndHandlingAmount            as NetIIShippingAndHandlingAmount
         --------------------------
         ,CTEExistII.NetPreviousCreditAmount                     as NetPreviousCreditAmount
         ,CTEExistII.NetPreviousCreditTaxAmount                  as NetPreviousCreditTaxAmount
         ,CTEExistII.NetPreviousShippingAndHandlingCreditAmount  as NetPreviousShippingAndHandlingCreditAmount
         --------------------------
         ,CTEExistII.NetAvailableCreditAmount                    as NetAvailableCreditAmount
         ,CTEExistII.NetAvailableCreditTaxAmount                 as NetAvailableCreditTaxAmount
         ,CTEExistII.NetAvailableShippingAndHandlingCreditAmount as NetAvailableShippingAndHandlingCreditAmount
         --------------------------
         ,CTEExistII.SortOrder
  from  CTE_ExistingInvoiceItem  CTEExistII
  -------------------------------------------------------------------------------------------
  ---Now comes the crazy 3 Select(s) which needs to be cleaned up when UI is ready Down the road.
  -------------------------------------------------------------------------------------------
  ---First Resultset 1:
 --------------------------------------------------------------------------------
  Select S.InvoiceItemIDSeq                                     as IDSeq 
        ,S.ProductCode                                          as ProductCode
        ,S.ProductName                                          as ProductName
        ,S.ChargeTypeCode                                       as ChargeType
        ,(case when (@IPVC_CreditType='FullCredit')
                then S.NetAvailableCreditAmount
               else 0.00
          end)                                                  as CreditAmount
        ,S.NetIIChargeAmount                                    as ChargeAmount
        ,(case when (@IPVC_CreditType='FullCredit')
                then S.NetAvailableCreditTaxAmount
               when (@IPVC_CreditType='TaxCredit' or @IPVC_CreditType = 'FullTax')
                then S.NetAvailableCreditTaxAmount
               else 0.00
          end)                                                  as TaxAmount
        ,S.IITaxPercent                                         as TaxPercent
        ,(case when (@IPVC_CreditType='FullCredit')
                then S.NetAvailableCreditAmount
               else 0.00
         end) +
        (case when (@IPVC_CreditType='FullCredit')
                then S.NetAvailableCreditTaxAmount
               when (@IPVC_CreditType='TaxCredit' or @IPVC_CreditType = 'FullTax')
                then S.NetAvailableCreditTaxAmount
               else 0.00
         end)                                                   as Total
        ,S.NetIIChargeAmount                                    as NetPrice
        ,S.NetPreviousCreditAmount                              as TotalCreditAmount
        ,S.NetPreviousCreditTaxAmount                           as TotalTaxAmount
        ,S.NetAvailableCreditAmount                             as AvailableCredit
        ,S.InvoiceGroupIDSeq                                    as InvoiceGroupIDSeq
        ,convert(varchar(50),S.BillingPeriodFromDate,101)
          + ' - ' +
         convert(varchar(50),S.BillingPeriodToDate,101)         as BillingPeriod
        ,S.RenewalCount                                         as RenewalCount
        ,S.InvoiceIDSeq                                         as InvoiceIDSeq
        ,S.OrderIDSeq                                           as OrderIDSeq
        ,S.OrderGroupIDSeq                                      as OrderGroupIDSeq
        ,S.CustomBundleNameEnabledFlag                          as CustomBundleNameEnabledFlag
        ,''                                                     as CreditMemoItemIDSeq
        ,S.InvoiceItemIDSeq                                     as InvoiceItemIDSeq
        ,S.ReportingTypeCode                                    as ReportingTypeCode
        ,S.NetAvailableCreditTaxAmount                          as ActualTaxAmount
        ,S.NetAvailableCreditTaxAmount                          as InvoiceTaxAmount
        ,convert(varchar(50),S.BillingPeriodFromDate,101)       as BillingPeriodFromDate
        ,convert(varchar(50),S.BillingPeriodToDate,101)         as BillingPeriodToDate
        ,(case when (@IPVC_CreditType='FullCredit')
                    then S.NetAvailableShippingAndHandlingCreditAmount
               when (@IPVC_CreditType='TaxCredit' or @IPVC_CreditType = 'FullTax')
                    then 0.00
               when (@IPVC_CreditType='PartialCredit') 
                    then 0.00
               else S.NetAvailableShippingAndHandlingCreditAmount
         end)                                                   as ShippingAndHandlingAmount
        ,S.NetAvailableShippingAndHandlingCreditAmount          as AvailShippingAndHandlingAmount
        ,S.SortOrder                                            as SortOrder
    from  #LT_InvoiceCreditSummary S with (nolock)
    where (
            ------------------------------------------
            (
             ((S.NetAvailableCreditAmount > 0) OR (S.NetAvailableCreditTaxAmount > 0) OR (S.NetAvailableShippingAndHandlingCreditAmount > 0))
                AND
             ((@IPVC_CreditType='FullCredit') OR (@IPVC_CreditType='PartialCredit'))  
            )
            ------------------------------------------
                OR
           ( 
             ((S.NetAvailableCreditTaxAmount > 0))
               AND
             ((@IPVC_CreditType='FullTax'))  
            )
            ------------------------------------------
          )
    order by S.ProductName ASC,S.SortOrder ASC,S.BillingPeriodFromDate ASC;
  --------------------------------------------------------------------------------
  ---Second Resultset 2: (I think this is for Total Row)
  --------------------------------------------------------------------------------
  Select 
        sum((case when (@IPVC_CreditType='FullCredit')
                then S.NetAvailableCreditAmount
               when (@IPVC_CreditType='TaxCredit' or @IPVC_CreditType = 'FullTax')
                then 0.00
               when (@IPVC_CreditType='PartialCredit') 
                then 0.00
               else S.NetAvailableCreditAmount
             end)
            )                                                  as TotalCredit
       ,sum((case when (@IPVC_CreditType='FullCredit')
                then S.NetAvailableCreditTaxAmount
               when (@IPVC_CreditType='TaxCredit' or @IPVC_CreditType = 'FullTax')
                then S.NetAvailableCreditTaxAmount
               when (@IPVC_CreditType='PartialCredit') 
                then 0.00
               else S.NetAvailableCreditTaxAmount
             end)
            )                                                  as TotalTax
       ,Sum((case when (@IPVC_CreditType='FullCredit')
                    then S.NetAvailableShippingAndHandlingCreditAmount
                  when (@IPVC_CreditType='TaxCredit' or @IPVC_CreditType = 'FullTax')
                    then 0.00
                  when (@IPVC_CreditType='PartialCredit') 
                    then 0.00
                  else S.NetAvailableShippingAndHandlingCreditAmount
             end)
            )                                                  as SnHTotal
       ,sum((case when (@IPVC_CreditType='FullCredit')
                then S.NetAvailableCreditAmount
               when (@IPVC_CreditType='TaxCredit' or @IPVC_CreditType = 'FullTax')
                then 0.00
               when (@IPVC_CreditType='PartialCredit') 
                then 0.00
               else S.NetAvailableCreditAmount
             end)
            ) +
        Sum((case when (@IPVC_CreditType='FullCredit')
                    then S.NetAvailableShippingAndHandlingCreditAmount
                  when (@IPVC_CreditType='TaxCredit' or @IPVC_CreditType = 'FullTax')
                    then 0.00
                  when (@IPVC_CreditType='PartialCredit') 
                    then 0.00
                  else S.NetAvailableShippingAndHandlingCreditAmount
             end)
            ) +
        sum((case when (@IPVC_CreditType='FullCredit')
                then S.NetAvailableCreditTaxAmount
               when (@IPVC_CreditType='TaxCredit' or @IPVC_CreditType = 'FullTax')
                then S.NetAvailableCreditTaxAmount
               when (@IPVC_CreditType='PartialCredit') 
                then 0.00
               else S.NetAvailableCreditTaxAmount
             end)
            )                                                 as NetTotal
  from #LT_InvoiceCreditSummary S with (nolock)
  where (
            ------------------------------------------
            (
             ((S.NetAvailableCreditAmount > 0) OR (S.NetAvailableCreditTaxAmount > 0) OR (S.NetAvailableShippingAndHandlingCreditAmount > 0))
                AND
             ((@IPVC_CreditType='FullCredit') OR (@IPVC_CreditType='PartialCredit'))  
            )
            ------------------------------------------
                OR
           ( 
             ((S.NetAvailableCreditTaxAmount > 0))
               AND
             ((@IPVC_CreditType='TaxCredit') OR (@IPVC_CreditType='FullTax')) 
            )
            ------------------------------------------
          );

  --Third Resultset : 3
  select Top 1
         convert(varchar(50),I.InvoiceDate,101) as InvoiceDate,
         I.EpicorPostingCode                    as EpicorPostingCode,
         I.TaxwareCompanyCode                   as TaxwareCompanyCode
 from  Invoices.dbo.Invoice I with (nolock)
 where I.InvoiceIDSeq = @IPVC_InvoiceIDSeq;
 --------------------------------------------------------------------------------
END ----> Main END
GO
