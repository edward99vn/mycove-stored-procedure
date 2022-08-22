CREATE DEFINER=`root`@`localhost` PROCEDURE `product_insert_stored_procedure`(
	-- Add the parameters for the stored procedure here
	IN usrName varchar(55), 
	OUT statusResponse INT
)
BEGIN
	-- DECLARE VARIABLE
	Declare xml longtext default '';
    Declare x INT default 1;
    Declare recordNumber integer default 0;    
    Declare recent datetime;
    Declare valueReturn int;
    Declare invalidRows longtext default '';
    
		-- param
	Declare clientIdParam int default 0;
    Declare productCategoryId int;
    Declare createdUserId int;
    
    -- product values
    Declare productNameValue varchar(55) default '';
    Declare productCategoryNameValue varchar(55) default '';
    Declare descriptionValue varchar(255) default '';
    
	-- pass condition data into variable
	select v.xml from `validate_import_table` v where v.username = usrName and v.date = (select max(date) from validate_import_table) into xml;
	select extractvalue(xml, 'count(/records/record)') into recordNumber;
	select max(date) from validate_import_table into recent;
	-- Find Client Id
	select c.client_id from `client` c, `user` u where c.user_id = u.df_user_id and u.user_email = usrName into clientIdParam;
	select c.user_id from `client` c where c.client_id = clientIdParam into createdUserId;
    
	-- Turn off SQL SAFE UPDATES
    SET SQL_SAFE_UPDATES = 0;
    
	-- ----------------------------------------------------- VALIDATION -----------------------------------------------------
	
    WHILE x <= recordNumber DO
		SELECT extractvalue(xml, '/records/record[$x]/product_name') into productNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/product_category_name') into productCategoryNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/description') into descriptionValue;
        
			-- find product category id by productCategoryNameValue;
		Select product_category_id from product_category where TRIM(product_category_name) = productCategoryNameValue ORDER BY product_category_id DESC LIMIT 1 into productCategoryId;
        
        -- INSERT Product
        INSERT INTO `product` (`product_category_id`, `product_name`, `product_description`, `product_archived_flag`, `product_blocked_flag`, `product_created_by`, `product_created_at`) VALUES
		(productCategoryId, productNameValue, descriptionValue, 0, 0, createdUserId, CURRENT_TIMESTAMP());
        
		SET x = x + 1;
    END WHILE;
	-- ----------------------------------------------------- END VALIDATION -------------------------------------------------
    
        -- RETURN RESULT
    IF (invalidRows != '') THEN
    	UPDATE validate_import_table
		SET	status = 0, invalid_rows = invalidRows, error_message = 'Invalid data', notes = 'Product'
		WHERE username = usrName
			AND date = recent;
	ELSE
		UPDATE validate_import_table
        SET status = 1, notes = 'Product'
        WHERE username = usrName
			AND date = recent;
    END IF;
    
	-- Return 0 -> status: error
    -- Return 1 -> status: success
    SELECT v.status from `validate_import_table` v where v.date = recent into statusResponse;
        
	-- Turn on SQL SAFE UPDATES
    SET SQL_SAFE_UPDATES = 1;
END