SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspCREDITS_CreditListCount]
-- Description     : This procedure returns record count of the Credit records 
--                   based on the search parameters
-- Input Parameters:  1.  @IPI_RowsPerPage as int,
--                    2.  @IPI_PageNumber as int,
--                    3.  @IPVC_InvoiceIDSeq as varchar(22),
--                    4.  @IPVC_CustomerName as varchar(100),
--                    5.  @IPVC_RequestedBy as varchar(70),
--                    6.  @IPVC_RequestedDate as varchar(12),  
--                    7.  @IPVC_ProductCode varchar(30),
--                    8.  @IPVC_AccountID varchar(22),
--                    9.  @IPVC_Status  varchar(5),
--                    10. @IPVC_PropertyName varchar(100),
--                    11. @IPB_PropertyIncluded bit,
--                    12. @IPI_DateSelected int
--                    13. @IPI_CrReverse int,
--					  14. @IPI_PrintFlag varchar(5),
--                    15. @IPVC_InvoiceID varchar(22),
--					  16. @IPVC_CountryCode     varchar(20)=''  
-- 
-- OUTPUT          : RecordSet of ID,AccountName,City,State,Zip,AccountTypeCode,Units,PPU
-- Code Example    : Exec INVOICES.[dbo].[uspCREDITS_CreditListCount] @IPI_RowsPerPage = 15,
--                                                                @IPI_PageNumber = 1,
--                                                                @IPVC_InvoiceIDSeq = '',
--                                                                @IPVC_CustomerName = '',
--                                                                @IPVC_RequestedBy = '',
--                                                                @IPVC_RequestedDate = '',  
--                                                                @IPVC_ProductCode = '',
--                                                                @IPVC_AccountID = '',
--                                                                @IPVC_Status  = '',
--                                                                @IPVC_PropertyName = '',
--                                                                @IPB_PropertyIncluded = 1,
--                                                                @IPI_DateSelected = 1,
--                                                                @IPI_CrReverse =0,
--													              @IPI_PrintFlag =0,
--                                                                @IPVC_InvoiceID ='',
--												                  @IPVC_CountryCode =''  
-- 
-- Revision History:
-- Author          : KRK, SRA Systems Limited 
-- 05/11/2006      : Modified by STA. Modified as per the latest schema change.
-- 04/22/2008      : Defect #4950
-- 06/16/2008      : Modified by Shashi Bhushan, to include the new parameter @IPI_CrReverse as in
--                   uspCREDITS_CreditList procedure
-- 12/13/2010	   : Damodar N (Defect# :8642 Replaced @IPVC_RequestedBy with @IPVC_ProcessedBy and Removed @IPI_PrintFlag )
-- 10/19/2011      : Mahaboob ( TFS #1151 - CountryCode has been added in the Search criteria. )
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspCREDITS_CreditListCount](
												                           
                                                    @IPVC_CompanyIDSeq as varchar(22),
                                                   -- @IPVC_CustomerName as varchar(100),
                                                    @IPVC_EpicorID        varchar(50),
                                                    @IPVC_ProcessedBy as varchar(150),
                                                    @IPVC_RequestedDate as varchar(12),  
--                                                    @IPVC_ProductCode varchar(30),
                                                    @IPVC_AccountID varchar(22),
                                                    @IPVC_Status  varchar(5),
                                                    @IPVC_PropertyName varchar(100),
                                                    @IPB_PropertyIncluded bit,
                                                    @IPI_DateSelected int,
                                                    @IPI_CrReverse int,
--													@IPI_PrintFlag varchar(5),
                                                    @IPVC_InvoiceID varchar(22),
													@IPVC_CountryCode     varchar(20)=''
                                                ) 

AS
BEGIN-->Main Begin
declare @customerid   varchar(50);
select  @customerid = (select top 1 companyidseq from INVOICES.dbo.Invoice I with (nolock) 
												 inner join Invoices.dbo.CreditMemo CM with (nolock)
												 on   I.InvoiceIdSeq = CM.InvoiceIdSeq
												 where ((I.accountidseq = @IPVC_AccountID)
												 or  (I.EpicorCustomerCode  = @IPVC_EpicorID ))
												 AND  I.AccountTypeCode = 'AHOFF')

IF ((@IPVC_PropertyName = '') and (@customerid is null) and (@IPVC_CompanyIDSeq =''))
BEGIN
set @IPB_PropertyIncluded = 1
END       
  
--set @IPVC_AccountID = nullif(@IPVC_AccountID,'');
set @customerid		   = nullif(@customerid,''); 			

  ----------------------------------------------------------------------------
  --Final Select 
  ----------------------------------------------------------------------------
  WITH tablefinal AS 
       ----------------------------------------------------------  
       (SELECT tableinner.*
        FROM
           ---------------------------------------------------------- 
          (select  *
           from
             ---------------------------------------------------------- 
            (SELECT        CM.CreditMemoIDSeq            as [ID],
                           CM.ApplyToCreditMemoIDSeq     as ApplyToCreditMemoIDSeq,
                           CM.CreditMemoReversalFlag     as CreditMemoReversalFlag                          

              FROM          Invoices.dbo.CreditMemo CM
            	
              INNER JOIN    Invoices.dbo.CreditStatusType CST
                ON          CM.CreditStatusCode = CST.Code

              INNER JOIN    Invoices.dbo.Invoice I
                ON          CM.InvoiceIDSeq = I.InvoiceIDSeq

              
                WHERE      (((@IPVC_EpicorID = '' OR I.EpicorCustomerCode LIKE '%' + @IPVC_EpicorID + '%'))-- and @IPI_PropertyIncluded = 0 AND (PropertyIDSeq is null))    )  
              or  ((@IPB_PropertyIncluded = 1) AND I.CompanyIDSeq  = coalesce(@customerid,I.CompanyIDSeq) AND (@customerid is not null)))  
              AND (((I.CompanyName  LIKE '%' + @IPVC_PropertyName + '%') and @IPB_PropertyIncluded = 0 AND (PropertyIDSeq is null))    
              OR  ((I.CompanyName  LIKE '%' + @IPVC_PropertyName + '%') or (I.PropertyName LIKE '%' + @IPVC_PropertyName + '%')) and (@IPB_PropertyIncluded = 1))      
              AND ((@IPVC_ProcessedBy     = '')  or (CM.CreatedBy      like '%' + @IPVC_ProcessedBy + '%'))     
              AND ((@IPVC_Status          = '')  or (CM.CreditStatusCode like '%' + @IPVC_Status + '%'))     
              AND (((@IPVC_AccountID       = '')  or (I.AccountIDSeq      = @IPVC_AccountID))   
              or  ((@IPB_PropertyIncluded = 1) AND I.CompanyIDSeq  = coalesce(@customerid,I.CompanyIDSeq) AND (@customerid is not null)))  
              AND ((@IPVC_CompanyIDSeq    = '')  or (I.CompanyIDSeq     = @IPVC_CompanyIDSeq ))    
              AND ((@IPVC_InvoiceID    = '')  or (CM.InvoiceIDSeq     = @IPVC_InvoiceID )) 
			  AND ((@IPVC_CountryCode    = '')  or (I.BillToCountryCode     = @IPVC_CountryCode ))      
--              AND ((@IPI_PrintFlag='')or  (CM.PrintFlag LIKE '%' + @IPI_PrintFlag + '%'))     
              AND (       
                                  (@IPI_DateSelected = 4 and convert(varchar(12),CM.RequestedDate,101) = @IPVC_RequestedDate)    
                                   or    
                                  (@IPI_DateSelected = 1 and convert(varchar(12),CM.RequestedDate,101) = convert(varchar(12),getdate(),101))           
                                   or    
                                  (@IPI_DateSelected = 2 and CM.RequestedDate between (dateadd(week,-1,getdate())) and getdate())            
                                   or    
                                  (@IPI_DateSelected = 3 and CM.RequestedDate between (dateadd(m,-1,getdate())) and getdate())             
                                   or    
                                   @IPI_DateSelected = 0    
                          )    
--                AND         (@IPVC_ProductCode = '' or exists
--                              (
--                                SELECT * FROM CreditMemoItem CMI, InvoiceItem II, InvoiceGroup IG
--						                         where IG.InvoiceIDSeq = I.InvoiceIDSeq
--                                     and IG.IDSeq = II.InvoiceGroupIDSeq
--                                     and CMI.InvoiceItemIDSeq = II.IDSeq 
--							                       and II.ProductCode like '%'+@IPVC_ProductCode+'%' 
--                              )
--                              )
               -------------------------------------------------------------
              )source
             ----------------------------------------------------------------
             )tableinner
            -------------------------------------------------------------------
          )
         --------------------------------------------------------------------------
		SELECT  tablefinal.ID                       as CreditID,
				tablefinal.ApplyToCreditMemoIDSeq   as ApplyToCreditMemoIDSeq,
				tablefinal.CreditMemoReversalFlag   as CreditMemoReversalFlag
		INTO    #temp_tbl
		FROM    tablefinal 
  ----------------------------------------------------------------------------
  --Retrieving Final Recordset
  ----------------------------------------------------------------------------
   IF (@IPI_CrReverse = 1)
     BEGIN
       SELECT CreditID                 as CreditID
       INTO   #temp_Finaltbl      
	   FROM   #temp_tbl 
       WHERE  CreditMemoReversalFlag=0
         AND  CreditID in (select ApplyToCreditMemoIDSeq from #temp_tbl)

       SELECT Count(CreditID)
       FROM   #temp_Finaltbl

       DROP TABLE #temp_Finaltbl					
     END
   ELSE 
     IF (@IPI_CrReverse = 0)
       BEGIN
         SELECT  CreditID
         INTO    #temp_Finaltbl2
         FROM    #temp_tbl 
         WHERE   CreditID NOT IN (
                                  SELECT ApplyToCreditMemoIDSeq 
                                  FROM   #temp_tbl 
                                  WHERE  ApplyToCreditMemoIDSeq IS NOT NULL
                                 )
         SELECT Count(CreditID)
         FROM   #temp_Finaltbl2

         DROP TABLE #temp_Finaltbl2					
       END

   DROP TABLE #temp_tbl
                        
END-->Main End   
GO
