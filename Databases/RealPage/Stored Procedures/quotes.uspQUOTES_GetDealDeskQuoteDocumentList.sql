SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_GetDealDeskQuoteDocumentList
-- Description     : This procedure gets the list of Deal Desk documents for a given Quote and CompanyIDSq
--
-- Input Parameters: As Below
-- 
-- OUTPUT          : A recordSet of Deal Desk Documents paths
--
--
--syntax           : 
/*
Exec QUOTES.dbo.uspQUOTES_GetDealDeskQuoteDocumentList @IPI_PageNumber=1,@IPI_RowsPerPage=5,
                                                       @IPVC_QuoteIDSeq='Q1104000100',
                                                       @IPVC_CompanyIDSeq='C0901002633',
                                                       @IPVC_DocumentType='DealDesk'
*/
-- Revision History:
-- Author          : SRS
-- 05/15/2011      : Stored Procedure Created.TFS : 267 : Deal Desk Project
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetDealDeskQuoteDocumentList] (@IPI_PageNumber                  int        =1,          ---> This is Page Number. Default is 1 and based on user click on page number
                                                                 @IPI_RowsPerPage                 int        =999999999,  ---> This is number of records that a single page can accomodate. 
                                                                                                                           --   Default is 5 rows per page. UI can pass different value based on UI realestate.
                                                                                                                           --   For Export to Excel list this value will be 999999999
                                                                 @IPVC_QuoteIDSeq                 varchar(50),            ---> This is the QuoteIDSeq that UI is Operating under. UI knows this Q number
                                                                 @IPVC_CompanyIDSeq               varchar(50)='',         ---> This is the CompanyIDSeq that UI is Operating under. UI knows this C number associated with Q number in question.
                                                                 @IPVC_QDocIDSeq                  varchar(50)='',         ---> Optional: This is the Unique Quote DocumentIDSeq. UI may pass this for more-->View if specific documentID record needs to retrieved.
                                                                 @IPVC_DocumentType               varchar(50)='DealDesk'  ---> This is Document Type that UI is looking for. For Deal Desk, it is going to be 'DealDesk'
                                                                )
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
         @IPVC_QDocIDSeq               = nullif(ltrim(rtrim(@IPVC_QDocIDSeq)),'');
  -----------------------------------------------------
  ;WITH tablefinal AS
       (Select QD.QDocIDSeq                                                           as QDocIDSeq,       ---> This is the Unique Primary Key that UI will hold in hidden variable and pass it for Update/Delete of document.
               QD.QuoteIDSeq                                                          as QuoteIDSeq,      ---> This is QuoteID
               QD.CompanyIDSeq                                                        as CompanyIDSeq,    ---> This is CompanyID associated with QuoteID
               QD.DocumentType                                                        as DocumentType,    ---> This is Document Type associated with Document. For Deal Desk, it will be 'DealDesk'
               QD.DocumentName                                                        as DocumentName,    ---> This is Short name identifying the document.
               QD.DocumentNote                                                        as DocumentNote,    --> This is Description or Notes associated with the document.
               QD.DocumentPath                                                        as DocumentPath,        --> This is partial document path leading to the document.
                                                                                                              --  eg: 'DealDesk\QuoteIdSeq_uniqueUIGeneratedRowGuid.doc'
                                                                                                               --   UI already knows main path from web.config \\servername\omsfilerepository\CompanyIDseq\'
               QD.ActiveFlag                                                          as ActiveFlag,          --> This is ActiveFlag identifying status of document. Not required to show in UI.
               (ltrim(rtrim(UC.FirstName + ' ' + UC.LastName))) collate SQL_Latin1_General_CP850_CI_AI
                                                                                      as DocumentCreatedByUserName,
               QD.CreatedDate                                                         as DocumentCreatedDate,
               (ltrim(rtrim(UM.FirstName + ' ' + UM.LastName))) collate SQL_Latin1_General_CP850_CI_AI
                                                                                      as DocumentModifiedByUserName,
               QD.ModifiedDate                                                        as DocumentModifiedDate,
               row_number() OVER(ORDER BY QD.QDocIDSeq DESC)                          as [RowNumber],
               Count(1) OVER()                                                        as TotalBatchCountForPaging
        from   Quotes.dbo.QuoteDocument QD with (nolock)
        Left Outer Join
               SECURITY.dbo.[User] UC with (nolock)
        on     QD.CreatedByIDSeq  = UC.IDSeq
        and    QD.QuoteIDSeq      = @IPVC_QuoteIDSeq
        Left Outer Join
               SECURITY.dbo.[User] UM with (nolock)
        on     QD.ModifiedByIDSeq = UM.IDSeq
        and    QD.QuoteIDSeq      = @IPVC_QuoteIDSeq
        where  QD.QuoteIDSeq      = @IPVC_QuoteIDSeq
        and    QD.QDocIDSeq       = coalesce(@IPVC_QDocIDSeq,QD.QDocIDSeq)
        and    QD.CompanyIDSeq    = coalesce(@IPVC_CompanyIDSeq,QD.CompanyIDSeq)
        and    QD.DocumentType    = coalesce(@IPVC_DocumentType,QD.DocumentType)
        and    QD.ActiveFlag      = 1 ---Always return only Active Documents.
       )
  select tablefinal.QDocIDSeq,            ---> This is the Unique Primary Key that UI will hold in hidden variable and pass it for Update/Delete of document.
         tablefinal.QuoteIDSeq,
         tablefinal.CompanyIDSeq,
         tablefinal.DocumentType,
         tablefinal.DocumentName,
         tablefinal.DocumentNote,
         tablefinal.DocumentPath,         
         ----------------------------
         tablefinal.DocumentCreatedByUserName,
         tablefinal.DocumentCreatedDate,
         tablefinal.DocumentModifiedByUserName,
         tablefinal.DocumentModifiedDate,
         tablefinal.TotalBatchCountForPaging
  from   tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
  order by tablefinal.RowNumber asc;
  -----------------------------------------------
END
GO
