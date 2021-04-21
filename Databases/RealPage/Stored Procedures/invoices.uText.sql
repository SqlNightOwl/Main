SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Stored Procedure  
  
  
-- Stored Procedure  
  
--  
-- Find Any Text in any stored procedure  
--  
-- Parameters:  
--   @Text - Text to search  
--   @ObjectType - Object Type (v=View, u=UserTable, p=StoredProcedure, ''= all)  
--   @SortByName - Sort by the Object Name  
CREATE  proc [invoices].[uText] @text varchar(255), @ObjectType varchar(10)= '', @SortByName bit = 1   as  
  
-- utext text  
-- utext text, p  
-- utext text, '', 0  
  
/*  
select * from syscomments  
select * from sysobjects  
*/  
  
if @SortByName = 0  
begin  
  -- Do not sort name  
  select  
    so.name as Name,  
    so.type,  
    'exec uscript ' + so.name + ',0,1,0' as Uscript,  
    substring(  
      text,  
      case when patindex('%'+@text+'%',text) <1 then 1  
      else patindex('%'+@text+'%',text)-15 end ,100  
    ) as SearchText  
    ,text as LineText  
  from syscomments sc,sysobjects so  
  where text like '%' + @text + '%' and  
        sc.id=so.id and  
        so.xtype like @objecttype + '%'  
  
end  
else  
begin  
  -- Sort by SPName  
  select  
    so.name as Name,  
    so.type,  
    'exec uscript ' + so.name + ',0,1,0' as Uscript,  
    substring(  
      text,  
      case when patindex('%'+@text+'%',text) <1 then 1  
      else patindex('%'+@text+'%',text)-15 end ,100  
    ) as SearchText  
    ,substring(text,1,255) as LineText  
  from syscomments sc,sysobjects so  
  where text like '%' + @text + '%' and  
        sc.id=so.id  and  
        so.xtype like @objecttype + '%'  
  order by so.xtype,so.name  
end  
  
  
  
  
  
GO
