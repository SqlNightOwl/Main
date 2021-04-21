SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_ExecutiveCompanyInsert]
-- Description     : This procedure gets called for Creation of Brand New ExecutiveCompany  
--                    This procedure takes care of Inserting Only ExecutiveCompany Records. 
-- Input Parameters: As Below in Sequential order.  
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_CompanyInsert  Passing Input Parameters  
-- Revision History:  
-- Author          : Mahaboob (Defect 909)  07/26/2011
-- 2011-09-06      : Mahaboob ( TFS 1026)     --  Changes  are made as per the Revised "ExecutiveCompany" table script 
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_ExecutiveCompanyInsert] (  @IPVC_CompanyIDSeq           varchar(50),                      --> UI will pass based on the Company selected.  
																@IPVC_CompanyName            varchar(255),                     --> UI will pass based on the Company selected                                                       
																@IPVC_Status				 bit = 1,                          --> UI will pass based on Value of Active checkbox.Default 1  
															    @IPBI_UserIDSeq              bigint                            --> This is UserID of person logged on and creating this ExecutiveCompany in OMS.(Mandatory)  
                                                              )
as   
BEGIN  
  set nocount on;    
  SET CONCAT_NULL_YIELDS_NULL off;  
  ----------------------------------------------------------------------------  
  -- Local Variable Declaration  
  ----------------------------------------------------------------------------   
  declare @LVC_ExecutiveCompanyIDSeq    varchar(50)  
  declare @LDT_SystemDate      datetime  
  declare @LVC_CodeSection     varchar(1000)  
  ----------------------------------------------------------------------------  
  ---Inital validation  
  if exists(select top 1 1   
            from   Customers.dbo.ExecutiveCompany C with (nolock)  
            where  C.ExecutiveCompanyIDSeq  = @IPVC_CompanyIDSeq  
            and    len(NULLIF(@IPVC_CompanyIDSeq,'')) > 0  
           )  
  begin  
    select @LVC_CodeSection='ExecutiveCompanyID: ' + @IPVC_CompanyIDSeq + ' already exists in the system. Wrong Proc call uspCUSTOMERS_ExecutiveCompanyInsert from UI.'  
    select '-1' as ExecutiveCompanyID  
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection  
    return  
  end  
  ----------------------------------------------------------------------------  
  --Initialization of Variables.  
  select @IPVC_CompanyIDSeq  = LTRIM(RTRIM(UPPER(@IPVC_CompanyIDSeq))),
         @IPVC_CompanyName   = LTRIM(RTRIM(UPPER(@IPVC_CompanyName)))  
  ----------------------------------------------------------------------------  
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
                                          
      select @LVC_ExecutiveCompanyIDSeq  as ExecutiveCompanyIDSeq, @IPVC_CompanyIDSeq as CompanyIDSeq, @IPVC_CompanyName as CompanyName,
		    @IPVC_Status   as ActiveFlag, @IPBI_UserIDSeq as CreatedByIDSeq
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
    select @LVC_CodeSection =  'Proc :uspCUSTOMERS_ExecutiveCompanyInsert;Error Creating ExecutiveCompany Record For: '+ @IPVC_CompanyName  
    ------------------------  
    select '-1' as ExecutiveCompanyID       
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection  
    return;                    
  END CATCH;   
  -------------------------------------------------------------------------------  
  ---Final Return to UI  
  -------------------------------------------------------------------------------  
  select @LVC_ExecutiveCompanyIDSeq as ExecutiveCompanyID  
  -------------------------------------------------------------------------------  
END  
GO
