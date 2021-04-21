SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : QUOTES       
-- Procedure Name  : [uspQUOTES_Rep_TrendReviewReport_ByFamilyAndCategory]      
-- Description     : This procedure gets Review Report Details based on Family and Category. 
--					 And this is based on the Excel File 'Quotes Trend Review Report_By Family and Category.xls'
-- Input Parameters: Optional except @IPDT_CurrentDate
-- Code Example    : Exec Quotes.dbo.[uspQUOTES_Rep_TrendReviewReport_ByFamilyAndCategory] '',@IPDT_CurrentDate='08/16/2007' 
-- Revision History:      
-- Author          : Shashi Bhushan      
-- 07/24/2007      : Stored Procedure Created.    
-- 08/03/2007      : SRS :  Queries Changed to reflect correct data.  
------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspQUOTES_Rep_TrendReviewReport_ByFamilyAndCategory]
(
 @IPVC_CompanyID     varchar(50) = '',
 @IPDT_CurrentDate   Datetime = '',
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
------------------------------------------------------------
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
	If(@IPDT_CurrentDate='')
		Begin                    -- Assigning Current Date
				Set @IPDT_CurrentDate =convert(varchar(50),getdate(),101)
		End  
	*/
--------------------------------------------------------------
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
Declare @LT_M_TempQuoteAgeSummary  table   -- this local table variable is used to get monthly data 
(
 PlatformName	 varchar(50),
 FamilyName		 varchar(50),
 CategoryName	 varchar(70),
 m_quotestatuscode  varchar(20),
 m_ageingbucket     varchar(50),
 m_bucketcount      bigint,
 m_bucketvalue      money
)

Declare @LT_Q_TempQuoteAgeSummary  table   -- this local table variable is used to get Quarterly data
(
 PlatformName	 varchar(50),
 FamilyName		 varchar(50),
 CategoryName	 varchar(70),
 q_quotestatuscode varchar(20),
 q_ageingbucket    varchar(50),
 q_bucketcount     bigint,
 q_bucketvalue     money
)

Declare @LT_Y_TempQuoteAgeSummary  table  -- this local table variable is used to get Yearly data
(
 PlatformName	 varchar(50),
 FamilyName		 varchar(50),
 CategoryName	 varchar(70),
 y_quotestatuscode varchar(20),
 y_ageingbucket    varchar(50),
 y_bucketcount     bigint,
 y_bucketvalue     money
)

Declare @LT_Complete_TempQuoteAgeSummary  table  -- this table variable is used to consolidate data related to month/quarter/year
(
 PlatformName	 varchar(50),
 FamilyName		 varchar(50),
 CategoryName	 varchar(70),
 m_quotestatuscode varchar(20),
 m_ageingbucket    varchar(50),
 m_bucketcount     bigint,
 m_bucketvalue     money,
 q_quotestatuscode varchar(20),
 q_ageingbucket    varchar(50),
 q_bucketcount     bigint,
 q_bucketvalue     money,
 y_quotestatuscode varchar(20),
 y_ageingbucket    varchar(50),
 y_bucketcount     bigint,
 y_bucketvalue     money
)

Declare @LT_FinalAgeQuoteSummary Table 
(
 sortseq			   bigint not null identity(1,1),
 PlatformName		   varchar(50),
 FamilyName			   varchar(50),
 CategoryName		   varchar(70),
 NS_Month_Quotes       bigint,
 NS_Month_QuoteValue   numeric(18,2) null default 0.00,
 S_Month_Quote         bigint,
 S_Month_QuoteValue    numeric(18,2) null default 0.00,
 A_Month_Quotes 	   bigint,
 A_Month_QuoteValue    numeric(18,2) null DEFAULT 0.00, 

 NS_Quarter_Quotes     bigint,
 NS_Quarter_QuoteValue numeric(18,2) null default 0.00,
 S_Quarter_Quotes      bigint,
 S_Quarter_QuoteValue  numeric(18,2) null default 0.00,
 A_Quarter_Quotes 	   bigint,
 A_Quarter_QuoteValue  numeric(18,2) null DEFAULT 0.00,

 NS_Year_Quotes       bigint,
 NS_Year_QuoteValue   numeric(18,2) null default 0.00,
 S_Year_Quotes        bigint,
 S_Year_QuoteValue    numeric(18,2) null default 0.00,
 A_Year_Quotes 	      bigint,
 A_Year_QuoteValue    numeric(18,2) null DEFAULT 0.00
)
  -------------------------------------------------------------------------- 
  --Get top level records from Quotes.dbo.Quote that qualify for ageing.
  ---         that does not have Quotestatuscode = 'CNL' -- CNL is Cancelled
  ----------------------------------------------------------------------------
--                          *****MONTH Data*****
----------------------------------------------------------------------------
 Insert into @LT_M_TempQuoteAgeSummary(PlatformName,FamilyName,CategoryName,m_quotestatuscode, m_ageingbucket,m_bucketcount,m_bucketvalue)
 Select PF.Name,F.Name,Cat.Name,
         (case when (Q.QuoteStatusCode = 'NSU')
                then 'NOTSUBMITTED'
              when (Q.QuoteStatusCode = 'SUB')
                then 'SUBMITTED'
			  when (Q.QuoteStatusCode = 'APR')
                then 'APPROVED'
          end)                                                                      as m_quotestatuscode,
         'MONTH'																	as m_ageingbucket,
        count(distinct Q.Quoteidseq)                                                as m_bucketcount,        
        convert(NUMERIC(30,2),sum(QI.NetExtYear1Chargeamount))						as m_bucketvalue
 From Quotes.dbo.quote Q with (nolock)
	join Quotes.dbo.QuoteItem QI with (nolock) on Q.QuoteIDSeq=QI.QuoteIDSeq
	join Products..Product P with (nolock) on P.Code=QI.ProductCode and QI.PriceVersion=P.PriceVersion and P.DisplayName like '%' + @IPVC_ProductName + '%'
						and P.PlatformCode = isnull(@IPVC_PlatformCode, P.PlatformCode)
						and P.FamilyCode = isnull(@IPVC_FamilyCode, P.FamilyCode)
						and P.CategoryCode = isnull(@IPVC_CategoryCode, P.CategoryCode) 
	join Products..[Platform] PF with (nolock) on PF.Code=P.PlatformCode
	join Products..Family F with (nolock) on F.Code=P.FamilyCode
	join Products..Category Cat with (nolock) on Cat.Code=P.CategoryCode
	join  Customers.dbo.Company C with (nolock) on   Q.customeridseq = C.IDSeq    
	 and   Q.Quotestatuscode <> 'CNL' and Year(Q.CreateDate) = Year(@IPDT_CurrentDate)
     and  Q.customeridseq = (case when (@IPVC_CompanyID <> '' and @IPVC_CompanyID is not null)
									 then @IPVC_CompanyID  
							    else Q.customeridseq end)  
	 and C.Name like '%' + @IPVC_CustomerName+ '%'
	 and ((@IPC_PropertyID is null) or EXISTS(select 1 from Quotes..GroupProperties GP (nolock) 
												where GP.QuoteIDSeq=Q.QuoteIDSeq and GP.PropertyIDSeq= @IPC_PropertyID))
	 and ((@IPI_AccountManager is null) or EXISTS(select 1 from  Quotes..QuoteSaleAgent QSA (nolock)
												where QSA.QuoteIDSeq=Q.QuoteIDSeq and QSA.SalesAgentIDSeq = @IPI_AccountManager))

	 and ((@IPI_CreatedBy is null) or EXISTS(select 1 from Quotes..QuoteItem qi (nolock)
											where qi.QuoteIDSeq = Q.QuoteIDSeq and Q.CreatedByIDSeq = @IPI_CreatedBy))
	 and convert(varchar(50),Q.createdate,101) between DATEADD(mm, DATEDIFF(mm,0,@IPDT_CurrentDate), 0) and  @IPDT_CurrentDate
Group By PF.Name,F.Name,Cat.Name,
         (case when (Q.QuoteStatusCode = 'NSU')
                then 'NOTSUBMITTED'
              when (Q.QuoteStatusCode = 'SUB')
                then 'SUBMITTED'
			  when (Q.QuoteStatusCode = 'APR')
                then 'APPROVED'
          end) 
-------------------------------------------------------------------------
--                          *****QUARTER Data*****
----------------------------------------------------------------------------
Insert into @LT_Q_TempQuoteAgeSummary(PlatformName,FamilyName,CategoryName,q_quotestatuscode, q_ageingbucket,q_bucketcount,q_bucketvalue)
 Select PF.Name,F.Name,Cat.Name,
         (case when (Q.QuoteStatusCode = 'NSU')
                then 'NOTSUBMITTED'
              when (Q.QuoteStatusCode = 'SUB')
                then 'SUBMITTED'
			  when (Q.QuoteStatusCode = 'APR')
                then 'APPROVED'
          end)                                                                      as q_quotestatuscode,
         'QUARTER'																	as q_ageingbucket,
        count(distinct Q.Quoteidseq)                                                         as q_bucketcount,        
        convert(NUMERIC(30,2),sum(QI.NetExtYear1Chargeamount))						as q_bucketvalue
 From Quotes.dbo.quote Q with (nolock)
	join Quotes.dbo.QuoteItem QI with (nolock) on Q.QuoteIDSeq=QI.QuoteIDSeq
	join Products..Product P with (nolock) on P.Code=QI.ProductCode and QI.PriceVersion=P.PriceVersion and P.DisplayName like '%' + @IPVC_ProductName + '%'
						and P.PlatformCode = isnull(@IPVC_PlatformCode, P.PlatformCode)
						and P.FamilyCode = isnull(@IPVC_FamilyCode, P.FamilyCode)
						and P.CategoryCode = isnull(@IPVC_CategoryCode, P.CategoryCode) 
	join Products..[Platform] PF with (nolock) on PF.Code=P.PlatformCode
	join Products..Family F with (nolock) on F.Code=P.FamilyCode
	join Products..Category Cat with (nolock) on Cat.Code=P.CategoryCode
	join  Customers.dbo.Company C with (nolock) on   Q.customeridseq = C.IDSeq
     and   Q.Quotestatuscode <> 'CNL' and Year(Q.CreateDate) = Year(@IPDT_CurrentDate)
	 and  Q.customeridseq = (case when (@IPVC_CompanyID <> '' and @IPVC_CompanyID is not null)
									 then @IPVC_CompanyID  
									else Q.customeridseq end)  
	 and C.Name like '%' + @IPVC_CustomerName+ '%'
	 and ((@IPC_PropertyID is null) or EXISTS(select 1 from Quotes..GroupProperties GP (nolock) 
												where GP.QuoteIDSeq=Q.QuoteIDSeq and GP.PropertyIDSeq= @IPC_PropertyID))
	 and ((@IPI_AccountManager is null) or EXISTS(select 1 from  Quotes..QuoteSaleAgent QSA (nolock)
												where QSA.QuoteIDSeq=Q.QuoteIDSeq and QSA.SalesAgentIDSeq = @IPI_AccountManager))
	 and ((@IPI_CreatedBy is null) or EXISTS(select 1 from Quotes..QuoteItem qi (nolock)
											where qi.QuoteIDSeq = Q.QuoteIDSeq and Q.CreatedByIDSeq = @IPI_CreatedBy))
	 and convert(varchar(50),Q.createdate,101) between DATEADD(qq, DATEDIFF(qq,0,@IPDT_CurrentDate), 0) and  @IPDT_CurrentDate 
Group By PF.Name,F.Name,Cat.Name,
         (case when (Q.QuoteStatusCode = 'NSU')
                then 'NOTSUBMITTED'
              when (Q.QuoteStatusCode = 'SUB')
                then 'SUBMITTED'
			  when (Q.QuoteStatusCode = 'APR')
                then 'APPROVED'
          end) 
-------------------------------------------------------------------------
--                          *****YEAR Data*****
----------------------------------------------------------------------------
Insert into @LT_Y_TempQuoteAgeSummary(PlatformName,FamilyName,CategoryName,y_quotestatuscode, y_ageingbucket,y_bucketcount,y_bucketvalue)
 Select PF.Name,F.Name,Cat.Name,
         (case when (Q.QuoteStatusCode = 'NSU')
                then 'NOTSUBMITTED'
              when (Q.QuoteStatusCode = 'SUB')
                then 'SUBMITTED'
			  when (Q.QuoteStatusCode = 'APR')
                then 'APPROVED'
          end)                                                                      as y_quotestatuscode,
         'YEAR'																	as y_ageingbucket,
        count(distinct Q.Quoteidseq)                                                         as y_bucketcount,        
        convert(NUMERIC(30,2),sum(QI.NetExtYear1Chargeamount))						as y_bucketvalue
 From Quotes.dbo.quote Q with (nolock)
	join Quotes.dbo.QuoteItem QI with (nolock) on Q.QuoteIDSeq=QI.QuoteIDSeq
	join Products..Product P with (nolock) on P.Code=QI.ProductCode and QI.PriceVersion=P.PriceVersion and P.DisplayName like '%' + @IPVC_ProductName + '%'
						and P.PlatformCode = isnull(@IPVC_PlatformCode, P.PlatformCode)
						and P.FamilyCode = isnull(@IPVC_FamilyCode, P.FamilyCode)
						and P.CategoryCode = isnull(@IPVC_CategoryCode, P.CategoryCode) 
	join Products..[Platform] PF with (nolock) on PF.Code=P.PlatformCode
	join Products..Family F with (nolock) on F.Code=P.FamilyCode
	join Products..Category Cat with (nolock) on Cat.Code=P.CategoryCode
	join  Customers.dbo.Company C with (nolock) on   Q.customeridseq = C.IDSeq
      and   Q.Quotestatuscode <> 'CNL' and Year(Q.CreateDate) = Year(@IPDT_CurrentDate)
      and  Q.customeridseq = (case when (@IPVC_CompanyID <> '' and @IPVC_CompanyID is not null)
									 then @IPVC_CompanyID  
									else Q.customeridseq end)  
	  and C.Name like '%' + @IPVC_CustomerName+ '%'
	 and ((@IPC_PropertyID is null) or EXISTS(select 1 from Quotes..GroupProperties GP (nolock) 
												where GP.QuoteIDSeq=Q.QuoteIDSeq and GP.PropertyIDSeq= @IPC_PropertyID))
	  and ((@IPI_AccountManager is null) or EXISTS(select 1 from  Quotes..QuoteSaleAgent QSA (nolock)
												where QSA.QuoteIDSeq=Q.QuoteIDSeq and QSA.SalesAgentIDSeq = @IPI_AccountManager))
	  and ((@IPI_CreatedBy is null) or EXISTS(select 1 from Quotes..QuoteItem qi (nolock)
											where qi.QuoteIDSeq = Q.QuoteIDSeq and Q.CreatedByIDSeq = @IPI_CreatedBy))
Group By PF.Name,F.Name,Cat.Name,
         (case when (Q.QuoteStatusCode = 'NSU')
                then 'NOTSUBMITTED'
              when (Q.QuoteStatusCode = 'SUB')
                then 'SUBMITTED'
			  when (Q.QuoteStatusCode = 'APR')
                then 'APPROVED'
          end) 
--------------------------------------------------------------------------
--	Inserting Final Data into ''@LT_Complete_TempQuoteAgeSummary' variable 
--	from the table variables @LT_M_TempQuoteAgeSummary, @LT_Q_TempQuoteAgeSummary and @LT_Y_TempQuoteAgeSummary
--------------------------------------------------------------------------
Insert into @LT_Complete_TempQuoteAgeSummary
select     Y.PlatformName,Y.FamilyName,Y.CategoryName,
	       m_quotestatuscode,m_ageingbucket,m_bucketcount,m_bucketvalue,
	       q_quotestatuscode,q_ageingbucket,q_bucketcount,q_bucketvalue,
	       y_quotestatuscode,y_ageingbucket,y_bucketcount,y_bucketvalue		
from       @LT_Y_TempQuoteAgeSummary Y
left join  @LT_Q_TempQuoteAgeSummary Q on Y.PlatformName=Q.PlatformName and Y.FamilyName=Q.FamilyName and Y.CategoryName=Q.CategoryName
left join  @LT_M_TempQuoteAgeSummary M on Q.PlatformName=M.PlatformName and Q.FamilyName=M.FamilyName and Q.CategoryName=M.CategoryName

--------------------------------------------------------------------------
  --Transposing Records to fall under the right Ageing bucket.
--------------------------------------------------------------------------

Insert Into @LT_FinalAgeQuoteSummary(PlatformName,FamilyName,CategoryName,
                                     NS_Month_Quotes,NS_Month_QuoteValue,S_Month_Quote,S_Month_QuoteValue,A_Month_Quotes,A_Month_QuoteValue,
                                     NS_Quarter_Quotes,NS_Quarter_QuoteValue,S_Quarter_Quotes,S_Quarter_QuoteValue,A_Quarter_Quotes,A_Quarter_QuoteValue,
                                     NS_Year_Quotes,NS_Year_QuoteValue,S_Year_Quotes,S_Year_QuoteValue,A_Year_Quotes,A_Year_QuoteValue)
Select  A.PlatformName,A.FamilyName,A.CategoryName,
          (case when ( m_quotestatuscode = 'NOTSUBMITTED' and  m_ageingbucket = 'MONTH') then  m_bucketcount
                  else 0 
             end)                         as NS_Month_Quotes,
          (case when ( m_quotestatuscode = 'NOTSUBMITTED' and  m_ageingbucket = 'MONTH') then  m_bucketvalue
                  else 0 
             end)                         as NS_Month_QuoteValue,
          (case when ( m_quotestatuscode = 'SUBMITTED' and  m_ageingbucket  = 'MONTH') then  m_bucketcount
                  else 0 
             end)                         as S_Month_Quote,
          (case when ( m_quotestatuscode = 'SUBMITTED' and  m_ageingbucket  = 'MONTH') then  m_bucketvalue
                  else 0 
             end)                         as S_Month_QuoteValue,
		  (case when ( m_quotestatuscode  = 'APPROVED' and  m_ageingbucket  = 'MONTH') then  m_bucketcount
                  else 0 
             end)                         as A_Month_Quotes,
          (case when ( m_quotestatuscode = 'APPROVED' and  m_ageingbucket  = 'MONTH') then  m_bucketvalue
                  else 0 
             end)                         as A_Month_QuoteValue,
         ----------------------
          (case when ( q_quotestatuscode = 'NOTSUBMITTED' and  q_ageingbucket = 'QUARTER') then  q_bucketcount
                  else 0 
             end)                         as NS_Quarter_Quotes,
          (case when ( q_quotestatuscode = 'NOTSUBMITTED' and  q_ageingbucket = 'QUARTER') then  q_bucketvalue
                  else 0 
             end)                         as NS_Quarter_QuoteValue,
          (case when ( q_quotestatuscode = 'SUBMITTED' and  q_ageingbucket = 'QUARTER') then  q_bucketcount
                  else 0 
             end)                         as S_Quarter_Quotes,
          (case when ( q_quotestatuscode = 'SUBMITTED' and  q_ageingbucket = 'QUARTER') then  q_bucketvalue
                  else 0 
             end)                         as S_Quarter_QuoteValue,
		  (case when ( q_quotestatuscode  = 'APPROVED' and  q_ageingbucket  = 'QUARTER') then  q_bucketcount
                  else 0 
             end)                         as A_Quarter_Quotes,
          (case when ( q_quotestatuscode = 'APPROVED' and  q_ageingbucket = 'QUARTER') then  q_bucketvalue
                  else 0 
             end)                         as A_Quarter_QuoteValue,
         ----------------------
          (case when ( y_quotestatuscode = 'NOTSUBMITTED' and  y_ageingbucket = 'YEAR') then  y_bucketcount
                  else 0 
             end)                         as NS_Year_Quotes,
          (case when ( y_quotestatuscode = 'NOTSUBMITTED' and  y_ageingbucket = 'YEAR') then  y_bucketvalue
                  else 0 
             end)                         as NS_Year_QuoteValue,
          (case when ( y_quotestatuscode = 'SUBMITTED' and  y_ageingbucket  = 'YEAR') then  y_bucketcount
                  else 0 
             end)                         as S_Year_Quotes,
          (case when ( y_quotestatuscode = 'SUBMITTED' and  y_ageingbucket  = 'YEAR') then  y_bucketvalue
                  else 0 
             end)                         as S_Year_QuoteValue,
		  (case when ( y_quotestatuscode  = 'APPROVED' and  y_ageingbucket  = 'YEAR') then  y_bucketcount
                  else 0 
             end)                         as A_Year_Quotes,
          (case when ( y_quotestatuscode = 'APPROVED'   and  y_ageingbucket  = 'YEAR') then  y_bucketvalue
                  else 0 
             end)                         as A_Year_QuoteValue
From @LT_Complete_TempQuoteAgeSummary A
Group by  PlatformName,FamilyName,A.CategoryName,m_quotestatuscode,m_ageingbucket,m_bucketcount,m_bucketvalue,
		  q_quotestatuscode,q_ageingbucket,q_bucketcount,q_bucketvalue,
		  y_quotestatuscode,y_ageingbucket,y_bucketcount,y_bucketvalue
Order by  PlatformName,FamilyName  
--------------------------------------------------------------------------
---Final Select for the Report
-------------------------------------------------------------------------- 
Select PlatformName,FamilyName,CategoryName,
max(NS_Month_Quotes) as NS_Month_Quotes,
max(NS_Month_QuoteValue) as NS_Month_QuoteValue,
max(S_Month_Quote) as S_Month_Quotes,
max(S_Month_QuoteValue) as S_Month_QuoteValue,
max(A_Month_Quotes) as A_Month_Quotes,
max(A_Month_QuoteValue) as A_Month_QuoteValue,
max(NS_Quarter_Quotes) as NS_Quarter_Quotes,
max(NS_Quarter_QuoteValue) as NS_Quarter_QuoteValue,
max(S_Quarter_Quotes) as S_Quarter_Quotes,
max(S_Quarter_QuoteValue) as S_Quarter_QuoteValue,
max(A_Quarter_Quotes) as A_Quarter_Quotes,
max(A_Quarter_QuoteValue) as A_Quarter_QuoteValue,
max(NS_Year_Quotes) as NS_Year_Quotes,
max(NS_Year_QuoteValue) as NS_Year_QuoteValue,
max(S_Year_Quotes) as S_Year_Quotes,
max(S_Year_QuoteValue) as S_Year_QuoteValue,
max(A_Year_Quotes) as A_Year_Quotes,
max(A_Year_QuoteValue) as A_Year_QuoteValue
From  @LT_FinalAgeQuoteSummary
Group by PlatformName,FamilyName,CategoryName
END  
GO
