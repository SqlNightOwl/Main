SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_GetOrdersRenewalForMassRenewals
-- Description     : Get Detail of Upcoming Renewal
-- Input Parameters: 
-- Code Example    : --EXEC [ORDERS].dbo.[uspORDERS_GetOrdersRenewalForMassRenewals]  
--@IPVC_BillingCycleDate='',@IPVC_StartDate='10/01/2010',@IPVC_EndDate='12/03/2010',@IPI_SearchByBillingCyleFlag='0',@IPVC_CompanyID='',@IPVC_AccountID='',@IPVC_CompanyName='',@IPVC_AccountName='',@IPVC_ProductName='',@IPI_IncludeProperties='1',@IPVC_RenewalReviewedFlag='',@IPVC_RenewalTypeCode='',@IPVC_SortBy='renewaldate',@IPVC_OrderID='',@IPVC_FamilyCode='',@IPVC_OrderItemID='349341||349344||' 
-- Revision History:
-- Author          : dnethunuri
-- 11/02/2010      : Stored Procedure Created.
-- 05/12/2011 Mahaboob : Stored Procedure modified to include CurrentActivationDate in Select List for Defect #:315
-- 07/06/2011      : DNETHUNURI - Modifications related to defect# 729,728 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetOrdersRenewalForMassRenewals](@IPI_PageNumber  bigint      =1, 
                                                    @IPI_RowsPerPage              bigint      =99999,
                                                    @IPI_SearchByBillingCyleFlag  int         =1,
                                                    @IPVC_StartDate               varchar(50) ='',
                                                    @IPVC_EndDate                 varchar(50) ='',                                                   
                                                    @IPVC_BillingCycleDate        varchar(50) ='',
                                                    @IPVC_CompanyID               varchar(50) ='',
                                                    @IPVC_AccountID               varchar(50) ='',                                                   
                                                    @IPVC_CompanyName             varchar(255)='',
                                                    @IPVC_AccountName             varchar(255)='',	
                                                    @IPVC_ProductName             varchar(255)='',  
                                                    @IPVC_OrderID                 varchar(50) ='',	
                                                    @IPI_IncludeProperties        int         =1,				   
                                                    @IPVC_RenewalReviewedFlag     varchar(1)  ='',
                                                    @IPVC_RenewalTypeCode         varchar(5)  ='',
                                                    @IPVC_FamilyCode              varchar(10) ='',
                                                    @IPVC_SortBy                  varchar(100)='renewaldate',
													@IPVC_OrderItemID             varchar(max) ,
													@IPVC_ChkAllFlag              int         =0 ,                                     
													@IPVC_Mode                    int         =0                                      

                                                    )
AS
BEGIN
  set nocount on;  
  set quoted_identifier on;

    Create table #RenewalsSummary
                                ( 
	                             accountidseq                varchar(50),
                                 accountname                 varchar(255),
                                 allowchangerenewalstartdateflag int null,
                                 companyidseq                varchar(50),
                                 companyname                 varchar(255),
                                 currentactivationenddate    varchar(50), 
                                 currentactivationstartdate  varchar(50),
								 currentbaseprice			numeric(30,2) null,
								 listbaseprice				numeric(30,2) null,
                                 custombundlenameenabledflag int not null default (0),                                
                                 discountpercent             float null,                                                                 
                                 effectivequantity           numeric(30,5) null,                                   
                                 frequencyname               varchar(50),
                                 measurename                 varchar(50),                                 
                                 nonuseradjustedchargeamountdisplay  money null, ---> numeric(30,2) null,                           
                                 nonuseradjustedrenewaladjustmenttype    varchar(50) NULL default 'N/A',   
                                 ordergroupidseq             bigint,                                
                                 orderidseq                  varchar(50), 
                                 orderitemcount              bigint  null,
                                 orderitemidseq              bigint,                                   
                                 PriceCapFlag                int default (0),
                                 productdisplayname          varchar(255),
                                 propertyidseq               varchar(50),
                                 recordtype                  varchar(5) not null default 'PR',
                                 renewalactivationenddate    varchar(50), 
                                 renewalactivationstartdate  varchar(50),
                                 renewaladjustedchargeamountdisplay  money null, ---> numeric(30,2) null,
                                 renewaladjustmenttype       varchar(50) NULL default 'N/A',
                                 renewalchargeamount         numeric(30,2) null,
                                 renewalcount                bigint  null,
                                 renewalnotes                varchar(1000) null,
                                 renewalreviewedflag         bigint  null,      
                                 renewaltypecode             varchar(5), 
                                 renewaltypename             varchar(20), 
                                 RenewalUserOverrideFlag     int default (0),
								 TotalRecords                bigint not null default (0)
					)

	INSERT INTO #RenewalsSummary (

						TotalRecords,
						accountidseq,
						companyidseq,
						propertyidseq,
						companyname,
						accountname,
						productdisplayname,
						currentactivationstartdate,
						currentactivationenddate,
						renewalactivationstartdate,
						renewalactivationenddate,
						renewaltypename,
						measurename,
						frequencyname,
						renewalchargeamount,
						discountpercent,
						nonuseradjustedchargeamountdisplay,
						renewaladjustedchargeamountdisplay,
						nonuseradjustedrenewaladjustmenttype,
						renewaladjustmenttype,
						renewalreviewedflag,
						pricecapflag,
						renewaluseroverrideflag,
						renewalnotes,
						orderidseq,
						ordergroupidseq,
						orderitemidseq,
						renewalcount,
						orderitemcount,
						renewaltypecode,
						custombundlenameenabledflag,
						recordtype,
						allowchangerenewalstartdateflag,
						effectivequantity,
						currentbaseprice,
						listbaseprice
								 
			)
		 EXEC [Orders].[dbo].[uspORDERS_GetOrdersRenewal]   
				@IPI_PageNumber=1,  @IPI_RowsPerPage=99999,  @IPVC_BillingCycleDate=@IPVC_BillingCycleDate,  @IPVC_CompanyID=@IPVC_CompanyID,  @IPVC_AccountID=@IPVC_AccountID,  
				@IPVC_CompanyName=@IPVC_CompanyName,  @IPVC_AccountName=@IPVC_AccountName,  
				@IPVC_ProductName=@IPVC_ProductName,  @IPI_IncludeProperties=@IPI_IncludeProperties,  @IPVC_RenewalReviewedFlag=@IPVC_RenewalReviewedFlag,  @IPVC_RenewalTypeCode=@IPVC_RenewalTypeCode,  
				@IPVC_SortBy=@IPVC_SortBy,  @IPVC_OrderID=@IPVC_OrderID,  @IPVC_FamilyCode=@IPVC_FamilyCode,  @IPI_SearchByBillingCyleFlag=@IPI_SearchByBillingCyleFlag,  
				@IPVC_StartDate=@IPVC_StartDate,  @IPVC_EndDate=@IPVC_EndDate


 if(@IPVC_Mode = 0)  
 begin  
   SELECT   
  
     S.orderidseq as OrderID,  
     S.productdisplayname as [ProductName],  
     S.renewaltypename as [RenewalStatus],  
     S.currentbaseprice as [CurrentBasePrice],  
     S.nonuseradjustedchargeamountdisplay as [SystemSuggestionPrice],   
     S.renewalchargeamount as [RenewalAmount],  
     convert(numeric(30,5),S.discountpercent) as [AdjustedPercent],  
     S.renewaladjustedchargeamountdisplay as [AdjustedDollar],  
     S.renewalactivationstartdate as [RenewalDate],  
     S.ordergroupidseq as GroupIDSeq,  
     S.orderitemidseq as OrderItemIDSeq,  
     S.recordtype as RecordType,  
     S.custombundlenameenabledflag as CustomEnableFlag,  
     S.renewalcount as RenewalCount,  
     S.orderitemcount as OrderItemCount,  
     S.renewaluseroverrideflag as RenewalOverrideFlag,  
     S.renewaltypecode as RenewalTypeCode,
	 S.currentactivationenddate  as [CurrentActivationEndDate]  
                   
   FROM #RenewalsSummary S WITH (NOLOCK)  
   where   ((@IPVC_ChkAllFlag= 0 and  S.orderitemidseq IN (select Items from Orders.[dbo].[fn_SplitDelimitedStringIntoRows](@IPVC_OrderItemID,'||')))  
     OR  
    (@IPVC_ChkAllFlag= 1) AND  1=1)   
  
  order by S.recordtype ASC  
 end  
  
 else  
 begin  
  SELECT   
  
     S.orderidseq as OrderID,  
     S.productdisplayname as [Product Name],  
     S.renewaltypename as [Renewal Status],  
     S.currentbaseprice as [Current Base Price($)],  
     S.nonuseradjustedchargeamountdisplay as [System Suggestion(w/Applicable PriceCap)($)],   
     S.renewalchargeamount as [Renewal($)],  
     convert(numeric(30,5),S.discountpercent) as [Adjusted(%)],  
     S.renewaladjustedchargeamountdisplay as [Adjusted($)],
     S.currentactivationenddate  as [CurrentActivationEndDate]
                   
   FROM #RenewalsSummary S WITH (NOLOCK)  
   where    
     ((@IPVC_ChkAllFlag= 0 and  S.orderitemidseq IN (select Items from Orders.[dbo].[fn_SplitDelimitedStringIntoRows](@IPVC_OrderItemID,'||')))  
     OR  
    (@IPVC_ChkAllFlag= 1) AND  1=1)   
  
  order by   S.recordtype ASC  
  end  
  -----------------------------------------------------------------------------------------  
  ---Final Cleanup  
  -----------------------------------------------------------------------------------------
  
  drop table #RenewalsSummary 
  -----------------------------------------------------------------------------------------
END
GO
