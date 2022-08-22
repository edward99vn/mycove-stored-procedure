CREATE DEFINER=`root`@`localhost` PROCEDURE `product_item_insert_stored_procedure`(
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
    Declare productIdParam int;
    
    -- product item values
    Declare productItemNameValue varchar(55) default '';
    Declare productNameValue varchar(55) default '';
    Declare itemBrandValue varchar(255) default '';
    
	-- pass condition data into variable
	select v.xml from `validate_import_table` v where v.username = usrName and v.date = (select max(date) from validate_import_table) into xml;
	select extractvalue(xml, 'count(/records/record)') into recordNumber;
	select max(date) from validate_import_table into recent;
			-- Find Client Id
	select c.client_id from `client` c, `user` u where c.user_id = u.df_user_id and u.user_email = usrName into clientIdParam;
	select c.user_id from `client` c where c.client_id = clientIdParam into createdUserId;
    
	-- ----------------------------------------------------- INSERT -----------------------------------------------------
    
	WHILE x <= recordNumber DO
		SELECT extractvalue(xml, '/records/record[$x]/product_item_name') into productItemNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/product_name') into productNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/item_brand') into itemBrandValue;
        
			-- FIND product Id rely on product item name
        select product_id from product where TRIM(product_name) = TRIM(productNameValue) Order by product_id DESC limit 1 into productIdParam;
        
        -- INSERT Product Item
		INSERT INTO `product_item` (`product_item_product_id`, `product_item_name`, `product_item_brand`, `product_item_code`, `product_item_mesure_unit`, `product_item_unit`, `product_item_ref_link`, `product_item_internal_ref`, `product_item_warranty_exp_period`, `product_item_warranty_exp_type`, `product_item_warranty_remarks`, `product_item_archived_flag`, `product_item_blocked_flag`, `product_item_created_by`, `product_item_created_at`, `product_item_updated_at`) VALUES
		(productIdParam, productItemNameValue, itemBrandValue, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, 0, createdUserId, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

		SET x = x + 1;
    END WHILE;
    
	-- ----------------------------------------------------- END INSERT -----------------------------------------------------

END