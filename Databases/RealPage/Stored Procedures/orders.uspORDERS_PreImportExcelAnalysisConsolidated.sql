SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_PreImportExcelAnalysisConsolidated]
-- Description     : This Proc Imports XLS into a temporary table, Analyses and returns result with all
--                   identifying information to UI for Final Confimation from User.
--                   On Click of Final import button from UI, for each of non Errored orderitems
--                   uspORDERS_FinalImportExcel SP is to be called.

-- Input Parameters: 
--                     @IPVC_ProductCode       varchar(2000), ---This is from Drop down user selects.
--                     @IPXML_ExcelXML         xml
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : SRS #6120
-- 09/20/2009      : 
-- 05/10/2010      : SRS #7677
------------------------------------------------------------------------------------------------------
Create Procedure [orders].[uspORDERS_PreImportExcelAnalysisConsolidated]  (@IPXML_ExcelXML    XML
                                                                       ) --WITH RECOMPILE
AS
BEGIN
    set nocount on;  
  SET CONCAT_NULL_YIELDS_NULL OFF;  
  ------------------------------------------------------------------------  
  declare  @LDT_MinDateRange  datetime;  
  declare  @LDT_MaxDateRange  datetime;  
    
  select  @LDT_MinDateRange = convert(datetime,convert(varchar(50),dateadd(m,-12,getdate()),101)) ---> 12 Months prior to current system date  
         ,@LDT_MaxDateRange = convert(datetime,convert(varchar(50),dateadd(m,12,getdate()),101))  ---> 12 Months forward to current system date    
  ------------------------------------------------------------------------  
  if (object_id('tempdb.dbo.#LT_PreImportExcelAnalysis') is not null)   
  begin  
    drop table #LT_PreImportExcelAnalysis;  
  end;  
  if (object_id('tempdb.dbo.#LT_PreImportStatistics') is not null)   
  begin  
    drop table #LT_PreImportStatistics;  
  end;  
  ------------------------------------------------------------------------  
  --Temporary Table Creation  
  Create Table #LT_PreImportExcelAnalysis  (SortSeq                    bigint not null identity(1,1),  
                                            XLSPMCID                   varchar(100)  null,  
                                            XLSSITEID                  varchar(100)  null,  
                                            XLSPMCNAME                 varchar(500)  null,  
                                            XLSSITENAME                varchar(500)  null,  
                                            XLSSourceTransactionID     varchar(100)  null,  
                                            XLSTransactionDescription  varchar(max)  null,  
                                            XLSQuantity                varchar(100)  null,  
                                            XLSUnitCostAmount          varchar(100)  null,  
                                            XLSOverrideFlag            varchar(10)   null,  
                                            XLSTransactionDate         varchar(50)   null,  
                                            ------------------------------------------------  
                                            ValidationErrorFlag        int           NOT NULL DEFAULT (0),  
                                            ValidationErrorSortSeq     int           NOT NULL default (100),  
                                            ValidationErrorMessage     varchar(8000) NULL,  
                                            InternalProcessedFlag      int           NOT NULL DEFAULT (0),  
                                            ------------------------------------------------  
                                            TransactionServiceDate     datetime      NULL,  
                                            CompanyIDSeq               varchar(50)   NULL,  
                                            PropertyIDSeq              varchar(50)   NULL,  
                                            AccountIDSeq               varchar(50)   NULL,  
                                            AccountName                varchar(500)  NULL,  
                                            Accounttype                varchar(50)   NULL,  
                                            ProductCode                varchar(50)   NULL,  
                                            PriceVersion               varchar(50)   NULL,  
                                            ProductName                varchar(255)  NULL,  
                                            OrderIDSeq                 varchar(50)   NULL,  
                                            OrderGroupIDSeq            bigint        NULL,  
                                            OrderItemIDSeq             bigint        NULL,  
                                            SOCChargeAmount            numeric(30,4) NULL,                                             
                                            ------------------------------------------------  
                                            ImportableTransactionFlag  int           NOT NULL DEFAULT (0),  
                                            TranEnablerRecordFoundFlag int           NOT NULL DEFAULT (0),                                              
                                            -------------------------------------------------  
                                            ---calculated columns  
                                            ListPrice                  as (case when isnumeric(XLSOverrideFlag)=1   
                                                                                  then  
                                                                                     (Case when  convert(numeric(30,0),XLSOverrideFlag)=1   
                                                                                             then (case when isnumeric(XLSUnitCostAmount)=1 then convert(numeric(30,4),XLSUnitCostAmount)  
                                                                                                        else 0    
                                                                                                   end)  
                                                                                           When  convert(numeric(30,0),XLSOverrideFlag)=0   
                                                                                             then (case when isnumeric(SOCChargeAmount)=1 then convert(numeric(30,4),SOCChargeAmount)  
                                                                                                        else 0    
                                                                                                   end)   
                                                                                      end)  
                                                                            else 0  
                                                                          end),  
                                            Quantity                   as (case when isnumeric(XLSQuantity)=1 then convert(numeric(30,0),XLSQuantity)   
                                                                                else 0  
                                                                           end),  
                                            NetPrice                   as (case when isnumeric(XLSOverrideFlag)=1   
                                                                                  then  
                                                                                    (case when convert(numeric(30,0),XLSOverrideFlag)=1   
                                                                                            then (case when (isnumeric(XLSUnitCostAmount)=1 and  
                                                     isnumeric(XLSQuantity)=1  
                                                                                                             )  
                                                                                                         then convert(numeric(30,4),XLSUnitCostAmount)* convert(numeric(30,0),XLSQuantity)  
                                                                                                        else 0  
                                                                                                   end)   
                                                                                          when convert(numeric(30,0),XLSOverrideFlag)=0   
                                                                                            then (case when (isnumeric(SOCChargeAmount)=1 and  
                                                                                                             isnumeric(XLSQuantity)=1  
                                                                                                            )  
                                                                                                         then convert(numeric(30,4),SOCChargeAmount)* convert(numeric(30,0),XLSQuantity)  
                                                                                                       else 0  
                                                                                                   end)   
                                                                                          else 0  
                                                                                      end)  
                                                                            else 0  
                                                                            end)  
                                            -------------------------------------------------   
                                            PRIMARY KEY CLUSTERED   
                                              (  
                                          [SortSeq] ASC  
                                              )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]  
                                            ) ON [PRIMARY];  
  
  create table #LT_PreImportStatistics(sortseq                          int,  
                                       LegendName                       varchar(200),  
                                       LegendColor                      varchar(50),  
                                       RecordCount                      bigint not null default(0),  
                                       EstimatedTotalNetChargeAmount    numeric(30,4) not null default(0.0000)  
                                       PRIMARY KEY CLUSTERED   
                                        (  
                                  [SortSeq] ASC  
                                        )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]  
                                       );    
  -----------------------------------------------------------------------------------  
  declare @idoc  int;  
  -----------------------------------------------------------------------------------  
  --Create Handle to access newly created internal representation of the XML document  
  -----------------------------------------------------------------------------------  
  EXEC sp_xml_preparedocument @idoc OUTPUT,@IPXML_ExcelXML;  
  -----------------------------------------------------------------------------------  
  --Step 1 : OPENXML to read XML and Import raw data as such into Temp table With NO Validations  
  -----------------------------------------------------------------------------------    
  BEGIN TRY  
  Insert into #LT_PreImportExcelAnalysis(XLSPMCID,XLSSITEID,XLSPMCNAME,XLSSITENAME,XLSSourceTransactionID,XLSTransactionDescription,  
                                           XLSQuantity,XLSUnitCostAmount,XLSOverrideFlag,XLSTransactionDate,ProductCode  
                                          )  
    select A.XLSPMCID,A.XLSSITEID,A.XLSPMCNAME,A.XLSSITENAME,A.XLSSourceTransactionID,A.XLSTransactionDescription,  
           A.XLSQuantity,A.XLSUnitCostAmount,A.XLSOverrideFlag,A.XLSTransactionDate,A.ProductCode  
    from   (select NULLIF(ltrim(rtrim(pmcid)),'')          as XLSPMCID,  
                   NULLIF(ltrim(rtrim(siteid)),'')         as XLSSITEID,  
                   NULLIF(ltrim(rtrim(pmcname)),'')        as XLSPMCNAME,  
                   NULLIF(ltrim(rtrim(sitename)),'')       as XLSSITENAME,  
                   NULLIF(ltrim(rtrim(tranid)),'')         as XLSSourceTransactionID,  
                   NULLIF(ltrim(rtrim([description])),'')  as XLSTransactionDescription,  
                   quantity                                as XLSQuantity,  
                   unitprice                               as XLSUnitCostAmount,  
                   [override]                              as XLSOverrideFlag,                                
                   [date]                                  as XLSTransactionDate,                   
                   productcode                             as ProductCode                      
             from OPENXML (@idoc,'root/row',1)   
             with (pmcid              varchar(100),  
                   siteid             varchar(100),                                  
                   pmcname            varchar(500),  
                   sitename           varchar(500),  
                   tranid             varchar(100),  
                   [description]      varchar(max),  
                   quantity           varchar(50),  
                   unitprice          varchar(50),  
                   [override]         varchar(50),  
                   [date]             varchar(50),  
                   productcode        varchar(50)  
                 )  
           ) A  
    order by A.XLSSITENAME ASC,A.XLSPMCNAME ASC,A.XLSTransactionDate ASC,A.XLSTransactionDescription ASC  
  
    ---Step 1.1 --Delete Junk Rows id any from #LT_PreImportExcelAnalysis   
    Delete from #LT_PreImportExcelAnalysis  
    where (   
           (XLSPMCID is null and XLSSITEID is null and XLSPMCNAME is null and XLSSITENAME is null and  
            XLSSourceTransactionID is null and XLSTransactionDescription is null and XLSQuantity is null and   
            (XLSUnitCostAmount is null OR XLSUnitCostAmount ='0') and XLSOverrideFlag is null and XLSTransactionDate is null  
           )  
            OR  
           (XLSPMCID ='' and XLSSITEID ='' and XLSPMCNAME ='' and XLSSITENAME ='' and  
            XLSSourceTransactionID ='' and XLSTransactionDescription ='' and isnumeric(XLSQuantity) =0 and   
            isnumeric(XLSUnitCostAmount) =0 and isnumeric(XLSOverrideFlag) =0 and isdate(XLSTransactionDate)=0  
           )  
         )  
   END TRY  
   BEGIN CATCH       
     Update #LT_PreImportExcelAnalysis  
     set    ValidationErrorSortSeq = 1,  
            ValidationErrorFlag    = 1,  
            InternalProcessedFlag  = 1,  
            ValidationErrorMessage = 'OMS Unable to Process Excel Row(s) XML PARSE ERROR. Input Excel has no valid row(s) or Possibly Corrupt XML.'  
     where  ValidationErrorFlag  =0  
     and    InternalProcessedFlag=0   
  
     if @idoc is not null  
     begin  
       EXEC sp_xml_removedocument @idoc  
       set @idoc = NULL  
     end   
     GOTO FinalSelect  
     return  
   END   CATCH  
  ------------------------------------------------------------------------  
  --Preliminary Update  
  Update #LT_PreImportExcelAnalysis  
  set    AccountName = Coalesce(nullif(XLSSITENAME,''),nullif(XLSPMCNAME,'')),  
         Accounttype = (case when nullif(XLSSITEID,'') is not null then 'Property'  
             when nullif(XLSPMCID,'')  is not null then 'Company'  
                             else 'Unknown'  
                        end)   
    
  Update D  
  set    D.ProductName = S.Displayname  
  from   #LT_PreImportExcelAnalysis D with (nolock)  
  inner join  
         Products.dbo.Product       S with (nolock)  
  on     D.ProductCode = S.Code  
  and    S.DisabledFlag= 0   
  ------------------------------------------------------------------------  
  --Step 2: Preliminary Mandatory Temp data validation for attributes.  
  ------------------------------------------------------------------------  
  --2.1 -- Raw data : PMCID Is Null validation  
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 1,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'PMC ID is not filled in Excel. PMC ID is mandatory.'  
  where  ValidationErrorFlag  =0  
  and    InternalProcessedFlag=0  
  and    (XLSPMCID is NULL or XLSPMCID = '' or XLSPMCID = NULL)  
  ------------------------  
  --2.2 -- Raw data : Both PMCID and SITEID is NULL  
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 2,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'PMC ID and SITE ID are not filled in Excel. PMC ID is mandatory.'  
  where  ValidationErrorFlag  =0  
  and    InternalProcessedFlag=0  
  and    (XLSPMCID  is NULL  or XLSPMCID  = ''  or XLSPMCID  = NULL or XLSPMCID  = 'NULL')  
  and    (XLSSITEID is NULL  or XLSSITEID = ''  or XLSSITEID = NULL or XLSSITEID = 'NULL')  
  ------------------------  
  --2.3 -- Raw data : Both PMCID and SITEID is NOT NULL and Mixed OMS and 7 digit sitemasterid  
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 3,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'PMC ID and SITE ID identifiers cannot be mixed. Enter either OMS System IDs or 7 digit SiteMasterIDs.'  
  where  ValidationErrorFlag  =0  
  and    InternalProcessedFlag=0  
  and    (XLSPMCID  is NOT NULL  and XLSPMCID  <> ''  and XLSPMCID  <> 'NULL')  
  and    (XLSSITEID is NOT NULL  and XLSSITEID <> ''  and XLSSITEID <> 'NULL')  
  and    ((isnumeric(XLSPMCID)=1 and isnumeric(XLSSITEID)=0)  
            OR  
          (isnumeric(XLSPMCID)=0 and isnumeric(XLSSITEID)=1)  
         )  
  ------------------------  
  --2.4 --Raw Data : Quantity is Non Numeric  
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 4,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'Quantity is not valid. Quantity should be a whole number and can be either 1 or greater.'  
  where  ValidationErrorFlag  =0  
  and    InternalProcessedFlag=0  
  and    (isnumeric(XLSQuantity)=  0  
            OR  
          XLSQuantity < '1'  
            OR  
          XLSQuantity LIKE '%[^0-9]%'  
         )   
  ------------------------  
  --2.5 --Raw Data : XLSOverrideFlag should be either 1 or 0  
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 5,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'OverrideFlag is not valid. It should be 1 or 0.'  
  where  ValidationErrorFlag    = 0  
  and    InternalProcessedFlag  = 0    
  and    (isnumeric(XLSOverrideFlag)  =  0  
            OR  
          XLSOverrideFlag not in ('0','1')  
            OR   
          XLSOverrideFlag LIKE '%[^0-9]%'  
         )  
  ------------------------  
  --2.6 --Raw Data : XLSTransactionDate should be valid date and also not 1/1/1900 date  
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 6,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'Transaction Date is not valid.'  
  where  ValidationErrorFlag    = 0  
  and    InternalProcessedFlag  = 0     
  and    (ISDATE(XLSTransactionDate) = 0 or  
          XLSTransactionDate is null     or  
          XLSTransactionDate = ''        or  
          XLSTransactionDate = '01/01/1900'  
         )  
  ------------------------  
  --2.7 --Raw Data : XLSTransactionDate should be valid date and Date must be within the range of 12 months from current system date  
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 7,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'Transaction Date is not within valid date range. Date must be within the range of 12 months from current system date.'  
  where  ValidationErrorFlag    = 0  
  and    InternalProcessedFlag  = 0     
  and    ISDATE(XLSTransactionDate) = 1  
  and    NOT ((case when ISDATE(XLSTransactionDate) = 1   
                     then convert(datetime,XLSTransactionDate)   
                    else  convert(datetime,'01/01/3000')   
               end)  >=  @LDT_MinDateRange  
                and  
              (case when ISDATE(XLSTransactionDate) = 1   
                     then convert(datetime,XLSTransactionDate)   
                    else  convert(datetime,'01/01/3000')   
               end) <=  @LDT_MaxDateRange  
             )           
  ------------------------  
  --2.8 --Raw Data : Amount is Non Numeric or less than 0 (negative number) for XLSOverrideFlag = 1  
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 8,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'Amount is not valid. Amount can be 0.00 or greater when Override is 1.'  
  where  ValidationErrorFlag    = 0  
  and    InternalProcessedFlag  = 0   
  and    (isnumeric(XLSUnitCostAmount)=  0  
            or  
          XLSUnitCostAmount < convert(numeric(30,10),'0.00')  
         )   
  and    (isnumeric(XLSOverrideFlag)  =  1    
           and  
          XLSOverrideFlag = '1'  
         )  
  ------------------------   
  --2.9 --Raw Data : Amount is Non Numeric for XLSOverrideFlag = 1  
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 9,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'Amount is not valid. Amount should be left at $0.00 if Override is 0.'  
  where  ValidationErrorFlag    = 0  
  and    InternalProcessedFlag  = 0   
  and    (isnumeric(XLSUnitCostAmount)=  0  
            or  
          XLSUnitCostAmount <> convert(numeric(30,10),'0.00')  
         )   
  and    (isnumeric(XLSOverrideFlag)  =  1    
           and  
          XLSOverrideFlag = '0'  
         )  
  ------------------------    
  --2.10 --Raw Data : Description cannot be blank  
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 10,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'Description is not valid. Description cannot be blank.'  
  where  ValidationErrorFlag    = 0  
  and    InternalProcessedFlag  = 0   
  and    (len(ltrim(rtrim(XLSTransactionDescription))) =0  
           OR  
          ltrim(rtrim(XLSTransactionDescription)) = ''  
           OR  
          ltrim(rtrim(XLSTransactionDescription)) is NULL  
         )  
  ------------------------  
  --2.11 --Raw Data : Description is limited to 255 characters  
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 11,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'Description is longer than 255 characters. Description should be limited to 255 characters.'  
  where  ValidationErrorFlag    = 0  
  and    InternalProcessedFlag  = 0   
  and    len(ltrim(rtrim(XLSTransactionDescription))) > 255  
  ------------------------    
  --2.11 --Raw Data : Productcode should be valid  
  Update D  
  set    D.ValidationErrorSortSeq = 12,  
         D.ValidationErrorFlag    = 1,  
         D.InternalProcessedFlag  = 1,  
         D.ValidationErrorMessage = 'ProductCode in Excel:' + coalesce(D.ProductCode,'') + ' is not valid active OMS product',  
         D.ProductName            = NULL  
  from   #LT_PreImportExcelAnalysis D with (nolock)  
  where  D.ValidationErrorFlag    = 0  
  and    D.InternalProcessedFlag  = 0   
  and    not exists (select top 1 1  
                     from   products.dbo.product P with (nolock)  
                     where  P.disabledflag = 0  
                     and    P.Code = coalesce(D.Productcode,'')  
                    )    
  if not exists(select top 1 1 from #LT_PreImportExcelAnalysis with (nolock) where InternalProcessedFlag=0)  
  begin  
    GOTO FinalSelect  
    return  
  end   
  ------------------------------------------------------------------------------------------    
  --Step 3 : Based on XLSPMCID and XLSSITEID Find if Muliple active accounts exists in OMS   
  --         Report as Error  
  --3.1 First pass : Get for those records which are ValidationErrorFlag=0 with AccountIDSeq as NULL  
  --                    and those that have both XLSPMCID and XLSSITEID filled and   
  --                    have mulitple active accounts  
  Update D  
  set    D.ValidationErrorSortSeq = 20,  
         D.ValidationErrorFlag    = 1,  
         D.InternalProcessedFlag  = 1,  
         D.ValidationErrorMessage = 'Multiple Active OMS Accounts Located for Company:'+D.XLSPMCID + ',Property:'+D.XLSSITEID  
  from   #LT_PreImportExcelAnalysis D with (nolock)  
  inner join  
         (select A.IDSeq as AccountIDSeq,C.IDSeq as CompanyIDSeq,P.IDSeq as PropertyIDSeq,  
                 T.XLSPMCID as XLSPMCID,T.XLSSITEID as XLSSITEID  
          from   Customers.dbo.Account  A with (nolock)  
          inner join  
                 Customers.dbo.Property P with (nolock)  
          on     A.PropertyIdSeq  = P.IdSeq  
          and    A.CompanyIDSeq   = P.PMCIDSeq  
          and    A.AccountTypeCode= 'APROP'  
          and    P.StatusTypeCode = 'ACTIV'  
          and    A.ActiveFlag     = 1  
          inner Join  
                 Customers.dbo.Company C with (nolock)  
          on     A.CompanyIdSeq  = C.IDSeq  
          and    P.PMCIDSeq      = C.IDSeq  
          and    C.StatusTypeCode= 'ACTIV'  
          inner join  
                (select distinct x.XLSPMCID,x.XLSSITEID,x.AccountIDSeq  
                 from   #LT_PreImportExcelAnalysis x with (nolock)  
                 where  x.ValidationErrorFlag  =0  
                 and    x.InternalProcessedFlag=0  
                 and    x.AccountIDSeq is NULL  
                ) as T  
          on     (  
                   (A.CompanyIDSeq = T.XLSPMCID  
                   and  
                   P.PMCIDSeq      = T.XLSPMCID  
                   and  
                   C.IDSeq         = T.XLSPMCID  
                   )  
                   OR  
                   (C.SiteMasterId = T.XLSPMCID)  
                 )  
         AND  
                 (  
                   (A.PropertyIDSeq = T.XLSSITEID  
                   and  
                   P.IDSeq          = T.XLSSITEID          
                   )  
                   OR  
                   (P.SiteMasterId  = T.XLSSITEID)                 
                 )           
         group by A.IDSeq,C.IDSeq,P.IDSeq,T.XLSPMCID,T.XLSSITEID  
         having count(*) > 1  
        ) as Source  
  on  D.XLSPMCID = Source.XLSPMCID  
  and D.XLSSITEID= Source.XLSSITEID  
  and D.ValidationErrorFlag  =0  
  and D.InternalProcessedFlag=0  
  and D.AccountIDSeq is NULL  
  
  if not exists(select top 1 1 from #LT_PreImportExcelAnalysis with (nolock) where InternalProcessedFlag=0)  
  begin  
    GOTO FinalSelect  
    return  
  end  
  -----------------------------  
  --3.2 : Second Pass : Get for those records which are ValidationErrorFlag=0 with AccountIDSeq as NULL  
  ---                   and those that have XLSPMCID filled and XLSSITEID is null and have multiple active accounts     
  Update D  
  set    D.ValidationErrorSortSeq = 20,  
         D.ValidationErrorFlag    = 1,  
         D.InternalProcessedFlag  = 1,  
         D.ValidationErrorMessage = 'Multiple Active OMS Accounts Located for Company:'+D.XLSPMCID   
  from   #LT_PreImportExcelAnalysis D with (nolock)    
  inner join  
         (select A.IDSeq as AccountIDSeq,C.IDSeq as CompanyIDSeq,  
                 T.XLSPMCID as XLSPMCID  
          from   Customers.dbo.Account  A with (nolock)            
          inner Join  
                 Customers.dbo.Company C with (nolock)  
          on     A.CompanyIdSeq  = C.IDSeq            
          and    A.AccountTypeCode= 'AHOFF'  
          and    C.StatusTypeCode = 'ACTIV'  
          and    A.ActiveFlag     = 1   
          inner join  
                 (select distinct x.XLSPMCID,x.AccountIDSeq  
                  from   #LT_PreImportExcelAnalysis x with (nolock)  
                  where  x.ValidationErrorFlag  =0  
                  and    x.InternalProcessedFlag=0  
                  and    x.AccountIDSeq is NULL  
                  and    (x.XLSSITEID = '' or x.XLSSITEID is NULL or x.XLSSITEID = 'NULL')  
                ) as T  
          on     (  
                   (A.CompanyIDSeq = T.XLSPMCID  
                   and                     
                   C.IDSeq         = T.XLSPMCID  
                   )  
                   OR  
                   (C.SiteMasterId = T.XLSPMCID)  
                 )                        
         group by A.IDSeq,C.IDSeq,T.XLSPMCID  
         having count(*)>1  
        ) as Source  
  on  D.XLSPMCID = Source.XLSPMCID      
  and D.ValidationErrorFlag  =0  
  and D.InternalProcessedFlag=0  
  and D.AccountIDSeq is NULL  
  and (D.XLSSITEID = '' or D.XLSSITEID is NULL or D.XLSSITEID = 'NULL')  
  
  if not exists(select top 1 1 from #LT_PreImportExcelAnalysis with (nolock) where InternalProcessedFlag=0)  
  begin  
    GOTO FinalSelect  
    return  
  end  
  ------------------------------------------------------------------------------------------  
  --Step 4 : Based on XLSPMCID and XLSSITEID, Get CompanyIDSeq,PropertyIDSeq,AccountIDSeq  
  ---4.1   : First pass : Get for those records which are ValidationErrorFlag=0 with AccountIDSeq as NULL  
  ---                     and those that have both XLSPMCID and XLSSITEID filled.  
  Update D  
  set    D.AccountIDSeq = Source.AccountIDSeq,  
         D.CompanyIDSeq = Source.CompanyIDSeq,  
         D.PropertyIDSeq= Source.PropertyIDSeq,  
         D.AccountName  = Source.AccountName,  
         D.AccountType  = Source.AccountType  
  from   #LT_PreImportExcelAnalysis D with (nolock)  
  inner join  
         (select A.IDSeq as AccountIDSeq,C.IDSeq as CompanyIDSeq,P.IDSeq as PropertyIDSeq,  
                 T.XLSPMCID as XLSPMCID,T.XLSSITEID as XLSSITEID,  
                 Max(P.Name) as AccountName,'Property' as AccountType  
          from   Customers.dbo.Account  A with (nolock)  
          inner join  
                 Customers.dbo.Property P with (nolock)  
          on     A.PropertyIdSeq  = P.IdSeq  
          and    A.CompanyIDSeq   = P.PMCIDSeq  
          and    A.AccountTypeCode= 'APROP'  
          and    P.StatusTypeCode = 'ACTIV'  
          and    A.ActiveFlag     = 1  
          inner Join  
                 Customers.dbo.Company C with (nolock)  
          on     A.CompanyIdSeq  = C.IDSeq  
          and    P.PMCIDSeq      = C.IDSeq  
          and    C.StatusTypeCode= 'ACTIV'  
          inner join  
                 (select distinct x.XLSPMCID,x.XLSSITEID,x.AccountIDSeq  
                  from   #LT_PreImportExcelAnalysis x with (nolock)  
                  where  x.ValidationErrorFlag  =0  
                  and    x.InternalProcessedFlag=0  
                  and    x.AccountIDSeq is NULL  
                 ) as T  
          on     (  
                   (A.CompanyIDSeq = T.XLSPMCID  
                   and  
                   P.PMCIDSeq      = T.XLSPMCID  
                   and  
                   C.IDSeq         = T.XLSPMCID  
                   )  
                   OR  
                   (C.SiteMasterId = T.XLSPMCID)  
                 )  
         AND  
                 (  
                   (A.PropertyIDSeq = T.XLSSITEID  
                   and  
                   P.IDSeq          = T.XLSSITEID          
                   )  
                   OR  
                   (P.SiteMasterId  = T.XLSSITEID)  
                 )           
         group by A.IDSeq,C.IDSeq,P.IDSeq,T.XLSPMCID,T.XLSSITEID  
         having count(*)=1  
        ) as Source  
  on  D.XLSPMCID = Source.XLSPMCID  
  and D.XLSSITEID= Source.XLSSITEID  
  and D.ValidationErrorFlag  =0  
  and D.InternalProcessedFlag=0  
  and D.AccountIDSeq is NULL  
  -----------------------------  
  --4.2 : Second Pass : Get for those records which are ValidationErrorFlag=0 with AccountIDSeq as NULL  
  ---                   and those that have XLSPMCID filled and XLSSITEID is null      
  Update D  
  set    D.AccountIDSeq = Source.AccountIDSeq,  
         D.CompanyIDSeq = Source.CompanyIDSeq,  
         D.PropertyIDSeq= NULL,  
         D.AccountName  = Source.AccountName,  
         D.AccountType  = Source.AccountType  
  from   #LT_PreImportExcelAnalysis D with (nolock)  
  inner join  
         (select A.IDSeq as AccountIDSeq,C.IDSeq as CompanyIDSeq,  
                 T.XLSPMCID as XLSPMCID,  
                 Max(C.Name) as AccountName,'Company' as AccountType  
          from   Customers.dbo.Account  A with (nolock)            
          inner Join  
                 Customers.dbo.Company C with (nolock)  
          on     A.CompanyIdSeq  = C.IDSeq            
          and    A.AccountTypeCode= 'AHOFF'  
          and    C.StatusTypeCode = 'ACTIV'  
          and    A.ActiveFlag     = 1   
          inner join  
                 (select distinct x.XLSPMCID,x.AccountIDSeq  
                  from   #LT_PreImportExcelAnalysis x with (nolock)  
                  where  x.ValidationErrorFlag  =0  
                  and    x.InternalProcessedFlag=0  
                  and    x.AccountIDSeq is NULL  
                  and    (x.XLSSITEID = '' or x.XLSSITEID is NULL or x.XLSSITEID = 'NULL')  
                ) as T  
          on     (  
                   (A.CompanyIDSeq = T.XLSPMCID  
                   and                     
                   C.IDSeq         = T.XLSPMCID  
                   )  
                   OR  
                   (C.SiteMasterId = T.XLSPMCID)  
                 )                       
         group by A.IDSeq,C.IDSeq,T.XLSPMCID  
         having count(*)=1  
        ) as Source  
  on  D.XLSPMCID = Source.XLSPMCID      
  and D.ValidationErrorFlag  =0  
  and D.InternalProcessedFlag=0  
  and D.AccountIDSeq is NULL  
  and (D.XLSSITEID = '' or D.XLSSITEID is NULL or D.XLSSITEID = 'NULL')  
  ------------------------------------------------------------------------------------------  
  ---Step 5 : Step 3 should have gotten OMS AccountIDs. Now validate and set Error for those  
  --          that have OMS AccountID as NULL, before processing further.   
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 30,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'Active OMS AccountID not found for Company:'+XLSPMCID + ',Property:'+XLSSITEID  
  where  ValidationErrorFlag    = 0  
  and    InternalProcessedFlag  = 0     
  and    AccountIDSeq is NULL  
  
  if not exists(select top 1 1 from #LT_PreImportExcelAnalysis with (nolock) where InternalProcessedFlag=0)  
  begin  
    GOTO FinalSelect  
    return  
  end  
  ------------------------------------------------------------------------------------------  
  ---Intermediate step for TransactionServiceDate to be used below  
  Update #LT_PreImportExcelAnalysis  
  set    TransactionServiceDate = convert(datetime,convert(varchar(50),convert(datetime,XLSTransactionDate),101))  
  where  ValidationErrorFlag    = 0  
  
  if not exists(select top 1 1 from #LT_PreImportExcelAnalysis with (nolock) where InternalProcessedFlag=0)  
  begin  
    GOTO FinalSelect  
    return  
  end  
  ------------------------------------------------------------------------------------------  
  ---Step 6 : Validate if Active Subscription Order for the given account and productcode  
  --          already exists for daterange of XLSTransaction  
  --          and mark those as Errors.    
  Update D  
  set    D.ValidationErrorSortSeq = 40,  
         D.ValidationErrorFlag    = 1,  
         D.InternalProcessedFlag  = 1,  
         D.ValidationErrorMessage = 'Account:'+Source.AccountIDSeq+';Order:'+OI.OrderIDSeq+'; Fulfilled Subscription recurring Yearly or Monthly order(s) found for :'+Source.ProductName +  
                                    ' from ' + convert(varchar(50),OI.Startdate,101) + ' to ' + convert(varchar(50),coalesce(OI.Canceldate,OI.Enddate),101) +  
                                    '. Transactions cannot be imported when TransactionServiceDate falls with in this range.'  
  from   #LT_PreImportExcelAnalysis D with (nolock)  
  inner join  
         (Select O.AccountIDSeq      as AccountIDSeq,S.Productcode     as Productcode,  
                 MAX(OI.IDSeq)       as OrderitemIDSeq,  
                 Min(P.DisplayName)  as ProductName,                   
                 S.SortSeq           as SortSeq  
          from   ORDERS.dbo.[Order]         O with (nolock)  
          inner join  
                 #LT_PreImportExcelAnalysis S with (nolock)  
          on     O.AccountIDSeq = S.AccountIDSeq  
          and    S.ValidationErrorFlag  =0  
          and    S.InternalProcessedFlag=0  
          and    S.AccountIDSeq is not null  
          inner join  
                 ORDERS.dbo.[OrderItem] OI with (nolock)  
          on     O.OrderIDSeq   = OI.OrderIDSeq  
          and    OI.ProductCode = S.ProductCode  
          and    OI.Chargetypecode = 'ACS'  
          and    OI.MeasureCode   <> 'TRAN'  
          and    OI.FrequencyCode in ('YR','MN')  
          and    isdate(OI.Startdate)= 1  
          and    S.TransactionServiceDate >= OI.Startdate  
          and    S.TransactionServiceDate <= coalesce(OI.Canceldate-1,OI.Enddate)  
          inner join  
                 Products.dbo.Product P with (nolock)  
          on     OI.Productcode = P.Code  
          and    OI.PriceVersion= P.PriceVersion  
          and    OI.Productcode = S.Productcode            
          group by O.AccountIDSeq,S.Productcode,S.SortSeq  
         ) Source   
  on  D.AccountIDSeq = Source.AccountIDSeq  
  and D.ProductCode  = Source.ProductCode  
  and D.SortSeq      = Source.SortSeq  
  and D.ValidationErrorFlag  =0  
  and D.InternalProcessedFlag=0  
  and D.AccountIDSeq is not null    
  inner join  
      ORDERS.dbo.[OrderItem] OI with (nolock)  
  on   OI.IDSeq       = Source.OrderItemIDSeq  
  and  OI.Productcode = Source.ProductCode   
   
  if not exists(select top 1 1 from #LT_PreImportExcelAnalysis with (nolock) where InternalProcessedFlag=0)  
  begin  
    GOTO FinalSelect  
    return  
  end  
  ------------------------------------------------------------------------------------------  
  --Step 7 : Validation for Duplicate Orderitemtransction previous imported  
  --         for the same account, productcode,Transactionid,Transactiondate  
  Update D  
  set    D.ValidationErrorSortSeq = 50,  
         D.ValidationErrorFlag    = 1,  
         D.InternalProcessedFlag  = 1,  
         D.ValidationErrorMessage = 'Duplicate found. This transaction with same attributes has been previously imported. Duplicate Check is on same Account,Product,Transaction ID,Name,Date,AmountOverride,Amount. '  
  from   #LT_PreImportExcelAnalysis D with (nolock)  
  inner join  
         (select O.AccountIDSeq,OIT.ProductCode,S.SortSeq as SortSeq  
          from   ORDERS.dbo.[Order]         O with (nolock)  
          inner join  
                 #LT_PreImportExcelAnalysis S with (nolock)  
          on     O.AccountIDSeq = S.AccountIDSeq  
          and    S.ValidationErrorFlag  =0  
          and    S.InternalProcessedFlag=0  
          and    S.AccountIDSeq is not null  
          inner join  
                Orders.dbo.OrderItemTransaction OIT with (nolock)  
          on    O.OrderIDSeq     = OIT.OrderIDSeq  
        and   OIT.ProductCode  = S.Productcode  
          and   OIT.TransactionalFlag   = 1  
          and   OIT.SourceTransactionID = S.XLSSourceTransactionID  
          and   substring(ltrim(rtrim(OIT.TransactionItemName)),1,300) = substring(ltrim(rtrim(S.XLSTransactionDescription)),1,300)  
          and   OIT.Servicedate     = S.TransactionServiceDate  
          and   OIT.NetChargeAmount = (case when convert(numeric(30,0),XLSOverrideFlag)=1 then S.NetPrice else OIT.NetChargeAmount end)  
          group by O.AccountIDSeq,OIT.ProductCode,S.SortSeq  
         ) Source   
  on  D.AccountIDSeq = Source.AccountIDSeq  
  and D.ProductCode  = Source.ProductCode  
  and D.SortSeq      = Source.SortSeq  
  and D.ValidationErrorFlag  =0  
  and D.InternalProcessedFlag=0  
  and D.AccountIDSeq is not null  
  
  if not exists(select top 1 1 from #LT_PreImportExcelAnalysis with (nolock) where InternalProcessedFlag=0)  
  begin  
    GOTO FinalSelect  
    return  
  end  
  ------------------------------------------------------------------------------------------------  
  --Step 8 : All validation errors at this point are done. For Non Error rows,Get Order attributes.  
  ---8.1 : All valid accounts for matching productcodes    
  Update D  
  set    D.ValidationErrorFlag = 0,  
         D.PriceVersion    = OI.PriceVersion,  
         D.OrderIDSeq      = OI.OrderIDSeq,  
         D.OrderGroupIDSeq = OI.OrderGroupIDSeq,  
         D.OrderItemIDSeq  = Source.OrderItemIDSeq,  
         D.SOCChargeAmount = OI.NetchargeAmount,  
         D.ImportableTransactionFlag  = 1,  
         D.TranEnablerRecordFoundFlag = 1,  
         D.InternalProcessedFlag      = 1,  
         D.ValidationErrorMessage     = (case when len(D.XLSTransactionDescription) > 255   
                                                then 'Transaction Description is greater than 255. Only First 255 characters of Transaction Description will be considered for import. '  
                                              else ''  
                                         end)  
  from  #LT_PreImportExcelAnalysis D with (nolock)  
  inner join  
         (Select O.AccountIDSeq      as AccountIDSeq,  
                 OI.Productcode      as Productcode,                  
                 MAX(OI.IDSeq)       as OrderItemIDSeq,  
                 S.SortSeq           as SortSeq                       
          from   ORDERS.dbo.[Order]         O with (nolock)  
          inner join  
                 #LT_PreImportExcelAnalysis S with (nolock)  
          on     O.AccountIDSeq = S.AccountIDSeq  
          and    S.ValidationErrorFlag  =0  
          and    S.InternalProcessedFlag=0  
          and    S.AccountIDSeq is not null  
          and    S.TranEnablerRecordFoundFlag = 0  
          inner join  
                 ORDERS.dbo.[OrderItem] OI with (nolock)  
          on     O.OrderIDSeq   = OI.OrderIDSeq  
          and    OI.ProductCode = S.ProductCode  
          and    OI.Chargetypecode = 'ACS'  
          and    OI.MeasureCode    = 'TRAN'   
          and    OI.FrequencyCode  = 'OT'           
          and    isdate(OI.Startdate)= 1  
          and    S.TransactionServiceDate >= OI.Startdate  
          and    S.TransactionServiceDate <= coalesce(OI.Canceldate,OI.Enddate)  
          --and    S.TransactionServiceDate >= O.ApprovedDate    
          inner join  
                 Products.dbo.Product P with (nolock)  
          on     OI.Productcode = P.Code  
          and    OI.PriceVersion= P.PriceVersion  
          group by O.AccountIDSeq,OI.Productcode,S.SortSeq      
         ) Source   
  on  D.AccountIDSeq = Source.AccountIDSeq  
  and D.ProductCode  = Source.ProductCode  
  and D.SortSeq      = Source.SortSeq  
  and D.ValidationErrorFlag  =0  
  and D.InternalProcessedFlag=0  
  and D.AccountIDSeq is not null  
  and D.TranEnablerRecordFoundFlag = 0  
  inner join  
      ORDERS.dbo.[OrderItem] OI with (nolock)  
  on   OI.IDSeq = Source.OrderItemIDSeq  
  and  OI.Productcode = Source.ProductCode    
  ------------------------------------------------------------------------------------------------  
  --Step 9 : Remaining records for which TRAN enabler Order records are not found but for  
  --         user approval to create one, when product charge has TRAN Measure record   
  --         and allows TRAN enabler to be created.    
  Update D  
  set    D.ValidationErrorFlag    = 1,  
         D.ValidationErrorSortSeq = 200,           
         D.PriceVersion    = Source.PriceVersion,  
         D.OrderIDSeq      = NULL,  
         D.OrderGroupIDSeq = NULL,  
         D.OrderItemIDSeq  = NULL,  
         D.SOCChargeAmount = Source.SOCChargeAmount,  
         D.ImportableTransactionFlag  = 1,  
         D.TranEnablerRecordFoundFlag = 0,  
         D.InternalProcessedFlag  = 1,  
         D.ValidationErrorMessage =  (case when len(D.XLSTransactionDescription) > 255   
                                               then 'Transaction Description is greater than 255. Only First 255 characters of Transaction Description will be considered for import. '  
                                             else ''  
                                        end)  
  from   #LT_PreImportExcelAnalysis D with (nolock)  
  inner join  
         (select S.AccountIDSeq,C.Productcode,Max(C.Priceversion) as Priceversion,Max(C.ChargeAmount) as SOCChargeAmount,  
                 S.SortSeq as SortSeq  
          from   Products.dbo.Charge C with (nolock)  
          inner join  
                 #LT_PreImportExcelAnalysis S with (nolock)  
          on     C.Productcode = S.ProductCode  
          and    C.DisabledFlag= 0  
          and    C.Chargetypecode = 'ACS'  
          and    C.Measurecode    = 'TRAN'  
          and    C.FrequencyCode  = 'OT'  
          and    C.SystemAutoCreateEnablerFlag = 1  
          and    S.ValidationErrorFlag  =0  
          and    S.InternalProcessedFlag=0  
          and    S.AccountIDSeq is not null  
          and    S.TranEnablerRecordFoundFlag = 0  
          group by S.AccountIDSeq,C.Productcode,S.SortSeq  
         ) Source   
  on  D.AccountIDSeq = Source.AccountIDSeq  
  and D.Productcode  = Source.Productcode  
  and D.SortSeq      = Source.SortSeq      
  and D.ValidationErrorFlag    = 0  
  and D.InternalProcessedFlag  = 0   
  and D.AccountIDSeq is not null  
  and D.TranEnablerRecordFoundFlag = 0    
  ------------------------------------------------------------------------------------------------  
  --Step 10 : Remaining records for which TRAN enabler Order records are not found when product charge has TRAN Measure record   
  --         but does not allows TRAN enabler to be created.  
  --         #7677    
  Update D  
  set    D.ValidationErrorFlag    = 1,  
         D.ValidationErrorSortSeq = 15,           
         D.PriceVersion    = Source.PriceVersion,  
         D.OrderIDSeq      = NULL,  
         D.OrderGroupIDSeq = NULL,  
         D.OrderItemIDSeq  = NULL,  
         D.SOCChargeAmount = Source.SOCChargeAmount,  
         D.ImportableTransactionFlag  = 0,  
         D.TranEnablerRecordFoundFlag = 0,  
         D.InternalProcessedFlag  = 1,  
         D.ValidationErrorMessage = 'Account:'+Source.AccountIDSeq+' does not have an active order for ' + Source.ProductName +   
                                    ' and the product is not configured for system to create enabler order records.' +  
                                    ' Please create an active order for the account before importing the transaction. '  
  from   #LT_PreImportExcelAnalysis D with (nolock)  
  inner join  
         (select S.AccountIDSeq,C.Productcode,Max(C.Priceversion) as Priceversion,Max(C.ChargeAmount) as SOCChargeAmount,  
                 S.SortSeq as SortSeq,Max(S.ProductName) as ProductName  
          from   Products.dbo.Charge C with (nolock)  
          inner join  
                 #LT_PreImportExcelAnalysis S with (nolock)  
          on     C.Productcode = S.ProductCode  
          and    C.DisabledFlag= 0  
          and    C.Chargetypecode = 'ACS'  
          and    C.Measurecode    = 'TRAN'  
          and    C.FrequencyCode  = 'OT'  
          and    C.SystemAutoCreateEnablerFlag = 0  
          and    S.ValidationErrorFlag  =0  
          and    S.InternalProcessedFlag=0  
          and    S.AccountIDSeq is not null  
          and    S.TranEnablerRecordFoundFlag = 0  
          group by S.AccountIDSeq,C.Productcode,S.SortSeq  
         ) Source   
  on  D.AccountIDSeq = Source.AccountIDSeq  
  and D.Productcode  = Source.Productcode  
  and D.SortSeq      = Source.SortSeq      
  and D.ValidationErrorFlag    = 0  
  and D.InternalProcessedFlag  = 0   
  and D.AccountIDSeq is not null  
  and D.TranEnablerRecordFoundFlag = 0    
  -----------------------------------------------------------------------------------------------------  
  --Step 11 : Validation for Product to have mandatory Revenue related code and taxware code.  
  Update D  
  set    D.ValidationErrorFlag       = 1,  
         D.ValidationErrorSortSeq    = 13,  
         D.ImportableTransactionFlag = 0,           
         D.InternalProcessedFlag     = 1,  
         D.ValidationErrorMessage    =  'OMS ProductMaster does not have critical Revenue related code(s) and/or Taxware Code. Please submit Product Change Approval form. '  
                                        + coalesce(D.ValidationErrorMessage,'')  
  from   #LT_PreImportExcelAnalysis D with (nolock)  
  where  (D.ValidationErrorFlag    = 0  or D.ImportableTransactionFlag=1)  
  and    exists (select top 1 1   
                 from   Products.dbo.Charge C with (nolock)  
                 where  C.Productcode = D.ProductCode  
                 and    C.PriceVersion= D.PriceVersion  
                 and    C.Chargetypecode = 'ACS'  
                 and    C.Measurecode    = 'TRAN'  
                 and    C.FrequencyCode  = 'OT'  
                 and (  
                        (ltrim(rtrim(C.RevenueAccountCode)) is NULL or ltrim(rtrim(C.RevenueAccountCode)) = '') --> Mandatory     
                          OR  
                        (ltrim(rtrim(C.RevenueTierCode)) is NULL or ltrim(rtrim(C.RevenueTierCode)) = '') --> Mandatory            
                          OR  
                        (ltrim(rtrim(C.TaxwareCode)) is NULL or ltrim(rtrim(C.TaxwareCode)) = '') --> Mandatory                                      
                          OR    
                        (C.RevenueRecognitionCode in ('SRR','MRR') and (ltrim(rtrim(C.DeferredRevenueAccountCode)) is null or ltrim(rtrim(C.DeferredRevenueAccountCode)) = '')  
                        ) --> DeferredRevenueAccountCode is Mandatory for RevenueRecognitionCode SRR,MRR  
                     )  
                )  
  
  if not exists(select top 1 1 from #LT_PreImportExcelAnalysis with (nolock) where InternalProcessedFlag=0)  
  begin  
    GOTO FinalSelect  
    return  
  end  
  ----------------------------------------------------------------------------------------------------  
  --Step 12 : For rows with productcodes that are not processed above when product charge does not have TRAN Measure record   
  --          , mark those with a error message.  
  Update D  
  set    D.ValidationErrorSortSeq = 60,  
         D.ValidationErrorFlag    = 1,  
         D.InternalProcessedFlag  = 1,  
         D.ValidationErrorMessage = 'OMS ProductMaster does not have TRAN Enabler Charge record set up. Please submit Product Change Approval form.'  
  from   #LT_PreImportExcelAnalysis D with (nolock)  
  where  D.ValidationErrorFlag    = 0    
  and    D.OrderIDSeq is NULL   
  and    D.ImportableTransactionFlag  = 0  
  and    D.TranEnablerRecordFoundFlag = 0  
  and    not exists (select top 1 1   
                     from   Products.dbo.Charge C with (nolock)  
                     where  C.Productcode = D.ProductCode  
                     and    C.DisabledFlag= 0  
                     and    C.Chargetypecode = 'ACS'  
                     and    C.Measurecode    = 'TRAN'  
                     and    C.FrequencyCode  = 'OT'  
                    )  
  
  if not exists(select top 1 1 from #LT_PreImportExcelAnalysis with (nolock) where InternalProcessedFlag=0)  
  begin  
    GOTO FinalSelect  
    return  
  end  
  -----------------------------------------------------------------------------------------------------    
  --Step 13 : Final step : Mark Anything Left over as Unknown Errors (This scenario should not exist)  
  --          But fail safe if any of the above scenarios have not caught this.  
  Update #LT_PreImportExcelAnalysis  
  set    ValidationErrorSortSeq = 100,  
         ValidationErrorFlag    = 1,  
         InternalProcessedFlag  = 1,  
         ValidationErrorMessage = 'UnKnown Errors'  
  where  ValidationErrorFlag    = 0    
  and    (OrderIDSeq is NULL and ImportableTransactionFlag=0)  
  
  begin  
    GOTO FinalSelect  
    return  
  end    
  ----------------------------------------------------------------------------------------------------   
  ---Final Select to UI  
  ----------------------------------------------------------------------------------------------------  
  FinalSelect:  
  ----First Result Set  
  Select   
         -------------------------------------------  
         T.XLSSourceTransactionID                                                                as [User Input Tran ID],      --- (Export)  
         T.ProductCode                                                                           as [User Input ProductCode],  --- (Export)  
         T.XLSTransactionDescription                                                             as [User Input Description],  --- (Export)  
         T.XLSPMCNAME                                                                            as [User Input PMC Name],     --- (Export)  
         T.XLSPMCID                                                                              as [User Input PMC ID],       --- (Export)    
         T.XLSSITENAME                                                                           as [User Input Site Name],    --- (Export)  
         T.XLSSITEID                                                                             as [User Input Site ID],      --- (Export)  
         T.XLSQuantity                                                                           as [User Input Quantity],     --- (Export)  
         T.XLSUnitCostAmount                                                                     as [User Input Unit Price],   --- (Export)  
         T.XLSTransactionDate                                                                    as [User Input Date],         --- (Export)  
         T.XLSOverrideFlag                                                                       as [User Input Override],     --- (Export)  
         -------------------------------------------  
         ''                                                                                      as [ ],                        --- (Export delimiter column)              
         -------------------------------------------  
         ---Attributes to display in UI  
         T.XLSSourceTransactionID                                                                as SourceTransactionID,       --- pass back to db(Export and internal)  
         T.XLSTransactionDescription                                                             as Description,               --- pass back to db(Export,UI and internal)   
         T.ProductCode                                                                           as ProductCode,               --- pass back to db(internal)          
         T.PriceVersion                                                                          as PriceVersion,              --- pass back to db(internal)  
         T.ProductName                                                                           as ProductName,               --- (Export Informational)  
         T.SOCChargeAmount                                                                       as SOCChargeAmount,           --- pass back to db(internal)  
         T.CompanyIDSeq                                  as CompanyIDSeq,              --- pass back to db(internal)    
         T.PropertyIDSeq                                                                         as PropertyIDSeq,             --- pass back to db(internal)  
         T.AccountIDSeq                                                                          as AccountIDSeq,              --- pass back to db(internal)  
         T.AccountName                                                                           as AccountName,               --- (Export Informational)  
         T.AccountType                                                                           as AccountType,               --- (Export Informational)   
         -------------------------------------------          
         (case when (T.ImportableTransactionFlag=0 and T.ValidationErrorFlag = 1)  
                then convert(varchar(50),T.XLSQuantity)  
               else  convert(varchar(50),T.Quantity)  
          end)   
                                                                                                 as Quantity,                  --- pass back to db(Export,UI and internal)   
         (case when (T.ImportableTransactionFlag=0 and T.ValidationErrorFlag = 1)  
                then T.XLSUnitCostAmount  
               else  convert(varchar(50),T.ListPrice)  
         end)                                                                                    as ListPrice,                 --- pass back to db(Export,UI and internal)           
         convert(varchar(50),T.XLSOverrideFlag)                                                  as AmountOverrideFlag,        --- pass back to db  
         (case when (T.ImportableTransactionFlag=0 and T.ValidationErrorFlag = 1 and T.XLSOverrideFlag='0')  
                then '0.00'  
               else  convert(varchar(50),T.NetPrice)  
         end)                                                                                    as NetPrice,                  --- pass back to db(internal)  
         (case when (T.ImportableTransactionFlag=0 and T.ValidationErrorFlag = 1)  
                then T.XLSTransactionDate  
               else  convert(varchar(50),T.TransactionServiceDate,101)   
         end)                                                                                    as TransactionServiceDate,    --- pass back to db(Export,UI and internal)                             
         ------------------------------------------  
         ---Internal columns that are to be passed back to DB and Not displayed in UI                              
         T.OrderIDSeq                                                                            as OrderIDSeq,                --- pass back to db(internal)     
         T.OrderGroupIDSeq                                                                       as OrderGroupIDSeq,           --- pass back to db(internal)    
         T.OrderItemIDSeq                                                                        as OrderItemIDSeq,            --- pass back to db(internal)           
         ---------------------------------------           
         T.ImportableTransactionFlag                                                             as ImportableTransactionFlag, --- pass back to db(internal)  
         T.TranEnablerRecordFoundFlag                                                            as TranEnablerRecordFoundFlag,--- pass back to db(internal)  
         T.ValidationErrorFlag                                                                   as ValidationErrorFlag,       --- pass back to db(internal)  
         T.ValidationErrorMessage                                                                as ValidationErrorMessage     --- pass back to db(Export,UI and internal)  
         ------------------------------------------  
  from #LT_PreImportExcelAnalysis T with (nolock)   
  order by T.ValidationErrorSortSeq ASC,T.SortSeq ASC;  
  ----------------------------------------------------------------------------------------------------  
  --: Get Statistics after analysis.  
  ----1.1 : Critical Error  
  
  insert into #LT_PreImportStatistics(SortSeq,LegendName,LegendColor,RecordCount,EstimatedTotalNetChargeAmount)  
  select 1 as SortSeq,'Total Excel Rows' as LegendName,'' as LegendColor,count(*) as RecordCount,coalesce(sum(convert(numeric(30,5),NetPrice)),0)  
  from   #LT_PreImportExcelAnalysis with (nolock)  
  
  insert into #LT_PreImportStatistics(SortSeq,LegendName,LegendColor,RecordCount,EstimatedTotalNetChargeAmount)  
  select 2 as SortSeq,'Critical Error' as LegendName,'Red' as LegendColor,count(*) as RecordCount,coalesce(sum(convert(numeric(30,5),NetPrice)),0)  
  from   #LT_PreImportExcelAnalysis with (nolock)  
  where  ImportableTransactionFlag = 0   
  and    ValidationErrorFlag       = 1  
  
  insert into #LT_PreImportStatistics(SortSeq,LegendName,LegendColor,RecordCount,EstimatedTotalNetChargeAmount)  
  select 3 as SortSeq,'User Approval Required' as LegendName,'Yellow' as LegendColor,count(*) as RecordCount,coalesce(sum(convert(numeric(30,5),NetPrice)),0)  
  from   #LT_PreImportExcelAnalysis with (nolock)  
  where  ImportableTransactionFlag  = 1   
  and    TranEnablerRecordFoundFlag = 0  
  and    ValidationErrorFlag        = 1  
  
  insert into #LT_PreImportStatistics(SortSeq,LegendName,LegendColor,RecordCount,EstimatedTotalNetChargeAmount)  
  select 4 as SortSeq,'User Approved' as LegendName,'Blue' as LegendColor,0 as RecordCount,0.0000 as EstimatedTotalNetChargeAmount   
  
  insert into #LT_PreImportStatistics(SortSeq,LegendName,LegendColor,RecordCount,EstimatedTotalNetChargeAmount)  
  select 5 as SortSeq,'Qualifies' as LegendName,'Green' as LegendColor,count(*) as RecordCount,coalesce(sum(convert(numeric(30,5),NetPrice)),0)  
  from   #LT_PreImportExcelAnalysis with (nolock)  
  where  ImportableTransactionFlag  = 1   
  and    TranEnablerRecordFoundFlag = 1  
  and    ValidationErrorFlag        = 0  
  
  insert into #LT_PreImportStatistics(SortSeq,LegendName,LegendColor,RecordCount,EstimatedTotalNetChargeAmount)  
  select 6 as SortSeq,'Total Qualifies' as LegendName,'GreenBlue' as LegendColor,Max(RecordCount) as RecordCount,Max(EstimatedTotalNetChargeAmount) as EstimatedTotalNetChargeAmount  
  from   #LT_PreImportStatistics with (nolock)  
  where  LegendName = 'Qualifies'  
    
  ---------------------------------------------------------------------------------------------  
  ---Second Result Set  
  select LegendName,LegendColor,RecordCount,EstimatedTotalNetChargeAmount from #LT_PreImportStatistics with (nolock)  
  order by sortseq ASC;   
  ---------------------------------------------------------------------------------------------  
  ---Third Result Set : Distinct Account,Product order that require user approval  
  select Max(T.AccountName)   as AccountName,  
         T.AccountIDSeq       as AccountIDSeq,  
         Max(T.AccountType)   as AccountType,  
         Max(T.CompanyIDSeq)  as CompanyIDSeq,  
         Max(T.PropertyIDSeq) as PropertyIDSeq,  
         T.ProductCode        as ProductCode,  
         Max(T.ProductName)   as ProductName,  
         Count(1)             as TransactionCount,  
         sum(T.NetPrice)      as ClusterNetChargeAmount  
  from   #LT_PreImportExcelAnalysis T with (nolock)   
  where  T.ImportableTransactionFlag  = 1  
  and    T.TranEnablerRecordFoundFlag = 0  
  and    T.ValidationErrorFlag        = 1   
  group by  T.AccountIDSeq,T.ProductCode  
  order by  AccountName ASC,ProductName ASC;  
  ---------------------------------------------------------------------------------------------    
  ------Final Cleanup  
  ---------------------------------------------------------------------------------------------    
  if (object_id('tempdb.dbo.#LT_PreImportExcelAnalysis') is not null)   
  begin  
    drop table #LT_PreImportExcelAnalysis;  
  end;  
  if (object_id('tempdb.dbo.#LT_PreImportStatistics') is not null)   
  begin  
    drop table #LT_PreImportStatistics;  
  end;  
  if @idoc is not null  
  begin  
    EXEC sp_xml_removedocument @idoc  
    set @idoc = NULL  
  end   
  ---------------------------------------------------------------------------------------------  
END
GO
