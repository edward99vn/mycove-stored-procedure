CREATE DEFINER=`dbmasteruser`@`%` PROCEDURE `property_manager_validation_stored_procedure`(
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
    
    		-- Property Manager values
    Declare propertyManagerNameValue varchar(55) default '';
    Declare propertyManagerEmailValue varchar(55) default '';
    Declare propertyNameValue varchar(55) default '';
    Declare propertyManagerPhoneValue varchar(55) default '';
    
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
		SELECT extractvalue(xml, '/records/record[$x]/property_manager_name') into propertyManagerNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_manager_email') into propertyManagerEmailValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_name') into propertyNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/property_manager_phone') into propertyManagerPhoneValue;
        
		-- START validation
		SET x = x + 1;
        
        -- VALIDATE property manager name
        
		IF (propertyManagerNameValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Manager Name is null on row(s): ', x, '; ');
		END IF; 
        
		-- VALIDATE property manager email
        
        IF (propertyManagerEmailValue = '' ) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Manager Email is null on row(s): ', x, '; ');
		ELSEIF (isEmailValid(propertyManagerEmailValue) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Manager Email is invalid on row(s): ', x, '; ');
		ELSEIF ((select COUNT(*) from property_manager where emailid = propertyManagerEmailValue) != 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Email address is already being used on row(s): ', x, '; ');
		ELSEIF ((select COUNT(*) from user where user_email = propertyManagerEmailValue) != 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Email address is already being used on row(s): ', x, '; ');
        END IF;
        
		-- VALIDATE property name
        IF (propertyNameValue != '' and (select COUNT(*) from property where property_name = propertyNameValue and property_client_id = clientIdParam) = 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Name does not exist on row(s): ', x, '; ');
        END IF;
	
		-- VALIDATE propertyManagerPhoneValue
        
        IF (propertyManagerPhoneValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Manager Phone is null on row(s): ', x, '; ');
		ELSEIF (isPhoneNumberValid(propertyManagerPhoneValue) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Property Manager Phone is invalid on row(s): ', x, '; ');
		END IF;
        
    END WHILE;
    
	-- ----------------------------------------------------- END VALIDATION -----------------------------------------------------
    
        -- RETURN RESULT
    IF (invalidRows != '') THEN
    	UPDATE validate_import_table
		SET	status = 0, invalid_rows = invalidRows, error_message = 'Invalid data', notes = 'Property Manager'
		WHERE username = usrName
			AND date = recent;
	ELSE
		UPDATE validate_import_table
        SET status = 1, notes = 'Property Manager'
        WHERE username = usrName
			AND date = recent;
    END IF;
    
	-- Return 0 -> status: error
    -- Return 1 -> status: success
    SELECT v.status from `validate_import_table` v where v.date = recent into statusResponse;
        
	-- Turn on SQL SAFE UPDATES
    SET SQL_SAFE_UPDATES = 1;
END