SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetCountryList
-- Description     : This is the Main UI Search Proc for Monitor Screen
-- PreRequisites   : EXEC PRODUCTS.dbo.uspPRODUCTS_GetCountry;  is called by UI to populate Country Code Drop down.
--                   UI will default to Blank in the drop down by default. If user selects the drop down for Code to search
--                    then UI will make that selection and also Prepopulate the corresponding Country Name and Greyout
-- Input Parameters: As below
-- Returns         : RecordSet



-- Code Example    : 
/*
--Scenario 1: Blind Search (search all) ie Country Name : Text box is blank
Exec PRODUCTS.dbo.uspPRODUCTS_GetCountryList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_CountryName        = ''
                                  ,@IPVC_CountryCode        = ''                        
                                  ,@IPI_UserIDSeq           = 123

--Scenario 2 : Search for all Countrys records that have the name Site (Country Name Text Box)
Exec PRODUCTS.dbo.uspPRODUCTS_GetCountryList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_CountryName        = 'United States'
                                  ,@IPVC_CountryCode        = '' 
                                  ,@IPI_UserIDSeq           = 123

--Scenario 3 : Search for all Countrys records that have the Country Code UNIT (ie.User selected from Country drop down)
--             In this case, Country Code UNIT is selected by user from drop down for search. UI will prepopulate corresponding
--              Country Name in Country Name Text box corresponding to Drop down and grey out.
Exec PRODUCTS.dbo.uspPRODUCTS_GetCountryList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_CountryName        = 'RealPage'
                                  ,@IPVC_CountryCode        = '01'                              
                                  ,@IPI_UserIDSeq           = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Country Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetCountryList] (@IPI_PageNumber                  int         =1,          ---> Madatory: This is Page Number. Default is 1 and based on user click on page number.
                                                     @IPI_RowsPerPage                 int         =999999999,  ---> Madatory: This is number of records that a single page can accomodate. UI will pass 24. For Excel Export 999999999.
                                                     @IPVC_CountryName                varchar(100)='',         ---> Optional: This is Country Name (Text box search value user may have entered. Default is blank)          
                                                     @IPVC_CountryCode                varchar(3)  ='',         ---> Optional: This is from Drop down from EXEC PRODUCTS.dbo.uspPRODUCTS_GetCountry
                                                     @IPI_UserIDSeq                   bigint      =-1          ---> Madatory: UI will pass UserId of the person doing the operation
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
  select @IPVC_CountryName = coalesce(nullif(ltrim(rtrim(@IPVC_CountryName)),''),'')
        ,@IPVC_CountryCode = nullif(ltrim(rtrim(@IPVC_CountryCode)),'');
  ----------------------------------------------------
  ;with CTE_CountryList (CountryCode,CountryName,                       
                                CreatedBy,CreatedDate,ModifiedBy,ModifiedDate
                               ,[RowNumber],TotalBatchCountForPaging
                               )
  as (select ltrim(rtrim(CNTRY.Code))                 as   CountryCode
            ,ltrim(rtrim(CNTRY.Name))                 as   CountryName
            ,UC.FirstName + ' ' + UC.LastName         as   CreatedBy
            ,convert(varchar(50),CNTRY.CreatedDate)   as   CreatedDate
            ,UM.FirstName + ' ' + UM.LastName         as   ModifiedBy
            ,convert(varchar(50),CNTRY.ModifiedDate)  as   ModifiedDate
            ,row_number() OVER(ORDER BY (case when ltrim(rtrim(CNTRY.Code)) = 'USA' then '001'
                                              when ltrim(rtrim(CNTRY.Code)) = 'CAN' then '002'
                                              else ltrim(rtrim(CNTRY.Name))
                                         end) asc)
                                                      as   [RowNumber]
            ,Count(1) OVER()                          as   TotalBatchCountForPaging
      from  CUSTOMERS.dbo.Country CNTRY with (nolock) 
      left outer join
            SECURITY.dbo.[User] UC with (nolock)
      on    CNTRY.CreatedByIDSeq = UC.IDSeq
      left outer join
            SECURITY.dbo.[User] UM with (nolock)
      on    CNTRY.ModifiedByIDSeq = UM.IDSeq
      where CNTRY.Name like '%' + @IPVC_CountryName + '%'
      and   CNTRY.Code = coalesce(@IPVC_CountryCode,CNTRY.Code)
     )
  select tablefinal.CountryCode                  as CountryCode
        ,tablefinal.CountryName                  as CountryName
        ,tablefinal.CreatedBy                    as CreatedBy
        ,tablefinal.CreatedDate                  as CreatedDate
        ,tablefinal.ModifiedBy                   as ModifiedBy
        ,tablefinal.ModifiedDate                 as ModifiedDate
        ,tablefinal.TotalBatchCountForPaging     as TotalBatchCountForPaging
  from   CTE_CountryList as  tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
  order by tablefinal.RowNumber asc;
END--> Main End
GO
