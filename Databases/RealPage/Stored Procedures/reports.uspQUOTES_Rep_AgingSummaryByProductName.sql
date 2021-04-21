SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : QUOTES       
-- Procedure Name  : uspQUOTES_Rep_AgingSummaryByProductName      
-- Description     : This procedure gets Quote Summary Details based on ProductName. 
--					 And this is based on the Excel File 'Quotes Aging Summary_By Product Name.xls'
-- Input Parameters: Optional except @IPD_StartDate and @IPD_EndDate 
-- Code Example    : Exec Quotes.dbo.[uspQUOTES_Rep_AgingSummaryByProductName] @IPD_EndDate = '04/16/2008'
-- Revision History:      
-- Author          : Shashi Bhushan      
-- 07/24/2007      : Stored Procedure Created.    
-- 08/03/2007      : SRS :  Queries Changed to reflect correct data.  
------------------------------------------------------------------------------------------------------      
create procedure [reports].[uspQUOTES_Rep_AgingSummaryByProductName]
(
 @IPVC_CompanyID     char(11) = '',
 @IPD_EndDate        datetime = '',
 @IPVC_PlatformCode  varchar(3) = '', 
 @IPVC_FamilyCode    varchar(3) = '', 
 @IPVC_CategoryCode  varchar(3) = '', 
 @IPVC_ProductName   varchar(255) = '', 
 @IPVC_CustomerName  varchar(100) = '',
 @IPC_AccountID      char(11) = '',
 @IPC_PropertyID     char(11) = '',
 @IPI_AccountManager bigint = '',
 @IPI_CreatedBy      bigint = ''
)      
as      
Begin         
Set nocount on   
--------------------------------------------------------------------------
set @IPVC_PlatformCode   = nullif(@IPVC_PlatformCode, '')
set @IPVC_FamilyCode     = nullif(@IPVC_FamilyCode, '')
set @IPVC_CategoryCode   = nullif(@IPVC_CategoryCode, '')
set @IPVC_ProductName    = @IPVC_ProductName
set @IPVC_CustomerName   = @IPVC_CustomerName
set @IPVC_CompanyID      = nullif(@IPVC_CompanyID, '')
set @IPC_AccountID       = nullif(@IPC_AccountID, '')
set @IPC_PropertyID      = nullif(@IPC_PropertyID, '')
set @IPI_AccountManager  = nullif(@IPI_AccountManager, '')
set @IPI_CreatedBy       = nullif(@IPI_CreatedBy, '')
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
 PlatformName	 varchar(50),
 FamilyName		 varchar(50),
 ProductName	 varchar(255),
 quotestatuscode varchar(20),
 ageingbucket	 varchar(50),
 bucketcount	 bigint,
 bucketvalue	 money
)
  
Declare @LT_FinalAgeQuoteSummary Table 
( 
 sortseq			   bigint not null identity(1,1),
 PlatformName		   varchar(50),
 FamilyName			   varchar(50),
 ProductName		   varchar(255),
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
Insert Into @LT_TempQuoteAgeSummary(PlatformName,FamilyName,ProductName,quotestatuscode,ageingbucket,bucketcount,bucketvalue)
Select	PF.Name,F.Name,P.Name,
		(case when (Q.QuoteStatusCode = 'NSU')
                then 'NOTSUBMITTED'
              when (Q.QuoteStatusCode = 'SUB')
                then 'SUBMITTED'
          end)                                                                      as quotestatuscode,
		(case	when (datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) <= 30)	then '00-30'
				when (datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) > 30
				 and datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) <= 90)	then '30-90'
				when (datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) > 90)    then '90-900'
		   else '0'
		end)                                                                       as ageingbucket,
        count(distinct Q.Quoteidseq)                                                        as bucketcount,
        convert(NUMERIC(30,2),sum(QI.NetExtYear1Chargeamount))					   as bucketvalue
FROM Quotes.dbo.quote Q with (nolock)
	join Quotes.dbo.QuoteItem QI (nolock) on Q.QuoteIDSeq=QI.QuoteIDSeq
	join Products..Product P  (nolock) on P.Code=QI.ProductCode and QI.PriceVersion=P.PriceVersion and P.DisplayName like '%' + @IPVC_ProductName + '%'
						and P.PlatformCode = isnull(@IPVC_PlatformCode, P.PlatformCode)
						and P.FamilyCode = isnull(@IPVC_FamilyCode, P.FamilyCode)
						and P.CategoryCode = isnull(@IPVC_CategoryCode, P.CategoryCode) 
	join Products..[Platform] PF (nolock) on PF.Code=P.PlatformCode
	join Products..Family F (nolock) on F.Code=P.FamilyCode
	join Products..Category Cat (nolock) on Cat.Code=P.CategoryCode
	join  Customers.dbo.Company C (nolock) on   Q.customeridseq = C.IDSeq 
	and  (Q.Quotestatuscode <> 'CNL' and Q.Quotestatuscode <> 'APR')
    and Year(Q.CreateDate) = Year(@IPD_EndDate)
	and  Q.customeridseq = (case when (@IPVC_CompanyID <> '' and @IPVC_CompanyID is not null) then @IPVC_CompanyID
                               else Q.customeridseq
                          end) 
	and C.Name like '%' + @IPVC_CustomerName+ '%'	 
	and ((@IPC_PropertyID is null) or EXISTS(select 1 from Quotes..GroupProperties GP (nolock) 
												where GP.QuoteIDSeq=Q.QuoteIDSeq and GP.PropertyIDSeq= @IPC_PropertyID))
	and ((@IPI_AccountManager is null) or EXISTS(select 1 from  Quotes..QuoteSaleAgent QSA (nolock)
												where QSA.QuoteIDSeq=Q.QuoteIDSeq and QSA.SalesAgentIDSeq = @IPI_AccountManager))
	and ((@IPI_CreatedBy is null) or EXISTS(select 1 from Quotes..QuoteItem qi (nolock)
											where qi.QuoteIDSeq = Q.QuoteIDSeq and Q.CreatedByIDSeq = @IPI_CreatedBy))
GROUP BY PF.Name,F.Name,P.Name,
			(case when (datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) <= 30)     then '00-30'
                 when (datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) > 30
                     and datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) <= 90)    then '30-90'
                 when (datediff(day,convert(varchar(50),Q.createdate,101),@IPD_EndDate) > 90)       then '90-900'
               else '0'
            end),
			(case when (Q.QuoteStatusCode = 'NSU')
                then 'NOTSUBMITTED'
              when (Q.QuoteStatusCode = 'SUB')
                then 'SUBMITTED'
			end)
--------------------------------------------------------------------------
  --Transposing Records to fall under the right Ageing bucket.
--------------------------------------------------------------------------
  Insert Into @LT_FinalAgeQuoteSummary(PlatformName,FamilyName,ProductName,
                                       NS_30_Quotes,NS_30_QuoteValue,S_30_Quotes,S_30_QuoteValue,
                                       NS_30to90_Quotes,NS_30to90_QuoteValue,S_30to90_Quotes,S_30to90_QuoteValue,
                                       NS_Above90_Quotes,NS_Above90_QuoteValue,S_Above90_Quotes,S_Above90_QuoteValue)
  Select A.PlatformName,A.FamilyName,A.ProductName,
         sum(case when (A.quotestatuscode = 'NOTSUBMITTED' and A.ageingbucket = '00-30') then A.bucketcount
                  else 0 
             end)                         as NS_30_Quotes,
         sum(case when (A.quotestatuscode = 'NOTSUBMITTED' and A.ageingbucket = '00-30') then A.bucketvalue
                  else 0 
             end)                         as NS_30_QuoteValue,
         sum(case when (A.quotestatuscode = 'SUBMITTED' and A.ageingbucket  = '00-30') then A.bucketcount
                  else 0 
             end)                         as S_30_Quotes,
         sum(case when (A.quotestatuscode = 'SUBMITTED' and A.ageingbucket  = '00-30') then A.bucketvalue
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
  Group By A.PlatformName,A.FamilyName,A.ProductName
  Order By A.PlatformName  
  --------------------------------------------------------------------------
  ---Final Select for the Report
  --------------------------------------------------------------------------  
  Select PlatformName,FamilyName,ProductName,
         NS_30_Quotes,NS_30_QuoteValue,S_30_Quotes,S_30_QuoteValue,
         NS_30to90_Quotes,NS_30to90_QuoteValue,S_30to90_Quotes,S_30to90_QuoteValue,
         NS_Above90_Quotes,NS_Above90_QuoteValue,S_Above90_Quotes,S_Above90_QuoteValue
  From  @LT_FinalAgeQuoteSummary
  Order By sortseq asc
END  
GO
