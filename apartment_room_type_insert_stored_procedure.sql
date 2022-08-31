CREATE DEFINER=`dbmasteruser`@`%` PROCEDURE `apartment_room_type_insert_stored_procedure`(
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
    Declare apartmentRoomTypeId int;
    Declare productId int;

    -- apartment room type values
    Declare apartmentRoomTypeNameValue varchar(55) default '';
    Declare descriptionValue varchar(255) default '';
    Declare productNameValue varchar(55) default '';

    -- pass condition data into variable
	select v.xml from `validate_import_table` v where v.username = usrName and v.date = (select max(date) from validate_import_table) into xml;
	select extractvalue(xml, 'count(/records/record)') into recordNumber;
	select max(date) from validate_import_table into recent;
			-- Find Client Id
	select c.client_id from `client` c, `user` u where c.user_id = u.df_user_id and u.user_email = usrName into clientIdParam;
	select c.user_id from `client` c where c.client_id = clientIdParam into createdUserId;

	-- ----------------------------------------------------- INSERT -----------------------------------------------------

	WHILE x <= recordNumber DO
		SELECT extractvalue(xml, '/records/record[$x]/apartment_room_type_name') into apartmentRoomTypeNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/description') into descriptionValue;
		SELECT extractvalue(xml, '/records/record[$x]/product_name') into productNameValue;

        IF (productNameValue = '') THEN         
			INSERT INTO `apartment_room_type` (`apartment_room_type_name`, `appartment_room_type_category_id`, `apartment_room_type_description`, `apartment_room_type_archived_flag`, `apartment_room_type_blocked_flag`, `apartment_room_type_created_by`, `apartment_room_type_created_at`) VALUES
			(apartmentRoomTypeNameValue, NULL, descriptionValue, 0, 0, createdUserId, CURRENT_TIMESTAMP());
		ELSE
				-- find apartment room type id by apartment room type name
            select apartment_room_type_id from apartment_room_type where TRIM(apartment_room_type_name) = TRIM(apartmentRoomTypeNameValue) ORDER BY apartment_room_type_id DESC LIMIT 1 into apartmentRoomTypeId;
				-- find product id by product name
			select product_id from product where TRIM(product_name) = TRIM(productNameValue) ORDER BY product_id DESC limit 1 into productId;

			-- IF relationship is not available, insert a new one
			IF ((select COUNT(*) from apartment_room_type_product where apartment_room_type_id = apartment_room_type_id and product_id = productId) = 0) THEN
				-- INSERT relationship between apartment room type and product
				INSERT INTO `apartment_room_type_product` (`apartment_room_type_id`, `product_id`, `created_by`, `created_date`, `last_modified_date`, `last_modified_by`) VALUES
				(apartmentRoomTypeId, productId, createdUserId,	CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), createdUserId);
            END IF;
        END IF;

		SET x = x + 1;
    END WHILE;

	-- ----------------------------------------------------- END INSERT -------------------------------------------------
  
END