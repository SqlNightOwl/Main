SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetFamilyList
-- Description     : This is the Main UI Search Proc for Monitor Screen
-- PreRequisites   : EXEC PRODUCTS.dbo.uspPRODUCTS_FamilyList;  is called by UI to populate Family Code Drop down.
--                   UI will default to Blank in the drop down by default. If user selects the drop down for Code to search
--                    then UI will make that selection and also Prepopulate the corresponding Family Name and Greyout
-- Input Parameters: As below
-- Returns         : RecordSet



-- Code Example    : 
/*
--Scenario 1: Blind Search (search all) ie Family Name : Text box is blank
Exec PRODUCTS.dbo.uspPRODUCTS_GetFamilyList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_FamilyName        = ''
                                  ,@IPVC_FamilyCode        = ''                        
                                  ,@IPI_UserIDSeq           = 123

--Scenario 2 : Search for all Familys records that have the name Site (Family Name Text Box)
Exec PRODUCTS.dbo.uspPRODUCTS_GetFamilyList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_FamilyName        = 'OneSite'
                                  ,@IPVC_FamilyCode        = '' 
                                  ,@IPI_UserIDSeq           = 123

--Scenario 3 : Search for all Familys records that have the Family Code UNIT (ie.User selected from Family drop down)
--             In this case, Family Code UNIT is selected by user from drop down for search. UI will prepopulate corresponding
--              Family Name in Family Name Text box corresponding to Drop down and grey out.
Exec PRODUCTS.dbo.uspPRODUCTS_GetFamilyList 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 24
                                  ,@IPVC_FamilyName        = 'OneSite'
                                  ,@IPVC_FamilyCode        = 'OSD'                              
                                  ,@IPI_UserIDSeq           = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Family Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetFamilyList] (@IPI_PageNumber                  int        =1,          ---> Madatory: This is Page Number. Default is 1 and based on user click on page number.
                                                    @IPI_RowsPerPage                 int        =999999999,  ---> Madatory: This is number of records that a single page can accomodate. UI will pass 24. For Excel Export 999999999.
                                                    @IPVC_FamilyName                 varchar(50)='',         ---> Optional: This is Family Name (Text box search value user may have entered. Default is blank)          
                                                    @IPVC_FamilyCode                 varchar(10)='',         ---> Optional: 
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
  select @IPVC_FamilyName = coalesce(nullif(ltrim(rtrim(@IPVC_FamilyName)),''),'')
        ,@IPVC_FamilyCode = nullif(ltrim(rtrim(@IPVC_FamilyCode)),'');
  ----------------------------------------------------
  ;with CTE_FamilyList (FamilyCode,FamilyName,FamilyDescription,
                        FamilyEpicorPostingCode,FamilyTaxwareCompanyCode,
                        FamilyBusinessUnitLogo,PrintFamilyNoticeFlag,
                        CreatedBy,CreatedDate,ModifiedBy,ModifiedDate
                       ,[RowNumber],TotalBatchCountForPaging
                        )
  as (select ltrim(rtrim(FM.Code))                    as   FamilyCode
            ,FM.Name                                  as   FamilyName
            ,FM.Description                           as   FamilyDescription
            ,FM.EpicorPostingCode                     as   FamilyEpicorPostingCode
            ,FM.TaxwareCompanyCode                    as   FamilyTaxwareCompanyCode
            ,FM.BusinessUnitLogo                      as   FamilyBusinessUnitLogo
            ,FM.PrintFamilyNoticeFlag                 as   PrintFamilyNoticeFlag
            ,UC.FirstName + ' ' + UC.LastName         as   CreatedBy
            ,convert(varchar(50),FM.CreatedDate)      as   CreatedDate
            ,UM.FirstName + ' ' + UM.LastName         as   ModifiedBy
            ,convert(varchar(50),FM.ModifiedDate)     as   ModifiedDate
            ,row_number() OVER(ORDER BY FM.Name asc)
                                                      as   [RowNumber]
            ,Count(1) OVER()                          as   TotalBatchCountForPaging
      from  PRODUCTS.dbo.Family FM with (nolock) 
      left outer join
            SECURITY.dbo.[User] UC with (nolock)
      on    FM.CreatedByIDSeq = UC.IDSeq
      left outer join
            SECURITY.dbo.[User] UM with (nolock)
      on    FM.ModifiedByIDSeq = UM.IDSeq
      where FM.Code not in ('ADM','RPM')
      and   FM.Name like '%' + @IPVC_FamilyName + '%'
      and   FM.Code = coalesce(@IPVC_FamilyCode,FM.Code)
     )
  select tablefinal.FamilyCode                   as FamilyCode
        ,tablefinal.FamilyName                   as FamilyName
        ,tablefinal.FamilyDescription            as FamilyDescription
        ,tablefinal.FamilyEpicorPostingCode      as FamilyEpicorPostingCode
        ,tablefinal.FamilyTaxwareCompanyCode     as FamilyTaxwareCompanyCode
        ,tablefinal.FamilyBusinessUnitLogo       as FamilyBusinessUnitLogo
        ,tablefinal.PrintFamilyNoticeFlag        as PrintFamilyNoticeFlag
        ,tablefinal.CreatedBy                    as CreatedBy
        ,tablefinal.CreatedDate                  as CreatedDate
        ,tablefinal.ModifiedBy                   as ModifiedBy
        ,tablefinal.ModifiedDate                 as ModifiedDate
        ,tablefinal.TotalBatchCountForPaging     as TotalBatchCountForPaging
  from   CTE_FamilyList as  tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
  order by tablefinal.RowNumber asc;
END--> Main End
GO
