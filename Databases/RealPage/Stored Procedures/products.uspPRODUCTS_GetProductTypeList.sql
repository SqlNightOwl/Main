SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetProductTypeList
-- Description     : This is the Main UI Search Proc for Monitor Screen
-- PreRequisites   : Exec PRODUCTS.dbo.uspPRODUCTS_GetProductType is called by UI to populate ProductType Code Drop down.
--                   UI will default to Blank in the drop down by default. If user selects the drop down for Code to search
--                    then UI will make that selection and also Prepopulate the corresponding ProductType Name and Greyout
-- Input Parameters: As below
-- Returns         : RecordSet



-- Code Example    : 
/*
--Scenario 1: Blind Search (search all) ie ProductType Name : Text box is blank
Exec PRODUCTS.dbo.uspPRODUCTS_GetProductTypeList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_ProductTypeName    = ''
                                  ,@IPVC_ProductTypeCode    = ''                        
                                  ,@IPI_UserIDSeq           = 123

--Scenario 2 : Search for all ProductTypes records that have the name Site (ProductType Name Text Box)
Exec PRODUCTS.dbo.uspPRODUCTS_GetProductTypeList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_ProductTypeName    = 'Conv'
                                  ,@IPVC_ProductTypeCode    = '' 
                                  ,@IPI_UserIDSeq           = 123

--Scenario 3 : Search for all ProductTypes records that have the ProductType Code UNIT (ie.User selected from ProductType drop down)
--             In this case, ProductType Code UNIT is selected by user from drop down for search. UI will prepopulate corresponding
--              ProductType Name in ProductType Name Text box corresponding to Drop down and grey out.
Exec PRODUCTS.dbo.uspPRODUCTS_GetProductTypeList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_ProductTypeName    = 'L & R Conventional'
                                  ,@IPVC_ProductTypeCode    = 'CNV'                              
                                  ,@IPI_UserIDSeq           = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration ProductType Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetProductTypeList] (@IPI_PageNumber                  int        =1,          ---> Madatory: This is Page Number. Default is 1 and based on user click on page number.
                                                         @IPI_RowsPerPage                 int        =999999999,  ---> Madatory: This is number of records that a single page can accomodate. UI will pass 24. For Excel Export 999999999.
                                                         @IPVC_ProductTypeName            varchar(50)='',         ---> Optional: This is ProductType Name (Text box search value user may have entered. Default is blank)          
                                                         @IPVC_ProductTypeCode            varchar(10)='',         ---> Optional: 
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
  select @IPVC_ProductTypeName = coalesce(nullif(ltrim(rtrim(@IPVC_ProductTypeName)),''),'')
        ,@IPVC_ProductTypeCode = nullif(ltrim(rtrim(@IPVC_ProductTypeCode)),'');
  ----------------------------------------------------
  ;with CTE_ProductTypeList (ProductTypeCode,ProductTypeName,ProductTypeDescription,
                             ReportPrimaryProductFlag,
                             CreatedBy,CreatedDate,ModifiedBy,ModifiedDate
                            ,[RowNumber],TotalBatchCountForPaging
                        )
  as (select ltrim(rtrim(PT.Code))                    as   ProductTypeCode
            ,PT.Name                                  as   ProductTypeName
            ,PT.Description                           as   ProductTypeDescription
            ,convert(int,PT.ReportPrimaryProductFlag) as   ReportPrimaryProductFlag
            ,UC.FirstName + ' ' + UC.LastName         as   CreatedBy
            ,convert(varchar(50),PT.CreatedDate)      as   CreatedDate
            ,UM.FirstName + ' ' + UM.LastName         as   ModifiedBy
            ,convert(varchar(50),PT.ModifiedDate)     as   ModifiedDate
            ,row_number() OVER(ORDER BY PT.Name asc)
                                                      as   [RowNumber]
            ,Count(1) OVER()                          as   TotalBatchCountForPaging
      from  PRODUCTS.dbo.ProductType PT with (nolock) 
      left outer join
            SECURITY.dbo.[User] UC with (nolock)
      on    PT.CreatedByIDSeq = UC.IDSeq
      left outer join
            SECURITY.dbo.[User] UM with (nolock)
      on    PT.ModifiedByIDSeq = UM.IDSeq
      where PT.Name like '%' + @IPVC_ProductTypeName + '%'
      and   PT.Code = coalesce(@IPVC_ProductTypeCode,PT.Code)
     )
  select tablefinal.ProductTypeCode              as ProductTypeCode
        ,tablefinal.ProductTypeName              as ProductTypeName
        ,tablefinal.ProductTypeDescription       as ProductTypeDescription
        ,tablefinal.ReportPrimaryProductFlag     as PPCReportPrimaryProductFlag
        ,tablefinal.CreatedBy                    as CreatedBy
        ,tablefinal.CreatedDate                  as CreatedDate
        ,tablefinal.ModifiedBy                   as ModifiedBy
        ,tablefinal.ModifiedDate                 as ModifiedDate
        ,tablefinal.TotalBatchCountForPaging     as TotalBatchCountForPaging
  from   CTE_ProductTypeList as  tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
  order by tablefinal.RowNumber asc;
END--> Main End
GO
