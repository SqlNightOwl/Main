SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : QUOTES       
-- Procedure Name  : uspQUOTES_Rep_AgingSummaryByPMCName      
-- Description     : This procedure gets Quote Summary Details based on Customer. And this is based
--					 on the Excel File 'Quotes Aging Summary_By PMC Name.xls'     
-- Input Parameters: Optional except @IPD_StartDate and @IPD_EndDate
-- Code Example    : Exec Quotes.dbo.uspQUOTES_Rep_AgingSummaryByPMCName @IPD_EndDate = '04/16/2008'
-- Revision History:      
-- Author          : Shashi Bhushan      
-- 07/24/2007      : Stored Procedure Created.    
-- 08/02/2007      : SRS :  Queries Changed to reflect correct data.  
------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspQUOTES_Rep_AgingSummaryByPMCName] 
(
 @IPVC_CompanyID     varchar(50)  = '',
 @IPD_EndDate        datetime     = '',
 @IPVC_PlatformCode  varchar(3)   = '',
 @IPVC_FamilyCode    varchar(3)   = '',
 @IPVC_CategoryCode  varchar(3)   = '',
 @IPVC_ProductName   varchar(255) = '',
 @IPVC_CustomerName  varchar(100) = '',
 @IPC_AccountID      varchar(50)  = '',
 @IPC_PropertyID     varchar(50)  = '',
 @IPI_AccountManager bigint       = '',
 @IPI_CreatedBy      bigint       = ''
)      
as      
BEGIN         
  Set nocount on  
  --------------------------------------------------------------------------
  set @IPVC_CompanyID     = nullif(@IPVC_CompanyID,'')
  set @IPVC_PlatformCode  = nullif(@IPVC_PlatformCode,'')
  set @IPVC_FamilyCode    = nullif(@IPVC_FamilyCode,'')
  set @IPVC_CategoryCode  = nullif(@IPVC_CategoryCode,'')
  set @IPVC_ProductName   = @IPVC_ProductName
  set @IPVC_CustomerName  = @IPVC_CustomerName
  set @IPC_AccountID      = nullif(@IPC_AccountID,'')
  set @IPC_PropertyID     = nullif(@IPC_PropertyID,'')
  set @IPI_AccountManager = nullif(@IPI_AccountManager,'')
  set @IPI_CreatedBy      = nullif(@IPI_CreatedBy,'') 
--------------------------------------------------------------------------        
  --Initialize Local Variables
  -- This code is commented as these fields are mandatory from UI but 
  -- can be un-commented and used while testing the procedure
	
	/*
	  if (@IPD_EndDate is null or @IPD_EndDate = '')
	  begin
		select @IPD_EndDate = CONVERT(VARCHAR(50),getdate(),101)
	  end
	  if (@IPD_StartDate is null or @IPD_StartDate = '')
	  begin
		select @IPD_StartDate = CONVERT(VARCHAR(50),getdate()-90,101)
	  end
	*/
-------------------------------------------------------------------------- 
  -- An AccountID when passed and not null, will belong either to a company
  -- or property. Hence the following Select will suffice.
  If (@IPC_AccountID is not null and @IPC_AccountID <> '')
  begin
    Select @IPVC_CompanyID = A.CompanyIDSeq,
           @IPC_PropertyID = A.PropertyIDSeq
    from   Customers.dbo.Account A with (nolock)
    where  A.IDSeq = @IPC_AccountID
  end
--------------------------------------------------------------------------
--Declaring local table variables          
--------------------------------------------------------------------------      
  Declare @LT_TempQuoteAgeSummary  Table  
(
 companyid        varchar(50), 
 companyname      varchar(255),
 quotestatuscode  varchar(20),
 ageingbucket     varchar(50),
 bucketcount      bigint,
 bucketvalue      money
)

Declare @LT_FinalAgeQuoteSummary Table 
(
 sortseq               bigint not null identity(1,1),
 companyid             varchar(50), 
 companyname           varchar(255),
 NS_30_Quotes          bigint,
 NS_30_QuoteValue      numeric(18,2) null default 0.00,
 S_30_Quotes           bigint,
 S_30_QuoteValue       numeric(18,2) null default 0.00,

 NS_30to90_Quotes      bigint,
 NS_30to90_QuoteValue  numeric(18,2) null default 0.00,
 S_30to90_Quotes       bigint,
 S_30to90_QuoteValue   numeric(18,2) null default 0.00,

 NS_Above90_Quotes     bigint,
 NS_Above90_QuoteValue numeric(18,2) null default 0.00,
 S_Above90_Quotes      bigint,
 S_Above90_QuoteValue  numeric(18,2) null default 0.00
)  
-------------------------------------------------------------------------- 
--Get top level records from Quotes.dbo.Quote that qualify for ageing.
---         that does not have Quotestatuscode = 'CNL' -- CNL is Cancelled
---                        and QuoteStatuscode = 'APR' -- APR is Approved.
-- Note: Cancelled and Approved Quotes do not Age with time.
----------------------------------------------------------------------------
  Insert Into @LT_TempQuoteAgeSummary(companyid,companyname,quotestatuscode,ageingbucket,bucketcount,bucketvalue)
  Select Q.customeridseq                                                           as companyid,
         C.Name                                                                    as CompanyName,
         (case when (Q.QuoteStatusCode = 'NSU')
                then 'NOTSUBMITTED'
              when (Q.QuoteStatusCode = 'SUB')
                then 'SUBMITTED'
          end)                                                                      as quotestatuscode,
         (case when (datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) <= 30)     then '00-30'
               when (datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) > 30
                     and datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) <= 90) then '30-90'
               when (datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) > 90)      then '90-900'
               else '0'
         end)                                                                       as ageingbucket,
        count(distinct Q.Quoteidseq)                                                as bucketcount,
        
        convert(NUMERIC(30,2),sum(Q.ILFNetExtYearChargeAmount)+
                              sum(Q.AccessNetExtYear1ChargeAmount)
               )                                                                    as bucketvalue
  From       QUOTES.dbo.quote      Q with (nolock) 
  inner join CUSTOMERS.dbo.Company C with (nolock)  
  -----------------------------------------------------------------------------------
  on         (Q.Quotestatuscode <> 'CNL' and Q.Quotestatuscode <> 'APR')
  and Year(Q.CreateDate) = Year(@IPD_EndDate)
  -----------------------------------------------------------------------------------
  and        Q.customeridseq = C.IDSeq
  and        Q.customeridseq = (case when (@IPVC_CompanyID <> '' and @IPVC_CompanyID is not null)
                                     then @IPVC_CompanyID
                                else Q.customeridseq
                               end)
  and C.Name like '%' + @IPVC_CustomerName+ '%' 
  and ((@IPVC_ProductName is null and @IPVC_PlatformCode is null and @IPVC_FamilyCode is null and @IPVC_CategoryCode is null) 
		or EXISTS(select TOP 1 1 
                          from       QUOTES.dbo.QuoteItem QI with (nolock) 
			  inner join PRODUCTS.dbo.Product P  with (nolock)                      
                          On    QI.QuoteIDSeq = Q.QuoteIDSeq 
                          and   P.Code=QI.ProductCode 
                          and   P.PriceVersion=QI.PriceVersion				  
		          and   P.DisplayName like '%' + @IPVC_ProductName + '%'
			  and   P.PlatformCode = isnull(@IPVC_PlatformCode, P.PlatformCode)
			  and   P.FamilyCode   = isnull(@IPVC_FamilyCode, P.FamilyCode)
			  and   P.CategoryCode = isnull(@IPVC_CategoryCode, P.CategoryCode)
                         )
        )
 and ((@IPC_PropertyID is null) or EXISTS(select Top 1 1 
                                          from  Quotes.dbo.GroupProperties GP with (nolock) 
					   where GP.QuoteIDSeq   = Q.QuoteIDSeq 
                                          and   GP.PropertyIDSeq= @IPC_PropertyID
											)
      )  
  and ((@IPI_AccountManager is null) or EXISTS(select Top 1 1  
	 				       from  Quotes.dbo.QuoteSaleAgent QSA (nolock)
					       where QSA.QuoteIDSeq=Q.QuoteIDSeq 
                                               and   QSA.SalesAgentIDSeq = @IPI_AccountManager
                                               )
      )
  and ((@IPI_CreatedBy is null) or EXISTS(select Top 1 1 
                                          from Quotes.dbo.QuoteItem QI (nolock)
					  where QI.QuoteIDSeq = Q.QuoteIDSeq 
                                          and   Q.CreatedByIDSeq = @IPI_CreatedBy
                                         )
       )   
  Group by Q.customeridseq,C.Name,
           (case when (datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) <= 30)     then '00-30'
                 when (datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) > 30
                       and datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) <= 90) then '30-90'
                 when (datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) > 90)      then '90-900'
                 else '0'
            end),
            (case when (Q.QuoteStatusCode = 'NSU')
                then 'NOTSUBMITTED'
              when (Q.QuoteStatusCode = 'SUB')
                then 'SUBMITTED'
             end)            
  --------------------------------------------------------------------------
  --Transposing Records to fall under the right bucket.
  --------------------------------------------------------------------------
  Insert into @LT_FinalAgeQuoteSummary(companyid,companyname,
                                       NS_30_Quotes,NS_30_QuoteValue,S_30_Quotes,S_30_QuoteValue,
                                       NS_30to90_Quotes,NS_30to90_QuoteValue,S_30to90_Quotes,S_30to90_QuoteValue,
                                       NS_Above90_Quotes,NS_Above90_QuoteValue,S_Above90_Quotes,S_Above90_QuoteValue)
  Select A.companyid,A.companyname,
         sum(case when (A.quotestatuscode = 'NOTSUBMITTED' and A.ageingbucket = '00-30') then A.bucketcount
                  else 0 
             end)                         as NS_30_Quotes,
         sum(case when (A.quotestatuscode = 'NOTSUBMITTED' and A.ageingbucket = '00-30') then A.bucketvalue
                  else 0 
             end)                         as NS_30_QuoteValue,
         sum(case when (A.quotestatuscode = 'SUBMITTED' and A.ageingbucket  = '00-30') then A.bucketcount
                  else 0 
             end)                         as S_30_Quotes,
         sum(case when (A.quotestatuscode = 'SUBMITTED'  and A.ageingbucket  = '00-30') then A.bucketvalue
                  else 0 
             end)                         as S_30_QuoteValue,
         ----------------------
         sum(case when (A.quotestatuscode = 'NOTSUBMITTED' and A.ageingbucket = '30-90') then A.bucketcount
                  else 0 
             end)                         as NS_30to90_Quotes,
         sum(case when (A.quotestatuscode = 'NOTSUBMITTED' and A.ageingbucket = '30-90') then A.bucketvalue
                  else 0 
             end)                         as NS_30to90_QuoteValue,
         sum(case when (A.quotestatuscode = 'SUBMITTED' and A.ageingbucket  = '30-90') then A.bucketcount
                  else 0 
             end)                         as S_30to90_Quotes,
         sum(case when (A.quotestatuscode = 'SUBMITTED' and A.ageingbucket  = '30-90') then A.bucketvalue
                  else 0 
             end)                         as S_30to90_QuoteValue,
         ----------------------
         sum(case when (A.quotestatuscode = 'NOTSUBMITTED' and A.ageingbucket = '90-900') then A.bucketcount
                  else 0 
             end)                         as NS_Above90_Quotes,
         sum(case when (A.quotestatuscode = 'NOTSUBMITTED' and A.ageingbucket = '90-900') then A.bucketvalue
                  else 0 
             end)                         as NS_Above90_QuoteValue,
         sum(case when (A.quotestatuscode = 'SUBMITTED' and A.ageingbucket  = '90-900') then A.bucketcount
                  else 0 
             end)                         as S_Above90_Quotes,
         sum(case when (A.quotestatuscode = 'SUBMITTED' and A.ageingbucket  = '90-900') then A.bucketvalue
                  else 0 
             end)                         as S_Above90_QuoteValue   
  From @LT_TempQuoteAgeSummary A
  Group By A.companyid,A.companyname
  Order By A.companyname Asc
  --------------------------------------------------------------------------
  ---Final Select for the Report
  --------------------------------------------------------------------------  
  Select Companyid,CompanyName,
         NS_30_Quotes,NS_30_QuoteValue,S_30_Quotes,S_30_QuoteValue,
         NS_30to90_Quotes,NS_30to90_QuoteValue,S_30to90_Quotes,S_30to90_QuoteValue,
         NS_Above90_Quotes,NS_Above90_QuoteValue,S_Above90_Quotes,S_Above90_QuoteValue
  From  @LT_FinalAgeQuoteSummary
  Order By sortseq asc
  --------------------------------------------------------------------------  
END 

GO
