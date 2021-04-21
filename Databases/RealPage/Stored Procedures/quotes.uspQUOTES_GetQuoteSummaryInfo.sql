SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_GetQuoteSummaryInfo
-- Description     : This procedure gets the Quote Summary Information for a given Quote. One ResultSet Row
--
-- Input Parameters: @IPVC_QuoteIDSeq varchar(50)
--
-- 
-- OUTPUT          : One ResultSet Row
--
-- Code Example    : Exec QUOTES.[dbo].[uspQUOTES_GetQuoteSummaryInfo] @IPVC_QuoteIDSeq = 'Q1104001010'
--
-- Author          : SRS
-- 05/15/2011      : Stored Procedure Created. TFS # 267 Deal Desk Project
-- Author          : Satya B
-- 07/18/2011      : Added new column PrePaidFlag,RequestedBy with refence to TFS #295 Instant Invoice Transactions through OMS
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetQuoteSummaryInfo]    (@IPVC_QuoteIDSeq        varchar(50) ----> Mandatory.
                                                          )
AS
BEGIN -- :Main Begin
  set nocount on;
  -----------------------------------------
  declare @LVC_CompanyIDSeq   varchar(50);
  select  @LVC_CompanyIDSeq = Q.CustomerIDSeq
  from    Quotes.dbo.Quote Q with (nolock)
  where   Q.QuoteIDSeq = @IPVC_QuoteIDSeq;
  -----------------------------------------
  ;with QG_CTE (QuoteIDSeq,ilf,access1,access2,access3)
   as (select G.QuoteIDSeq                                                                         as QuoteIDSeq,
              Quotes.DBO.fn_FormatCurrency(coalesce(sum(G.ILFNetExtYearChargeAmount),'0'),1,2)     as ilf,
              Quotes.DBO.fn_FormatCurrency(coalesce(sum(G.AccessNetExtYear1ChargeAmount),'0'),1,2) as access1,
              Quotes.DBO.fn_FormatCurrency(coalesce(sum(G.AccessNetExtYear2ChargeAmount),'0'),1,2) as access2,
              Quotes.DBO.fn_FormatCurrency(coalesce(sum(G.AccessNetExtYear3ChargeAmount),'0'),1,2) as access3
       from   Quotes.dbo.[Group] G with (nolock)
       where  G.QuoteIDSeq    = @IPVC_QuoteIDSeq
       and    G.CustomerIDSeq = @LVC_CompanyIDSeq
       group by QuoteIDSeq
      ),
   -----------------------------------------
   GP_CTE (QuoteIDSeq,sites,units,beds)
   as (select @IPVC_QuoteIDSeq as QuoteIDSeq,
              count(1) as sites,sum(PRP.QuotableUnits) as units,sum(PRP.QuotableBeds) as Beds
       from   Customers.dbo.Property PRP with (nolock)
       where  exists (select top 1 1 
                      from   Quotes.dbo.GroupProperties GP with (nolock)
                      where  GP.PropertyIDSeq = PRP.IDSeq
                      and    GP.CustomerIDSeq = PRP.PMCIDSeq
                      and    GP.QuoteIDSeq    = @IPVC_QuoteIDSeq
                      and    GP.CustomerIDSeq = @LVC_CompanyIDSeq
                      and    PRP.PMCIDSeq     = @LVC_CompanyIDSeq
                     )
      ),
   -----------------------------------------
   COM_CTE(QuoteIDSeq,customerid,customername,customerurl,customersince,agreementdate,sitemasterid,siebelid,epicorid)
   as (select Top 1 @IPVC_QuoteIDSeq                                 as QuoteIDSeq,
                    @LVC_CompanyIDSeq                                as customerid,
                    C.Name                                           as customername,
                    coalesce(AddrCOM.URL,'')                         as customerurl,
                    convert(varchar(20),C.CreatedDate,101)           as customersince,
                    '[Unknown]'                                      as agreementdate,
                    coalesce(C.sitemasterid,'N/A')                   as sitemasterid,
                    coalesce(C.siebelid,'N/A')                       as siebelid,
                    coalesce(C.EpicorCustomerCode,'')                as EpicorCustomerCode
       from   CUSTOMERS.dbo.Company C        with (nolock)
       inner Join
              CUSTOMERS.dbo.Address AddrCOM  with (nolock)
       on     C.IDSeq = AddrCOM.CompanyIDSeq
       and    C.IDSeq = @LVC_CompanyIDSeq
       and    AddrCOM.CompanyIDSeq = @LVC_CompanyIDSeq
       and    AddrCOM.AddressTypecode = 'COM'
       Left Outer Join
              CUSTOMERS.dbo.Account AcctCOM  with (nolock)
       on     C.IDSeq = AcctCOM.CompanyIDSeq
       and    AcctCOM.AccountTypeCode = 'AHOFF'
       and    AcctCOM.PropertyIDSeq is null
       and    AcctCOM.ActiveFlag = 1
      ),
   -----------------------------------------
   Q_CTE (QuoteIDSeq,quotetypecode,quotetype,quotestatuscode,quotestatus,
          QuoteDescription,
          CreatedBy,CreatedDate,ModifiedBy,ModifiedDate,ExpirationDate,
          SubmittedDate,CancelledDate,AcceptanceDate,ApprovalDate,
          CSRIDSeq,ClientServiceRepresentative,
          DealDeskReferenceLevel,DealDeskCurrentLevel,
          DealDeskStatusCode,DealDeskStatus,
          DealDeskQueuedDate,DealDeskQueuedByIDSeq,DealDeskQueuedBy,
          DealDeskDecisionMadeBy,
          DealDeskNote,DealDeskResolvedByIDSeq,DealDeskResolvedBy,
          DealDeskResolvedDate,
          RollbackReasonName,RollBackBy,RollBackDate,
          PrePaidFlag,RequestedBy,ExternalQuoteIIFlag
         )
    as (select Q.QuoteIDSeq                                        as QuoteIDSeq,
               Q.QuoteTypeCode                                     as quotetypecode,
               QT.[Name]                                           as quotetype,
               Q.quotestatuscode                                   as quotestatuscode,
               QS.[Name]                                           as quotestatus,
               coalesce(Q.[Description],'N/A')                     as QuoteDescription,
              (case when UC.IDSeq is not null
                       then UC.FirstName+' ' + UC.LastName
                     else 'N/A'
                end)                                               as CreatedBy,
               convert(varchar(20),Q.CreateDate,101)               as CreatedDate,
               ----------------------------------
               (case when UM.IDSeq is not null
                       then (UM.FirstName+' ' + UM.LastName) collate SQL_Latin1_General_CP850_CI_AI
                     else 'N/A'
                end)                                               as ModifiedBy,
               convert(varchar(20),Q.ModifiedDate,101)             as ModifiedDate,
               ----------------------------------
               convert(varchar(20),Q.ExpirationDate,101)           as ExpirationDate,
               convert(varchar(20),Q.SubmittedDate,101)            as SubmittedDate,
               convert(varchar(20),Q.CancelledDate,101)            as CancelledDate,
               convert(varchar(20),Q.AcceptanceDate,101)           as AcceptanceDate,
               convert(varchar(20),Q.ApprovalDate,101)             as ApprovalDate,
               ----------------------------------
               coalesce(convert(varchar(50),Q.CSRIDSeq),'0')       as CSRIDSeq,
               (case when UCSR.IDSeq is not null
                       then (UCSR.FirstName+ ' ' + UCSR.LastName) collate SQL_Latin1_General_CP850_CI_AI
                     else 'N/A'
                end)                                               as ClientServiceRepresentative,
               ----------------------------------
               Q.DealDeskReferenceLevel                            as DealDeskReferenceLevel,
               Q.DealDeskCurrentLevel                              as DealDeskCurrentLevel,
               Q.DealDeskStatusCode                                as DealDeskStatusCode,
               (Case when Q.DealDeskStatusCode = 'NSU'
                      then 'Not Submitted for Approval'
                     when Q.DealDeskStatusCode = 'SUB'
                      then 'Submitted for Approval'
                     else QDS.[Name]
                end)                                               as DealDeskStatus,
               convert(varchar(20),Q.DealDeskQueuedDate,101)       as DealDeskQueuedDate,
               coalesce(convert(varchar(50),Q.DealDeskQueuedByIDSeq),'0')
                                                                   as DealDeskQueuedByIDSeq,
               (case when UDDQ.IDSeq is not null
                       then (UDDQ.FirstName+' ' + UDDQ.LastName) collate SQL_Latin1_General_CP850_CI_AI
                     else 'N/A'
                end)                                               as DealDeskQueuedBy, 
               coalesce(Q.DealDeskDecisionMadeBy,'N/A')            as DealDeskDecisionMadeBy,
               coalesce(Q.DealDeskNote,'N/A')                      as DealDeskNote,
               coalesce(convert(varchar(50),Q.DealDeskResolvedByIDSeq),'0') 
                                                                   as DealDeskResolvedByIDSeq,
               (case when UDD.FirstName is not null
                       then (UDD.FirstName+' ' + UDD.LastName) collate SQL_Latin1_General_CP850_CI_AI
                     else 'N/A'
                end)                                               as DealDeskResolvedBy,
               convert(varchar(20),Q.DealDeskResolvedDate,101)     as DealDeskResolvedDate,
               ----------------------------------
               RR.ReasonName                                       as RollbackReasonName,
               (case when URQ.FirstName is not null
                       then (URQ.FirstName+' ' + URQ.LastName) collate SQL_Latin1_General_CP850_CI_AI
                     else 'N/A'
                end)                                               as RollBackBy,
               convert(varchar(20),Q.RollBackDate,101)             as RollBackDate,
               ----------------------------------
               Q.PrePaidFlag                                       as PrePaidFlag,
               Q.RequestedBy                                       as RequestedBy,
               Q.ExternalQuoteIIFlag                               as ExternalQuoteIIFlag
               ----------------------------------
        from   QUOTES.dbo.Quote Q with (nolock)
        inner join
               QUOTES.dbo.QuoteStatus QS with (nolock)
        on     Q.quotestatuscode = QS.Code
        and    Q.QuoteIDSeq      = @IPVC_QuoteIDSeq 
        and    Q.CustomerIDSeq   = @LVC_CompanyIDSeq 
        left outer Join
               QUOTES.dbo.QuoteType QT with (nolock)
        on     Q.quoteTypecode   = QT.Code
        and    Q.QuoteIDSeq      = @IPVC_QuoteIDSeq 
        and    Q.CustomerIDSeq   = @LVC_CompanyIDSeq 
        left outer Join
               QUOTES.dbo.QuoteStatus QDS with (nolock)
        on     Q.DealDeskStatusCode = QDS.Code 
        and    Q.QuoteIDSeq      = @IPVC_QuoteIDSeq
        and    Q.CustomerIDSeq   = @LVC_CompanyIDSeq
        Left Outer Join
               SECURITY.dbo.[User] UC with (nolock)
        on     Q.CreatedByIDSeq  = UC.IDSeq 
        Left Outer Join
               SECURITY.dbo.[User] UM with (nolock)
        on     Q.ModifiedByIDSeq = UM.IDSeq
        Left Outer Join
               SECURITY.dbo.[User] UCSR with (nolock)
        on     Q.CSRIDSeq  = UCSR.IDSeq
        Left Outer Join
               SECURITY.dbo.[User] UDDQ with (nolock)
        on     Q.DealDeskQueuedByIDSeq  = UDDQ.IDSeq
        and    Q.QuoteIDSeq      = @IPVC_QuoteIDSeq
        and    Q.CustomerIDSeq   = @LVC_CompanyIDSeq
        Left Outer Join
               SECURITY.dbo.[User] UDD with (nolock)
        on     Q.DealDeskResolvedByIDSeq  = UDD.IDSeq
        Left Outer Join
               SECURITY.dbo.[User] URQ with (nolock)
        on     Q.RollBackByIDseq  = URQ.IDSeq
        left Outer Join
               ORDERS.dbo.Reason   RR with (nolock)
        on     Q.RollbackReasonCode = RR.Code
        where  Q.QuoteIDSeq      = @IPVC_QuoteIDSeq
        and    Q.CustomerIDSeq   = @LVC_CompanyIDSeq
    )
   -----------------------------------------
   --Final Select 
   select COM_CTE.quoteidseq                                 as quoteidseq,
          COM_CTE.customerid                                 as customerid,          
          COM_CTE.customername                               as customername,
          COM_CTE.customerurl                                as customerurl,
          COM_CTE.customersince                              as customersince,
          COM_CTE.agreementdate                              as agreementdate,
          COM_CTE.sitemasterid                               as sitemasterid,
          COM_CTE.siebelid                                   as siebelid,
          COM_CTE.epicorid                                   as epicorid,
          ------------------
          coalesce(GP_CTE.sites,'0')                         as sites,
          coalesce(GP_CTE.units,'0')                         as units,
          coalesce(GP_CTE.beds,'0')                          as beds,
          ------------------
          Q_CTE.quotetypecode                                as quotetypecode,
          Q_CTE.quotetype                                    as quotetype,
          Q_CTE.quotestatuscode                              as quotestatuscode,
          Q_CTE.quotestatus                                  as quotestatus,
          Q_CTE.QuoteDescription                             as [Description],
          Q_CTE.CreatedBy                                    as CreatedBy,
          Q_CTE.CreatedDate                                  as CreatedDate,
          Q_CTE.ModifiedBy                                   as ModifiedBy,
          Q_CTE.ModifiedDate                                 as ModifiedDate,
          Q_CTE.ExpirationDate                               as ExpirationDate,
          Q_CTE.SubmittedDate                                as SubmittedDate,
          Q_CTE.CancelledDate                                as CancelledDate,
          Q_CTE.AcceptanceDate                               as AcceptanceDate,
          Q_CTE.ApprovalDate                                 as ApprovalDate,
          Q_CTE.CSRIDSeq                                     as CSRIDSeq,
          Q_CTE.ClientServiceRepresentative                  as ClientServiceRepresentative,
          Q_CTE.DealDeskReferenceLevel                       as DealDeskReferenceLevel,
          Q_CTE.DealDeskCurrentLevel                         as DealDeskCurrentLevel,
          Q_CTE.DealDeskStatusCode                           as DealDeskStatusCode,
          Q_CTE.DealDeskStatus                               as DealDeskStatus,
          Q_CTE.DealDeskQueuedDate                           as DealDeskQueuedDate,
          Q_CTE.DealDeskQueuedByIDSeq                        as DealDeskQueuedByIDSeq,
          Q_CTE.DealDeskQueuedBy                             as DealDeskQueuedBy,
          Q_CTE.DealDeskNote                                 as DealDeskNote,
          Q_CTE.DealDeskDecisionMadeBy                       as DealDeskDecisionMadeBy,
          Q_CTE.DealDeskResolvedByIDSeq                      as DealDeskResolvedByIDSeq,
          Q_CTE.DealDeskResolvedBy                           as DealDeskResolvedBy, 
          Q_CTE.DealDeskResolvedDate                         as DealDeskResolvedDate,
          Q_CTE.RollbackReasonName                           as RollbackReasonName,
          Q_CTE.RollBackBy                                   as RollBackBy,
          Q_CTE.RollBackDate                                 as RollBackDate,
          ------------------
          coalesce(QG_CTE.ilf,'0')                           as ilf,
          coalesce(QG_CTE.access1,'0')                       as access1,
          coalesce(QG_CTE.access2,'0')                       as access2,
          coalesce(QG_CTE.access3,'0')                       as access3,
          ------------------ 
          Q_CTE.PrePaidFlag                                  as PrePaidFlag,
          Q_CTE.RequestedBy                                  as RequestedBy,
          Q_CTE.ExternalQuoteIIFlag                          as ExternalQuoteIIFlag
  from   COM_CTE
  inner  join
         Q_CTE
  on     COM_CTE.quoteidseq    = Q_CTE.quoteidseq
  left outer join
         QG_CTE
  on     COM_CTE.quoteidseq    = QG_CTE.quoteidseq 
  and    Q_CTE.quoteidseq      = QG_CTE.quoteidseq 
  left outer join
         GP_CTE
  on     COM_CTE.quoteidseq    = GP_CTE.quoteidseq 
  and    Q_CTE.quoteidseq      = GP_CTE.quoteidseq 
  and    QG_CTE.quoteidseq     = GP_CTE.quoteidseq
  where  Q_CTE.quoteidseq      = @IPVC_QuoteIDSeq
  and    COM_CTE.quoteidseq    = @IPVC_QuoteIDSeq
  and    COM_CTE.customerid    = @LVC_CompanyIDSeq 
END -- :Main End
GO
