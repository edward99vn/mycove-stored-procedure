CREATE DEFINER=`root`@`localhost` PROCEDURE `employee_insert_stored_procedure`(
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
    Declare createdUserIdParam int;
    Declare employeeTypeIdParam int;
    Declare employeeStreetAddress1 longtext default '';
    
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
	Declare addressStreetNameValue longtext default '';
    Declare addressLine2Value longtext default '';
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
	
    -- ----------------------------------------------------- INSERT -----------------------------------------------------

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
        
		-- HANDLE employeeTypeValue
        
        IF (employeeTypeValue = '') THEN
			SET employeeTypeValue = 'Maintenance Technician';
        END IF;
        
        -- HANDLE dateOfBirthValue 
        IF (dateOfBirthValue = '') THEN
			SET dateOfBirthValue = NULL;
		ELSE 
			SET dateOfBirthValue = DATE_FORMAT(STR_TO_DATE(dateOfBirthValue,'%m/%d/%Y'), '%Y-%m-%d'); 
        END IF;
        
        -- HANDLE joiningDate
		IF (joiningDate = '') THEN
			SET joiningDate = NULL;
		ELSE 
			SET joiningDate = DATE_FORMAT(STR_TO_DATE(joiningDate,'%m/%d/%Y'), '%Y-%m-%d'); 
        END IF;
        
        -- HANDLE relievingDate
		IF (relievingDate = '') THEN
			SET relievingDate = NULL;
		ELSE 
			SET relievingDate = DATE_FORMAT(STR_TO_DATE(relievingDate,'%m/%d/%Y'), '%Y-%m-%d'); 
        END IF;
        
		-- INSERT User
		INSERT INTO `user` (`password`, `user_email`, `user_first_name`, `user_last_name`, `user_avatar_url`, `user_display_name`, `user_phone`, `user_title`, `user_date_of_birth`, `user_card_holder_name`, `user_card_number`, `user_card_cvv`, `user_card_expiry_month`, `user_card_expiry_year`, `user_card_type_id`, `user_card_details_address_1`, `user_card_details_address_2`, `user_card_details_zip_code`, `user_card_details_city`, `user_card_details_state`, `user_card_details_country`, `is_trial`, `is_triggered`, `user_blocked_flag`, `user_archived_flag`, `user_created_datetime`, `signup_active_flag`, `is_active`, `email_verified`) VALUES
		(NULL, emailValue, firstNameValue, lastNameValue, NULL, firstNameValue, mobileNumberValue, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, CURRENT_TIMESTAMP(), 0, 1, 1);
			-- backup created user id
			select df_user_id from user where user_email = emailValue ORDER BY df_user_id DESC limit 1 into createdUserIdParam;
		
        -- INSERT Employee
			
            -- find employee type id rely on employee name
			select employee_type_id from employee_type where TRIM(employee_type_display_name) = TRIM('Maintenance Technician') order by employee_type_id desc limit 1 into employeeTypeIdParam;
			
            -- street address 1
			set employeeStreetAddress1 = addressDoorNumberValue + ' ' + addressStreetNameValue;
			
		INSERT INTO `employee` (`employee_client_id`, `employee_user_id`, `employee_type_id`, `employee_code`, `employee_first_name`, `employee_last_name`, `employee_date_of_birth`, `employee_mobile`, `employee_emergency_number`, `employee_work_number`, `employee_email`, `employee_alternate_email`, `employee_joining_date`, `employee_relieving_date`, `employee_mobile_notification`, `employee_street_address1`, `employee_street_address2`, `employee_zipcode`, `employee_city`, `employee_state`, `employee_country`, `employee_blocked_flag`, `employee_blocked_flag_remark`, `employee_archived_flag`, `employee_created_at`, `employee_updated_at`) VALUES
		(clientIdParam, createdUserIdParam, employeeTypeIdParam, employeeCodeValue, firstNameValue, lastNameValue, dateOfBirthValue, mobileNumberValue, emergencyNumberValue, workNumberValue, emailValue, alternateEmail, joiningDate, relievingDate, 1, employeeStreetAddress1, addressLine2Value, zipValue, cityValue, stateValue, countryValue, 0, 0, 0, CURRENT_DATE(), CURRENT_TIMESTAMP());

        -- INSERT RELATIONSHIP
		INSERT INTO `user_client_role_mapping` (`user_id`, `client_id`, `role_id`, `created_by`, `last_modified_by`, `last_modified_date_time`) VALUES
		(createdUserIdParam, clientIdParam, 4, NULL, NULL, CURRENT_TIMESTAMP());
		
		SET x = x + 1;

    END WHILE;
    
    -- ----------------------------------------------------- END INSERT -----------------------------------------------------

END