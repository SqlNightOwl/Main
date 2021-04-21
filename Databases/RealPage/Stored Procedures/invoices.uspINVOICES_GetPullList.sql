SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : [uspINVOICES_GetPullList]
-- Description     : This procedure inserts Account for a Pull List pertaining to passed AccountID
-- Input Parameters: 1. @IPVC_InvoiceID   AS varchar(10)
--                   
-- OUTPUT          : RecordSet of IDSEq is generated
--
--                   
-- Code Example    : Exec Invoices.dbo.uspINVOICES_GetPullList 1, 20,'','',''
-- 
-- 
-- Revision History:
-- Author          : Naval Kishore SIngh
-- 23/09/2007      : Stored Procedure Created.

-- Revision History:
-- Author          : Anand Chakravarthy
-- 03/17/2009      : Stored Procedure Modified.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetPullList](
														@IPI_PageNumber       int , 
														@IPI_RowsPerPage      int ,
														@IPVC_AccountIDSeq    varchar(20), 
														@ModifiedByIDSeq	  varchar(20),
														@IPVC_Title           varchar(100) 
																		
													)
AS
BEGIN      
  set nocount on;
  ----------------------------------------------------------------
  ---Get Records based on search criteria
  ----------------------------------------------------------------
  WITH tablefinal AS 
       (select tableinner.*
        from
          (select  row_number() over(order by source.PullListIDSeq) as RowNumber,
                   source.*
           from
            (select distinct 
                convert(varchar(50),p.IDSeq)        as PullListIDSeq, 
				p.title								as Title,               
                p.Description                       as Description, 
                Customers.dbo.fnGetUserNamefromID(p.modifiedByIDSEQ)  as ModifiedBy
               
            from    invoices..PullList p with (nolock)              
            inner join  invoices..PullListAccounts pa with (nolock)
            on        p.IDSeq = pa.PullListIDSeq 
            and       pa.AccountIdSeq              like '%'+ @IPVC_AccountIDSeq   + '%'
--          
            and       p.ModifiedByIDSeq            like '%'+ @ModifiedByIDSeq         + '%' 
            and       p.title                      like '%'+ @IPVC_Title   + '%'                                 
--            inner join  Customers..Account acct with (nolock)
--            on        acct.CompanyIDSeq = pa.AccountIdSeq
--           
            ) source
          ) tableinner
       where tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
       and   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       ) 
       select  tablefinal.RowNumber,
               tablefinal.PullListIDSeq  as PullListIDSeq,
               tablefinal.Title			 as Title,
               tablefinal.Description	 as Description,
               tablefinal.ModifiedBy	 as ModifiedBy
		from     tablefinal

 ----------------------------------------------------------------  
  --- The below portion is to get the record count for paging in UI 
  ----------------------------------------------------------------  
  SET ROWCOUNT 0;  
  WITH tablefinalcount AS   
  ----------------------------------------------------------------------------    
       (SELECT count(tableinner.[PullListIDSeq])   as [Count]  
        FROM  
         ----------------------------------------------------------------------------  
         (select  source.*  
          from  
            (select distinct 
                convert(varchar(50),p.IDSeq)        as PullListIDSeq, 
				p.title								as Title,               
                p.Description                       as Description, 
                Customers.dbo.fnGetUserNamefromID(p.modifiedByIDSEQ)  as ModifiedBy
               
            from    invoices..PullList p with (nolock)              
            inner join  invoices..PullListAccounts pa with (nolock)
            on        p.IDSeq = pa.PullListIDSeq 
            and       pa.AccountIdSeq              like '%'+ @IPVC_AccountIDSeq   + '%'
            and       p.ModifiedByIDSeq            like '%'+ @ModifiedByIDSeq         + '%' 
            and       p.title                      like '%'+ @IPVC_Title   + '%'                                 
           
            ) source
          ) tableinner
    )  
    SELECT  tablefinalcount.[Count]              
    FROM    tablefinalcount  
  
END  
  
      


GO
