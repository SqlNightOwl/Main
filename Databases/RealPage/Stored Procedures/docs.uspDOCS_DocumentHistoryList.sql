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


Example: EXEC uspDOCS_DocumentHistoryList

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_DocumentHistoryList](                  
                                                               @IPVC_DocumentIDSeq   varchar(22)  
                                                               ) WITH RECOMPILE    
AS
BEGIN
 
  ----------------------------------------------------------------
     SELECT    
                   DocHistory.IDSeq                               AS DocumentHistoryIDSeq,  
                   DocHistory.DocumentIDSeq                       AS DocumentIDSeq,
                   DC.IDSeq                                       AS DocumentClassIDSeq,  
                   PF.Name										  AS FamilyCode,  
                   DocStatus.Name								  AS StatusName,  
                   Cust.Name                                      AS CompanyName,  
                   DocHistory.ModifiedBy                          AS ModifiedBy,  
                   DocHistory.CreatedDate                         AS CreatedDate,
				   DocHistory.ModifiedDate                        AS ModifiedDate,  
                   DocHistory.Name                                AS [Name], 
                   CASE WHEN DocSource.Name = 'Order Management System' THEN 'OMS'
                   ELSE DocSource.Name   
                   END                                            AS SourceName,
                   DocHistory.IterationCount                      AS IterationCount,
                   DI.Name										  AS [Type],
                   DocHistory.DocumentPath                        AS DocumentPath 
                                                                     
                                                                     
         FROM  
           Docs.dbo.[DocumentHistory] DocHistory WITH (NOLOCK)   
           right outer join Docs..Status DocStatus       ON   DocStatus.code =  DocHistory.Statuscode  
		   right outer join Docs..DocumentClass DC       ON   DC.IDseq = DocHistory.DocumentClassIDSeq
           right outer join Docs..Source DocSource       ON   DC.SourceCode   = DocSource.Code
           right outer join Docs..Item DI                ON   DC.ItemCode = DI.Code  
           left outer join Docs..Contract DCT            ON   DCT.DocumentIDSeq = DocHistory.DocumentIDSeq  
           left  outer join Products..Family PF          ON   PF.Code  = DCT.FamilyCode  
           left outer join Customers..Company Cust       ON   Cust.IdSeq = DocHistory.CompanyIdSeq  
           
           WHERE   
             ((@IPVC_DocumentIDSeq <> '') and (DocHistory.DocumentIDSeq = @IPVC_DocumentIDSeq)) OR (@IPVC_DocumentIDSeq =  '')  
              
 END 
GO
