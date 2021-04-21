SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetCategoryList
-- Description     : This is the Main UI Search Proc for Monitor Screen
-- PreRequisites   : Exec PRODUCTS.dbo.uspPRODUCTS_GetCategory is called by UI to populate Category Code Drop down.
--                   UI will default to Blank in the drop down by default. If user selects the drop down for Code to search
--                    then UI will make that selection and also Prepopulate the corresponding Category Name and Greyout
-- Input Parameters: As below
-- Returns         : RecordSet



-- Code Example    : 
/*
--Scenario 1: Blind Search (search all) ie Category Name : Text box is blank
Exec PRODUCTS.dbo.uspPRODUCTS_GetCategoryList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_CategoryName        = ''
                                  ,@IPVC_CategoryCode        = ''                        
                                  ,@IPI_UserIDSeq           = 123

--Scenario 2 : Search for all Categorys records that have the name Site (Category Name Text Box)
Exec PRODUCTS.dbo.uspPRODUCTS_GetCategoryList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_CategoryName        = 'Conv'
                                  ,@IPVC_CategoryCode        = '' 
                                  ,@IPI_UserIDSeq           = 123

--Scenario 3 : Search for all Categorys records that have the Category Code UNIT (ie.User selected from Category drop down)
--             In this case, Category Code UNIT is selected by user from drop down for search. UI will prepopulate corresponding
--              Category Name in Category Name Text box corresponding to Drop down and grey out.
Exec PRODUCTS.dbo.uspPRODUCTS_GetCategoryList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_CategoryName        = 'L & R Conventional'
                                  ,@IPVC_CategoryCode        = 'CNV'                              
                                  ,@IPI_UserIDSeq           = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Category Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetCategoryList] (@IPI_PageNumber                  int        =1,          ---> Madatory: This is Page Number. Default is 1 and based on user click on page number.
                                                      @IPI_RowsPerPage                 int        =999999999,  ---> Madatory: This is number of records that a single page can accomodate. UI will pass 24. For Excel Export 999999999.
                                                      @IPVC_CategoryName               varchar(50)='',         ---> Optional: This is Category Name (Text box search value user may have entered. Default is blank)          
                                                      @IPVC_CategoryCode               varchar(10)='',         ---> Optional: 
                                                      @IPI_UserIDSeq                   bigint     =-1          ---> Madatory: UI will pass UserId of the person doing the operation
                                                     )
as
BEGIN --> Main Begin
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL OFF;
  -----------------------------------------------------
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)* @IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  -----------------------------------------------------
  select @IPVC_CategoryName = coalesce(nullif(ltrim(rtrim(@IPVC_CategoryName)),''),'')
        ,@IPVC_CategoryCode = nullif(ltrim(rtrim(@IPVC_CategoryCode)),'');
  ----------------------------------------------------
  ;with CTE_CategoryList (CategoryCode,CategoryName,CategoryDescription,
                          CreatedBy,CreatedDate,ModifiedBy,ModifiedDate
                         ,[RowNumber],TotalBatchCountForPaging
                        )
  as (select ltrim(rtrim(CAT.Code))                   as   CategoryCode
            ,CAT.Name                                 as   CategoryName
            ,CAT.Description                          as   CategoryDescription
            ,UC.FirstName + ' ' + UC.LastName         as   CreatedBy
            ,convert(varchar(50),CAT.CreatedDate)     as   CreatedDate
            ,UM.FirstName + ' ' + UM.LastName         as   ModifiedBy
            ,convert(varchar(50),CAT.ModifiedDate)    as   ModifiedDate
            ,row_number() OVER(ORDER BY CAT.Name asc)
                                                      as   [RowNumber]
            ,Count(1) OVER()                          as   TotalBatchCountForPaging
      from  PRODUCTS.dbo.Category CAT with (nolock) 
      left outer join
            SECURITY.dbo.[User] UC with (nolock)
      on    CAT.CreatedByIDSeq = UC.IDSeq
      left outer join
            SECURITY.dbo.[User] UM with (nolock)
      on    CAT.ModifiedByIDSeq = UM.IDSeq
      where CAT.Name like '%' + @IPVC_CategoryName + '%'
      and   CAT.Code = coalesce(@IPVC_CategoryCode,CAT.Code)
     )
  select tablefinal.CategoryCode                 as CategoryCode
        ,tablefinal.CategoryName                 as CategoryName
        ,tablefinal.CategoryDescription          as CategoryDescription
        ,tablefinal.CreatedBy                    as CreatedBy
        ,tablefinal.CreatedDate                  as CreatedDate
        ,tablefinal.ModifiedBy                   as ModifiedBy
        ,tablefinal.ModifiedDate                 as ModifiedDate
        ,tablefinal.TotalBatchCountForPaging     as TotalBatchCountForPaging
  from   CTE_CategoryList as  tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
  order by tablefinal.RowNumber asc;
END--> Main End
GO
