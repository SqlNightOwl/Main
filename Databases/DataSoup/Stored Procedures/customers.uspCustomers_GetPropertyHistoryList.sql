SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCustomers_GetPropertyHistoryList]
-- Description     : This procedure will do the following in an all or Nothing fashion
--                        a) get data from Property history table for particular companyid 
-- Input Parameters: 1.  @IPVC_PropertyID    as String,
--                   2.  @IPVC_ModifiedIDSeq as String
--					 3.  @IPVC_ModifiedDate   as String
--
-- Code Example    : 
/*
Exec CUSTOMERS.dbo.uspCustomers_GetPropertyHistoryList @IPI_PageNumber=1,@IPI_RowsPerPage=23,@IPVC_ModifiedIDSeq='',@IPVC_ModifiedDate='',
@IPVC_PropertyID='P0901064709'
*/
-- Revision History:
-- Author          : Naval Kishore Singh
-- 06/30/2010      : Stored Procedure Created.
-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 06/30/2010   Naval Kishore	Defect #7695 -- Company and Property Modal to show up History.
-- 08/11/2010   Naval kishore   Defect #8099 -- Modified Expand Custom bundle option.
--============================================================================================================================
CREATE PROCEDURE [customers].[uspCustomers_GetPropertyHistoryList] (@IPI_PageNumber        int,  
                                                              @IPI_RowsPerPage       int, 
                                                              @IPVC_PropertyID       varchar(50),
                                                              @IPVC_ModifiedIDSeq    varchar(30),
                                                              @IPVC_ModifiedDate     varchar(30)
                                                             )
AS
BEGIN --> Main Begin
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL off;
  -----------------------------------------------------------------------------------
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;  
  -----------------------------------------------------------------------------------
  select @IPVC_PropertyID      = nullif(@IPVC_PropertyID,''),
         @IPVC_ModifiedDate    = nullif(@IPVC_ModifiedDate,''),
         @IPVC_ModifiedIDSeq   = nullif(@IPVC_ModifiedIDSeq,'')        
  -----------------------------------------------------------------------------------
  ;WITH tablefinal AS
         (select PH.IDSeq                                               as IDSeq,
                 PH.PMCIDSeq                                            as [PMC ID],
                 PH.PropertyIDSeq                                       as [Property ID],
                 PH.SiteMasterID                                        as [SiteMaster ID],
                 PH.[Name]                                              as [Name],
                 (case when (PH.StatusTypecode = 'ACTIV')
                         then 'Active'
                       else 'InActive'
                  end)                                                  as [Status],
                 PH.Units                                               as [Units],
                 PH.Beds                                                as [Beds],
                 PH.PPUPercentage                                       as [PPU Percentage],
                 (case when (PH.CustomBundlesProductBreakDownTypeCode = 'YEBR')
						then 'Yes'
						else 'No'
				  end)					as [Expand Custom Bundle],
                 PH.SeparateInvoiceByFamilyFlag                         as [Separate Invoice],                 
                 row_number() OVER(ORDER BY PH.IDSeq desc)              as RowNumber,  --> This will show latest audit changes first as users will be interested in seeing recent changes to older changes.
                 Count(1) OVER()                                        as TotalCountForPaging -- UI to use the value of this column in the very first row for paging.No need for separate extra costly count(*)
          from   CUSTOMERS.dbo.PropertyHistory PH with (nolock)
          where  PH.PropertyIDSeq    = coalesce(@IPVC_PropertyID,PH.PropertyIDSeq)
          and  coalesce(PH.ModifiedByIDSeq,'0')  = coalesce(@IPVC_ModifiedIDSeq,coalesce(PH.ModifiedByIDSeq,'0'))  		
          and  convert(varchar(20),PH.ModifiedDate,101) = coalesce(@IPVC_ModifiedDate,convert(varchar(20),PH.ModifiedDate,101))
         )
  select tablefinal.IDSeq,
         tablefinal.[PMC ID],
         tablefinal.[Property ID],
         tablefinal.[SiteMaster ID],
         tablefinal.[Name],
         tablefinal.[Status],
         tablefinal.[Units],
         tablefinal.[Beds],
         tablefinal.[PPU Percentage],
         tablefinal.[Expand Custom Bundle],
         tablefinal.[Separate Invoice],         
         tablefinal.TotalCountForPaging
  from   tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
  -----------------------------------------------
END--> Main End 
GO
