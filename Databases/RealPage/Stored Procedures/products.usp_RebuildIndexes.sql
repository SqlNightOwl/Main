SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create proc [products].[usp_RebuildIndexes]    
AS
BEGIN
  ------------------------------------
  SET CONCAT_NULL_YIELDS_NULL OFF;  
  set nocount on;
  ------------------------------------
  declare @LVC_DBNAME   VARCHAR(200)
  select  @LVC_DBNAME = db_name()
  
  declare @LT_TABLENAMES TABLE (SEQ  INT IDENTITY(1,1) NOT NULL,
                                CMD  VARCHAR(1000)     NULL
                               )
  declare @LI_MIN  INT;
  declare @LI_MAX  INT;
  declare @LVC_SQL varchar(4000);
  -------------------------------------
  --Step 1 : ReIndex
  insert into @LT_TABLENAMES(CMD)
  SELECT  'DBCC DBREINDEX ([' + NAME + '],'''',100);' 
  FROM SYSOBJECTS WITH (NOLOCK) WHERE TYPE = 'U'

  select @LI_MIN = Min(SEQ),@LI_MAX = Max(Seq) from @LT_TABLENAMES
  while @LI_MIN <= @LI_MAX
  begin
    SELECT @LVC_SQL = 'USE  ' + @LVC_DBNAME + CHAR(13) + CMD FROM @LT_TABLENAMES WHERE SEQ = @LI_MIN
    begin try
      ---select @LVC_SQL
      EXEC(@LVC_SQL) 
    end try
    begin catch
      ---Do nothing
    end catch
    select @LI_MIN = @LI_MIN + 1
  end
  -----------------------------------
  DELETE FROM @LT_TABLENAMES;  
  -----------------------------------
  --Step 2 : IndexDefrag
  insert into @LT_TABLENAMES(CMD)
  SELECT 'DBCC INDEXDEFRAG ([' + @LVC_DBNAME + '],[' + OBJECT_NAME(I.ID)+ '],' + CONVERT(VARCHAR(50),I.INDID)+');'
  FROM SYSINDEXES I WITH (NOLOCK),SYSOBJECTS O WITH (NOLOCK) 
  WHERE I.ID = O.ID AND O.TYPE='U' AND O.NAME NOT IN ('dtproperties')
  AND 1 NOT IN (INDEXPROPERTY(I.ID,I.NAME,'ISSTATISTICS'),
                INDEXPROPERTY(I.ID,I.NAME,'ISAUTOSTATISTICS') ,
                INDEXPROPERTY(I.ID,I.NAME,'ISHYPOTHETICAL')
               )
  AND OBJECTPROPERTY(I.ID,'ISMSSHIPPED')= 0
  AND I.INDID BETWEEN 1 AND 254
  AND O.ID = I.ID

  select @LI_MIN = Min(SEQ),@LI_MAX = Max(Seq) from @LT_TABLENAMES
  while @LI_MIN <= @LI_MAX
  begin
    SELECT @LVC_SQL = 'USE  ' + @LVC_DBNAME + CHAR(13) + CMD FROM @LT_TABLENAMES WHERE SEQ = @LI_MIN
    begin try
      ---select @LVC_SQL
      EXEC(@LVC_SQL) 
    end try
    begin catch
      ---Do nothing
    end catch
    select @LI_MIN = @LI_MIN + 1
  end
  -----------------------------------
  --Step 3 : Update Stats
  SELECT @LVC_SQL = 'USE  ' + @LVC_DBNAME + CHAR(13) + 'EXEC ' + @LVC_DBNAME + '.dbo.sp_updatestats;'
  begin try
    ---select @LVC_SQL
    EXEC(@LVC_SQL)    
  end try
  begin catch
     ---Do nothing
  end catch  
  -----------------------------------
END
GO
