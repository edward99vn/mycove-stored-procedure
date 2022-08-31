CREATE DEFINER=`dbmasteruser`@`%` PROCEDURE `employee_validation_stored_procedure`(
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
    
		-- Employee params
	Declare firstNameValue varchar(55) default '';
	Declare lastNameValue varchar(55) default '';
	Declare employeeTypeValue varchar(55) default '';
 	Declare isMaintenanceEmployeeValue varchar(55) default '';	
    Declare employeeCodeValue varchar(55) default '';
	Declare dateOfBirthValue varchar(55) default '';
	Declare mobileNumberValue varchar(55) default '';
	Declare workNumberValue varchar(55) default '';
    Declare emergencyNumberValue varchar(55) default '';
	Declare emailValue varchar(55) default '';
	Declare alternateEmail varchar(55) default '';
    Declare joiningDate varchar(55) default '';
    Declare relievingDate varchar(55) default '';
	Declare addressDoorNumberValue varchar(55) default '';
	Declare addressStreetNameValue varchar(55) default '';
    Declare addressLine2Value varchar(55) default '';
	Declare zipValue varchar(55) default '';
	Declare stateValue varchar(55) default '';
    Declare cityValue varchar(55) default '';
	Declare countryValue varchar(55) default '';
    
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
		SELECT extractvalue(xml, '/records/record[$x]/first_name') into firstNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/last_name') into lastNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/employee_type') into employeeTypeValue;
		SELECT extractvalue(xml, '/records/record[$x]/is_maintenance_employee') into isMaintenanceEmployeeValue;
		SELECT extractvalue(xml, '/records/record[$x]/employee_code') into employeeCodeValue;
		SELECT extractvalue(xml, '/records/record[$x]/date_of_birth') into dateOfBirthValue;
		SELECT extractvalue(xml, '/records/record[$x]/mobile_number') into mobileNumberValue;
		SELECT extractvalue(xml, '/records/record[$x]/work_number') into workNumberValue;
		SELECT extractvalue(xml, '/records/record[$x]/emergency_number') into emergencyNumberValue;
		SELECT extractvalue(xml, '/records/record[$x]/email') into emailValue;
		SELECT extractvalue(xml, '/records/record[$x]/alternate_email') into alternateEmail;
		SELECT extractvalue(xml, '/records/record[$x]/joining_date') into joiningDate;
		SELECT extractvalue(xml, '/records/record[$x]/relieving_date') into relievingDate;
		SELECT extractvalue(xml, '/records/record[$x]/address_door_number') into addressDoorNumberValue;
		SELECT extractvalue(xml, '/records/record[$x]/address_street_name') into addressStreetNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/address_line_2') into addressLine2Value;
		SELECT extractvalue(xml, '/records/record[$x]/zip') into zipValue;
		SELECT extractvalue(xml, '/records/record[$x]/state') into stateValue;
		SELECT extractvalue(xml, '/records/record[$x]/city') into cityValue;
		SELECT extractvalue(xml, '/records/record[$x]/country') into countryValue;
        
		-- START validation
		SET x = x + 1;
		
        -- VALIDATE firstNameValue
        
		IF (firstNameValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'First Name is null on row(s): ', x, '; ');
		END IF; 
        
        -- VALIDATE lastNameValue
        
		IF (lastNameValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Last Name is null on row(s): ', x, '; ');
		END IF;
        
        -- VALIDATE employeeTypeValue
			-- IF null, default value is Employee
            
		-- VALIDATE isMaintenanceEmployeeValue
			-- Not implement yet
		
        -- VALIDATE employeeCodeValue
		
        IF (employeeCodeValue = '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Employee Code is null on row(s): ', x, '; ');
        END IF;
        
		-- VALIDTE dateOfBirthValue
        
        IF (isDateValid(dateOfBirthValue) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Date Of Birth is invalid on row(s): ', x, '; ');
        END IF;

		-- VALIDATE phonenumber
        
        IF (isPhoneNumberValid(mobileNumberValue) != true and mobileNumberValue != '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Mobile Number is invalid on row(s): ', x, '; ');
        END IF;
	
        IF (isPhoneNumberValid(workNumberValue) != true and workNumberValue != '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Work Number is invalid on row(s): ', x, '; ');
        END IF;
        
        IF (isPhoneNumberValid(emergencyNumberValue) != true and emergencyNumberValue != '') THEN
			SET invalidRows = CONCAT(invalidRows, 'Emergency Number is invalid on row(s): ', x, '; ');
        END IF;
        
        -- VALIDATE email
        
        IF (isEmailValid(emailValue) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Email is invalid on row(s): ', x, '; ');
        END IF;
        
        IF (isEmailValid(alternateEmail) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Alternate Email is invalid on row(s): ', x, '; ');
        END IF;
        
        -- VALIDATE Date
        
        IF (isDateValid(joiningDate) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Joining Date is invalid on row(s): ', x, '; ');
        END IF;
        
		IF (isDateValid(relievingDate) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Relieving Date is invalid on row(s): ', x, '; ');
        END IF;
        
        -- VALIDATE Address (BACKEND implement)
        
        -- VALIDATE GeoLocation
		
        IF (isZipcodeValid(zipValue) != true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Zipcode is invalid on row(s): ', x, '; ');
        END IF;
        
        IF (isNumberic(stateValue) = true) THEN
			SET invalidRows = CONCAT(invalidRows, 'State is invalid on row(s): ', x, '; ');
        END IF;
        
		IF (isNumberic(cityValue) = true) THEN
			SET invalidRows = CONCAT(invalidfRows, 'City is invalid on row(s): ', x, '; ');
        END IF;

		IF (isNumberic(countryValue) = true) THEN
			SET invalidRows = CONCAT(invalidRows, 'Country is invalid on row(s): ', x, '; ');
        END IF;
        
    END WHILE;

	-- ----------------------------------------------------- END VALIDATION -----------------------------------------------------
    
        -- RETURN RESULT
    IF (invalidRows != '') THEN
    	UPDATE validate_import_table
		SET	status = 0, invalid_rows = invalidRows, error_message = 'Invalid data', notes = 'Employee'
		WHERE username = usrName
			AND date = recent;
	ELSE
		UPDATE validate_import_table
        SET status = 1, notes = 'Employee'
        WHERE username = usrName
			AND date = recent;
    END IF;
    
	-- Return 0 -> status: error
    -- Return 1 -> status: success
    SELECT v.status from `validate_import_table` v where v.date = recent into statusResponse;
        
	-- Turn on SQL SAFE UPDATES
    SET SQL_SAFE_UPDATES = 1;
END