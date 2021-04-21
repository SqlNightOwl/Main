SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_AddMeasure
-- Description     : This proc is called by Product Administration Measure Management to Add New Measures
-- Input Parameters: @IPVC_MeasureCode,@IPVC_MeasureName
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_AddMeasure 
                       @IPVC_MeasureCode = 'RACK'  --> This is the new Measurecode 
                      ,@IPVC_MeasureName = 'Rack'  --> This is the new MeasureName  
                      ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Measure Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_AddMeasure]  (@IPVC_MeasureCode           varchar(10),     ---->MANDATORY : This is the upto 6 character Unique Measure Code for adding new measure
                                                  @IPVC_MeasureName           varchar(20),     ---->MANDATORY : This is Measure Name for the new measure 
                                                  @IPBI_UserIDSeq             bigint= -1       ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                 )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500),
          @LI_SortSeq      int; 
 
  select  @IPVC_MeasureCode = UPPER(NullIf(ltrim(rtrim(@IPVC_MeasureCode)),'')),
          @IPVC_MeasureName = NullIf(ltrim(rtrim(@IPVC_MeasureName)),''),
          @LDT_SystemDate   = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_MeasureCode or @IPVC_MeasureName cannot be blank or null
  If (@IPVC_MeasureCode is null)
  begin
    select @LVC_CodeSection = 'Error: Measure Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  If ( (isnumeric(@IPVC_MeasureCode) = 1) 
            OR 
       (PATINDEX('%[^A-Z]%',@IPVC_MeasureCode) > 0)
     )
  begin
    select @LVC_CodeSection = 'Error: Measure Code cannot be numeric or alpha numeric.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if len(@IPVC_MeasureCode) > 6
  begin
    select @LVC_CodeSection = 'Error: Measure Code cannot be more than 6 characters';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end

  If (@IPVC_MeasureName is null)
  begin
    select @LVC_CodeSection = 'Error: Measure Name cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  --Validation 2: @IPVC_MeasureCode or @IPVC_MeasureName should be unique and should not already exists
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Measure M with (nolock)
             where   (M.Code = @IPVC_MeasureCode)
            )
  begin
    select @LVC_CodeSection = 'Error: Measure Code already exists in the system. Measure Code should be unique for new measure additions.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Measure M with (nolock)
             where   (M.Name = @IPVC_MeasureName)
            )
  begin
    select @LVC_CodeSection = 'Error: Measure Name already exists in the system. Measure Name should be unique for new measure additions.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  if (not exists (select  Top 1 1
                  from    PRODUCTS.dbo.Measure M with (nolock)
                  where   (M.Code = @IPVC_MeasureCode)                  
                 )
         AND
      not exists (select  Top 1 1
                  from    PRODUCTS.dbo.Measure M with (nolock)
                  where   (M.Name = @IPVC_MeasureName)
                 )
     )
  begin
    select @LI_SortSeq = Max(M.SortSeq)+ 1 from PRODUCTS.dbo.Measure M with (nolock)

    Insert into Products.dbo.Measure(Code,Name,SortSeq,CreatedByIDSeq,CreatedDate,SystemLogDate)
    select @IPVC_MeasureCode as Code,@IPVC_MeasureName as Name,@LI_SortSeq as SortSeq,
           @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate;
  end
  ------------------------------------------
END--> Main End
GO
