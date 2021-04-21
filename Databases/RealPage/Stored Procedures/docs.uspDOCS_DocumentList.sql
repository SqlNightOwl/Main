SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_DocumentList

Purpose    :  Gets data from Document table.
             
Parameters : 

Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_DocumentList

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/     
CREATE Procedure [docs].[uspDOCS_DocumentList](                 @IPI_PageNumber      int,  
                                                               @IPI_RowsPerPage     int,  
                                                               @IPVC_CompanyIDSeq   varchar(22), 
                                                               @IPVC_AccountIDSeq    varchar(22),
                                                               @IPVC_QuoteIDSeq     varchar(22),  
                                                               @IPVC_InvoiceIDSeq   varchar(22),  
                                                               @IPVC_OrderIDSeq     varchar(22),  
                                                               @IPVC_DocumentType   varchar(5),   
                                                               @IPVC_FamilyCode     varchar(4000),  
                                                               @IPVC_AccountName    varchar(70),  
                                                               @IPVC_FromDate        varchar(20),  
                                                               @IPVC_ToDate        varchar(20),  
                                                               @IPVC_CreditIDSeq    varchar(22)   
                                                              ) WITH RECOMPILE    
AS
BEGIN
  set nocount on;
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;

  if (@IPVC_FromDate <> '' and isdate(@IPVC_FromDate) <> 1)
   begin
	 return -1
   end

  if (@IPVC_ToDate <> '' and isdate(@IPVC_ToDate) <> 1)
   begin
	 return -1
   end;
  ----------------------------------------------------------------
  WITH Temp_DocumentList AS (  
    SELECT    
      Count(*) OVER() as _TotalRows_, -- Adding this for Paging.  This will avoid multiple hits to table to get total count.  
      ROW_NUMBER() OVER (ORDER BY  doc.DocumentIDSeq)AS RowNumber,       
                   Doc.DocumentIDSeq                              AS DocumentIDSeq,  
                   DC.IDSeq                                       AS DocumentClassIDSeq,
                   Doc.IterationCount                             AS IterationCount,  
                   Doc.QuoteIDSeq                                 AS QuoteIDSeq,  
                   Doc.InvoiceIDSeq                               AS InvoiceIDSeq,  
                   Doc.CreditMemoIdSeq                            AS CreditIdSeq,  
                   DI.Name										  AS [Type],
                   CASE WHEN docScope.Name = 'Management Company' THEN 'PMC'
                   ELSE docScope.Name
                   END  
                                  								  AS ScopeName,   
                   PF.Name										  AS FamilyCode,  
                   DocStatus.Name								  AS StatusName,  
                   Cust.Name                                      AS CompanyName,  
                   CASE WHEN doc.InvoiceIDSeq is not null THEN ( '(' + doc.InvoiceIDSeq + ')')
                   WHEN doc.QuoteIDSeq is not null THEN ('(' + doc.QuoteIDSeq + ')')
                   WHEN doc.CreditMemoIdSeq is not null THEN ('(' + doc.CreditMemoIdSeq + ')')
                   ELSE ''
                   END                                             AS FormId,
                   doc.Description                                 AS Description,
                   isnull(DCT.ExecutedDate,'') AS DateSigned,  
                   Doc.CreatedBy                                  AS CreatedBy,
                   CASE WHEN Doc.StatusCode = 'CTD' THEN  DOC.CreatedDate
                   WHEN Doc.StatusCode = 'ETD' THEN DOC.ModifiedDate
                   WHEN Doc.StatusCode = 'SUB' THEN DCT.SubmittedDate
                   WHEN Doc.StatusCode = 'RCD' THEN DCT.ReceivedDate
                   WHEN Doc.StatusCode = 'APD' THEN DCT.ExecutedDate
                   ELSE Doc.CreatedDate 
                   END					                          AS CreatedDate,
                   --coalesce(Doc.CreatedDate,DCT.BeginDate,DCT.ExecutedDate) AS CreatedDate,  
                   Doc.Name                                       AS [Name],  
                   DCT.IDSeq                                      AS ContractIDSeq,  
                   Doc.DocumentPath                               AS DocumentPath,
                   DC.StructureCode                               AS StructureCode, 
                   Doc.AttachmentFlag                             AS AttachmentFlag
         FROM  
           Docs.dbo.[Document] Doc WITH (NOLOCK)   
           right outer join Docs.dbo.Scope docScope      ON   docScope.code  = doc.scopecode  
           right outer join Docs..Status DocStatus       ON   DocStatus.code =  doc.Statuscode  
		   right outer join Docs..DocumentClass DC       ON   DC.IDseq = doc.DocumentClassIDSeq
           right outer join Docs..Item DI                ON   DC.ItemCode = DI.Code  
           left outer join Docs..Contract DCT           ON   DCT.DocumentIDSeq = doc.DocumentIDSeq  
           left  outer join Products..Family PF          ON   PF.Code  = DCT.FamilyCode  
           left outer join Customers..Company Cust      ON   Cust.IdSeq = doc.CompanyIdSeq  
        WHERE   
             (((@IPVC_CompanyIDSeq <> '') and (Cust.IDSeq = @IPVC_CompanyIDSeq)) OR (@IPVC_CompanyIDSeq =  ''))  
        AND  (((@IPVC_AccountName <> '') and (Cust.Name like '%' + @IPVC_AccountName + '%'))OR (@IPVC_AccountName =  ''))  
        AND  (((@IPVC_FamilyCode <> '') and (PF.Name like '%' + @IPVC_FamilyCode + '%')) OR (@IPVC_FamilyCode =  ''))  
        AND  (((@IPVC_DocumentType <> '') and (DI.Code like '%' + @IPVC_DocumentType + '%')) OR (@IPVC_DocumentType =  ''))
        AND  (((@IPVC_AccountIDSeq <> '') and (Doc.AccountIDSeq like '%' + @IPVC_AccountIDSeq + '%'))OR (@IPVC_AccountIDSeq =  ''))  
        AND  (((@IPVC_OrderIDSeq <> '') and (Doc.OrderIDSeq like '%' + @IPVC_OrderIDSeq + '%')) OR (@IPVC_OrderIDSeq =  ''))
        AND  (((@IPVC_InvoiceIDSeq <> '') and (Doc.InvoiceIDSeq like '%' + @IPVC_InvoiceIDSeq + '%')) OR (@IPVC_InvoiceIDSeq =  ''))  
        AND  (((@IPVC_QuoteIDSeq <> '') and (Doc.QuoteIDSeq like '%' + @IPVC_QuoteIDSeq + '%'))  OR (@IPVC_QuoteIDSeq =  ''))  
        AND  (((@IPVC_CreditIDSeq <> '') and (Doc.CreditMemoIDSeq like '%' + @IPVC_CreditIDSeq + '%')) OR (@IPVC_CreditIDSeq =  ''))  
        AND  ((@IPVC_FromDate = '') OR (convert(varchar(12),Doc.CreatedDate,101)) >= convert(datetime,@IPVC_FromDate,101))
        AND  ((@IPVC_ToDate = '') OR (convert(varchar(12),Doc.CreatedDate,101)) <= convert(datetime,@IPVC_ToDate,101)))  
              
   SELECT    
      *  
    FROM  
      Temp_DocumentList  
      
    WHERE   
      RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage  
      and RowNumber <= (@IPI_PageNumber)  * @IPI_RowsPerPage  
       
  
  
END  
  
 
GO
