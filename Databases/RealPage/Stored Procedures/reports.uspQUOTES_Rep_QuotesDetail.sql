SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : [QUOTES]  
-- Procedure Name  : [uspQUOTES_Rep_QuotesDetail]  
-- Description     : This procedure gets Quotes based on parameters passed
-- Code Example    : Exec uspQUOTES_Rep_QuotesDetail @IPD_StartDate = '01/01/2008', @IPD_EndDate = '1/31/2009',@IPVC_QuoteType='NEWQ'
--                     
-- Revision History:  
-- Author          : 
-- 01/29/2009      : Naval Kishore Modified to add @IPVC_QuoteType parameter, Defect #5930. 
-- 10/09/2009      : Naval Kishore Modified to add new column (Description), Defect #7098. 
-- 05/16/2011      : Mahaboob Modified to include ApprovalStartDate and ApprovalEndDate parameters Defect #241
-- 10/25/2011      : Naval Kishore Modified to add new columns (Deal Desk Decision,Deal Desk Action Date), TFS # 1327
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [reports].[uspQUOTES_Rep_QuotesDetail]
						(
						 @IPVC_Quoteid       varchar(22)  = '',
						 @IPVC_CompanyID     CHAR(11)     = '',
						 @IPD_StartDate      datetime     = '',
						 @IPD_EndDate        datetime     = '',
						 @IPVC_PlatformCode  varchar(3)   = '',
						 @IPVC_FamilyCode    varchar(3)   = '',
						 @IPVC_CategoryCode  varchar(3)   = '',
						 @IPVC_ProductName   varchar(255) = '',
						 @IPC_QuoteStatus    varchar(4)   = '',
						 @IPVC_CustomerName  varchar(100) = '',
						 @IPC_AccountID      varchar(50)  = '',
						 @IPC_PropertyID     varchar(50)  = '',
						 @IPI_AccountManager varchar(200) = '',
						 @IPI_CreatedBy      varchar(100) = '',
						 @IPVC_QuoteType     varchar(4)   = '',
					     @IPD_ApprovalStartDate datetime  = '',  
					     @IPD_ApprovalEndDate   datetime  = ''   
                         )
AS
BEGIN
  set nocount on;
  -----------------------------------------------------------
  create table #Temp_Rep_SalesAgent (QuoteIDSeq		    varchar(22),
                                     SalesAgentName         varchar(100)
                                    )   

  Create table #Temp_Rep_QuotesDetail (
                                       sortseq			    bigint not null IDENTITY(1,1),
                                       QuoteIDSeq		    varchar(22),
                                       StatusName		    varchar(20),
                                       ExpirationDate		datetime,
                                       CustomerName		    varchar(100),
                                       GroupIDSeq                   bigint,
                                       GroupName		    varchar(70),
                                       ProductName		    varchar(255),
                                       ProductCode                  varchar(50),
                                       Sites			    int,
                                       Units			    int,
                                       ILFMeasureName		    varchar(20),
                                       ILFFrequencyName		    varchar(20),
                                       ACSMeasureName		    varchar(20),
                                       ACSFrequencyName		    varchar(20),
                                       MeasureCode                  as (case when ACSMeasureName<>'' then ACSMeasureName 
                                                                             when ACSMeasureName ='' then ILFMeasureName 
                                                                        else '' end),
                                       FrequencyName                as (case when ACSFrequencyName<>'' then ACSFrequencyName
                                                                             when ACSFrequencyName ='' then ILFFrequencyName 
                                                                        else '' end),
                                       ILF_List			    numeric(18,2) null DEFAULT 0.00,
                                       ILF_DiscPercent	            numeric(18,2),
                                       ILF_NetAmount		    numeric(18,2) null DEFAULT 0.00,
                                       ILFUnitPrice		    numeric(18,2) null DEFAULT 0.00,
                                       ACSUnitPrice                 numeric(18,2) null DEFAULT 0.00,                                       
                                       ACS_List			    numeric(18,2) null DEFAULT 0.00,
                                       ACS_DiscPercent	            numeric(18,2),
                                       ACS_NetAmount_Year1          numeric(18,2) null DEFAULT 0.00,
                                       TotalValue_List	            as convert(numeric(18,2),(ILF_List+ACS_List)),
                                       TotalValue_DiscPercent       as convert(numeric(18,2),
                                                                                 (((ILF_List+ACS_List) - (ILF_NetAmount+ACS_NetAmount_Year1))*100)
                                                                                  /
                                                                                 (case when (ILF_List+ACS_List) > 0 then (ILF_List+ACS_List) else 1 end)
                                                                               ),
                                       TotalValue_NetAmount         as convert(numeric(18,2),(ILF_NetAmount+ACS_NetAmount_Year1)),
                                       SalesAgentName		    varchar(255) null,
									   QuoteType                varchar(50),
									   CreatedDate   		    datetime,
									   SubmittedDate		    datetime,
									   ApprovalDate 		    datetime,
									   ModifiedDate 		    datetime,
									   [Description]	        varchar(255) null,
									   DealDeskDecision			varchar(255) null,
									   DealDeskActionDate		datetime,
				      )
  -----------------------------------------------------------
  SET @IPVC_Quoteid       = nullif(@IPVC_Quoteid,'')
  SET @IPVC_PlatformCode  = nullif(@IPVC_PlatformCode,'')
  SET @IPVC_FamilyCode    = nullif(@IPVC_FamilyCode,'')
  SET @IPVC_CategoryCode  = nullif(@IPVC_CategoryCode,'')
  SET @IPVC_ProductName   = @IPVC_ProductName
  SET @IPC_QuoteStatus    = nullif(@IPC_QuoteStatus,'')
  SET @IPVC_CustomerName  = @IPVC_CustomerName
  SET @IPVC_CompanyID     = nullif(@IPVC_CompanyID,'')
  SET @IPC_AccountID      = nullif(@IPC_AccountID,'')
  SET @IPC_PropertyID     = nullif(@IPC_PropertyID,'')
  SET @IPI_AccountManager = nullif(@IPI_AccountManager,'')
  SET @IPI_CreatedBy      = nullif(@IPI_CreatedBy,'')
  SET @IPVC_QuoteType      = nullif(@IPVC_QuoteType,'')

  select @IPD_StartDate   = convert(datetime,convert(varchar(50),@IPD_StartDate,101))
  select @IPD_EndDate     = convert(datetime,convert(varchar(50),@IPD_EndDate,101))+1

  IF( @IPD_ApprovalStartDate = '' OR @IPD_ApprovalEndDate = '')
  BEGIN
		SET @IPD_ApprovalStartDate = ''
		SET @IPD_ApprovalEndDate = ''
  END

  IF( @IPD_ApprovalStartDate <> '' AND @IPD_ApprovalEndDate <> '')
  BEGIN
		SET @IPC_QuoteStatus = 'APR'
		select @IPD_ApprovalStartDate   = convert(datetime,convert(varchar(50),@IPD_ApprovalStartDate,101))
		select @IPD_ApprovalEndDate     = convert(datetime,convert(varchar(50),@IPD_ApprovalEndDate,101))+1
  END
 
  SET @IPD_ApprovalStartDate = nullif(@IPD_ApprovalStartDate, '')
  SET @IPD_ApprovalEndDate   = nullif(@IPD_ApprovalEndDate, '')

  -----------------------------------------------------------  
  -- An AccountID when passed and not null, will belong either to a company
  -- or property. Hence the following Select will suffice.
  IF (@IPC_AccountID is not null and @IPC_AccountID <> '')
  BEGIN
    SELECT @IPVC_CompanyID = A.CompanyIDSeq,
	   @IPC_PropertyID = A.PropertyIDSeq
    FROM   Customers.dbo.Account A WITH (NOLOCK)
    WHERE  A.IDSeq         = @IPC_AccountID
  END
  -----------------------------------------------------------
  insert into #Temp_Rep_SalesAgent(QuoteIDSeq,SalesAgentName)
  select X.Quoteidseq,Min(Coalesce(X.SalesAgentName,''))   as SalesAgentName
  From   QUOTES.dbo.QuoteSaleAgent X with (nolock)
  where  X.SalesAgentIDSeq =  coalesce(@IPI_AccountManager,X.SalesAgentIDSeq)
  group by X.Quoteidseq
  -----------------------------------------------------------  
  Insert into #Temp_Rep_QuotesDetail(QuoteIDSeq,StatusName,ExpirationDate,CustomerName,
                                     GroupIDSeq,GroupName,ProductName,ProductCode,Sites,Units,
                                     ILFMeasureName,ILFFrequencyName,ACSMeasureName,ACSFrequencyName,
                                     ILF_List,ILF_DiscPercent,ILF_NetAmount,ILFUnitPrice,
                                     ACSUnitPrice,ACS_List,ACS_DiscPercent,ACS_NetAmount_Year1,SalesAgentName,
									 QuoteType,CreatedDate,SubmittedDate,ApprovalDate,ModifiedDate,[Description],
									 DealDeskDecision,DealDeskActionDate
                                     )
  select Q.QuoteIDSeq as QuoteIDSeq,
         QS.Name      as StatusName,
         Max(Q.ExpirationDate)               as ExpirationDate,
         COM.Name           as CustomerName,
         G.IDSeq            as GroupIDSeq,
         G.Name             as GroupName,
         PRD.DisplayName    as ProductName,
         QI.ProductCode     as ProductCode,
         ------------------------------------
         Max(QI.Sites)      as Sites,
         Max(QI.Units)      as Units,
         ------------------------------------
         Max(case when (QI.chargetypecode = 'ILF') then M.Name
		  else ''
	     end)	                                                   as ILFMeasureName,
         Max(case when (QI.chargetypecode = 'ILF') then F.Name
		  else ''
	     end)	                                                   as ILFFrequencyName,
         ------------------------------------
         Max(case when (QI.chargetypecode = 'ACS') then M.Name
		  else ''
	     end)	                                                   as ACSMeasureName,
         Max(case when (QI.chargetypecode = 'ACS') then F.Name
		  else ''
	     end)	                                                   as ACSFrequencyName,
         ------------------------------------
         Sum(case when (QI.chargetypecode = 'ILF') then convert(NUMERIC(30,2),QI.ExtYear1ChargeAmount)                                                                 
		  else 0
	     end)	                                                   as ILF_List, 
         Sum(case when (QI.chargetypecode = 'ILF') then convert(NUMERIC(30,2),QI.TotalDiscountPercent)
		  else 0
	     end)	                                                   as ILF_DiscPercent, 
         Sum(case when (QI.chargetypecode = 'ILF') then convert(NUMERIC(30,2),QI.NetExtYear1ChargeAmount)
		  else 0
	     end)	                                                   as ILF_NetAmount, 
         Sum(case when (QI.chargetypecode = 'ILF') then convert(NUMERIC(30,2),
                                                                  QI.NetExtYear1ChargeAmount
                                                                  /(case when QI.Multiplier = 0 then 1 else QI.Multiplier end)
                                                                )
		  else 0
	     end)	                                                   as ILFUnitPrice, 
         ------------------------------------
         Sum(case when (QI.chargetypecode = 'ACS') then  convert(NUMERIC(30,2),
                                                                  QI.NetExtYear1ChargeAmount
                                                                  /(case when QI.Multiplier = 0 then 1 else QI.Multiplier end)
                                                                )
		  else 0
	     end)	                                                   as ACSUnitPrice, 
         Sum(case when (QI.chargetypecode = 'ACS') then convert(NUMERIC(30,2),QI.ExtYear1ChargeAmount)
		  else 0
	     end)	                                                   as ACS_List, 
         Sum(case when (QI.chargetypecode = 'ACS') then convert(NUMERIC(30,2),QI.TotalDiscountPercent)
		  else 0
	     end)	                                                   as ACS_DiscPercent, 
         Sum(case when (QI.chargetypecode = 'ACS') then convert(NUMERIC(30,2),QI.NetExtYear1ChargeAmount)
		  else 0
	     end)	                                                   as ACS_NetAmount_Year1,   
         ------------------------------------
         Min(Coalesce(QSA.SalesAgentName,''))                              as SalesAgentName,
		 ------------------------------------
		 QT.Name														   as QuoteType,
         --''                                                              as SalesAgentName
         Q.CreateDate							 					   as CreatedDate,
         Q.SubmittedDate											   as SubmittedDate,
         Q.ApprovalDate											       as ApprovalDate,
         Q.ModifiedDate				                            	   as ModifiedDate,
		 Q.Description												   as [Description],
		 DQS.Name																AS DealDeskDecision,
		 coalesce(max(Q.DealDeskResolvedDate), max(Q.DealDeskQueuedDate))       AS DealDeskActionDate	
          
  from   QUOTES.dbo.Quote       Q   with (nolock)

  inner join
         Quotes.dbo.QuoteType QT with (nolock)
  on     Q.QuoteTypeCode = QT.Code
  and    Q.QuoteTypeCode = isnull(@IPVC_QuoteType,Q.QuoteTypeCode)

  inner join
         CUSTOMERS.dbo.Company  COM with (nolock)
  on     Q.CustomerIDSeq = COM.IDSeq
  and    Q.QuoteIDSeq    = coalesce(@IPVC_Quoteid,Q.Quoteidseq)
--  and    coalesce(Q.CreatedByIDSeq,'')= coalesce(@IPI_CreatedBy,coalesce(Q.CreatedByIDSeq,''))
  and    Q.CreatedBy = isnull((select Customers.dbo.fnGetUserNamefromID(@IPI_CreatedBy)), Q.CreatedBy)
  and    Q.QuoteStatusCode = coalesce(@IPC_QuoteStatus,Q.QuoteStatusCode)
  and    Q.CustomerIDSeq = coalesce(@IPVC_CompanyID,Q.CustomerIDSeq)
  and    COM.IDSeq       = coalesce(@IPVC_CompanyID,COM.IDSeq)
  and    COM.Name        like '%' + @IPVC_CustomerName + '%'
  and     (
            --------------------------------------------------
           (
            (@IPC_QuoteStatus = 'NSU' and Q.QuoteStatusCode = 'NSU')
                       and
             convert(datetime,convert(varchar(50),Q.CreateDate,101)) >= @IPD_StartDate 
                       and
             convert(datetime,convert(varchar(50),Q.CreateDate,101)) < @IPD_EndDate
            )
           --------------------------------------------------
                       OR   
           (       
            (@IPC_QuoteStatus = 'SUB' and Q.QuoteStatusCode = 'SUB') 
                       and
             convert(datetime,convert(varchar(50),Q.SubmittedDate,101)) >= @IPD_StartDate 
                       and
             convert(datetime,convert(varchar(50),Q.SubmittedDate,101)) < @IPD_EndDate
            )
           --------------------------------------------------
                       OR        
           (  
            (@IPC_QuoteStatus = 'APR' and Q.QuoteStatusCode = 'APR') 
                       and
             convert(datetime,convert(varchar(50),Q.ApprovalDate,101)) >= coalesce(@IPD_ApprovalStartDate, @IPD_StartDate) 
                       and
             convert(datetime,convert(varchar(50),Q.ApprovalDate,101)) <  coalesce(@IPD_ApprovalEndDate, @IPD_EndDate)
            ) 
           --------------------------------------------------
                       OR      
           (    
            (@IPC_QuoteStatus = 'CNL' and Q.QuoteStatusCode = 'CNL') 
                       and
             convert(datetime,convert(varchar(50),Q.ModifiedDate,101)) >= @IPD_StartDate 
                       and
             convert(datetime,convert(varchar(50),Q.ModifiedDate,101)) < @IPD_EndDate
            ) 
           --------------------------------------------------  
                       OR        
           (      
            (@IPC_QuoteStatus is null)   
                       and  
             convert(datetime,convert(varchar(50),Q.CreateDate,101)) >= @IPD_StartDate   
                       and  
             convert(datetime,convert(varchar(50),Q.CreateDate,101)) < @IPD_EndDate  
            )   
           -------------------------------------------------- 
         )
  inner join
         Quotes.dbo.QuoteStatus QS with (nolock)
  on     Q.QuoteStatusCode = QS.Code
  and    Q.QuoteStatusCode = coalesce(@IPC_QuoteStatus,Q.QuoteStatusCode)
  and    QS.Code           = coalesce(@IPC_QuoteStatus,QS.Code)
  
  inner join
         Quotes.dbo.[Group]     G  with (nolock)
  on     G.Quoteidseq = Q.Quoteidseq
  and   ((G.grouptype = 'PMC' and @IPC_PropertyID is null)
             OR
         (G.grouptype = 'SITE' and exists (select top 1 1
                                          from   QUOTES.dbo.GroupProperties GP with (nolock)
                                          Where  GP.Quoteidseq = Q.Quoteidseq
                                          and    GP.Quoteidseq = G.Quoteidseq
                                          and    GP.QuoteIDSeq    = coalesce(@IPVC_Quoteid,GP.Quoteidseq)
                                          and    GP.PropertyIDSeq = coalesce(@IPC_PropertyID, GP.PropertyIDSeq)
                                         )
         )
         )
  inner join
         Quotes.dbo.Quoteitem   QI with (nolock)
  on     Q.Quoteidseq = QI.Quoteidseq
  and    G.IDSeq      = QI.Groupidseq
  inner join
         Products.dbo.Product  PRD with (nolock)
  on     QI.Productcode = PRD.Code
  and    QI.priceversion= PRD.priceversion
  and    PRD.PlatformCode = coalesce(@IPVC_PlatformCode, PRD.PlatformCode)
  and    PRD.FamilyCode   = coalesce(@IPVC_FamilyCode,   PRD.FamilyCode)
  and    PRD.CategoryCode = coalesce(@IPVC_CategoryCode, PRD.CategoryCode)
  and    PRD.DisplayName  like '%' + @IPVC_ProductName + '%'
  inner join
         Products.dbo.Measure M with (nolock)
  on     QI.Measurecode   = M.code
  inner join
         Products.dbo.Frequency F with (nolock)
  on     QI.Frequencycode = F.code
  inner join
         #Temp_Rep_SalesAgent QSA
  on    Q.Quoteidseq = QSA.Quoteidseq
  left outer join
         Quotes.dbo.QuoteStatus DQS with (nolock)
  on     Q.DealDeskStatusCode = DQS.Code
 
  Group by Q.QuoteIDSeq,Q.QuoteStatusCode,QS.Name,
           COM.IDSeq,COM.Name,G.IDSeq,G.Name,QI.ProductCode,PRD.DisplayName,QT.Name,Q.CreateDate,Q.SubmittedDate,Q.ApprovalDate,Q.ModifiedDate,Q.Description,DQS.Name
  Order by COM.Name,Q.QuoteIDSeq,G.Name,G.IDSeq,PRD.DisplayName
  -------------------------------------------------------------------------------
  ---Final Select for Report
  Select QuoteIDSeq,StatusName,ExpirationDate,CustomerName,
         GroupName,ProductName,
         Sites,Units,
         MeasureCode,FrequencyName,
         ILF_List,ILF_DiscPercent,ILF_NetAmount,
         ACSUnitPrice as UnitPrice,
         ACS_List,ACS_DiscPercent,ACS_NetAmount_Year1,TotalValue_NetAmount,
         TotalValue_List,TotalValue_DiscPercent
         ,SalesAgentName,QuoteType,CreatedDate,SubmittedDate,ApprovalDate,ModifiedDate,[Description]
		 ,DealDeskDecision,DealDeskActionDate
  from #Temp_Rep_QuotesDetail with (nolock)
  order by Sortseq asc
  --------------------------------------------------------------------------------
  --Fianl Cleanup
  drop table #Temp_Rep_QuotesDetail
  drop table #Temp_Rep_SalesAgent
  --------------------------------------------------------------------------------
END
GO
