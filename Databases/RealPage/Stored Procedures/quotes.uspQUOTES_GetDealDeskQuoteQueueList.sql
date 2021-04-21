SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_GetDealDeskQuoteQueueList
-- Description     : This procedure gets the list of Quotes Queued for Deal Desk Approval 
--
-- Input Parameters: As Below
--
-- 
-- OUTPUT          : A recordSet of QuoteID, CustomerID, CustomerName ....
--

--syntax           : Exec QUOTES.dbo.uspQUOTES_GetDealDeskQuoteQueueList @IPI_PageNumber=1,@IPI_RowsPerPage=22,...other parameters
-- Revision History:
-- Author          : SRS
-- 2011-11-16      : LWW-Add ExternalQuoteIIFlag to result set (W/I-1315)
-- 2011-08-12      : LWW-Add PrePaidFlag to result set
-- 05/15/2011      : Stored Procedure Created. ---TFS : 267 : Deal Desk Project
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetDealDeskQuoteQueueList] (@IPI_PageNumber                  int            =1,          ---> This is Page Number. Default is 1 and based on user click on page number
                                                              @IPI_RowsPerPage                 int            =999999999,  ---> This is number of records that a single page can accomodate. 
                                                                                                                           --   Default is 22 rows per page. UI can pass different value based on UI realestate.
                                                                                                                           --   For Export to Excel list this value will be 999999999
                                                              @IPVC_QuoteIDSeq                 varchar(50)    ='',  ---> This is the QuoteIDSeq if searched for a specific Quote Number. Default is '' 
                                                              @IPVC_CompanyIDSeq               varchar(50)    ='',  ---> This is the CompanyIDSeq if searched for a specific Customer Number. Default is '' ,
                                                              @IPVC_CustomerName               varchar(255)   ='',  ---> This is the Customer Name for Like Search. Default is ''
                                                              @IPBI_ClientServiceRepID         varchar(50)    ='',  ---> This is the IDSeq corresponding to Client Service Rep associated with a Quote CSRID. 
                                                                                                                       --    UI calls EXEC QUOTES.dbo.uspQUOTES_GetAllUser to populate the drop down.
                                                                                                                       --    UI will pass blank '' if none is selected by default in search.
                                                              @IPBI_SalesRepID                 varchar(50)    ='',  ---> This is the IDSeq corresponding to Sales Rep associated with a Quote Quote Sales Agent. 
                                                                                                                       --    UI calls EXEC QUOTES.dbo.uspQUOTES_RepresentativeList to populate the drop down.
                                                                                                                       --    UI will pass blank '' if none is selected by default in search.
                                                              @IPVC_DealDeskQueuedStartDate    varchar(50)    ='',  ---> This is DD Queued start Date range. Default is balnk ''
                                                                                                                       -- UI to enforce DealDeskQueuedEndDate as mandatory to be entered if  DealDeskQueuedStartDate is entered and vice versa
                                                              @IPVC_DealDeskQueuedEndDate      varchar(50)    =''   ---> This is DD Queued start Date range. Default is balnk ''
                                                                                                                       -- UI to enforce DealDeskQueuedEndDate as mandatory to be entered if  DealDeskQueuedStartDate is entered and vice versa
                                                             ) --WITH RECOMPILE 
AS
BEGIN-->Main Begin
  set nocount on;
  -----------------------------------------------------
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  -----------------------------------------------------
  select @IPVC_QuoteIDSeq              = nullif(ltrim(rtrim(@IPVC_QuoteIDSeq)),''),
         @IPVC_CompanyIDSeq            = nullif(ltrim(rtrim(@IPVC_CompanyIDSeq)),''),
         @IPVC_CustomerName            = coalesce(nullif(ltrim(rtrim(@IPVC_CustomerName)),''),''),
         @IPBI_ClientServiceRepID      = nullif(ltrim(rtrim(@IPBI_ClientServiceRepID)),''),
         @IPBI_SalesRepID              = nullif(ltrim(rtrim(@IPBI_SalesRepID)),''),
         @IPVC_DealDeskQueuedStartDate = nullif(ltrim(rtrim(@IPVC_DealDeskQueuedStartDate)),''),
         @IPVC_DealDeskQueuedEndDate   = nullif(ltrim(rtrim(@IPVC_DealDeskQueuedEndDate)),'')

  declare @LDT_QueueStartDate  datetime,
          @LDT_QueueEndDate    datetime
  select  @LDT_QueueStartDate = (case when isdate(@IPVC_DealDeskQueuedStartDate)=1
                                        then convert(datetime,@IPVC_DealDeskQueuedStartDate)
                                      else convert(datetime,'01/01/1900')
                                 end
                                ),
          @LDT_QueueEndDate   = (case when isdate(@IPVC_DealDeskQueuedEndDate)=1
                                        then convert(datetime,@IPVC_DealDeskQueuedEndDate)
                                      else convert(datetime,'12/31/2199')
                                 end
                                )
  -----------------------------------------------------
  ;WITH tablefinal AS
       (Select Q.QuoteIDSeq                                                           as QuoteIDSeq,
               Q.CustomerIDSeq                                                        as CompanyIDSeq,
               Q.CompanyName                                                          as CompanyName,
               Q.Description                                                          as QuoteDescription,
               QT.[Name]                                                              as QuoteType,
			   coalesce(Q.PrePaidFlag,0)											  as PrePaidFlag,
			   Coalesce(Q.ExternalQuoteIIFlag,0)										  as ExternalQuoteIIFlag,
               QS.[Name]                                                              as QuoteStatus,
               Q.DealDeskQueuedDate                                                   as DealDeskQueuedDate,
               (ltrim(rtrim(UDDQ.FirstName + ' ' + UDDQ.LastName))) collate SQL_Latin1_General_CP850_CI_AI
                                                                                      as DealDeskQueuedByUserName,
               (Case when Q.DealDeskStatusCode = 'NSU'
                      then 'Not Submitted for Deal Desk Approval'
                     when Q.DealDeskStatusCode = 'SUB'
                      then 'Submitted for Deal Desk Approval'
                     else QDS.[Name]
                end)                                                                  as DealDeskStatus,
               Quotes.DBO.fn_FormatCurrency(Q.ILFExtYearChargeAmount,1,2)             as ILFListAmount,
               Quotes.DBO.fn_FormatCurrency(Q.ILFDiscountAmount,1,2)                  as ILFDiscountAmount,
               Quotes.DBO.fn_FormatCurrency(Q.ILFDiscountPercent,1,3)                 as ILFDiscountPercentage,
               Quotes.DBO.fn_FormatCurrency(Q.ILFNetExtYearChargeAmount,1,2)          as ILFNetAmount,
               -----------------------------------
               Quotes.DBO.fn_FormatCurrency(Q.AccessExtYear1ChargeAmount,1,2)         as AccessListAmount,
               Quotes.DBO.fn_FormatCurrency(Q.AccessYear1DiscountAmount,1,2)          as AccessDiscountAmount,
               Quotes.DBO.fn_FormatCurrency(Q.AccessYear1DiscountPercent,1,3)         as AccessDiscountPercentage,
               Quotes.DBO.fn_FormatCurrency(Q.AccessNetExtYear1ChargeAmount,1,2)      as AccessNetAmount,
               -----------------------------------
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
               row_number() OVER(ORDER BY Q.DealDeskQueuedDate desc)                  as  [RowNumber],
               Count(1) OVER()                                                        as  TotalBatchCountForPaging
        from   QUOTES.dbo.Quote Q with (nolock)
        inner join
               QUOTES.dbo.QuoteStatus QS with (nolock)
        on     Q.quotestatuscode = QS.Code
        and    Q.DealDeskCurrentLevel > 0
        and    Q.DealDeskStatusCode   = 'SUB'
        and    Q.QuoteIDSeq      = coalesce(@IPVC_QuoteIDSeq,Q.QuoteIDSeq) 
        and    Q.CustomerIDSeq   = coalesce(@IPVC_CompanyIDSeq,Q.CustomerIDSeq)
        and    convert(datetime,convert(varchar(30),Q.DealDeskQueuedDate,101)) >= @LDT_QueueStartDate
        and    convert(datetime,convert(varchar(30),Q.DealDeskQueuedDate,101)) <= @LDT_QueueEndDate
        and    Q.CompanyName like '%' + @IPVC_CustomerName + '%'
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
                and    Q1.DealDeskStatusCode   = 'SUB'
                and    Q1.QuoteIDSeq      = coalesce(@IPVC_QuoteIDSeq,Q1.QuoteIDSeq) 
                and    Q1.CustomerIDSeq   = coalesce(@IPVC_CompanyIDSeq,Q1.CustomerIDSeq)
                and    convert(datetime,convert(varchar(30),Q1.DealDeskQueuedDate,101)) >= @LDT_QueueStartDate
                and    convert(datetime,convert(varchar(30),Q1.DealDeskQueuedDate,101)) <= @LDT_QueueEndDate
                and    QSA.SalesAgentIDSeq     = coalesce(@IPBI_SalesRepID,QSA.SalesAgentIDSeq)
                Left Outer Join
                       SECURITY.dbo.[User] QSAU with (nolock)
                on     QSA.SalesAgentIDSeq     = QSAU.IDSeq 
                and    QSA.QuoteIDSeq          = coalesce(@IPVC_QuoteIDSeq,QSA.QuoteIDSeq)
                and    QSA.SalesAgentIDSeq     = coalesce(@IPBI_SalesRepID,QSA.SalesAgentIDSeq)
                where  Q1.QuoteIDSeq           = coalesce(@IPVC_QuoteIDSeq,Q1.QuoteIDSeq) 
                and    QSA.QuoteIDSeq          = coalesce(@IPVC_QuoteIDSeq,QSA.QuoteIDSeq)
                and    QSA.SalesAgentIDSeq     = coalesce(@IPBI_SalesRepID,QSA.SalesAgentIDSeq)
                group by QSA.QuoteIDSeq
               ) QSAO
        on   Q.QuoteIDSeq = QSAO.QuoteIDSeq
        and  coalesce(QSAO.SalesAgentIDSeq,-1) = coalesce(@IPBI_SalesRepID,coalesce(QSAO.SalesAgentIDSeq,-1))
        where  Q.DealDeskCurrentLevel > 0
        and    Q.DealDeskStatusCode   = 'SUB'
        and    Q.QuoteIDSeq      = coalesce(@IPVC_QuoteIDSeq,Q.QuoteIDSeq) 
        and    Q.CustomerIDSeq   = coalesce(@IPVC_CompanyIDSeq,Q.CustomerIDSeq)
        and    convert(datetime,convert(varchar(30),Q.DealDeskQueuedDate,101)) >= @LDT_QueueStartDate
        and    convert(datetime,convert(varchar(30),Q.DealDeskQueuedDate,101)) <= @LDT_QueueEndDate
        and    Q.CompanyName like '%' + @IPVC_CustomerName + '%'
        and   ((coalesce(Q.ModifiedByIDSeq,-1) = coalesce(@IPBI_ClientServiceRepID,coalesce(Q.ModifiedByIDSeq,-1)))
                  OR
               (coalesce(Q.CSRIDSeq,-1) = coalesce(@IPBI_ClientServiceRepID,coalesce(Q.CSRIDSeq,-1)))
              )
        and  coalesce(QSAO.SalesAgentIDSeq,-1) = coalesce(@IPBI_SalesRepID,coalesce(QSAO.SalesAgentIDSeq,-1))
       )
  select tablefinal.QuoteIDSeq,
         tablefinal.CompanyIDSeq,
         tablefinal.CompanyName,
         tablefinal.QuoteDescription,
         tablefinal.QuoteType,
		 tablefinal.PrePaidFlag,
		 tablefinal.ExternalQuoteIIFlag,
         tablefinal.QuoteStatus,
         tablefinal.DealDeskQueuedDate,
         tablefinal.DealDeskQueuedByUserName,
         tablefinal.DealDeskStatus,
         ----------------------------
         tablefinal.ILFListAmount,
         tablefinal.ILFDiscountAmount,
         tablefinal.ILFDiscountPercentage,
         tablefinal.ILFNetAmount,
         ----------------------------
         tablefinal.AccessListAmount,
         tablefinal.AccessDiscountAmount,
         tablefinal.AccessDiscountPercentage,
         tablefinal.AccessNetAmount,
         ----------------------------
         tablefinal.ClientServiceRepresentative,
         tablefinal.QuoteSalesRepresentative,
         tablefinal.QuoteCreatedByUserName,
         tablefinal.QuoteCreatedDate,
         tablefinal.QuoteModifiedByUserName,
         tablefinal.QuoteModifiedDate,
         tablefinal.TotalBatchCountForPaging
  from   tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
  order by tablefinal.RowNumber asc;
  -----------------------------------------------
END
GO
