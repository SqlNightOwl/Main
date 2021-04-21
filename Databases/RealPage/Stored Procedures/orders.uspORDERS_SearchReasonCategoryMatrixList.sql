SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_SearchReasonCategoryMatrixList]
-- Description     : Lists all distinct reason for the Search Reasons Maintenance Screen 2
--                   Search Parameter for Reason Category Matrix Search Maintenance Screen 2 are 
--                   Reason Category Drop down : Populated by calling EXEC ORDERS.dbo.uspORDERS_GetCategory
--                   Reason : Text Box
--                   Status : Drop down with hardcoded Status : All, Active, InActive

-- Parameters      : @IPI_PageNumber,@IPI_RowsPerPage, other optional search parameters
-- Syntax examples : 
/*
EXEC ORDERS.dbo.uspORDERS_SearchReasonCategoryMatrixList @IPI_PageNumber=1,@IPI_RowsPerPage=24,@IPI_ExcelExportFlag=0         -- Blind search UI
EXEC ORDERS.dbo.uspORDERS_SearchReasonCategoryMatrixList @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPI_ExcelExportFlag=1  -- Blind search export to Excel

EXEC ORDERS.dbo.uspORDERS_SearchReasonCategoryMatrixList @IPI_PageNumber=1,@IPI_RowsPerPage=24,@IPVC_CategoryCode='CANC' -- Search when Category is selected in drop down

EXEC ORDERS.dbo.uspORDERS_SearchReasonCategoryMatrixList @IPI_PageNumber=1,@IPI_RowsPerPage=24,@IPVC_ReasonName='Cancel' -- Search when reasonname is typed in search

EXEC ORDERS.dbo.uspORDERS_SearchReasonCategoryMatrixList @IPI_PageNumber=1,@IPI_RowsPerPage=24,@IPVC_Status='Active' -- Search by status

---Similary different combination searches are possible.
*/
------------------------------------------------------------------------------------------------------------------------------------------
CREATE procedure [orders].[uspORDERS_SearchReasonCategoryMatrixList] (@IPI_PageNumber          bigint,               --> page number. Starting with 1 : Passed by UI
                                                                   @IPI_RowsPerPage         bigint,               --> Records per page. Default 21 : Passed by UI. For Export of Excel, UI will pass 999999999 to get all records.
                                                                   @IPVC_CategoryCode       varchar(20)  = '',    --> Default is Blank for all. else pass the code corresponding to categoryname selected by user.
                                                                   @IPVC_ReasonName         varchar(255) = '',    -->Optional. UI Text box Reason:
                                                                   @IPVC_Status             varchar(20)  = 'All', -->This is  Status of ReasonCategory.Default is All. Other values could be Active, InActive from drop down.
                                                                   @IPI_ExcelExportFlag     int          = 0      -->Default is 0, which is to show in UI. But if user clicks Export to Excel,
                                                                                                                    --  then call this proc with @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPI_ExcelExportFlag=1 
                                                                                                                    --   along with other optional search criteria that user has typed if any for reasonname, Status.
                                                                  )  																
AS
BEGIN
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL off;
  ----------------------------------------------------------------
  select  @IPVC_CategoryCode = nullif(@IPVC_CategoryCode,'')
  ---------------------------------------------------------------- 
  --If Excel Export only option
  if (@IPI_ExcelExportFlag=1)
  begin
    select @IPI_PageNumber  =1,
           @IPI_RowsPerPage =999999999;
  end 
  -----------------------------------------
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;  
  ----------------------------------------------------------------
  if (@IPI_ExcelExportFlag=0) ---> This means search results are only for UI
  begin
    ;WITH tablefinal AS
         (select R.Code                                 as ReasonCode, 
                 R.ReasonName                           as ReasonName,
                 C.Code                                 as CategoryCode,
                 C.CategoryName                         as CategoryName,
                 (Case when RC.InternalFlag = 0
                         then 'Internal and External'     
                       when RC.InternalFlag = 1
                         then 'Internal'  
                  end)                                  as Availability,
                 (case when RC.ActiveFlag = 1 
                         then 'Active'
                       else 'InActive'
                  end)                                  as  ReasonCategoryStatus,
                  UC.FirstName + ' ' + UC.LastName      as  CreatedBy,    
                  Convert(varchar(50),R.CreatedDate,22) as  CreateDate,   

                  (case when RC.ModifiedByIDSeq is null
                          then UC.FirstName + ' ' + UC.LastName
                        else UM.FirstName + ' ' + UM.LastName
                   end)                                 as  ModifiedBy,   
                  Convert(varchar(50),coalesce(RC.ModifiedDate,R.CreatedDate),22)
                                                        as  ModifiedDate,
                  row_number() OVER(ORDER BY C.CategoryName asc,R.ReasonName asc) as [RowNumber],
                  Count(1) OVER()                            as TotalCountForPaging 
              from   ORDERS.dbo.ReasonCategory  RC with (nolock)
              inner join
                     ORDERS.dbo.Reason R with (nolock)
              on     RC.ReasonCode = R.Code
              and    RC.CategoryCode = coalesce(@IPVC_CategoryCode,RC.CategoryCode)
              and    R.ReasonName like '%' + @IPVC_ReasonName + '%'
              inner join
                     ORDERS.dbo.Category C with (nolock)
              on     RC.CategoryCode = C.Code
              and    C.Code = coalesce(@IPVC_CategoryCode,C.Code)
              left outer join
                     Security.dbo.[User] UC with (nolock)
              on     RC.CreatedByIDSeq  = UC.IDSeq
              left outer join
                     Security.dbo.[User] UM with (nolock)
              on     RC.ModifiedByIDSeq = UM.IDSeq
              where  RC.CategoryCode = coalesce(@IPVC_CategoryCode,RC.CategoryCode)
              and    C.Code = coalesce(@IPVC_CategoryCode,C.Code)
              and    R.ReasonName like '%' + @IPVC_ReasonName + '%'
              and    ( (@IPVC_Status = 'All')
                         OR
                       (@IPVC_Status = 'Active' and RC.ActiveFlag   = 1)
                         OR
                       (@IPVC_Status = 'InActive' and RC.ActiveFlag = 0)
                     )
           )  
    select  tablefinal.ReasonCode,     --> This is only for Excel Export to show in EXCEL. Not for UI Binding to show. UI to hold it internally for passing to More-->View or More--Edit
            tablefinal.ReasonName,     --> UI to show as ReasonName in Search Results and also EXCEL. UI to hold it internally for passing to More-->View or More--Edit
            tablefinal.CategoryCode,   --> This is only for Excel Export to show in EXCEL. Not for UI Binding to show. UI to hold it internally 
            tablefinal.CategoryName,   --> UI to show as CategoryName in Search Results and also EXCEL
            tablefinal.Availability,   --> UI to show as Availability in Search Results and also EXCEL
            tablefinal.ReasonCategoryStatus, --> UI to show as Status in Search Results and also EXCEL
            tablefinal.ModifiedBy,   --> This is for UI Binding and also for Excel Export to show in EXCEL.
            tablefinal.ModifiedDate, --> This is for UI Binding and also for Excel Export to show in EXCEL.
            tablefinal.TotalCountForPaging ---> UI to use the value of this column of the first row for Pagination. This eliminates the need for separate count(*) logic.    
    from   tablefinal
    where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
    and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
    -----------------------------------------------
  end
  else
    begin
    ;WITH tablefinal AS
         (select R.Code                                 as ReasonCode, 
                 R.ReasonName                           as ReasonName,
                 C.Code                                 as CategoryCode,
                 C.CategoryName                         as CategoryName,
                 (Case when RC.InternalFlag = 0
                         then 'Internal and External'     
                       when RC.InternalFlag = 1
                         then 'Internal'  
                  end)                                  as Availability,
                 (case when RC.ActiveFlag = 1 
                         then 'Active'
                       else 'InActive'
                  end)                                  as  ReasonCategoryStatus,
                  UC.FirstName + ' ' + UC.LastName      as  CreatedBy,    
                  Convert(varchar(50),R.CreatedDate,22) as  CreateDate,   

                  (case when R.ModifiedByIDSeq is null
                          then UC.FirstName + ' ' + UC.LastName
                        else UM.FirstName + ' ' + UM.LastName
                   end)                                 as  ModifiedBy,   
                  Convert(varchar(50),coalesce(R.ModifiedDate,R.CreatedDate),22)
                                                        as  ModifiedDate,
                  row_number() OVER(ORDER BY C.CategoryName asc,R.ReasonName asc) as [RowNumber],
                  Count(1) OVER()                            as TotalCountForPaging 
              from   ORDERS.dbo.ReasonCategory  RC with (nolock)
              inner join
                     ORDERS.dbo.Reason R with (nolock)
              on     RC.ReasonCode = R.Code
              and    RC.CategoryCode = coalesce(@IPVC_CategoryCode,RC.CategoryCode)
              and    R.ReasonName like '%' + @IPVC_ReasonName + '%'
              inner join
                     ORDERS.dbo.Category C with (nolock)
              on     RC.CategoryCode = C.Code
              and    C.Code = coalesce(@IPVC_CategoryCode,C.Code)
              left outer join
                     Security.dbo.[User] UC with (nolock)
              on     RC.CreatedByIDSeq  = UC.IDSeq
              left outer join
                     Security.dbo.[User] UM with (nolock)
              on     RC.ModifiedByIDSeq = UM.IDSeq
              where  RC.CategoryCode = coalesce(@IPVC_CategoryCode,RC.CategoryCode)
              and    C.Code = coalesce(@IPVC_CategoryCode,C.Code)
              and    R.ReasonName like '%' + @IPVC_ReasonName + '%'
              and    ( (@IPVC_Status = 'All')
                         OR
                       (@IPVC_Status = 'Active' and RC.ActiveFlag   = 1)
                         OR
                       (@IPVC_Status = 'InActive' and RC.ActiveFlag = 0)
                     )
           )  
    select  tablefinal.ReasonCode as [Reason Code],     --> This is only for Excel Export to show in EXCEL. Not for UI Binding to show. UI to hold it internally
            tablefinal.ReasonName as [Reason Name],     --> UI to show as ReasonName in Search Results and also EXCEL
            tablefinal.CategoryCode  as [Category Code],   --> This is only for Excel Export to show in EXCEL. Not for UI Binding to show. UI to hold it internally
            tablefinal.CategoryName  as [Category Name],   --> UI to show as CategoryName in Search Results and also EXCEL
            tablefinal.Availability as [Availability],   --> UI to show as Availability in Search Results and also EXCEL
            tablefinal.ReasonCategoryStatus  as [Reason Category Status], --> UI to show as Status in Search Results and also EXCEL
            tablefinal.CreatedBy  as [Created By],    --> This is only for Excel Export to show in EXCEL. Not for UI Binding
            tablefinal.CreateDate  as [Create Date],   --> This is only for Excel Export to show in EXCEL. Not for UI Binding
            tablefinal.ModifiedBy  as [Modified By],   --> This is for UI Binding and also for Excel Export to show in EXCEL.
            tablefinal.ModifiedDate  as [Modified Date]  --> This is for UI Binding and also for Excel Export to show in EXCEL.
               
    from   tablefinal
    where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
    and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
    -----------------------------------------------
  end   
END
GO
