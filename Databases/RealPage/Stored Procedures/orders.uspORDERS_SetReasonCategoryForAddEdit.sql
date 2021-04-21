SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_SetReasonCategoryForAddEdit]
-- Description     : This proc gets called from the modal Save for the following
--                   1) From Reason Search Maintenance Screen                 1. More-->View or More-->Edit. Any change in the modal and Save.
--                   2) From Reason Category Matrix Search Maintenance Screen 1. More-->View or More-->Edit. Any change in the modal and Save.

--                   3) From Add-->Reason. User enters new Reason,4 digit ReasonCode, Move categories from LHS to RHS, checks/unchecks internalflag, Save.

--                   UI will trap any Critical returned by this proc and show in UI

-- Parameters      : below
-- Syntax examples : 
/*
---Scenario 1: Adding Brand new Reason with 4 digit ReasonTypeCode and along with corresponding Category Association from RHS.
EXEC ORDERS.dbo.uspORDERS_SetReasonCategoryForAddEdit @IPVC_ReasonName= 'Order Cancellations Test',@IPVC_ReasonCode = 'CCCV',@IPBI_UserIDSeq=130,
                                                      @IPX_RHSXML = '<root>
                                                                        <row reasoncategoryidseq="-1" categorycode="CANC" internalflag="1" />
                                                                        <row reasoncategoryidseq="-1" categorycode="CRED" internalflag="1" />
                                                                     </root>' 
 

---Scenario 2: Editing Existing Reason that already has 4 digit ReasonTypeCode (greyedout) and along with corresponding Category Association for Internal Flags from RHS.
EXEC ORDERS.dbo.uspORDERS_SetReasonCategoryForAddEdit @IPVC_ReasonName= 'Order Cancellations Test1',@IPVC_ReasonCode = 'CCCV',@IPBI_UserIDSeq=130,
                                                      @IPX_RHSXML = '<root>
                                                                        <row reasoncategoryidseq="8" categorycode="CANC" internalflag="1" />
                                                                        <row reasoncategoryidseq="9" categorycode="CRED" internalflag="0" />
                                                                     </root>'  

---Scenario 3: Editing Existing Reason that already has 4 digit ReasonTypeCode (greyedout) and user removing one association from RHS and moved it to LHS
EXEC ORDERS.dbo.uspORDERS_SetReasonCategoryForAddEdit @IPVC_ReasonName= 'Order Cancellations Test',@IPVC_ReasonCode = 'CCCV',@IPBI_UserIDSeq=130,
                                                      @IPX_RHSXML = '<root>                                                                        
                                                                        <row reasoncategoryidseq="9" categorycode="CRED" internalflag="0" />
                                                                     </root>'  
                                                        
---Scenario 3: Editing Existing Reason that already has 4 digit ReasonTypeCode (greyedout) and user removing all association from RHS to LHS.
--             Note: UI internally has UserEditableFlag. Only when 1, user can move records from RHS back to LHS. Else UI should not allow moving that record from RHS to LHS.
EXEC ORDERS.dbo.uspORDERS_SetReasonCategoryForAddEdit @IPVC_ReasonName= 'Order Cancellations Test',@IPVC_ReasonCode = 'CCCV',@IPBI_UserIDSeq=130,
                                                      @IPX_RHSXML = '<root>                                                                        
                                                                     </root>'

*/
------------------------------------------------------------------------------------------------------------------------------------------
CREATE procedure [orders].[uspORDERS_SetReasonCategoryForAddEdit] (@IPVC_ReasonName   varchar(255),  --> This is ReasonName that user types for brand new or Edits or does not change at all, in the modal.
                                                                @IPVC_ReasonCode   varchar(20),   --> This is the 4 digit ReasonCode that user types for brand new, or kept greyout for Edit from existing.
                                                                @IPBI_UserIDSeq    bigint,        --> This is the userIDSeq of the user who is initiating Add or Edit Operation in the modal.
                                                                @IPX_RHSXML        xml,           --> This is the xml of rows that are only in Right hand side (RHS)
                                                                @IPVC_Mode         varchar(10)    --> This is to know whether it is from Add or Edit
                                                               )  																
AS
BEGIN -->Main Begin
  set nocount on;
  --------------------------------------------------------------------
  ---Local variables Declaration
  declare @LI_NewReasonFlag    int;
  declare @LVC_CodeSection     varchar(1000);
  declare @LDT_SystemLogDate   datetime;
  declare @idoc                int;

  declare @LT_RHSTableValues  Table(SortSeq                    bigint      not null identity(1,1) primary key,
                                    reasoncategoryidseq        int         not null,
                                    categorycode               varchar(20) not null,
                                    internalflag               int         not null
                                   );

  --------------------------------------------------------------------
  --Local Variables intialization
  select @IPVC_ReasonName  = ltrim(rtrim(@IPVC_ReasonName)),
         @IPVC_ReasonCode  = Upper(ltrim(rtrim(@IPVC_ReasonCode))), 
         @LI_NewReasonFlag = 0,
         @LDT_SystemLogDate= Getdate()
  --------------------------------------------------------------------
  ---If 4 digit unique ReasonCode does not exists in Orders.dbo.Reason Table
  --   then this is new Add Reason Event.
 -- Default @LI_NewReasonFlag to 1 when Adding New Reason   
 if(@IPVC_Mode = 'Add')
 Begin
 select @LI_NewReasonFlag = 1
 End
  --------------------------------------------------------------------
  --Step 1 : General Validation 1 : @IPVC_ReasonName cannot be blank or null
  if (@IPVC_ReasonName = '' or len(@IPVC_ReasonName)=0)
  begin
    select  @LVC_CodeSection = 'Reason Name Cannot be Blank'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  --Step 2: General Validation 2 : @IPVC_ReasonName cannot be blank or null
  if (@IPVC_ReasonCode = '' or len(@IPVC_ReasonCode)=0)
  begin
    select  @LVC_CodeSection = 'Reason Code Cannot be Blank'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  --------------------------------------------------------------------
  ---Validation for New Add Reason: UI Should trap this and Show in UI and also log 
  --  using existing logging mechanizm to Customers.dbo.ErrorLog table.
  if (@LI_NewReasonFlag=1)
  begin
    --Step 3 : Validation 1 : New Add Reason Name should be unique.
    if exists (select top 1 1 
               from   ORDERS.dbo.Reason R with (nolock)
               where  ltrim(rtrim(R.ReasonName)) = @IPVC_ReasonName
              )
    begin
      select  @LVC_CodeSection = 'Reason: ' + @IPVC_ReasonName + ' already exists in the system. Reason Name should be unique to Add New Reason.'
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
      return
    end
    --Step 4 : Validation 2 : New Add Reason Code should be unique.
    if exists (select top 1 1 
               from   ORDERS.dbo.Reason R with (nolock)
               where  R.Code = @IPVC_ReasonCode
              )
    begin
      select  @LVC_CodeSection = '4 digit Reason Code : ' + @IPVC_ReasonCode + ' already exists in the system. Reason Code should be unique to Add New Reason.'
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
      return
    end
  end
  -----------------------------------------------------------------------------------
  --Create Handle to access newly created internal representation of the XML document
  -----------------------------------------------------------------------------------
  EXEC sp_xml_preparedocument @idoc OUTPUT,@IPX_RHSXML;
  -----------------------------------------------------------------------------------
  --Step 1 : OPENXML to read XML and Import raw data as such into @LT_RHSTableValues
  -----------------------------------------------------------------------------------  
  BEGIN TRY
    insert into @LT_RHSTableValues(reasoncategoryidseq,categorycode,internalflag)
    select A.reasoncategoryidseq,A.categorycode,A.internalflag
    from   (select convert(int,reasoncategoryidseq)   as reasoncategoryidseq,
                   ltrim(rtrim(categorycode))         as categorycode,
                   convert(int,internalflag)          as internalflag

            from OPENXML (@idoc,'root/row',1) 
             with (reasoncategoryidseq   int,
                   categorycode          varchar(20),                                
                   internalflag          int
                 )
           ) A
  END TRY
  BEGIN CATCH    
    select  @LVC_CodeSection = 'Proc: uspORDERS_SetReasonCategoryForAddEdit - Critical Internal Error Parsing XML list.'
  
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end   
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection      
    return
  END   CATCH
  -----------------------------------------------------------------------------------
  ---Validation for @LT_RHSTableValues
  ---If Brand new Reason Addition and that No associated Categories from RHS, then throw and Error.
  -- ie. For Brand New Reason addition, there must be atleast One Associated Category in RHS in UI.
  if (((select count(1) from @LT_RHSTableValues) = 0)
        AND
      (@LI_NewReasonFlag = 1)
     )
  begin 
    select  @LVC_CodeSection = 'No Associated Categories selected for Adding new Reason : ' + @IPVC_ReasonName + '. Alteast one valid category should be associated.'
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
      return
  end
  -----------------------------------------------------------------------------------
  BEGIN TRY
    BEGIN TRANSACTION RC; 
      --Step 2: Processing for ORDERS.dbo.Reason table
      --        If Brand New Reason Proceed to Insert a new Reason Record.
      --        If Edit of Existing reason, Update only when Reason Name is changed.
      if (@LI_NewReasonFlag = 1)
      begin
        Insert into ORDERS.dbo.Reason(Code,ReasonName,CreatedByIDSeq,CreatedDate,SystemLogDate)
        select @IPVC_ReasonCode as Code,@IPVC_ReasonName as ReasonName,
               @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemLogDate as CreatedDate,@LDT_SystemLogDate as SystemLogDate
        where  not exists (select top 1 1 
                           from   ORDERS.dbo.Reason R with (nolock)
                           where  R.Code = @IPVC_ReasonCode
                          )
      end
      else 
      begin
        ---Update Only when @IPVC_ReasonName is changed from existing Reason for the same Code.
        Update R
        set    R.ReasonName      = @IPVC_ReasonName,
               R.ModifiedByIDSeq = @IPBI_UserIDSeq,
               R.ModifiedDate    = @LDT_SystemLogDate,
               R.SystemLogDate   = @LDT_SystemLogDate
        from   ORDERS.dbo.Reason R with (nolock)
        where  R.Code    = @IPVC_ReasonCode
        and    ltrim(rtrim(R.ReasonName)) <> @IPVC_ReasonName
      end
      -----------------------------------------------------------------------------------
      --Step 3: Processing for ORDERS.dbo.ReasonCategory table
      ---3.1 Insert if ReasonCategory does not exist in table but present in @LT_RHSTableValues with reasoncategoryidseq of -1
      --------------------------------------------------------------------------------------
      Insert into ReasonCategory (ReasonCode,CategoryCode,InternalFlag,ActiveFlag,
                                  CreatedByIDSeq,CreatedDate,SystemLogDate)
      select @IPVC_ReasonCode    as ReasonCode,Source.CategoryCode as CategoryCode,
             Source.InternalFlag as InternalFlag,1 as ActiveFlag,  ---> RHS results always means it is Active.
             @IPBI_UserIDSeq     as CreatedByIDSeq,
             @LDT_SystemLogDate  as CreatedDate,@LDT_SystemLogDate as SystemLogDate
      from   @LT_RHSTableValues Source
      where  Source.reasoncategoryidseq = -1
      and    not exists (select top 1 1
                         from   ORDERS.dbo.ReasonCategory RC with (nolock)
                         where  RC.ReasonCode   = @IPVC_ReasonCode
                         and    RC.CategoryCode = Source.CategoryCode
                        )
      --------------------------------------------------------------------------------------
      ---3.2 Update for ReasonCategory row for Existing ReasonCode and records matching @LT_RHSTableValues Source
      ---    ie.ReasonCode, CategoryCode matches, but only attribute of InternalFlag is changed by user in RHS.
      --------------------------------------------------------------------------------------
      Update RC
      set    RC.InternalFlag    = Source.InternalFlag,
             RC.ActiveFlag      = 1,
             RC.ModifiedByIDSeq = @IPBI_UserIDSeq,
             RC.ModifiedDate    = @LDT_SystemLogDate,
             RC.SystemLogDate   = @LDT_SystemLogDate
      from   ORDERS.dbo.ReasonCategory RC with (nolock)
      inner join
             @LT_RHSTableValues Source
      on     RC.ReasonCode   = @IPVC_ReasonCode
      and    RC.CategoryCode = Source.CategoryCode
      and    ((RC.InternalFlag <> Source.InternalFlag)
                 OR
              (RC.ActiveFlag   <> 1)
             )
      and    RC.IDSeq        = Source.reasoncategoryidseq
      and    Source.reasoncategoryidseq <> -1      
      --------------------------------------------------------------------------------------
      ---3.3 Update for ReasonCategory rows for existing Reason Code @IPVC_ReasonCode,
      --     where rows are not present in @LT_RHSTableValues 
      --     ie. User has moved all records from RHS to LHS and Saved, so that @LT_RHSTableValues is empty.
      --------------------------------------------------------------------------------------
      Update RC
      set    RC.ActiveFlag      = 0,
             RC.ModifiedByIDSeq = @IPBI_UserIDSeq,
             RC.ModifiedDate    = @LDT_SystemLogDate,
             RC.SystemLogDate   = @LDT_SystemLogDate
      from   ORDERS.dbo.ReasonCategory RC with (nolock)
      where  RC.UserEditableFlag = 1
      and    RC.ReasonCode   = @IPVC_ReasonCode
      and    not exists (select top 1 1
                         from   @LT_RHSTableValues Source
                         where  RC.IDSeq        = (case when Source.reasoncategoryidseq = -1 
                                                          then RC.IDSeq 
                                                        else Source.reasoncategoryidseq 
                                                   end)
                         and    RC.Categorycode = Source.Categorycode
                        )
      --------------------------------------------------------------------------------------
    COMMIT TRANSACTION RC; 
  END TRY
  BEGIN CATCH
    -- XACT_STATE:
    -- If 1, the transaction is committable.
    -- If -1, the transaction is uncommittable and should be rolled back.
    -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION RC;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION RC;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION RC; 
    ------------------------       
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end     
    ------------------------      
    select @LVC_CodeSection =  'Proc: uspORDERS_SetReasonCategoryForAddEdit - Critical Internal Processing Error Insert/Update for ReasonCategory'
    ------------------------     
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;                  
  END CATCH; 
  --------------------------------------------------------------------------------------
  ---Final Cleanup
  if @idoc is not null
  begin
    EXEC sp_xml_removedocument @idoc
    set @idoc = NULL
  end
END --> Main End
GO
