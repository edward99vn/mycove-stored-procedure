CREATE DEFINER=`dbmasteruser`@`%` PROCEDURE `tenant_validation_stored_procedure`(
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
    
		-- Tenant values
    Declare tenantFirstNameValue varchar(55) default '';
    Declare tenantMiddleNameValue varchar(55) default '';
    Declare tenantLastNameValue varchar(55) default '';
    Declare apartmentNameValue varchar(55) default '';
    Declare tenantEmailValue varchar(55) default '';
    Declare dateOfBirthValue varchar(55) default '';
    Declare mobileNumberValue varchar(55) default '';
    Declare workNumberValue varchar(55) default '';
    
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
		SELECT extractvalue(xml, '/records/record[$x]/first_name') into tenantFirstNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/middle_name') into tenantMiddleNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/last_name') into tenantLastNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/apartment_name') into apartmentNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/tenant_email') into tenantEmailValue;
		SELECT extractvalue(xml, '/records/record[$x]/date_of_birth') into dateOfBirthValue;
		SELECT extractvalue(xml, '/records/record[$x]/mobile_number') into mobileNumberValue;
		SELECT extractvalue(xml, '/records/record[$x]/work_number') into workNumberValue;
        
		-- START validation
		SET x = x + 1;
        
        -- VALIDATE tenantFirstNameValue
        
		IF (tenantFirstNameValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Tenant First Name is null on row(s): ', x, '; ');
		END IF; 
        
        -- VALIDATE tenantMiddleNameValue (allow NULL)
        
        -- VALIDATE tenantLastNameValue
        
		IF (tenantLastNameValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Tenant Last Name is null on row(s): ', x, '; ');
		END IF; 
        
		-- VALIDATE apartmentNameValue
        
        IF (apartmentNameValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Name is null on row(s): ', x, '; ');
		ELSEIF ((select COUNT(*) from apartment where apartment_name = apartmentNameValue and apartment_client_id = clientIdParam) = 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Apartment Name does not exist on row(s): ', x, '; ');
        END IF;
        
        -- VALIDATE tenantEmailValue
        
		IF (tenantEmailValue = '' ) THEN
			SET invalidRows = CONCAT(invalidRows, 'Tenant Email is null on row(s): ', x, '; ');
		ELSEIF (isEmailValid(tenantEmailValue) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Tenant Email is invalid on row(s): ', x, '; ');
		ELSEIF ((select count(*) from tenant where tenant_alt_email_id = tenantEmailValue) != 0) THEN
			SET invalidRows = CONCAT(invalidRows, 'Email address is already being used on row(s): ', x, '; ');
        END IF;
        
        -- VALIDATE dateOfBirthValue
        
        IF (isDateValid(dateOfBirthValue) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Date of birth is invalid on row(s): ', x, '; ');
        END IF;
        
		-- VALIDATE mobileNumberValue
        
        IF (mobileNumberValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Tenant Mobile Phone is null on row(s): ', x, '; ');
		ELSEIF (isPhoneNumberValid(mobileNumberValue) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Tenant Mobile Phone is invalid on row(s): ', x, '; ');
		END IF;
        
		-- VALIDATE workNumberValue
        
        IF (workNumberValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Tenant Work Number Phone is null on row(s): ', x, '; ');
		ELSEIF (isPhoneNumberValid(workNumberValue) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Tenant Work Number Phone is invalid on row(s): ', x, '; ');
		END IF;
    
    END WHILE;
    
	-- ----------------------------------------------------- END VALIDATION -----------------------------------------------------
    	
    -- RETURN RESULT
    IF (invalidRows != '') THEN
    	UPDATE validate_import_table
		SET	status = 0, invalid_rows = invalidRows, error_message = 'Invalid data', notes = 'Tenant'
		WHERE username = usrName
			AND date = recent;
	ELSE
		UPDATE validate_import_table
        SET status = 1, notes = 'Tenant'
        WHERE username = usrName
			AND date = recent;
    END IF;

	-- Return 0 -> status: error
    -- Return 1 -> status: success
    SELECT v.status from `validate_import_table` v where v.date = recent into statusResponse;

	-- Turn on SQL SAFE UPDATES
    SET SQL_SAFE_UPDATES = 1;
    
END