SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_AccountDetails
-- Description     : This procedure gets the list of Properties 
--                   for the specific Customer.
--
-- Input Parameters: 1. @IPI_PageNumber     int, 
--                   2. @IPI_RowsPerPage    int, 
--                   3. @IPVC_CompanyID     varchar(11),
--                   4. @IPVC_PropertyID    varchar(11),
--                   5. @IPVC_AccountID     varchar(20),
--                   6. @IPVC_PropertyName  varchar(100),
--                   7. @IPVC_City          varchar(70),
--                   8. @IPVC_State         varchar(2),
--                   9. @IPVC_Zip           varchar(10)
-- 
-- OUTPUT          : RecordSet of Property ID, Property Name, Account ID,
--                   City, State, Zip and Units.
--
-- Code Example    : Exec uspCUSTOMERS_PropertyListSelect @IPI_PageNumber       = 1, 
--                                                          @IPI_RowsPerPage    = 10, 
--                                                          @IPVC_CompanyID     = '',
--                                                          @IPVC_PropertyID    = '',
--                                                          @IPVC_AccountID     = '',
--                                                          @IPVC_PropertyName  = '',
--                                                          @IPVC_City          = '',
--                                                          @IPVC_State         = '',
--                                                          @IPVC_Zip           = ''
-- 
-- 
-- Revision History:
-- Author          : TMN.
-- 2010-07-28: Larry-PCR 7848. Support NULL values in Address columns while still finding my property
-- 12/22/2006      : Modified by STA. Implemented Search functionality to search for properties 
--                   that does not have an account also.
-- 12/20/2006      : Changed by STA. Implemented Search functionality.
--
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [customers].[uspCUSTOMERS_PropertyListSelect] (@IPI_PageNumber      int, 
                                                          @IPI_RowsPerPage     int, 
                                                          @IPVC_CompanyID      varchar(11),
                                                          @IPVC_PropertyID     varchar(11),
                                                          @IPVC_AccountID      varchar(20),
                                                          @IPVC_PropertyName   varchar(100),
                                                          @IPVC_City           varchar(70),
                                                          @IPVC_State          varchar(2),
                                                          @IPVC_Zip            varchar(10),
                                                          @IPVC_Statustypecode varchar(50) = '', --- Default is '' which is ALL. 
                                                                                                --- Else it Should be 'ACTIV' or 'INACT' only
														  @IPVC_Country varchar(50)=''  
                                                         ) ---WITH RECOMPILE                                                          
AS
BEGIN        
  set nocount on;
  -----------------------------------------
  set @IPVC_CompanyID  = nullif(ltrim(rtrim(@IPVC_CompanyID)),'');
  set @IPVC_PropertyID = nullif(ltrim(rtrim(@IPVC_PropertyID)),'');
  set @IPVC_AccountID  = nullif(ltrim(rtrim(@IPVC_AccountID)),'');
  set @IPVC_Statustypecode = nullif(ltrim(rtrim(@IPVC_Statustypecode)),'');

  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  ----------------------------------------------------------------
  ---Get Records based on search criteria
  ----------------------------------------------------------------
  WITH tablefinal AS 
  ----------------------------------------------------------------------------  
       (SELECT tableinner.*
        FROM
         ----------------------------------------------------------------------------
         (select  row_number() over(order by source.[Name] asc)  as RowNumber,
                  source.*
          from
          (select P.IDSeq                             as ID,
                  P.Name                              as [Name], 
                  coalesce(ACCT.IDSeq,'')             as AccountID, 
                  coalesce(ADDR.City,'')              as City, 
                  coalesce(ADDR.State,'')             as State, 
				  coalesce(ADDR.CountryCode,'')       as CountryCode,
                  coalesce(ADDR.Zip,'')               as Zip,
                  P.Units                             as Units,
                  ST.[Name]                           as StatusType,
                  P.PMCIDSeq                          as PMCID,
                  P.TransferPMCIDSeq                  as TPMCID,
                  P.StatusTypeCode                    as StatusTypeCode
           from   CUSTOMERS.dbo.Property P    with (nolock)
           inner join
                  CUSTOMERS.dbo.StatusType ST with (nolock)
           on     P.StatusTypeCode = ST.Code
           and    P.PMCIDSeq       = @IPVC_CompanyID           
           and    P.IDSeq          = coalesce(@IPVC_PropertyID,P.IDSeq)
           and    ST.Code          = coalesce(@IPVC_Statustypecode,ST.Code)
           and    P.[Name]   like '%' + @IPVC_PropertyName  + '%'
           left outer join 
                  CUSTOMERS.dbo.Address ADDR with (nolock)
           on     ADDR.CompanyIDSeq    = P.PMCIDSeq
			and ADDR.CompanyIDSeq    = @IPVC_CompanyID           
			and ADDR.PropertyIDSeq   = P.IDSeq          
			and ADDR.AddressTypeCode = 'PRO'
			and ISNULL(ADDR.City,'') like  '%' + @IPVC_City  + '%' 
			and ISNULL(ADDR.State,'') like  '%' + @IPVC_State + '%' 
			and ISNULL(ADDR.Zip,'') like  '%' + @IPVC_Zip   + '%' 
			and ISNULL(ADDR.CountryCode,'') like  '%' + @IPVC_Country + '%' 
		left outer join
                  (select Max(XACCT.IDSEQ) as IDSEQ,XACCT.CompanyIDSeq,XACCT.PropertyIDSeq,XACCT.Accounttypecode
                   from   CUSTOMERS.dbo.Account XACCT with (nolock)
                   where  XACCT.CompanyIDSeq = @IPVC_CompanyID
                   and    XACCT.Accounttypecode = 'APROP'
                   and    XACCT.IDSEQ = coalesce(@IPVC_AccountID,XACCT.IDSEQ) 
                   and    XACCT.PropertyIDSeq = coalesce(@IPVC_PropertyID,XACCT.PropertyIDSeq) 
                   group by XACCT.CompanyIDSeq,XACCT.PropertyIDSeq,XACCT.Accounttypecode
                   ) ACCT
           on     ACCT.CompanyIDSeq = @IPVC_CompanyID
           and    ACCT.PropertyIDSeq= P.IDSeq           
           and    ACCT.Accounttypecode = 'APROP'           
           and    ACCT.IDSEQ           = coalesce(@IPVC_AccountID,ACCT.IDSEQ)
          ) source
          where source.City         like  '%' + @IPVC_City  + '%' 
           and  source.State        like  '%' + @IPVC_State + '%' 
           and  source.Zip          like  '%' + @IPVC_Zip   + '%' 
		   and  coalesce(source.CountryCode,'')  like  '%' + @IPVC_Country + '%' 
           and  source.AccountID    = coalesce(@IPVC_AccountID,source.AccountID)        
          -----------------------------------------------------------------------------------
         )tableinner  
        WHERE tableinner.RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage
        AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
    )
    SELECT  tablefinal.RowNumber,
            tablefinal.[ID]                     as [ID],
            tablefinal.[Name]                   as [Name],
            tablefinal.AccountID                as AccountID,
	    tablefinal.City                     as City,
            tablefinal.State                    as State,
            tablefinal.Zip                      as Zip,
            tablefinal.Units                    as Units,
	    tablefinal.StatusType               as StatusType, 
	    tablefinal.PMCID                    as PMCID,
            tablefinal.TPMCID                   as TPMCID,
            tablefinal.StatusTypeCode           as StatusTypeCode
    FROM    tablefinal    
END
GO
