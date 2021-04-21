SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name   : QUOTES
-- Procedure Name   : uspQUOTES_Rep_DealDeskDetail
-- Description      : All quotes where Deal Desk Approval = Required will be retrieved.
-- Input Parameters : 1. @IPVC_QuoteID  as varchar(22),
--					  2. @IPC_QuoteStatusCode  as char(4),
--					  3. @IPC_DDStatusCode  as char(4),
-- 					  4. @IPVC_DDStartDate as datetime,
--				 	  5. @IPVC_DDEndDate as datetime,
--					  6. @IPVC_DDApprovedBy	as varchar(100),
-- 					  7. @IPVC_CompanyName as varchar(255),
-- 					  8. @IPC_PMCID as char(11) 
-- 
-- Code example		: [uspQUOTES_Rep_DealDeskDetail] @IPVC_QuoteID = 'Q1108000069',
--						@IPC_QuoteStatusCode = '',
--						@IPC_DDStatusCode = 'APR',
--						@IPVC_DDStartDate = '08/26/2011',
--						@IPVC_DDEndDate = '',
--						@IPVC_DDApprovedBy = '',
--						@IPVC_CompanyName = '1109-1113 MANHATTAN AVENUE PARTNERS,LLC',
--						@IPC_PMCID = 'C1108000012'

-- OUTPUT           : The rows selected for the report criteria passed in.
--
-- Code Example     : Exec Invoices.DBO.uspQUOTES_Rep_DealDeskDetail  
--                          
-- 
-- Author           : Surya Kondapalli
-- 09/28/2011		: Surya Kondapalli Task# 968 - New report for Quotes processed through Deal Desk				
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspQUOTES_Rep_DealDeskDetail](
														  @IPVC_QuoteID  as varchar(22) = '',
														  @IPC_QuoteStatusCode  as char(4) = '',
														  @IPC_DDStatusCode  as char(4) = '',
														  @IPVC_DDStartDate as varchar(50) = '',
														  @IPVC_DDEndDate as varchar(50) = '',
														  @IPVC_DDApprovedBy	as varchar(100) = '',
														  @IPVC_CompanyName as varchar(255) = '',
														  @IPC_PMCID as char(11) = ''
                                                        )
AS
BEGIN
  SET  NOCOUNT ON;
  
 ;WITH tablefinal (QuoteIDSeq,CompanyIDSeq,CompanyName,QuoteType,QuoteStatus,QuoteDescription,                  
                  ClientServiceRepresentative,QuoteSalesRepresentative,
                  QuoteCreatedByUserName,QuoteCreatedDate,QuoteModifiedByUserName,QuoteModifiedDate,
                  QuoteSubmittedDate,QuoteApprovalDate,
                  DealDeskQueuedDate,DealDeskQueuedByUserName,DealDeskStatus,DealDeskDecisionMadeBy,DealDeskResolvedByUserName,DealDeskResolvedDate,
                  DealDeskNote,                  
                  QHRowNumber)
AS
       (Select Q.QuoteIDSeq                                                           as QuoteIDSeq,
               Q.CustomerIDSeq                                                        as CompanyIDSeq,               
               Q.CompanyName                                                          as CompanyName,
               QT.[Name]                                                              as QuoteType,
               QS.[Name]                                                              as QuoteStatus,
               coalesce(ltrim(rtrim(Q.Description)),'')                               as QuoteDescription,               
               -------------------------------------------------------------------------
               (case when UCSR.IDSeq is not null
                       then (ltrim(rtrim(UCSR.FirstName + ' ' + UCSR.LastName))) collate SQL_Latin1_General_CP850_CI_AI
                     else 'N/A'
                end)                                                                  as  ClientServiceRepresentative,
               (coalesce(QSAO.QuoteSalesRepresentative,'N/A'))  collate SQL_Latin1_General_CP850_CI_AI
                                                                                      as  QuoteSalesRepresentative,
               (ltrim(rtrim(UC.FirstName + ' ' + UC.LastName))) collate SQL_Latin1_General_CP850_CI_AI
                                                                                      as  QuoteCreatedByUserName,
               Q.CreateDate                                                           as  QuoteCreatedDate,
               (ltrim(rtrim(UM.FirstName + ' ' + UM.LastName))) collate SQL_Latin1_General_CP850_CI_AI          
                                                                                      as  QuoteModifiedByUserName,
               Q.ModifiedDate                                                         as  QuoteModifiedDate,
               -------------------------------------------------------------------------
               Q.SubmittedDate                                                        as  QuoteSubmittedDate,
               Q.ApprovalDate                                                         as  QuoteApprovalDate, 
               -------------------------------------------------------------------------
               Q.DealDeskQueuedDate                                                   as DealDeskQueuedDate,
               (ltrim(rtrim(UDDQ.FirstName + ' ' + UDDQ.LastName))) collate SQL_Latin1_General_CP850_CI_AI
                                                                                      as DealDeskQueuedByUserName,
               (Case when Q.DealDeskStatusCode = 'NSU'
                      then 'Not Submitted for Deal Desk Approval'
                     when Q.DealDeskStatusCode = 'SUB'
                      then 'Submitted for Deal Desk Approval'
                     else QDS.[Name]
                end)                                                                  as DealDeskStatus,
               Q.DealDeskDecisionMadeBy                                               as DealDeskDecisionMadeBy,
               (ltrim(rtrim(UDRQ.FirstName + ' ' + UDRQ.LastName))) collate SQL_Latin1_General_CP850_CI_AI
                                                                                      as DealDeskResolvedByUserName,
               Q.DealDeskResolvedDate                                                 as DealDeskResolvedDate,
               coalesce(ltrim(rtrim(Q.DealDeskNote)),'')                              as DealDeskNote,
               -------------------------------------------------------------------------                            
               row_number() OVER(ORDER BY Q.CompanyName asc,Q.DealDeskQueuedDate desc) as  [QHRowNumber]
        from   QUOTES.dbo.Quote Q with (nolock)
        inner join
               QUOTES.dbo.QuoteStatus QS with (nolock)
        on     Q.quotestatuscode = QS.Code
        and    Q.DealDeskCurrentLevel > 0        
        left outer Join
               QUOTES.dbo.QuoteType QT with (nolock)
        on     Q.quoteTypecode = QT.Code        
        left outer Join
               QUOTES.dbo.QuoteStatus QDS with (nolock)
        on     Q.DealDeskStatusCode = QDS.Code 
        Left Outer Join
               SECURITY.dbo.[User] UC with (nolock)
        on     Q.CreatedByIDSeq  = UC.IDSeq
        Left Outer Join
               SECURITY.dbo.[User] UM with (nolock)
        on     Q.ModifiedByIDSeq = UM.IDSeq
        Left Outer Join
               SECURITY.dbo.[User] UDDQ with (nolock)
        on     Q.DealDeskQueuedByIDSeq  = UDDQ.IDSeq
        Left Outer Join
               SECURITY.dbo.[User] UCSR with (nolock)
        on     Q.CSRIDSeq        = UCSR.IDSeq
        Left Outer Join
               SECURITY.dbo.[User] UDRQ with (nolock)
        on     Q.DealDeskResolvedByIDSeq  = UDRQ.IDSeq
        left outer Join
               (select QSA.QuoteIDSeq,
                       Max(coalesce(QSA.SalesAgentIDSeq,-1))               as SalesAgentIDSeq,
                       (Max(coalesce(nullif(ltrim(rtrim(QSAU.FirstName + ' ' + QSAU.LastName)),''),'N/A'))) collate SQL_Latin1_General_CP850_CI_AI 
                                                                           as QuoteSalesRepresentative
                from   Quotes.dbo.QuoteSaleAgent QSA with (nolock)
                inner join
                       Quotes.dbo.Quote Q1 with (nolock)
                on     Q1.QuoteIDSeq =  QSA.QuoteIDSeq
                and    Q1.DealDeskCurrentLevel > 0               
                Left Outer Join
                       SECURITY.dbo.[User] QSAU with (nolock)
                on     QSA.SalesAgentIDSeq     = QSAU.IDSeq
                group by QSA.QuoteIDSeq
               ) QSAO
        on   Q.QuoteIDSeq = QSAO.QuoteIDSeq        
        where  Q.DealDeskCurrentLevel > 0   
			  and (@IPC_PMCID = '' OR Q.customeridseq = @IPC_PMCID)
			  and (@IPVC_CompanyName = '' OR Q.CompanyName = @IPVC_CompanyName)											
			  and (@IPC_QuoteStatusCode = '' OR Q.quotestatuscode = @IPC_QuoteStatusCode)
              and (@IPC_DDStatusCode = '' OR Q.DealDeskStatusCode = @IPC_DDStatusCode) 											
			  and (@IPVC_QuoteID = '' OR Q.QuoteIDSeq = @IPVC_QuoteID)
			  and (@IPVC_DDApprovedBy = '' OR Q.DealDeskDecisionMadeBy = @IPVC_DDApprovedBy)
			  and (@IPVC_DDStartDate = '' OR convert(int, convert(varchar(10),Q.DealDeskResolvedDate, 112)) >= convert(int, convert(varchar(10),convert(datetime,@IPVC_DDStartDate), 112)))
			  and (@IPVC_DDEndDate = '' OR convert(int, convert(varchar(10),Q.DealDeskResolvedDate, 112))  <= convert(int, convert(varchar(10),convert(datetime,@IPVC_DDEndDate), 112))) 
       )
,CTE_QuoteDetail (QuoteIDSeq,CompanyIDSeq,BundleName,Sites,Units,FamilyName,ProductCode,ProductName,
                  ILFListAmount,ILFDiscountAmount,ILFDiscountPercentage,ILFNetAmount,
                  AccessListAmount,AccessDiscountAmount,AccessDiscountPercentage,AccessNetAmount,
                  QDRowNumber
                 )
as (select Q.QuoteIDSeq                                      as QuoteIDSeq,
           Q.CustomerIDSeq                                   as CompanyIDSeq,
           (case when Max(convert(int,G.CustomBundleNameEnabledFlag)) = 1
                  then Max(G.Name)
                else '' 
            end)                                             as BundleName,
           Max(QI.Sites)                                     as Sites, 
           Max(QI.Units)                                     as Units,
           Max(F.Name)                                       as FamilyName,
           QI.ProductCode                                    as ProductCode,
           Max(PRD.DisplayName)                              as ProductName,
           ---------------------------------
           (Sum((case when QI.Chargetypecode = 'ILF' then QI.ExtYear1ChargeAmount else 0 end)))
                                                             as ILFListAmount,
           ---------------------------------
           (Sum((case when QI.Chargetypecode = 'ILF' then QI.ExtYear1ChargeAmount else 0 end)))
                   -
           (Sum((case when QI.Chargetypecode = 'ILF' then QI.NetExtYear1ChargeAmount else 0 end)))
                                                             as ILFDiscountAmount,
           ---------------------------------
           (
            (Sum((case when QI.Chargetypecode = 'ILF' then QI.ExtYear1ChargeAmount else 0 end)))
                    -
            (Sum((case when QI.Chargetypecode = 'ILF' then QI.NetExtYear1ChargeAmount else 0 end)))
           ) * 100
           /
          (case when (Sum((case when QI.Chargetypecode = 'ILF' then QI.ExtYear1ChargeAmount else 0 end)))>0 
                  then (Sum((case when QI.Chargetypecode = 'ILF' then QI.ExtYear1ChargeAmount else 0 end)))
                else 1
           end)                                              as ILFDiscountPercentage,
           (Sum((case when QI.Chargetypecode = 'ILF' then QI.NetExtYear1ChargeAmount else 0 end)))
                                                             as ILFNetAmount,
           ---------------------------------
           (Sum((case when QI.Chargetypecode = 'ACS' then QI.ExtYear1ChargeAmount else 0 end)))
                                                             as AccessListAmount,
           ---------------------------------
           (Sum((case when QI.Chargetypecode = 'ACS' then QI.ExtYear1ChargeAmount else 0 end)))
                   -
           (Sum((case when QI.Chargetypecode = 'ACS' then QI.NetExtYear1ChargeAmount else 0 end)))
                                                             as AccessDiscountAmount,
           ---------------------------------
           (
            (Sum((case when QI.Chargetypecode = 'ACS' then QI.ExtYear1ChargeAmount else 0 end)))
                    -
            (Sum((case when QI.Chargetypecode = 'ACS' then QI.NetExtYear1ChargeAmount else 0 end)))
           ) * 100
           /
          (case when (Sum((case when QI.Chargetypecode = 'ACS' then QI.ExtYear1ChargeAmount else 0 end)))>0 
                  then (Sum((case when QI.Chargetypecode = 'ACS' then QI.ExtYear1ChargeAmount else 0 end)))
                else 1
           end)                                              as AccessDiscountPercentage,
           ---------------------------------
           (Sum((case when QI.Chargetypecode = 'ACS' then QI.NetExtYear1ChargeAmount else 0 end)))
                                                             as AccessNetAmount
           ---------------------------------
           ,row_number() OVER(ORDER BY Min(G.Name),Min(F.Name) asc,Min(PRD.DisplayName) asc) as  [QDRowNumber]
    from   QUOTES.dbo.Quote Q   with (nolock)
    inner join
           Quotes.dbo.[Group] G with (nolock)
    on     Q.QuoteIDSeq = G.QuoteIDSeq
    and    Q.DealDeskCurrentLevel > 0  
    inner join
           Quotes.dbo.QuoteItem QI with (nolock)
    on     Q.QuoteIDSeq = QI.QuoteIDSeq
    and    G.QuoteIDSeq = QI.QuoteIDSeq
    and    G.IDSeq      = QI.GroupIDSeq
    inner join
           Products.dbo.Product PRD with (nolock)
    on     QI.ProductCode = PRD.Code
    and    QI.PriceVersion= PRD.PriceVersion
    inner join
           Products.dbo.Family F with (nolock)
    on     PRD.FamilyCode = F.Code
    group by Q.QuoteIDSeq,Q.CustomerIDSeq,QI.GroupIDSeq,QI.ProductCode,PRD.FamilyCode
   )
--------------------------------------------
--Final Select    
--------------------------------------------
  select  tablefinal.QuoteIDSeq                                 as [Quote ID]
         ,tablefinal.CompanyIDSeq                               as [Company ID]
         ,tablefinal.CompanyName                                as [Company Name]
         ,tablefinal.QuoteType                                  as [Quote Type]
         ,tablefinal.QuoteStatus                                as [Quote Status]         
         ,tablefinal.QuoteDescription                           as [Quote Description]
         ,tablefinal.ClientServiceRepresentative                as [Client Service Representative]
         ,tablefinal.QuoteSalesRepresentative                   as [Quote Sales Representative]
         ,tablefinal.QuoteCreatedByUserName                     as [Quote CreatedBy]
         ,tablefinal.QuoteCreatedDate                           as [Quote Created Date]
         ,tablefinal.QuoteModifiedByUserName                    as [Quote ModifiedBy]
         ,tablefinal.QuoteModifiedDate                          as [Quote Modified Date]
         ,tablefinal.QuoteSubmittedDate                         as [Quote Submitted Date]
         ,tablefinal.QuoteApprovalDate                          as [Quote Approval Date]
          -----------------------------
         ,tablefinal.DealDeskQueuedByUserName                   as [DealDesk QueuedBy]
         ,tablefinal.DealDeskQueuedDate                         as [DealDesk Queued Date]
         ,tablefinal.DealDeskStatus                             as [DealDesk Status]
         ,tablefinal.DealDeskDecisionMadeBy                     as [DealDesk ApprovedBy]
         ,tablefinal.DealDeskResolvedByUserName                 as [DealDesk ResolvedBy]
         ,tablefinal.DealDeskResolvedDate                       as [DealDesk Resolved Date]
         ,tablefinal.DealDeskNote                               as [DealDesk Note]
         ----------------------------
         ,CTE_QuoteDetail.BundleName                            as BundleName
         ,CTE_QuoteDetail.Sites                                 as Sites
         ,CTE_QuoteDetail.Units                                 as Units
         ,CTE_QuoteDetail.FamilyName                            as FamilyName
         ,CTE_QuoteDetail.ProductCode                           as ProductCode
         ,CTE_QuoteDetail.ProductName                           as ProductName
         ,CTE_QuoteDetail.ILFListAmount                         as [ILF List($)]
         ,CTE_QuoteDetail.ILFDiscountAmount                     as [ILF Discount($)]
         ,CTE_QuoteDetail.ILFDiscountPercentage                 as [ILF Discount%]
         ,CTE_QuoteDetail.ILFNetAmount                          as [ILF Net($)]
         ----------------------------
         ,CTE_QuoteDetail.AccessListAmount                      as [Access List($)]
         ,CTE_QuoteDetail.AccessDiscountAmount                  as [Access Discount($)]
         ,CTE_QuoteDetail.AccessDiscountPercentage              as [Access Discount%]
         ,CTE_QuoteDetail.AccessNetAmount                       as [Access Net($)]
         ----------------------------
  from   tablefinal   
  inner join
         CTE_QuoteDetail
  on     tablefinal.QuoteIDSeq   =  CTE_QuoteDetail.QuoteIDSeq
  and    tablefinal.CompanyIDSeq =  CTE_QuoteDetail.CompanyIDSeq
  order by tablefinal.QHRowNumber asc,CTE_QuoteDetail.QDRowNumber asc;
  
End
GO
