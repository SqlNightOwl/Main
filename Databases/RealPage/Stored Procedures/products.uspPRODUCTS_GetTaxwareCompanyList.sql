SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetTaxwareCompanyList
-- Description     : This is the Main UI Search Proc for Monitor Screen
-- PreRequisites   : EXEC PRODUCTS.dbo.uspPRODUCTS_GetTaxwareCompany;  is called by UI to populate TaxwareCompany Code Drop down.
--                   UI will default to Blank in the drop down by default. If user selects the drop down for Code to search
--                    then UI will make that selection and also Prepopulate the corresponding TaxwareCompany Name and Greyout
-- Input Parameters: As below
-- Returns         : RecordSet



-- Code Example    : 
/*
--Scenario 1: Blind Search (search all) ie TaxwareCompany Name : Text box is blank
Exec PRODUCTS.dbo.uspPRODUCTS_GetTaxwareCompanyList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_TaxwareCompanyName = ''
                                  ,@IPVC_TaxwareCompanyCode = ''                        
                                  ,@IPI_UserIDSeq           = 123

--Scenario 2 : Search for all TaxwareCompanys records that have the name Site (TaxwareCompany Name Text Box)
Exec PRODUCTS.dbo.uspPRODUCTS_GetTaxwareCompanyList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_TaxwareCompanyName = 'RealPage'
                                  ,@IPVC_TaxwareCompanyCode = '' 
                                  ,@IPI_UserIDSeq           = 123

--Scenario 3 : Search for all TaxwareCompanys records that have the TaxwareCompany Code UNIT (ie.User selected from TaxwareCompany drop down)
--             In this case, TaxwareCompany Code UNIT is selected by user from drop down for search. UI will prepopulate corresponding
--              TaxwareCompany Name in TaxwareCompany Name Text box corresponding to Drop down and grey out.
Exec PRODUCTS.dbo.uspPRODUCTS_GetTaxwareCompanyList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_TaxwareCompanyName = 'RealPage'
                                  ,@IPVC_TaxwareCompanyCode = '01'                              
                                  ,@IPI_UserIDSeq           = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration TaxwareCompany Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetTaxwareCompanyList] (@IPI_PageNumber                  int        =1,          ---> Madatory: This is Page Number. Default is 1 and based on user click on page number.
                                                            @IPI_RowsPerPage                 int        =999999999,  ---> Madatory: This is number of records that a single page can accomodate. UI will pass 24. For Excel Export 999999999.
                                                            @IPVC_TaxwareCompanyName         varchar(70)='',         ---> Optional: This is TaxwareCompany Name (Text box search value user may have entered. Default is blank)          
                                                            @IPVC_TaxwareCompanyCode         varchar(10)='',         ---> Optional: 
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
  select @IPVC_TaxwareCompanyName = coalesce(nullif(ltrim(rtrim(@IPVC_TaxwareCompanyName)),''),'')
        ,@IPVC_TaxwareCompanyCode = nullif(ltrim(rtrim(@IPVC_TaxwareCompanyCode)),'');
  ----------------------------------------------------
  ;with CTE_TaxwareCompanyList (TaxwareCompanyCode,TaxwareCompanyName,TaxwareCompanyDescription,                       
                                CreatedBy,CreatedDate,ModifiedBy,ModifiedDate
                               ,[RowNumber],TotalBatchCountForPaging
                               )
  as (select ltrim(rtrim(TC.TaxwareCompanyCode))      as   TaxwareCompanyCode
            ,TC.Name                                  as   TaxwareCompanyName
            ,TC.Description                           as   TaxwareCompanyDescription
            ,UC.FirstName + ' ' + UC.LastName         as   CreatedBy
            ,convert(varchar(50),TC.CreatedDate)      as   CreatedDate
            ,UM.FirstName + ' ' + UM.LastName         as   ModifiedBy
            ,convert(varchar(50),TC.ModifiedDate)     as   ModifiedDate
            ,row_number() OVER(ORDER BY TC.Name asc)
                                                      as   [RowNumber]
            ,Count(1) OVER()                          as   TotalBatchCountForPaging
      from  PRODUCTS.dbo.TaxwareCompany TC with (nolock) 
      left outer join
            SECURITY.dbo.[User] UC with (nolock)
      on    TC.CreatedByIDSeq = UC.IDSeq
      left outer join
            SECURITY.dbo.[User] UM with (nolock)
      on    TC.ModifiedByIDSeq = UM.IDSeq
      where TC.Name like '%' + @IPVC_TaxwareCompanyName + '%'
      and   TC.TaxwareCompanyCode = coalesce(@IPVC_TaxwareCompanyCode,TC.TaxwareCompanyCode)
     )
  select tablefinal.TaxwareCompanyCode                   as TaxwareCompanyCode
        ,tablefinal.TaxwareCompanyName                   as TaxwareCompanyName
        ,tablefinal.TaxwareCompanyDescription            as TaxwareCompanyDescription
        ,tablefinal.CreatedBy                    as CreatedBy
        ,tablefinal.CreatedDate                  as CreatedDate
        ,tablefinal.ModifiedBy                   as ModifiedBy
        ,tablefinal.ModifiedDate                 as ModifiedDate
        ,tablefinal.TotalBatchCountForPaging     as TotalBatchCountForPaging
  from   CTE_TaxwareCompanyList as  tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
  order by tablefinal.RowNumber asc;
END--> Main End
GO
