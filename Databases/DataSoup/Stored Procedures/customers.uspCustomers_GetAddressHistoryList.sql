SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCustomers_GetAddressHistoryList]
-- Description     : This procedure will do the following in an all or Nothing fashion
--                        a) get data from Address history table for particular id 
-- Input Parameters:     @IPI_PageNumber     int,  
--                       @IPI_RowsPerPage    int, 
--					     @IPVC_ModifiedIDSeq  varchar(30),
--						 @IPVC_ModifiedDate varchar(30),
--						 @IPVC_AddressType varchar(30),
--						 @IPVC_mode varchar(50),
--						 @ID varchar(30)
-- Code Example    : 
/*
Exec CUSTOMERS.dbo.uspCustomers_GetAddressHistoryList @IPI_PageNumber=1,@IPI_RowsPerPage=23,@IPVC_ModifiedIDSeq='',@IPVC_ModifiedDate='',
@IPVC_AddressType='Street',@IPVC_mode='Property',@IPVC_ID='P0901037282'
*/
--
-- Revision History:
-- Author          : Naval Kishore Singh
-- 06/30/2010      : Stored Procedure Created.
-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 06/30/2010   Naval Kishore	Defect #7695 -- Company and Property Modal to show up History.
--============================================================================================================================
CREATE PROCEDURE [customers].[uspCustomers_GetAddressHistoryList] (@IPI_PageNumber      int,  
                                                             @IPI_RowsPerPage     int, 
                                                             @IPVC_ModifiedIDSeq  varchar(30),
                                                             @IPVC_ModifiedDate   varchar(30),
                                                             @IPVC_AddressType    varchar(30),
                                                             @IPVC_mode           varchar(50),
                                                             @IPVC_ID             varchar(30)
                                                            )
AS
BEGIN --> Main Begin
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL off;
  -----------------------------------------
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;  
  -----------------------------------------------------------------------------------
  select @IPVC_ID            = nullif(@IPVC_ID,''),
         @IPVC_ModifiedDate  = nullif(@IPVC_ModifiedDate,''),
         @IPVC_ModifiedIDSeq = nullif(@IPVC_ModifiedIDSeq,''),
         @IPVC_AddressType   = nullif(@IPVC_AddressType,'')       
  -----------------------------------------------------------------------------------
  select @IPVC_AddressType = (case when ((@IPVC_mode = 'Company')  and (@IPVC_AddressType ='Street')) then 'COM' 
                                   when ((@IPVC_mode = 'Company')  and (@IPVC_AddressType ='Bill'))   then 'CBT' 
                                   when ((@IPVC_mode = 'Company')  and (@IPVC_AddressType ='Ship'))   then 'CST' 
                                   when ((@IPVC_mode = 'Property') and (@IPVC_AddressType ='Street')) then 'PRO'
                                   when ((@IPVC_mode = 'Property') and (@IPVC_AddressType ='Bill'))   then 'PBT'
                                   when ((@IPVC_mode = 'Property') and (@IPVC_AddressType ='Ship'))   then 'PST'								     
                                   else '' 
                              end);
  -----------------------------------------------------------------------------------
  -- Getting data for company/Property address History based on input values
  -----------------------------------------------------------------------------------
  ;WITH tablefinal AS
         (select AH.IDSeq                                               as IDSeq,
                 (Case when AH.AddressTypeCode = 'CBT' then 'Bill To'
                       when AH.AddressTypeCode = 'COM' then 'Street'
                       when AH.AddressTypeCode = 'CST' then 'Ship To'
                       when AH.AddressTypeCode = 'PBT' then 'Bill To'
                       when AH.AddressTypeCode = 'PRO' then 'Street'
                       when AH.AddressTypeCode = 'PST' then 'Ship To'
                       else AH.AddressTypeCode 
                 end)                                                   as AddressTypeCode,
                 AH.AddressLine1                                        as AddressLine1,	
                 AH.AddressLine2                                        as AddressLine2,	
                 AH.City                                                as City,			
                 AH.Country                                             as Country,		
                 AH.[State]                                             as [State],		
                 AH.Zip                                                 as Zip,
                 row_number() OVER(ORDER BY AH.IDSeq desc)              as RowNumber,  --> This will show latest audit changes first as users will be interested in seeing recent changes to older changes.
                 Count(1) OVER()                                        as TotalCountForPaging -- UI to use the value of this column in the very first row for paging.No need for separate extra costly count(*)
          from   CUSTOMERS.dbo.AddressHistory AH with (nolock)
          where  ( 
                   (@IPVC_mode = 'Company'  and AH.CompanyIDSeq   = @IPVC_ID and AH.propertyidseq is null)
                      or
                   (@IPVC_mode = 'Property' and AH.PropertyIDSeq  = @IPVC_ID)
                 )
          and  coalesce(AH.ModifiedByIDSeq,'0')         = coalesce(@IPVC_ModifiedIDSeq,coalesce(AH.ModifiedByIDSeq,'0'))  		
          and  convert(varchar(20),AH.ModifiedDate,101) = coalesce(@IPVC_ModifiedDate,convert(varchar(20),AH.ModifiedDate,101))
 --         and  AH.AddressTypeCode                       = coalesce(@IPVC_AddressType,AH.AddressTypeCode)
			and  AH.AddressTypeCode                       = isnull(nullif(@IPVC_AddressType,''),AH.AddressTypeCode)
         )
  select tablefinal.IDSeq               as IDSeq,
         tablefinal.AddressTypeCode     as AddressTypeCode,
         tablefinal.AddressLine1        as AddressLine1,
         tablefinal.AddressLine2        as AddressLine2,
         tablefinal.City                as City,
         tablefinal.Country             as Country,
         tablefinal.[State]             as [State],
         tablefinal.Zip                 as Zip,
         tablefinal.TotalCountForPaging as TotalCountForPaging -- UI to use the value of this column in the very first row for paging.No need for separate extra costly count(*)
  from   tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
  -----------------------------------------------
END--> Main End 
GO
