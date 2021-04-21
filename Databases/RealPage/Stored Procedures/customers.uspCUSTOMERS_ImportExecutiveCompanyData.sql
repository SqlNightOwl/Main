SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_ImportExecutiveCompanyData]
-- Input Parameters: As Below in Sequential order.  
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_ImportExecutiveCompanyData  Passing Input Parameters  
-- Revision History:  
-- 2011-09-13     : Mahaboob ( TFS 1030)     --  Import Executive Company Data
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_ImportExecutiveCompanyData] (  @IPVC_ExecutiveCompanyCustomerID varchar(11),   
																    @IPVC_ExecutiveCompanyName       varchar(100),  
																    @IPVC_ChildCompanyID			 varchar(11),   
															        @IPVC_ChildCompanyName           varchar(100),
																    @IPBI_ModifyingUserID			 bigint
                                                                 )
as   
BEGIN  
  set nocount on;    
  SET CONCAT_NULL_YIELDS_NULL off;  
  ----------------------------------------------------------------------------  
  -- Local Variable Declaration  
  ----------------------------------------------------------------------------  
  declare @LVC_ExecutiveCompanyIDSeq varchar(11),  @LVC_CompanyIDSeq varchar(11)
  declare @LVC_ActiveFlag      bit, @IsAlreadyExecutiveCompany bit
  declare @LDT_SystemDate      datetime  
  declare @LVC_CodeSection     varchar(1000)  
   ----------------------------------------------------------------------------  
  --Initialization of Variables.  
   select @LVC_ExecutiveCompanyIDSeq = '',  @LVC_CompanyIDSeq = ''
   select @IPVC_ExecutiveCompanyCustomerID = LTRIM(RTRIM(UPPER(@IPVC_ExecutiveCompanyCustomerID)))
   if(   charindex('E',@IPVC_ExecutiveCompanyCustomerID) = 1  )
   begin
         select @LVC_ExecutiveCompanyIDSeq = @IPVC_ExecutiveCompanyCustomerID
   end
   else if(   charindex('C',@IPVC_ExecutiveCompanyCustomerID) = 1  )
   begin
         select @LVC_CompanyIDSeq = @IPVC_ExecutiveCompanyCustomerID
   end 
   select @IPVC_ExecutiveCompanyName       = LTRIM(RTRIM(UPPER(@IPVC_ExecutiveCompanyName))),  
		  @IPVC_ChildCompanyID             = LTRIM(RTRIM(UPPER(@IPVC_ChildCompanyID)))  ,
          @IPVC_ChildCompanyName           = LTRIM(RTRIM(UPPER(@IPVC_ChildCompanyName))) ,
          @LVC_ActiveFlag				   = 1,
          @IsAlreadyExecutiveCompany       = 0,
          @LDT_SystemDate                  = Getdate()
  ---------------------------------------------------------------------------- 
 if( len(NULLIF(@LVC_ExecutiveCompanyIDSeq,'')) > 0 )
 begin
 if exists(select top 1 1   
            from   Customers.dbo.ExecutiveCompany E with (nolock)  
            where  E.ExecutiveCompanyIDSeq  = @LVC_ExecutiveCompanyIDSeq  
            and    len(NULLIF(@LVC_ExecutiveCompanyIDSeq,'')) > 0  
           )  
 begin
       select @IsAlreadyExecutiveCompany = 1
 end
 end
 else if( len(NULLIF(@LVC_CompanyIDSeq,'')) > 0 )
 begin
 if exists(select top 1 1   
            from   Customers.dbo.ExecutiveCompany E with (nolock)  
            where  E.CompanyIDSeq  = @LVC_CompanyIDSeq  
            and    len(NULLIF(@LVC_CompanyIDSeq,'')) > 0  
           )  
 begin
       select @IsAlreadyExecutiveCompany = 1
 end
 END
 
 if( len(NULLIF(@LVC_CompanyIDSeq,'')) > 0 and @IsAlreadyExecutiveCompany = 0 )
 BEGIN
  BEGIN TRY  
    BEGIN TRANSACTION COMP; 
       
      ---------------------------------------------------------------------------------  
      --Step 1 : get unique New ExecutiveCompanyID generated for this Brand New ExecutiveCompany Creation  
      ---------------------------------------------------------------------------------  
      update CUSTOMERS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)  
      set    IDSeq = IDSeq+1,  
             GeneratedDate =CURRENT_TIMESTAMP   
      where  TypeIndicator = 'E'  
  
      select @LVC_ExecutiveCompanyIDSeq = IDGeneratorSeq  
      from   CUSTOMERS.DBO.IDGenerator with (NOLOCK)    
      where  TypeIndicator = 'E'  
      ---------------------------------------------------------------------------------  
      --Step 2: Insert ExecutiveCompany Record.  
      ---------------------------------------------------------------------------------  
      Insert into Customers.dbo.ExecutiveCompany (ExecutiveCompanyIDSeq, CompanyIDSeq, CompanyName, ActiveFlag, CreatedByIDSeq)
                                          
      select @LVC_ExecutiveCompanyIDSeq  as ExecutiveCompanyIDSeq, @LVC_CompanyIDSeq as CompanyIDSeq, @IPVC_ExecutiveCompanyName as CompanyName,
		     @LVC_ActiveFlag   as ActiveFlag, @IPBI_ModifyingUserID as CreatedByIDSeq
      ---------------------------------------------------------------------------------  
      --Step 3: Update Executive-Child Relationship in Company table 
      ---------------------------------------------------------------------------------  
      update  CUSTOMERS.dbo.Company 
      set     ModifiedByIDSeq			= @IPBI_ModifyingUserID,
              ModifiedDate				= @LDT_SystemDate,
              SystemLogDate				= @LDT_SystemDate,
              ExecutiveCompanyIDSeq     = @LVC_ExecutiveCompanyIDSeq
      where   IDSeq = @IPVC_ChildCompanyID 
      and     len(NULLIF(@IPVC_ChildCompanyID,'')) > 0
      ---------------------------------------------------------------------------------  
      
    COMMIT TRANSACTION COMP;   
  END TRY  
  BEGIN CATCH  
    -- XACT_STATE:  
    -- If 1, the transaction is committable.  
    -- If -1, the transaction is uncommittable and should be rolled back.  
    -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.  
    if (XACT_STATE()) = -1  
    begin  
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION COMP;  
    end  
    else if (XACT_STATE()) = 1  
    begin  
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION COMP;  
    end   
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION COMP;     
    ------------------------        
    select @LVC_CodeSection =  'Proc :uspCUSTOMERS_ExecutiveCompanyInsert;Error Creating ExecutiveCompany Record For: '+ @IPVC_ExecutiveCompanyName  
    ------------------------  
    select '-1' as ExecutiveCompanyID       
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection  
    return;                    
  END CATCH;
END 
else if( len(NULLIF(@LVC_CompanyIDSeq,'')) > 0 and @IsAlreadyExecutiveCompany = 1 )
begin
     select @LVC_ExecutiveCompanyIDSeq = ExecutiveCompanyIDSeq from Customers.dbo.ExecutiveCompany 
     where CompanyIDSeq = @LVC_CompanyIDSeq and ActiveFlag = 1
     ----------------------------------------------------------------------------------  
      -- Update Executive-Child Relationship in Company table 
     ----------------------------------------------------------------------------------  
     update  CUSTOMERS.dbo.Company 
     set     ModifiedByIDSeq			= @IPBI_ModifyingUserID,
             ModifiedDate				= @LDT_SystemDate,
             SystemLogDate				= @LDT_SystemDate,
             ExecutiveCompanyIDSeq      = @LVC_ExecutiveCompanyIDSeq
     where   IDSeq = @IPVC_ChildCompanyID  
     and     len(NULLIF(@IPVC_ChildCompanyID,'')) > 0
end
else if( len(NULLIF(@LVC_ExecutiveCompanyIDSeq,'')) > 0 and @IsAlreadyExecutiveCompany = 1 )
begin
     ----------------------------------------------------------------------------------  
      -- Update Executive-Child Relationship in Company table 
     ----------------------------------------------------------------------------------  
     update  CUSTOMERS.dbo.Company 
     set     ModifiedByIDSeq			= @IPBI_ModifyingUserID,
             ModifiedDate				= @LDT_SystemDate,
             SystemLogDate				= @LDT_SystemDate,
             ExecutiveCompanyIDSeq      = @LVC_ExecutiveCompanyIDSeq
     where   IDSeq = @IPVC_ChildCompanyID  
     and     len(NULLIF(@IPVC_ChildCompanyID,'')) > 0
end
END
GO
