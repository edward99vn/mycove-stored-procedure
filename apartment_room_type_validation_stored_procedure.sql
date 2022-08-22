CREATE DEFINER=`root`@`localhost` PROCEDURE `apartment_room_type_validation_stored_procedure`(
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
    
    -- Turn off SQL SAFE UPDATES
    SET SQL_SAFE_UPDATES = 0;
    
	-- ----------------------------------------------------- VALIDATION -----------------------------------------------------
	
	WHILE x <= recordNumber DO
		SELECT extractvalue(xml, '/records/record[$x]/apartment_room_type_name') into apartmentRoomTypeNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/description') into descriptionValue;
		SELECT extractvalue(xml, '/records/record[$x]/product_name') into productNameValue;
		
        -- START validation
		SET x = x + 1;
        
        IF (productNameValue = '') THEN 
			
            -- VALIDATE apartmentRoomTypeNameValue
			
            IF (apartmentRoomTypeNameValue = '') THEN
				SET invalidRows = CONCAT(invalidRows, 'Apartment Room Type Name is null on row(s): ', x, '; ');
			ELSEIF ((select COUNT(*) from apartment_room_type where TRIM(apartment_room_type_name) = TRIM(apartmentRoomTypeNameValue)) != 0) THEN
				SET invalidRows = CONCAT(invalidRows, 'Apartment Room Type Name is already exist row(s): ', x, '; ');
			END IF;
        END IF;
        
        -- VALIDATE productNameValue
        
        IF (productNameValue != '' and (select COUNT(*) from product where TRIM(product_name) = TRIM(productNameValue)) = 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Product does not exist row(s): ', x, '; ');
        END IF;
        
        -- VALIDATE descriptionValue
        
    END WHILE;
    -- ----------------------------------------------------- END VALIDATION -----------------------------------------------------
    
    -- RETURN RESULT
    IF (invalidRows != '') THEN
    	UPDATE validate_import_table
		SET	status = 0, invalid_rows = invalidRows, error_message = 'Invalid data', notes = 'Apartment Room Type'
		WHERE username = usrName
			AND date = recent;
	ELSE
		UPDATE validate_import_table
        SET status = 1, notes = 'Apartment Room Type'
        WHERE username = usrName
			AND date = recent;
    END IF;
    
	-- Return 0 -> status: error
    -- Return 1 -> status: success
    SELECT v.status from `validate_import_table` v where v.date = recent into statusResponse;

	-- Turn on SQL SAFE UPDATES
    SET SQL_SAFE_UPDATES = 1;
END