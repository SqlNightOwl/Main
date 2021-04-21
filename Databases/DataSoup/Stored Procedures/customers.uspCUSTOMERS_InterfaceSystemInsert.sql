SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_InterfaceInsert
-- Description     : This procedure gets called for Creation of Brand new System Interface--              
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_InterfaceSystemInsert  Passing Input Parameters
-- Revision History:
-- Author          : STH
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_InterfaceSystemInsert]
                                                    (@IPVC_CompanyIDSeq               varchar(50),   --> CompanyID (Mandatory) : For Both Company and Property Addresses
                                                     @IPVC_PropertyIDSeq              varchar(50)=null,--> For Company Records, PropertyID is NULL or Blank. 
                                                     @IPVC_InterfacedSystemID         varchar(50),   --> InterfacedSystemID to exact and actual Unique ID of External System for a given InterfacedSystemIDTypeCode. eg External System AccountID, Billing ID etc
                                                     @IPVC_InterfacedSystemClientType varchar(30)='', --> InterfacedSystemClientType to record External Systems Client type if different from OMS defined AHOFF and APROP.  Eg: Supplier which denotes Commercial type in Company with CommercialFlag set as 1. This column is useful for Migration needs.                                                                                                             
                                                     @IPVC_InterfacedSystemCode       varchar(5),    --> Code of External System Name that Interfaces with OMS. FK to InterfacedSystem. (Mandatory)                                                                                                         
                                                     @IPVC_InterfacedSystemIDTypeCode varchar(4),    --> Code of ID Name of External System Name that Interfaces with OMS. FK to InterfacedSystem.
                                                     @IPVC_CreatedByUserIDSeq         bigint
                                                    
                                                    )
as 
BEGIN
  set nocount on;   
  ----------------------------------------------------------------------------
  -- Local Variable Declaration
  ----------------------------------------------------------------------------   
  declare @LDT_SystemDate      datetime,
          @LVC_CodeSection     varchar(1000) 
  ----------------------------------------------------------------------------
  --Initialization of Variables.
  select @LDT_SystemDate      = Getdate() 
         
  ----------------------------------------------------------------------------
 
  ---Inital validation 1 : Check InterfaceSystem Code does exists 
  if not exists (select top 1 1
                 from   CUSTOMERS.dbo.InterfacedSystem   with (nolock) 
                 where  Code   = @IPVC_InterfacedSystemCode 
                )
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_InterfaceSystemInsert - InterfacedSystemCode : ' + @IPVC_InterfacedSystemCode + ' is not valid: ' + Coalesce(@IPVC_PropertyIDSeq,@IPVC_CompanyIDSeq) + '. Aborting Interface creation.'   
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection 
    select @LVC_CodeSection  
    return
  end    
  
  --Ensure the ID isn't already mapped for SF IDs
  if exists ( select top 1 1 From Customers.dbo.InterfacedSystemIdentifier isi (nolock)
             where   InterfacedSystemCode = 'SF' 
             and  InterfacedSystemID COLLATE SQL_Latin1_General_CP1_CS_AS  = @IPVC_InterfacedSystemID COLLATE SQL_Latin1_General_CP1_CS_AS 
          )
  BEGIN   
       select @LVC_CodeSection = case when p.Name is null then 'Mapping Already exists for ' + @IPVC_InterfacedSystemID +'. Currently Mapped to ' +c.Name + ': ' + c.IDSeq 
                      else 'Mapping Already exists for ' + @IPVC_InterfacedSystemID +'. Currently Mapped to ' +c.Name + ' ' + c.IDSeq + ' Property: ' + p.Name + ': ' + p.idseq
                  end 
       From Customers.dbo.InterfacedSystemIdentifier isi (nolock)
       join
           Customers.dbo.Company c (nolock)
       on  c.IDseq = isi.CompanyIDSeq
       left join
           Customers.dbo.Property p (nolock)
       on  p.pmcidseq = c.idseq
       and p.idseq    = isi.propertyIDSeq
       where 
            InterfacedSystemCode = @IPVC_InterfacedSystemCode
       and  InterfacedSystemID COLLATE SQL_Latin1_General_CP1_CS_AS   = @IPVC_InterfacedSystemID COLLATE SQL_Latin1_General_CP1_CS_AS 
 
       select @LVC_CodeSection 
       return     

   END  
  
  --Ensure it's unique
   if exists (select top 1 1
                 from   CUSTOMERS.dbo.InterfacedSystemIdentifier   with (nolock) 
                 where  InterfacedSystemCode = @IPVC_InterfacedSystemCode 
                 and    CompanyIDSeq         = @IPVC_CompanyIDSeq
                 and    PropertyIDSeq        = @IPVC_PropertyIDSeq
                 and    InterfacedSystemID   = @IPVC_InterfacedSystemID
            )
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_InterfaceSystemInsert - Another Interface already exists for ' + @IPVC_InterfacedSystemID + ' for Type ' + @IPVC_InterfacedSystemCode + '. Duplicate entry not allowed.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    select @LVC_CodeSection 
    return
  end
 
  ----------------------------------------------------------------------------  
  --Step 1 : Insert Interface Relation
  begin TRY
            INSERT INTO [InterfacedSystemIdentifier]
				   ([CompanyIDSeq]
				   ,[PropertyIDSeq]
				   ,[InterfacedSystemID]
				   ,[InterfacedSystemClientType]
				   ,[InterfacedSystemCode]
				   ,[InterfacedSystemIDTypeCode]
				   ,[CreatedByUserIDSeq]
				   ,[CreatedDate])
		    select  @IPVC_CompanyIDSeq
		           ,@IPVC_PropertyIDSeq
		           ,@IPVC_InterfacedSystemID
		           ,@IPVC_InterfacedSystemClientType
		           ,@IPVC_InterfacedSystemCode
		           ,@IPVC_InterfacedSystemIDTypeCode
		           ,@IPVC_CreatedByUserIDSeq
		           ,@LDT_SystemDate
		           
           select ''
  end TRY
  begin CATCH
    select @LVC_CodeSection='Proc:uspCUSTOMERS_InterfaceSystemInsert - Unexpected Internal Error Occurred during Insert of Address for ' + @IPVC_InterfacedSystemID + ' for Type ' + @IPVC_InterfacedSystemCode
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    select @LVC_CodeSection
    return
  end CATCH
  ---------------------------------------------------------------------------- 
END
GO
