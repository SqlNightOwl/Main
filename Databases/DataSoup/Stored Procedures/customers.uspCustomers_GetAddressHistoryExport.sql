SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCustomers_GetAddressHistoryExport]
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
Exec CUSTOMERS.dbo.[uspCustomers_GetAddressHistoryExport] @IPVC_ModifiedIDSeq='',@IPVC_ModifiedDate='',
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
CREATE PROCEDURE [customers].[uspCustomers_GetAddressHistoryExport] (@IPVC_ModifiedIDSeq  varchar(30),
                                                               @IPVC_ModifiedDate   varchar(30),
                                                               @IPVC_AddressType    varchar(30),
                                                               @IPVC_mode           varchar(50),
                                                               @IPVC_ID             varchar(30)
                                                              )
AS
BEGIN --> Main Begin
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL off;
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
  select
        CompanyIDSeq                                            as [Company ID Seq],		
        PropertyIDSeq                                           as [Property ID Seq],		
        (Case when AH.AddressTypeCode = 'CBT' then 'Bill To'
              when AH.AddressTypeCode = 'COM' then 'Street'
              when AH.AddressTypeCode = 'CST' then 'Ship To'
              when AH.AddressTypeCode = 'PBT' then 'Bill To'
              when AH.AddressTypeCode = 'PRO' then 'Street'
              when AH.AddressTypeCode = 'PST' then 'Ship To'
              else AH.AddressTypeCode 
         end)                                                   as [Address Type],			
         AH.AddressLine1                                        as [Address Line 1],		
         AH.AddressLine2                                        as [Address Line 2],		
         AH.City                                                as [City],
         AH.State                                               as [State],
         AH.Country                                             as Country,
         AH.Zip                                                 as Zip,
         AH.PhoneVoice1                                         as [Phone],
         AH.PhoneVoiceExt1                                      as [Ext], 
         AH.PhoneFax					        as [Phone Fax],
         AH.PhoneVoice4					        as [Cell],
         AH.Email						as Email,
         AH.URL							as URL,
         AH.SameAsPMCAddressFlag                                as [Same As PMC],
         (case when UC.IDSeq is null
                then 'Not Captured'
               else UC.FirstName + ' ' + UC.LastName
          end)                                                  as [Created By],
         (case when AH.CreatedDate is null
                then 'Not Captured'
               else convert(varchar(50),AH.CreatedDate,22)  
          end)                                                  as [Created Date],
         (case when UM.IDSeq is null
                then 'Not Captured'
               else UM.FirstName + ' ' + UM.LastName
          end)                                                  as [Modified By],
         (case when AH.ModifiedDate is null
                then 'Not Captured'
               else convert(varchar(50),AH.ModifiedDate,22)  
          end)                                                  as [Modified Date],
         AH.AttentionName                                       as [Contact Name]
  from   CUSTOMERS.dbo.AddressHistory AH with (nolock)
  left outer join
         Security.dbo.[User] UC with (nolock)
  on     AH.CreatedByIDSeq  = UC.IDSeq
  and    ( 
           (@IPVC_mode = 'Company'  and AH.CompanyIDSeq   = @IPVC_ID and AH.propertyidseq is null)
                or
           (@IPVC_mode = 'Property' and AH.PropertyIDSeq  = @IPVC_ID)
         )
  left outer join
         Security.dbo.[User] UM with (nolock)
  on     AH.ModifiedByIDSeq = UM.IDSeq
  and    ( 
           (@IPVC_mode = 'Company'  and AH.CompanyIDSeq   = @IPVC_ID and AH.propertyidseq is null)
                or
           (@IPVC_mode = 'Property' and AH.PropertyIDSeq  = @IPVC_ID)
         )
  where  ( 
           (@IPVC_mode = 'Company'  and AH.CompanyIDSeq   = @IPVC_ID and AH.propertyidseq is null)
                or
           (@IPVC_mode = 'Property' and AH.PropertyIDSeq  = @IPVC_ID)
         )
  and  coalesce(AH.ModifiedByIDSeq,'0')         = coalesce(@IPVC_ModifiedIDSeq,coalesce(AH.ModifiedByIDSeq,'0'))  		
  and  convert(varchar(20),AH.ModifiedDate,101) = coalesce(@IPVC_ModifiedDate,convert(varchar(20),AH.ModifiedDate,101))
--  and  AH.AddressTypeCode                       = coalesce(@IPVC_AddressType,AH.AddressTypeCode)
	and  AH.AddressTypeCode                       = isnull(nullif(@IPVC_AddressType,''),AH.AddressTypeCode)
  Order by AH.IDSeq desc; 
END --Main End
GO
