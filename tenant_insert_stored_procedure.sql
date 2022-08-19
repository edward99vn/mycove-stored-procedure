CREATE DEFINER=`root`@`localhost` PROCEDURE `tenant_insert_stored_procedure`(
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
	Declare createdTenantIdParam int;
    Declare apartmentIdParam int;
    
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
    
	-- ----------------------------------------------------- INSERT -----------------------------------------------------
    
    WHILE x <= recordNumber DO
		SELECT extractvalue(xml, '/records/record[$x]/first_name') into tenantFirstNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/middle_name') into tenantMiddleNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/last_name') into tenantLastNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/apartment_name') into apartmentNameValue;
		SELECT extractvalue(xml, '/records/record[$x]/tenant_email') into tenantEmailValue;
		SELECT extractvalue(xml, '/records/record[$x]/date_of_birth') into dateOfBirthValue;
		SELECT extractvalue(xml, '/records/record[$x]/mobile_number') into mobileNumberValue;
		SELECT extractvalue(xml, '/records/record[$x]/work_number') into workNumberValue;
        
        IF (dateOfBirthValue = '') THEN
			SET dateOfBirthValue = NULL;
        END IF;
	
		-- INSERT data into User table
		
        INSERT INTO `user` (`password`, `user_email`, `user_first_name`, `user_last_name`, `user_avatar_url`, `user_display_name`, `user_phone`, `user_title`, `user_date_of_birth`, `user_card_holder_name`, `user_card_number`, `user_card_cvv`, `user_card_expiry_month`, `user_card_expiry_year`, `user_card_type_id`, `user_card_details_address_1`, `user_card_details_address_2`, `user_card_details_zip_code`, `user_card_details_city`, `user_card_details_state`, `user_card_details_country`, `is_trial`, `is_triggered`, `user_blocked_flag`, `user_archived_flag`, `user_created_datetime`, `signup_active_flag`, `is_active`, `email_verified`) VALUES
		(NULL, tenantEmailValue, tenantFirstNameValue, tenantLastNameValue, NULL, tenantFirstNameValue, mobileNumberValue, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, CURRENT_TIMESTAMP(), 0, 1, 1);
				
                -- backup created user id
				select df_user_id from user where user_email = tenantEmailValue ORDER BY df_user_id DESC limit 1 into createdUserIdParam;
			
		-- INSERT data into Tenant table
        
        INSERT INTO `tenant` (`user_id`, `tenant_first_name`, `tenant_middle_name`, `tenant_last_name`, `tenant_date_of_birth`, `tenant_mobile_number`, `tenant_work_number`, `tenant_alt_email_id`, `tenant_active`, `tenant_active_remark`, `tenant_mobile_notification`, `tenant_lease_date`, `tenant_relieving_date`, `tenant_created_date`, `tenant_modified_datetime`) VALUES
		(createdUserIdParam, tenantFirstNameValue, tenantMiddleNameValue, tenantLastNameValue, dateOfBirthValue, mobileNumberValue, workNumberValue, tenantEmailValue, 1, 1, 1, NULL, NULL, CURRENT_DATE(), CURRENT_TIMESTAMP());
				-- backup created tenant id
				select tenant_id from tenant where tenant_alt_email_id = tenantEmailValue ORDER BY tenant_id limit 1 into createdTenantIdParam;
        
        -- UPDATE the role for Tenant
        
        INSERT INTO `user_client_role_mapping` (`user_id`, `client_id`, `role_id`, `created_by`, `last_modified_by`, `last_modified_date_time`) VALUES
		(createdUserIdParam, clientIdParam, 6, NULL, NULL, current_timestamp());
        
        -- UPDATE relationship between property name and tenant
        
        SELECT apartment_id FROM apartment WHERE apartment_client_id = clientIdParam and apartment_name = apartmentNameValue ORDER BY apartment_id DESC LIMIT 1 into apartmentIdParam;
        
        IF ((select COUNT(*) from tenant_apartment where apartment_id = apartmentIdParam) = 0) THEN
                INSERT INTO `tenant_apartment` (`apartment_id`, `tenant_id`, `tenant_created_date`, `tenant_modified_datetime`) VALUES
				(apartmentIdParam, createdTenantIdParam, CURRENT_DATE(), CURRENT_TIMESTAMP());
		ELSE
			UPDATE tenant_apartment SET tenant_id = createdTenantIdParam WHERE apartment_id = apartmentIdParam;
        END IF;
        
		SET x = x + 1;
    END WHILE;
    
END