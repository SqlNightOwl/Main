SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : Invoices  
-- Procedure Name  : [uspCredits_SyncCreditTaxAmount]  
-- Description     : This procedure Syncs Credit TaxAmount in creditmemoitem table
-- Code Example    : Exec Invoices.dbo.[uspCredits_SyncCreditTaxAmount] @IPVC_CreditMemoIDSeq = 'R0907000501' 
--                     
-- Revision History:  
-- Author          : Shashi Bhushan
-- 07/20/2009      : Stored Procedure Created. 
-- 09/26/2011      : SRS TFS 918 
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspCredits_SyncCreditTaxAmount] (@IPVC_CreditMemoIDSeq   varchar(50)
                                                        )  
AS  
BEGIN
  set nocount on;
  select @IPVC_CreditMemoIDSeq = coalesce(nullif(ltrim(rtrim(@IPVC_CreditMemoIDSeq)),''),'ABCDEFHIJK');
  -------------------------------------------------------
  ---If CreditMemoID not exists in the system, Just Exit
  -------------------------------------------------------
  if not exists (select Top 1 1
                 from   Invoices.dbo.CreditMemo CM with (nolock)
                 where  CM.CreditMemoIDSeq = @IPVC_CreditMemoIDSeq
                 )
  begin
    return;
  end
  --------------------------------------------------------
  declare @LVC_InvoiceID varchar(50)
  --------------------------------------------------------
  select Top 1 @LVC_InvoiceID = CM.InvoiceIDSeq
  from   INVOICES.dbo.CreditMemo CM with (nolock)
  where  CM.CreditMemoIDSeq   = @IPVC_CreditMemoIDSeq;
  -------------------------------------------------------- 
  ;with CMI_CTE(InvoiceIDSeq,CreditMemoIDSeq,TransactionCreditAmount,ILFCreditAmount,AccessCreditAmount,ShippingAndHandlingCreditAmount,TaxAmount)
   as (select CMI.InvoiceIDSeq                                                                                            as InvoiceIDSeq,
              CMI.CreditMemoIDSeq                                                                                         as CreditMemoIDSeq,
            sum((case when (X.Measurecode    = 'TRAN') then (CMI.NetCreditAmount) else 0 end))                            as TransactionCreditAmount,
            sum((case when (X.ChargeTypecode = 'ILF' and X.Measurecode <>'TRAN')  then (CMI.NetCreditAmount) else 0 end)) as ILFCreditAmount,
            sum((case when (X.ChargeTypecode = 'ACS' and X.Measurecode <>'TRAN')  then (CMI.NetCreditAmount) else 0 end)) as AccessCreditAmount,          
            sum(CMI.ShippingAndHandlingCreditAmount)                                                                      as ShippingAndHandlingCreditAmount,
            sum(CMI.TaxAmount)                                                                                            as TaxAmount          
            from   INVOICES.dbo.CreditMemoItem CMI with (nolock)
            inner join
                   INVOICES.dbo.InvoiceItem    X with (nolock)
            on     X.InvoiceIDSeq   = CMI.InvoiceIDSeq
            and    X.IDSeq          = CMI.InvoiceItemIDSeq 
            and    CMI.CreditMemoIDSeq = @IPVC_CreditMemoIDSeq
            where  CMI.CreditMemoIDSeq = @IPVC_CreditMemoIDSeq
            group by CMI.InvoiceIDSeq,CMI.CreditMemoIDSeq
        )
  Update CM
  set    CM.ILFCreditAmount         = coalesce(S.ILFCreditAmount,0),
         CM.AccessCreditAmount      = coalesce(S.AccessCreditAmount,0),
         CM.TransactionCreditAmount = coalesce(S.TransactionCreditAmount,0),
         CM.ShippingAndHandlingCreditAmount = coalesce(S.ShippingAndHandlingCreditAmount,0),
         CM.TaxAmount               = coalesce(S.TaxAmount,0),
         CM.TotalNetCreditAmount    = (coalesce(S.ILFCreditAmount,0)+coalesce(S.AccessCreditAmount,0)+coalesce(S.TransactionCreditAmount,0))
  from   INVOICES.dbo.CreditMemo CM with (nolock)
  left outer join 
         CMI_CTE   S
  on     CM.InvoiceIDSeq     = S.InvoiceIDSeq
  and    CM.CreditMemoIDSeq  = @IPVC_CreditMemoIDSeq
  and    S.CreditMemoIDSeq   = @IPVC_CreditMemoIDSeq
  and    CM.CreditMemoIDSeq  = S.CreditMemoIDSeq
  where  CM.CreditMemoIDSeq  = @IPVC_CreditMemoIDSeq;
  -------------------------------------------------------- 
  ;with CMII_CTE(InvoiceIDSeq,CreditMemoIDSeq,TransactionCreditAmount,ILFCreditAmount,AccessCreditAmount,ShippingAndHandlingCreditAmount,TaxAmount)
   as (select CMI.InvoiceIDSeq                                                                                            as InvoiceIDSeq,
              CMI.CreditMemoIDSeq                                                                                         as CreditMemoIDSeq,
            sum((case when (X.Measurecode    = 'TRAN') then (CMI.NetCreditAmount) else 0 end))                            as TransactionCreditAmount,
            sum((case when (X.ChargeTypecode = 'ILF' and X.Measurecode <>'TRAN')  then (CMI.NetCreditAmount) else 0 end)) as ILFCreditAmount,
            sum((case when (X.ChargeTypecode = 'ACS' and X.Measurecode <>'TRAN')  then (CMI.NetCreditAmount) else 0 end)) as AccessCreditAmount,          
            sum(CMI.ShippingAndHandlingCreditAmount)                                                                      as ShippingAndHandlingCreditAmount,
            sum(CMI.TaxAmount)                                                                                            as TaxAmount          
            from   INVOICES.dbo.CreditMemoItem CMI with (nolock)
            inner join
                   INVOICES.dbo.InvoiceItem    X with (nolock)
            on     X.InvoiceIDSeq   = CMI.InvoiceIDSeq
            and    X.IDSeq          = CMI.InvoiceItemIDSeq 
            and    CMI.InvoiceIDSeq = @LVC_InvoiceID
            where  CMI.InvoiceIDSeq = @LVC_InvoiceID
            group by CMI.InvoiceIDSeq,CMI.CreditMemoIDSeq
           )
  Update CM
  set      CM.ILFCreditAmount         = S.ILFCreditAmount,
           CM.AccessCreditAmount      = S.AccessCreditAmount,
           CM.TransactionCreditAmount = S.TransactionCreditAmount,
           CM.ShippingAndHandlingCreditAmount = S.ShippingAndHandlingCreditAmount,
           CM.TaxAmount               = S.TaxAmount,
           CM.TotalNetCreditAmount    = (S.ILFCreditAmount+S.AccessCreditAmount+S.TransactionCreditAmount)
  from   INVOICES.dbo.CreditMemo CM with (nolock)
  inner join 
         CMII_CTE   S
  on     CM.InvoiceIDSeq  = S.InvoiceIDSeq
  and    CM.InvoiceIDSeq  = @LVC_InvoiceID
  and    S.InvoiceIDSeq   = @LVC_InvoiceID
  and    CM.CreditMemoIDSeq = S.CreditMemoIDSeq
  where  CM.InvoiceIDSeq  = @LVC_InvoiceID;
  --------------------------------------------------------
  ;with IICMI_CTE(InvoiceIDSeq,InvoiceItemIDSeq,NetCreditAmount)
  as (select CMI.InvoiceIDSeq                                       as InvoiceIDSeq,
             CMI.InvoiceItemIDSeq                                   as InvoiceItemIDSeq,
             coalesce(sum(CMI.NetCreditAmount                 +                          
                          CMI.TaxAmount
                          )
                      ,0.00)                                        as NetCreditAmount
          from   INVOICES.dbo.CreditMemoItem CMI with (nolock)          
          inner join 
                 INVOICES.dbo.CreditMemo CM with (nolock)
          on     CM.InvoiceIDSeq     = CMI.InvoiceIDSeq
          and    CM.CreditMemoIDSeq  = CMI.CreditMemoIDSeq          
          and    CM.CreditStatusCode = 'APPR'
          and    CMI.InvoiceIDSeq = @LVC_InvoiceID
          and    CM.InvoiceIDSeq  = @LVC_InvoiceID
          where  CMI.InvoiceIDSeq = @LVC_InvoiceID
          and    CM.InvoiceIDSeq  = @LVC_InvoiceID
          and    CM.CreditStatusCode = 'APPR'
          group by CMI.InvoiceIDSeq,CMI.InvoiceItemIDSeq
         )
  Update IIO
  set    IIO.CreditAmount = coalesce(S.NetCreditAmount,0.00)
  From   INVOICES.dbo.InvoiceItem IIO with (nolock)
  left Outer join
         IICMI_CTE  S
  on    IIO.InvoiceIDSeq = S.InvoiceIDSeq
  and   IIO.IDSeq        = S.InvoiceItemIDSeq
  and   IIO.InvoiceIDSeq = @LVC_InvoiceID
  and   S.InvoiceIDSeq   = @LVC_InvoiceID
  where IIO.InvoiceIDSeq = @LVC_InvoiceID;
  --------------------------------------------------------
  ;With CTE_PreviousApprovedCMI (InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,CustomBundleNameEnabledFlag,
                                   NetCreditAmount,NetCreditTaxAmount,ShippingAndHandlingCreditAmount
                                  )
        as (select CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag,
                   Sum(CMI.NetCreditAmount)                 as NetCreditAmount,
                   Sum(CMI.TaxAmount)                       as NetCreditTaxAmount,
                   sum(CMI.ShippingAndHandlingCreditAmount) as ShippingAndHandlingCreditAmount
            from   INVOICES.dbo.CreditMemo     CM with (nolock)
            inner Join
                   INVOICES.dbo.CreditMemoItem CMI with (nolock)
            on     CM.CreditMemoIDSeq = CMI.CreditMemoIDSeq
            and    CM.InvoiceIDSeq    = CMI.InvoiceIDSeq
            and    CM.InvoiceIDSeq    = @LVC_InvoiceID
            and    CM.CreditStatusCode= 'APPR'
            group by CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag
           ) 
    --------------
    Update  II
    set     II.AllowCreditFlag =  (case when (
                                              (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))    > 0
                                                OR
                                              (II.NetChargeAmount - coalesce(CTE_PACMI.NetCreditAmount,0)) > 0
                                             )
                                           then 1
                                        else 0
                                   end) 
    from    Invoices.dbo.InvoiceItem  II WITH (NOLOCK)
    inner join 
            Invoices.dbo.InvoiceGroup IG WITH (NOLOCK)
    ON      IG.InvoiceIDSeq      = II.InvoiceIDSeq  
    and     IG.IDSeq             = II.InvoiceGroupIDSeq
    and     II.InvoiceIDSeq      = @LVC_InvoiceID
    and     IG.InvoiceIDSeq      = @LVC_InvoiceID
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
    and    CTE_PACMI.InvoiceIDSeq  = @LVC_InvoiceID   
    where   II.InvoiceIDSeq        = @LVC_InvoiceID
    and     IG.InvoiceIDSeq        = @LVC_InvoiceID;    
  --------------------------------------------------------
  --Final Clean for Orphan CreditMemo with No CreditMemoItem
  if not exists (select Top 1 1
                 from   Invoices.dbo.CreditMemoItem CMI with (nolock)
                 where  CMI.CreditMemoIDSeq = @IPVC_CreditMemoIDSeq
                 )
     and exists (select Top 1 1
                 from   Invoices.dbo.CreditMemo CM with (nolock)
                 where  CM.CreditMemoIDSeq  = @IPVC_CreditMemoIDSeq
                 and    CM.CreditStatusCode in ('PAPR','RSVD') 
                 ) 
  begin
    Delete D 
    from   INVOICES.dbo.CreditMemoItemNote D with (nolock)
    where  D.CreditMemoIDSeq = @IPVC_CreditMemoIDSeq;

    Delete D 
    from   INVOICES.dbo.CreditMemoItem D with (nolock)
    where  D.CreditMemoIDSeq = @IPVC_CreditMemoIDSeq;
  
    Delete D 
    from   INVOICES.dbo.CreditMemo D with (nolock)
    where  D.CreditMemoIDSeq = @IPVC_CreditMemoIDSeq;

    Delete D 
    from   Documents.dbo.Document D with (nolock)
    where  D.CreditMemoIDSeq = @IPVC_CreditMemoIDSeq; 
  end
  --------------------------------------------------------
END  
GO
