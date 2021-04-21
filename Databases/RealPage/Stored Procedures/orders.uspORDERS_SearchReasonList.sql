SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_SearchReasonList]
-- Description     : Lists all distinct reason for the Search Reasons Maintenance Screen 1
--                   Search Parameter for Reason are 
--                   Reason : Text Box
--                   Status : Drop down with hardcoded Status : All, Active, InActive

-- Parameters       : @IPI_PageNumber,@IPI_RowsPerPage, other optional search parameters
-- Syntax  Examples : EXEC ORDERS.dbo.uspORDERS_SearchReasonList @IPI_PageNumber=1,@IPI_RowsPerPage=24,'','All',0,''
/*
EXEC ORDERS.dbo.uspORDERS_SearchReasonList @IPI_PageNumber=1,@IPI_RowsPerPage=24,@IPI_ExcelExportFlag = 0         -- Blind search UI
EXEC ORDERS.dbo.uspORDERS_SearchReasonList @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPI_ExcelExportFlag = 1  -- Blind search export to Excel

EXEC ORDERS.dbo.uspORDERS_SearchReasonList @IPI_PageNumber=1,@IPI_RowsPerPage=24,@IPVC_ReasonName='Cancel' -- Search when reasonname is typed in search

EXEC ORDERS.dbo.uspORDERS_SearchReasonList @IPI_PageNumber=1,@IPI_RowsPerPage=24,@IPVC_Status='Active' -- Search by status

---Similary different combination searches are possible. For Excel Export pass @IPI_ExcelExportFlag=1. For UI @IPI_ExcelExportFlag=0(by default)
*/
------------------------------------------------------------------------------------------------------
CREATE procedure [orders].[uspORDERS_SearchReasonList] (@IPI_PageNumber        bigint,  --> page number. Starting with 1 : Passed by UI
                                                     @IPI_RowsPerPage       bigint,  --> Records per page. Default 21 : Passed by UI. For Export of Excel, UI will pass 999999999 to get all records.
                                                     @IPVC_ReasonName       varchar(255) = '',    -->Optional. UI Text box Reason:
                                                     @IPVC_Status           varchar(20)  = 'All', -->Default is All. Other values could be Active, InActive from drop down.
                                                     @IPI_ExcelExportFlag   int          = 0 ,     -->Default is 0, which is to show in UI. But if user clicks Export to Excel,
                                                                                                  --  then call this proc with @IPI_PageNumber=1,@IPI_RowsPerPage=999999999,@IPI_ExcelExportFlag=1 
                                                                                                  --   along with other optional search criteria that user has typed if any for reasonname, Status.
													 @IPVC_Category			varchar(20)
                                                     )  																
AS
BEGIN
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL off;
  ----------------------------------------- 
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
         (Select S.ReasonCode,
                 S.ReasonName,
                 S.ReasonStatus,
                 S.CreatedBy,
                 S.CreateDate,
                 S.ModifiedBy,
                 S.ModifiedDate,
                 row_number() OVER(ORDER BY S.ReasonName) as [RowNumber],
                 Count(1) OVER()                          as TotalCountForPaging 
         ------------------------------------------------------------------------------------------------------------
         from (select  Distinct
                 R.Code                                   as ReasonCode, 
                 R.ReasonName                             as ReasonName,
                 (case when exists(select top 1 1
                                   from   ORDERS.dbo.ReasonCategory RC with (nolock)
                                   where  RC.ReasonCode = R.Code
                                   and    RC.ActiveFlag = 1
                                  )
                         then  'Active' 
                       else    'InActive'
                  end)                                  as  ReasonStatus, --> This is the derived status. If atleast one Active ReasonCategory is found then it is Active Reason;Else Inactive Reason.
                  UC.FirstName + ' ' + UC.LastName      as  CreatedBy,    
                  Convert(varchar(50),R.CreatedDate,22) as  CreateDate,   

                  (case when R.ModifiedByIDSeq is null
                          then UC.FirstName + ' ' + UC.LastName
                        else UM.FirstName + ' ' + UM.LastName
                   end)                                 as  ModifiedBy,   
                  Convert(varchar(50),coalesce(R.ModifiedDate,R.CreatedDate),22)
                                                        as  ModifiedDate  --> This is for UI Binding and also for Excel Export to show in EXCEL.
              from   ORDERS.dbo.Reason   R with (nolock)
			  inner join ReasonCategory RC on R.Code = RC.ReasonCode
              left outer join
                     Security.dbo.[User] UC with (nolock)
              on     R.CreatedByIDSeq  = UC.IDSeq
              left outer join
                     Security.dbo.[User] UM with (nolock)
              on     R.ModifiedByIDSeq = UM.IDSeq
              where  R.ReasonName like '%' + @IPVC_ReasonName + '%' 
				and  ((@IPVC_Category='') or (RC.CategoryCode=@IPVC_Category))
              ) S
         ------------------------------------------------------------------------------------------------------------
         where ((@IPVC_Status = 'All')
                    OR
                (S.ReasonStatus = @IPVC_Status)
               )
         )           
    select  tablefinal.ReasonCode,   --> UI to show as ReasonCode in Search Results and also EXCEL
            tablefinal.ReasonName,   --> UI to show as ReasonName in Search Results and also EXCEL
            tablefinal.ReasonStatus, --> This is the derived status.  UI to show as ReasonName in Search Results and also EXCEL           
            tablefinal.ModifiedBy,   --> This is for UI Binding and also for Excel Export to show in EXCEL.
            tablefinal.ModifiedDate, --> This is for UI Binding and also for Excel Export to show in EXCEL.
            tablefinal.TotalCountForPaging ---> UI to use the value of this column of the first row for Pagination. This eliminates the need for separate count(*) logic.    
    from   tablefinal
    where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
    and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
    -----------------------------------------------
  end
  else
  begin --> This is Excel Export Only.
    ;WITH tablefinal AS
         (Select S.ReasonCode,
                 S.ReasonName,
                 S.ReasonStatus,
                 S.CreatedBy,
                 S.CreateDate,
                 S.ModifiedBy,
                 S.ModifiedDate,
                 row_number() OVER(ORDER BY S.ReasonName) as [RowNumber],
                 Count(1) OVER()                          as TotalCountForPaging 
         ------------------------------------------------------------------------------------------------------------
         from (select  Distinct
                 R.Code                                   as ReasonCode, 
                 R.ReasonName                             as ReasonName,
                 (case when exists(select top 1 1
                                   from   ORDERS.dbo.ReasonCategory RC with (nolock)
                                   where  RC.ReasonCode = R.Code
                                   and    RC.ActiveFlag = 1
                                  )
                         then  'Active' 
                       else    'InActive'
                  end)                                  as  ReasonStatus, --> This is the derived status. If atleast one Active ReasonCategory is found then it is Active Reason;Else Inactive Reason.
                  UC.FirstName + ' ' + UC.LastName      as  CreatedBy,    
                  Convert(varchar(50),R.CreatedDate,22) as  CreateDate,   

                  (case when R.ModifiedByIDSeq is null
                          then UC.FirstName + ' ' + UC.LastName
                        else UM.FirstName + ' ' + UM.LastName
                   end)                                 as  ModifiedBy,   
                  Convert(varchar(50),coalesce(R.ModifiedDate,R.CreatedDate),22)
                                                        as  ModifiedDate  --> This is for UI Binding and also for Excel Export to show in EXCEL.
              from   ORDERS.dbo.Reason   R with (nolock)
			inner join ORDERS.dbo.ReasonCategory RC  on R.Code = RC.ReasonCode
              left outer join
                     Security.dbo.[User] UC with (nolock)
              on     R.CreatedByIDSeq  = UC.IDSeq
              left outer join
                     Security.dbo.[User] UM with (nolock)
              on     R.ModifiedByIDSeq = UM.IDSeq
              where  R.ReasonName like '%' + @IPVC_ReasonName + '%'
			  and  ((@IPVC_Category='') or (RC.CategoryCode=@IPVC_Category))
              ) S
         ------------------------------------------------------------------------------------------------------------
         where ((@IPVC_Status = 'All')
                    OR
                (S.ReasonStatus = @IPVC_Status)
               )
         )           
    select  tablefinal.ReasonCode as [Reason Code],   --> UI to show as ReasonCode in Search Results and also EXCEL
            tablefinal.ReasonName as [Reason Name],   --> UI to show as ReasonName in Search Results and also EXCEL
            tablefinal.ReasonStatus as [Reason Status], --> This is the derived status.  UI to show as ReasonName in Search Results and also EXCEL
            tablefinal.CreatedBy as [Created By],    --> This is only for Excel Export to show in EXCEL. Not for UI Binding 
            tablefinal.CreateDate as [Create Date],   --> This is only for Excel Export to show in EXCEL. Not for UI Binding
            tablefinal.ModifiedBy as [Modified By],   --> This is for UI Binding and also for Excel Export to show in EXCEL.
            tablefinal.ModifiedDate as [Modified Date]  --> This is for UI Binding and also for Excel Export to show in EXCEL.
    from   tablefinal
    where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
    and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
    -----------------------------------------------
  end
  
END
GO
