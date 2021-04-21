SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [security].[uspADMINISTRATION_InsertRights](
                                                          @IPVC_RoleID           varchar(50),
                                                          @IPVC_RoleName         varchar(200),
                                                          @IPVC_RightsIDseq      varchar(8000),
                                                          @mode                  varchar(10),
														  @IPB_ActiveFlag         bit,
														  @IPVC_UserIDSeq         varchar(50)                                                                             
                                                     ) 

AS
BEGIN
  set nocount on;
  DECLARE @LBI_RoleIDSeq  bigint
  ---------------------------------------------------
  ---Step 1 : Update / Insert New Roles
  if( @mode = 'View')
  begin
		update [Security].dbo.[Roles]
		 set [Name]          = @IPVC_RoleName,
		     ActiveFlag      = @IPB_ActiveFlag,
			 ModifiedByIDSeq = @IPVC_UserIDSeq,
			 ModifiedDate    = getdate()
		where IDSeq = @IPVC_RoleID        
    select @LBI_RoleIDSeq =  @IPVC_RoleID 
    delete from [security].dbo.RoleRights where RoleIDSeq = @LBI_RoleIDSeq
  end
  else
  begin
    -------------------------------------------------
    if not exists (select top 1 1 from [Security].dbo.[Roles] with (nolock)
                   where  [Name] = @IPVC_RoleName
                  )
    begin
      select @LBI_RoleIDSeq = max(IDseq) from [Security].dbo.[Roles] with (nolock)
      select @LBI_RoleIDSeq = coalesce(@LBI_RoleIDSeq,0)+1
      insert into [Security].dbo.[Roles](IDSeq,Code,[Name],ActiveFlag,CreatedByIDSeq,CreatedDate)
      select @LBI_RoleIDSeq                           as IDSeq,
             'U'+substring(@IPVC_RoleName,1,3) as Code,
             @IPVC_RoleName                    as [Name],
			 @IPB_ActiveFlag                   as ActiveFlag,
			 @IPVC_UserIDSeq                   as CreatedByIDSeq,
			 getdate()                         as CreatedDate
    end
    else
    begin
      select TOP 1 @LBI_RoleIDSeq = IDseq from [Security].dbo.[Roles] with (nolock)
      where  [Name] = @IPVC_RoleName 
	  update [Security].dbo.[Roles]
		 set [Name]          = @IPVC_RoleName,
		     ActiveFlag      = @IPB_ActiveFlag,
			 ModifiedByIDSeq = @IPVC_UserIDSeq,
			 ModifiedDate    = getdate()
		where IDSeq = @IPVC_RoleID      
    end
    ----------------------------------------------
    delete from [security].dbo.RoleRights where RoleIDSeq = @LBI_RoleIDSeq
  end
  ---------------------------------------------------------------------------------
  --Step 2 : Insert new RoleRights for RoleID
  insert into [security].dbo.RoleRights(RoleIDSeq,RightIDSeq)
  select @LBI_RoleIDSeq as RoleIDSeq,
         ProductCode    as RightIDSeq              
  from [customers].dbo.[fnSplitProductCodes] ('|'+@IPVC_RightsIDseq)
  ---------------------------------------------------------------------------------
end                
GO
