SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Function  Name  : [FNSPLIT_STRING]
-- Description     : This procedure gets Invoice Details pertaining to passed 
--                        CustomerName,City,State,ZipCode and AccountID
-- Input Parameters: '1,2,3,4',','
-- 
-- 
-- 
-- Revision History:
-- Author          : NAl
-- 01/16/2007      : Function Created Date
------------------------------------------------------------------------------------------------------
CREATE  FUNCTION [invoices].[FNSPLIT_STRING]      
(@STR1 VARCHAR(7000),@CTERMINATOR CHAR(1))          
RETURNS @TABLE TABLE(STRNAME VARCHAR(7000))          
AS          
BEGIN          
          
IF(@STR1 IS NOT NULL)      
BEGIN      
DECLARE @STR2 VARCHAR(1000)          
DECLARE @INO INTEGER          
SELECT @INO=CHARINDEX(@CTERMINATOR,LTRIM(RTRIM(@STR1)),1)          
          
WHILE(@INO<>0)          
BEGIN          
   SELECT @STR2=SUBSTRING(LTRIM(RTRIM(@STR1)),1,@INO-1)          
         
   INSERT INTO @TABLE SELECT LTRIM(RTRIM(@STR2))          
   SELECT @STR2= SUBSTRING(LTRIM(RTRIM(@STR1)),@INO+1,LEN(LTRIM(RTRIM(@STR1))))         
   SELECT @INO=CHARINDEX(@CTERMINATOR,LTRIM(RTRIM(@STR2)),1)          
   SELECT @STR1=@STR2            
END          
   SELECT @STR2=SUBSTRING(LTRIM(RTRIM(@STR1)),1,LEN(LTRIM(RTRIM(@STR1))))          
   INSERT INTO @TABLE SELECT LTRIM(RTRIM(@STR2)) WHERE @STR2 <> ''        
   DELETE @TABLE WHERE LTRIM(RTRIM(STRNAME))=''      
END      
      
       
   RETURN           
END     
  







GO
