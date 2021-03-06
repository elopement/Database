USE [LMS]
GO
/****** Object:  StoredProcedure [dbo].[SSP_Checkisdealy_UPDATE]    Script Date: 11/29/2020 3:44:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter PROCEDURE [dbo].[SSP_CheckdealyIsoutdate]  --检查是否续借逾期
	
	--select * from  [dbo].BorrowRecord 

AS
	DECLARE @Body NVARCHAR(max)
	DECLARE @xml NVARCHAR(4000)
	DECLARE @Subject NVARCHAR(255)
	DECLARE @To VARCHAR(255)
	DECLARE @Cc VARCHAR(255)

BEGIN
 BEGIN TRANSACTION
    IF object_id('tempdb..#TEMP') IS NOT NULL
	DROP TABLE #TEMP  
	select 
		RecordID,
	    Account,
		Returndate,
		Email,
		BookName,
		administrator,
		delaydate
	INTO #TEMP
	from [dbo].BorrowRecord 
	where  delaydate  < GETDATE() AND Status = 7

	--SELECT * from [dbo].BorrowRecord 
	--SELECT * FROM #TEMP


DECLARE @Account nvarchar(50), @Email nvarchar(50),@BookName nvarchar(50),@administor nvarchar(50),@returndate NVARCHAR(50),@recordID nvarchar(50),@delaydate nvarchar(50)

DECLARE @VARCURSOR Cursor --定义游标变量
	
DECLARE Tra_cursor CURSOR FOR --创建游标

SELECT Account,Email,BookName,administrator,Returndate,RecordID,delaydate from #TEMP

OPEN Tra_cursor --打开游标

set @VARCURSOR=Tra_cursor--为游标变量赋值

FETCH NEXT FROM @VARCURSOR into @Account,@Email,@BookName,@administor,@returndate,@recordID,@delaydate

While(@@FETCH_STATUS=0)--判断FETCH语句是否执行成功
BEGIN
      

	SET @Body = N'
<html>
<head>
    <meta charset="utf-8" />
</head>
<body>
    <h3>Dear&nbsp;{Account},</h3>
    <p>&nbsp;&nbsp;您借阅的图书《{BookName}》已经于{delaydate}续借借阅逾期.根据图书借阅管理要求,请尽快归还图书。</p>
    <p>&nbsp;&nbsp;请点击<a href= "http://cnpvg-app11:8037/Record/Record ">图书管理系统</a>查看续借逾期书籍,在此提醒</p>
	<h3>EXEC HR Department</h2>
</body>
</html>'


	SET @To = @Email
	SET @CC = @administor+'@emerson.com'
	SET @Subject = N'EXEC图书管理平台:续借逾期通知'

	SET @Body = Replace(@body, '{Account}', isnull(@Account, ''))
	SET @Body = Replace(@body, '{BookName}', isnull(@BookName, ''))
	SET @Body = Replace(@body, '{delaydate}', isnull(@delaydate, ''))


	BEGIN
		EXEC msdb.dbo.sp_send_dbmail --使用系统提供的ssp发送邮件
		     @recipients = @To
			,@copy_recipients = @Cc
			,@subject = @Subject
			,@body = @Body
			,@body_format = 'HTML'
	END

	update [dbo].BorrowRecord set Status = 11 where RecordID = @recordID --更新借阅状态为逾期未还

	fetch next from Tra_cursor into @Account,@Email,@BookName,@administor,@returndate,@recordID,@delaydate
END
close Tra_cursor
deallocate Tra_cursor

	IF @@error != 0
	BEGIN
		ROLLBACK
	END
	ELSE
	BEGIN
		COMMIT 
	END
END