SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [products].[cc_pymt_hist_sp]	@customer_code 	varchar(8) = NULL,
																	@num_days	int = 365,
																	@num_trx	int = 50

AS


	SET NOCOUNT ON

	DECLARE @trx_ctrl_num	varchar(16),
					@doc_ctrl_num varchar(16),
					@on_acct 			float,
					@amt_net			float ,
					@row 					int

	CREATE TABLE #payments
	(
		trx_ctrl_num 			varchar(16) NULL,
		doc_ctrl_num 			varchar(16) NULL,
		date_doc 					int NULL,
		trx_type 					int NULL,
		amt_net 					float NULL,
		amt_paid_to_date 	float NULL,
		balance 					float NULL,
		customer_code 		varchar(12) NULL,
		void_flag 				smallint NULL,
		trx_type_code 		varchar(8) NULL,
		payment_type 			smallint NULL,
		nat_cur_code			varchar(8) NULL,
		date_sort					int,

		date_applied			int NULL,

		price_code				varchar(8) NULL,
		amt_on_acct				float NULL,
		sequence_id				int NULL
	)


	CREATE table #results
	(
		trx_ctrl_num 		varchar(16) NULL	
	)




	IF @num_days > 0
		INSERT #payments
		SELECT 	trx_ctrl_num, 
						doc_ctrl_num,
						date_posted, /*changed from date_doc, by CF*/
						trx_type,
						amt_net,
						null,
						amt_on_acct,
						customer_code,
						void_flag,
						NULL,
						payment_type,
						nat_cur_code,
						date_doc,
						date_applied,
						price_code,
						amt_on_acct,
						0
		FROM artrx 
		WHERE date_doc > DATEDIFF(dd,'01/01/1753',getdate()) + 639906 - @num_days
		AND trx_type = 2111
		AND customer_code = @customer_code




		AND payment_type = 1

	ELSE
		INSERT #payments
		SELECT 	trx_ctrl_num, 
						doc_ctrl_num,
						date_posted, /*changed from date_doc, by CF*/
						trx_type,
						amt_net,
						null,
						amt_on_acct,
						customer_code,
						void_flag,
						NULL,
						payment_type,
						nat_cur_code,
						date_doc,
						date_applied,
						price_code,
						amt_on_acct,
						0
		FROM artrx 
		WHERE trx_type = 2111
		AND customer_code =@customer_code




		AND payment_type = 1


CREATE INDEX payments_idx_1 ON #payments( doc_ctrl_num, payment_type )
CREATE INDEX payments_idx_2 ON #payments( doc_ctrl_num, trx_type )
CREATE INDEX payments_idx_3 ON #payments( doc_ctrl_num, trx_ctrl_num, customer_code )


	SELECT @doc_ctrl_num = MIN(doc_ctrl_num) FROM #payments WHERE payment_type <> 3
	WHILE (@doc_ctrl_num IS NOT NULL)
		BEGIN
			IF (	SELECT COUNT(*) 
					FROM #payments 
					WHERE doc_ctrl_num = @doc_ctrl_num
					AND	payment_type = 2 ) > 0
				BEGIN
					SELECT 	@on_acct = amt_on_acct,
									@amt_net = amt_net
					FROM #payments
					WHERE doc_ctrl_num = @doc_ctrl_num
					AND	payment_type = 1 
			
					UPDATE #payments
					SET balance = @on_acct,
							amt_net = @amt_net
					WHERE doc_ctrl_num = @doc_ctrl_num
					AND	payment_type = 2 
		
					DELETE #payments
					WHERE doc_ctrl_num = @doc_ctrl_num
					AND	payment_type = 1
				END
	
			SELECT @doc_ctrl_num = MIN(doc_ctrl_num) FROM #payments
			WHERE doc_ctrl_num > @doc_ctrl_num
		
			AND payment_type <> 3
		END	




	INSERT #payments
	SELECT	p.trx_ctrl_num, 
					a.doc_ctrl_num,
					a.date_posted, /*changed from a.date_doc, by CF*/
					a.trx_type,
					a.amt_net * -1,
					NULL,
					a.amt_on_acct * -1,
					a.customer_code,
					a.void_flag,
					NULL,
					a.payment_type,
					a.nat_cur_code,
					p.date_doc,
					p.date_applied,
					a.price_code,
					a.amt_on_acct,
					0
	FROM #payments p, artrx a 
	WHERE a.trx_type in (2112, 2113, 2121)
	AND a.customer_code = @customer_code
	AND a.doc_ctrl_num = p.doc_ctrl_num 



	UPDATE #payments
	SET 	doc_ctrl_num = 'VOID ICR',
				trx_type = 9999
	WHERE trx_type = 2112

	UPDATE #payments
	SET 	doc_ctrl_num = 'VOID CR',
				trx_type = 9999
	WHERE trx_type = 2113

	UPDATE #payments
	SET 	doc_ctrl_num = 'NSF',
				trx_type = 9999
	WHERE trx_type = 2121

	UPDATE #payments
	SET 	doc_ctrl_num = 'VOID WR',
				trx_type = 9999
	WHERE trx_type = 2142







	

SELECT @doc_ctrl_num = MIN(doc_ctrl_num) FROM #payments WHERE payment_type in (1,2)
WHILE (@doc_ctrl_num IS NOT NULL)
	BEGIN
		SELECT @trx_ctrl_num = trx_ctrl_num FROM	#payments WHERE doc_ctrl_num = @doc_ctrl_num 
		SELECT @row = MIN(sequence_id) FROM artrxpdt WHERE doc_ctrl_num = @doc_ctrl_num
		WHILE @row IS NOT NULL
			BEGIN
				INSERT #payments
				SELECT 	@trx_ctrl_num,
								d.apply_to_num, 
								h.date_posted, /*changed from h.date_doc, by CF*/
								9999,
								
								inv_amt_applied,
								NULL, 
								h.amt_net,
								NULL,
								0,
								NULL, 
								NULL,
								h.nat_cur_code,
								0,
								h.date_applied,
								h.price_code,
								h.amt_on_acct,
								d.sequence_id
					FROM artrxpdt d, artrx h








					WHERE d.doc_ctrl_num = @doc_ctrl_num 
					AND	d.apply_to_num = h.doc_ctrl_num		
--					AND	d.doc_ctrl_num = h.doc_ctrl_num		
--					AND	d.trx_ctrl_num = h.trx_ctrl_num		
				 	AND h.customer_code = @customer_code
					AND d.void_flag = 0 
					AND d.sequence_id = @row 

				SELECT @row = MIN(sequence_id) 
				FROM artrxpdt 
				WHERE doc_ctrl_num = @doc_ctrl_num
				AND sequence_id > @row
			END

		SELECT @doc_ctrl_num = MIN(doc_ctrl_num) 
		FROM #payments
		WHERE doc_ctrl_num > @doc_ctrl_num
	

		AND payment_type in (1,2)
	END	




	UPDATE #payments
	SET balance = h.amt_net
	FROM #payments p, artrx h
	WHERE	p.doc_ctrl_num = h.doc_ctrl_num
	AND h.trx_type = 2031


	UPDATE #payments 
	SET date_sort = b.date_doc
	FROM #payments , #payments b
	WHERE #payments.trx_ctrl_num = b.trx_ctrl_num
	AND #payments.trx_type = 9999
	AND b.trx_type = 2111
	AND	#payments.sequence_id = b.sequence_id


	UPDATE #payments
	SET #payments.trx_type_code = artrxtyp.trx_type_code
	FROM #payments,artrxtyp
	WHERE artrxtyp.trx_type = #payments.trx_type


	DELETE FROM #payments WHERE payment_type = 3

	UPDATE #payments SET trx_type = 9999 WHERE trx_type is null


	SET ROWCOUNT @num_trx
	INSERT #results
	SELECT trx_ctrl_num FROM #payments WHERE trx_type = 2111 ORDER BY date_doc DESC 
	SET ROWCOUNT 0

	SELECT 	#payments.trx_ctrl_num,
					doc_ctrl_num,
					date_doc,
					trx_type,
					'amt_net' = STR(amt_net,30,6), 
					'amt_paid_to_date' = STR(amt_paid_to_date,30,6), 
					'balance' = STR(balance,30,6), 
					customer_code,
					void_flag,
					trx_type_code,
					payment_type,
					nat_cur_code,
					date_sort,
					date_applied,
					price_code,

				(	SELECT count(*) 
					FROM cc_comments 
					WHERE ( doc_ctrl_num = #payments.doc_ctrl_num)
					AND	customer_code = @customer_code ),
				( SELECT COUNT(*) 
					FROM comments 
					WHERE key_1 IN (SELECT trx_ctrl_num 
													FROM artrx 
													WHERE ( doc_ctrl_num = #payments.doc_ctrl_num)
													AND	customer_code = @customer_code))
	FROM 	#payments,#results 
	WHERE 	#payments.trx_ctrl_num = #results.trx_ctrl_num
	ORDER BY #payments.trx_ctrl_num DESC, trx_type , date_doc

DROP TABLE #payments
DROP TABLE #results

SET NOCOUNT OFF


GO
