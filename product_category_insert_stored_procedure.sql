CREATE DEFINER=`root`@`localhost` PROCEDURE `product_category_insert_stored_procedure`(
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
     Declare createdUserId int;
     
    -- product category values
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
		SELECT extractvalue(xml, '/records/record[$x]/product_category_name') into productCategoryNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/description') into descriptionValue;
		
        -- INSERT product category
        INSERT INTO `product_category` (`product_category_name`, `product_category_description`, `product_category_archived_flag`, `product_category_blocked_flag`, `product_category_created_by`, `product_category_created_at`) VALUES
		(productCategoryNameValue, descriptionValue, 0, 0, createdUserId, CURRENT_TIMESTAMP());

		SET x = x + 1;
        
    END WHILE;
    -- ----------------------------------------------------- END VALIDATION -----------------------------------------------------
END