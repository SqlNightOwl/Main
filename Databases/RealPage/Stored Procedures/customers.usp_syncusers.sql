SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create proc [customers].[usp_syncusers]    
AS
begin
  SET CONCAT_NULL_YIELDS_NULL OFF;  
  set nocount on
  declare @LVC_DBNAME VARCHAR(200)
  select @LVC_DBNAME = db_name()
  set nocount on;
  -----------------------------------------------
  if user_id('customerportaluser') is null 
  begin
    EXEC sp_adduser 'customerportaluser', 'customerportaluser', 'db_datareader'
  end
  EXEC sp_change_users_login 'Auto_Fix', 'customerportaluser';

  if user_id('omsreportuser') is null 
  begin
    EXEC sp_adduser 'omsreportuser', 'omsreportuser', 'db_datareader'
  end
  EXEC sp_change_users_login 'Auto_Fix', 'omsreportuser';

  if user_id('OMSReadOnly') is null 
  begin
    EXEC sp_adduser 'OMSReadOnly', 'OMSReadOnly', 'db_datareader'
  end 
  EXEC sp_change_users_login 'Auto_Fix', 'OMSReadOnly'; 

  if user_id('omsappuser') is null 
  begin
    EXEC sp_adduser 'omsappuser', 'omsappuser', 'db_datareader'
  end  
  EXEC sp_change_users_login 'Auto_Fix', 'omsappuser';


  if user_id('LSDTransactionUser') is null 
  begin
    EXEC sp_adduser 'LSDTransactionUser', 'LSDTransactionUser'
  end  
  EXEC sp_change_users_login 'Auto_Fix', 'LSDTransactionUser';
  -----------------------------------------------
  declare @LT_TABLENAMES TABLE (SEQ  INT IDENTITY(1,1) NOT NULL,
                                CMD  VARCHAR(4000)     NULL
                               )
  declare @LI_MIN  INT
  declare @LI_MAX  INT
  declare @LVC_SQL varchar(4000)
  insert into @LT_TABLENAMES(CMD)
  select 'grant exec,view Definition on [' + name + '] to customerportaluser; '  from sysobjects where type  in ('P','FN', 'IF','FS', 'FT')
  union
  select 'grant select,view Definition on [' + name + '] to customerportaluser; '  from sysobjects where type in ('V','U','TF')
  union
  select 'grant exec,view Definition on [' + name + '] to omsreportuser; '  from sysobjects where type  in ('P','FN', 'IF','FS', 'FT')
  union
  select 'grant select,view Definition on [' + name + '] to omsreportuser; '  from sysobjects where type in ('V','U','TF')  
  union
  select 'grant view Definition on [' + name + '] to OMSReadOnly; '  from sysobjects where type  in ('P','FN', 'IF','FS', 'FT')
  union
  select 'grant select,view Definition on [' + name + '] to OMSReadOnly; '  from sysobjects where type in ('V','U','TF')
  union
  select 'grant exec,view Definition on [' + name + '] to omsappuser; '  from sysobjects where type in ('P','FN', 'IF','FS', 'FT')
  union
  select 'grant select,insert,update,delete,view Definition on [' + name + '] to omsappuser; '  from sysobjects where type in ('V','U')
  union
  select 'grant select,view Definition on [' + name + '] to omsappuser; '  from sysobjects where type in ('TF')
  union
  select 'grant select on [' + name + '] to LSDTransactionUser; '  from sysobjects where type in ('V','U','TF') and name in ('Company','Property','Address')
  
 
  set @LI_MIN = 1
  select @LI_MAX = count(*) from @LT_TABLENAMES
  while @LI_MIN <= @LI_MAX
  begin    
    SELECT @LVC_SQL = 'USE  ' + @LVC_DBNAME + ';' + CHAR(13) + CMD FROM @LT_TABLENAMES WHERE SEQ = @LI_MIN
    BEGIN TRY
       EXEC(@LVC_SQL) 
    END TRY
    BEGIN CATCH
    END   CATCH 
    select @LI_MIN = @LI_MIN + 1
  end
  
END
GO
