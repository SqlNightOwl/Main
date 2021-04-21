SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetMeasureList
-- Description     : This is the Main UI Search Proc for Monitor Screen
-- PreRequisites   : Exec PRODUCTS.dbo.uspPRODUCTS_GetMeasure is called by UI to populate Measure Code Drop down.
--                   UI will default to Blank in the drop down by default. If user selects the drop down for Code to search
--                    then UI will make that selection and also Prepopulate the corresponding Measure Name and Greyout
-- Input Parameters: As below
-- Returns         : RecordSet



-- Code Example    : 
/*
--Scenario 1: Blind Search (search all) ie Measure Name : Text box is blank
Exec PRODUCTS.dbo.uspPRODUCTS_GetMeasureList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_MeasureName        = ''
                                  ,@IPVC_MeasureCode        = ''                        
                                  ,@IPI_UserIDSeq           = 123

--Scenario 2 : Search for all measures records that have the name Site (Measure Name Text Box)
Exec PRODUCTS.dbo.uspPRODUCTS_GetMeasureList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_MeasureName        = 'Site'
                                  ,@IPVC_MeasureCode        = '' 
                                  ,@IPI_UserIDSeq           = 123

--Scenario 3 : Search for all measures records that have the Measure Code UNIT (ie.User selected from Measure drop down)
--             In this case, Measure Code UNIT is selected by user from drop down for search. UI will prepopulate corresponding
--              Measure Name in Measure Name Text box corresponding to Drop down and grey out.
Exec PRODUCTS.dbo.uspPRODUCTS_GetMeasureList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_MeasureName        = 'Unit'
                                  ,@IPVC_MeasureCode        = 'UNIT'                              
                                  ,@IPI_UserIDSeq           = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Measure Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetMeasureList] (@IPI_PageNumber                  int        =1,          ---> Madatory: This is Page Number. Default is 1 and based on user click on page number.
                                                     @IPI_RowsPerPage                 int        =999999999,  ---> Madatory: This is number of records that a single page can accomodate. UI will pass 24. For Excel Export 999999999.
                                                     @IPVC_MeasureName                varchar(50)='',         ---> Optional: This is Measure Name (Text box search value user may have entered. Default is blank)          
                                                     @IPVC_MeasureCode                varchar(10)='',         ---> Optional: 
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
  select @IPVC_MeasureName = coalesce(nullif(ltrim(rtrim(@IPVC_MeasureName)),''),'')
        ,@IPVC_MeasureCode = nullif(ltrim(rtrim(@IPVC_MeasureCode)),'');
  ----------------------------------------------------
  ;with CTE_MeasureList ( MeasureCode,MeasureName,
                          CreatedBy,CreatedDate,ModifiedBy,ModifiedDate
                         ,[RowNumber],TotalBatchCountForPaging
                        )
  as (select ltrim(rtrim(M.Code))                 as   MeasureCode
            ,M.Name                               as   MeasureName
            ,UC.FirstName + ' ' + UC.LastName     as   CreatedBy
            ,convert(varchar(50),M.CreatedDate)   as   CreatedDate
            ,UM.FirstName + ' ' + UM.LastName     as   ModifiedBy
            ,convert(varchar(50),M.ModifiedDate)  as   ModifiedDate
            ,row_number() OVER(ORDER BY M.Name asc)
                                                  as   [RowNumber]
            ,Count(1) OVER()                      as   TotalBatchCountForPaging
      from  PRODUCTS.dbo.Measure M with (nolock) 
      left outer join
            SECURITY.dbo.[User] UC with (nolock)
      on    M.CreatedByIDSeq = UC.IDSeq
      left outer join
            SECURITY.dbo.[User] UM with (nolock)
      on    M.ModifiedByIDSeq = UM.IDSeq
      where M.Name like '%' + @IPVC_MeasureName + '%'
      and   M.Code = coalesce(@IPVC_MeasureCode,M.Code)
     )
  select tablefinal.MeasureCode                  as MeasureCode
        ,tablefinal.MeasureName                  as MeasureName
        ,tablefinal.CreatedBy                    as CreatedBy
        ,tablefinal.CreatedDate                  as CreatedDate
        ,tablefinal.ModifiedBy                   as ModifiedBy
        ,tablefinal.ModifiedDate                 as ModifiedDate
        ,tablefinal.TotalBatchCountForPaging     as TotalBatchCountForPaging
  from   CTE_MeasureList as  tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
  order by tablefinal.RowNumber asc;
END--> Main End
GO
