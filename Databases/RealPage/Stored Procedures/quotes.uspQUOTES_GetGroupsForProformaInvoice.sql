SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-------------------------------------------------------------------------------------------------------------------------      
-- Database  Name  : QUOTES      
-- Procedure Name  : uspQUOTES_GetGroupsForProformaInvoice      
-- Description     : This procedure returns one record per each Group in Quote
--                   For each row of the resultset, call QUOTES.dbo.uspQUOTES_Rep_GetProformaInvoiceDetail
--                    to get one proforma Invoice for each Group and then consolidate into One single PDF File.
-- Input Parameters: @IPVC_QuoteID
--            
-- Code Example    : 
/*
 Exec QUOTES.dbo.uspQUOTES_GetGroupsForProformaInvoice @IPVC_QuoteID='Q0905000433'
 Exec QUOTES.dbo.uspQUOTES_GetGroupsForProformaInvoice @IPVC_QuoteID='Q1005000682'
 Exec QUOTES.dbo.uspQUOTES_GetGroupsForProformaInvoice @IPVC_QuoteID='Q1008000968'
 Exec QUOTES.dbo.uspQUOTES_GetGroupsForProformaInvoice @IPVC_QuoteID='Q1008001100'

*/
--       
--       
-- Revision History:      
-- Author          : SRS      
-- 08/26/2010      : Stored Procedure Created. Defect 8015
------------------------------------------------------------------------------------------------------ 
CREATE PROCEDURE [quotes].[uspQUOTES_GetGroupsForProformaInvoice] (@IPVC_QuoteID        varchar(50)
                                                                )
AS
BEGIN
  set nocount on;
  ----------------------------------------------------------------------------------------------------
  ;with FinalResults 
  AS   (
         select Q.QuoteIDSeq                                                               as QuoteID,
                QG.IDSeq                                                                   as GroupID,
                Q.CustomerIDSeq                                                            as CompanyID,
                coalesce(GP.PropertyIDSeq,Q.CustomerIDSeq)                                 as OMSID,
                ROW_NUMBER() OVER (
                                   PARTITION BY Q.QuoteIDSeq,QG.IDSeq,Q.CustomerIDSeq
                                   ORDER BY QG.IDSeq,coalesce(PRP.Name,'Abcdef') ASC
                                  )                                                        as  RowNumber
         from   Quotes.dbo.Quote   Q   with (nolock)
         inner Join
                Quotes.dbo.[Group] QG  with (nolock)
         on     Q.QuoteIDSeq     = QG.QuoteIDSeq
         and    Q.CustomerIDSeq  = QG.CustomerIDSeq
         and    Q.QuoteIDSeq     = @IPVC_QuoteID
         and    QG.QuoteIDSeq    = @IPVC_QuoteID
         left outer join
                Quotes.dbo.GroupProperties GP with (nolock)
         on     Q.QuoteIDSeq     = GP.QuoteIDSeq
         and    Q.CustomerIDSeq  = GP.CustomerIDSeq
         and    QG.QuoteIDSeq    = GP.QuoteIDSeq
         and    QG.CustomerIDSeq = GP.CustomerIDSeq
         and    QG.IDSeq         = GP.GroupIDSeq
         and    Q.QuoteIDSeq     = @IPVC_QuoteID
         and    QG.QuoteIDSeq    = @IPVC_QuoteID
         and    GP.QuoteIDSeq    = @IPVC_QuoteID
         left outer join
                Customers.dbo.Property PRP with (nolock)
         on     GP.PropertyIDSeq = PRP.IDSeq
         where  Q.QuoteIDSeq     = @IPVC_QuoteID
         and    QG.QuoteIDSeq    = @IPVC_QuoteID         
       )
  select FinalResults.QuoteID,               ----> Pass this as parameter @IPVC_QuoteID for QUOTES.dbo.uspQUOTES_Rep_GetProformaInvoiceDetail
         FinalResults.GroupID,               ----> Pass this as parameter @IPBI_GroupID for QUOTES.dbo.uspQUOTES_Rep_GetProformaInvoiceDetail
         FinalResults.CompanyID,             ----> Pass this as parameter @IPVC_CompanyID for QUOTES.dbo.uspQUOTES_Rep_GetProformaInvoiceDetail  
         FinalResults.OMSID                  ----> Pass this as parameter @IPVC_OMSID for QUOTES.dbo.uspQUOTES_Rep_GetProformaInvoiceDetail
  from   FinalResults
  where  RowNumber=1
END
GO
