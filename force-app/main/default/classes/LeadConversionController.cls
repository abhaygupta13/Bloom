/*****************************************************************************************
Class       : LeadConversionController
Author      : Biswajeet
Description : Lead Conversion Controller class
Created Date: 29 AUG 2024
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0             29AUG2024           Initial Version 
*****************************************************************************************/
public without sharing class LeadConversionController {
    
    private static final string LEAD_RT_DEV_NAME_INDIVIDUAL_LEAD { get { return 'IndividualLead'; } }
    private static final string LEAD_RT_DEV_NAME_ORGANIZATION_LEAD { get { return 'OrganizationLead'; } }
    private static final string LEAD_MANDATORY_FIELD_MESSAGE { get { return 'Please fill out missing field information to proceed with lead conversion.'; } }
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } }
    
    private static final string OPPORTUNITY_AGENT_TYPE_DIRECT { get { return 'Direct'; } }
    private static final string OPPORTUNITY_AGENT_TYPE_INDIRECT { get { return 'Indirect'; } }
    private static final string LEAD_SOURCE_BROKER { get { return 'Broker'; } }
    private static final string LEAD_CUSTOMER_TYPE_RESIDENT { get { return 'Resident'; } }
    private static final string LEAD_CUSTOMER_TYPE_UAE_NATIONAL { get { return 'UAE National'; } }
    private static final string LEAD_CUSTOMER_TYPE_INTERNATIONAL { get { return 'International'; } }
    private static final string LEAD_CUSTOMER_TYPE_GCC { get { return 'GCC'; } }
    
    private static final string MTD_LEAD_CONVERT_EMAIL_TEMPLATE_ID { get { return 'LeadConvertEmailTemplateId'; } }
    private static final string MTD_OWE_NO_REPLY_SALES_IT_ID { get { return 'NoReplySalesIT'; } }
    
    private static final string BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID { get { return 'BloomNoReplyLeasingOWEmailId'; } }
    private static final string BAPP_BROKER_AGENT_CONVERT_EMAIL_TEMPLATE { get { return 'BAPP_BROKER_AGENT_CONVERT_EMAIL_TEMPLATE'; } }
    private static final string BAPP_ORG_WIDE_EMAIL_ADDRESS { get { return 'BAPPOrgWideEmailAddress'; } }

    private static final string LEAD_BOOKING_STATUS_OPPORTUNITY_CREATED { get { return 'Opportunity Created'; } }
    
    @AuraEnabled
    public static String vaidateLead(Id leadId){
        String jsonData;
        LeadConvertWrapper obj = new LeadConvertWrapper();
        try{
            Id individualLeadRecordTypeId = Utility.getRecordTypeIdByDevName(Lead.SObjectType, LEAD_RT_DEV_NAME_INDIVIDUAL_LEAD);
            Id organizationLeadRecordTypeId = Utility.getRecordTypeIdByDevName(Lead.SObjectType, LEAD_RT_DEV_NAME_ORGANIZATION_LEAD);
            LeadService objLeadService = LeadService.getInstance();
            Lead objLead = objLeadService.getLeadById(leadId);
            obj.objLead = objLead;
            obj.isIndividualLead =  (objLead.RecordTypeId == individualLeadRecordTypeId);
            obj.hasDuplicateAccount = false;
            obj.isEligibleToConvert = false;
            List<String> missingFields = validateLeadBeforeConvert(objLead, individualLeadRecordTypeId, organizationLeadRecordTypeId);
            obj.message = LEAD_MANDATORY_FIELD_MESSAGE;
            obj.missingFields = missingFields;
            if(missingFields != NULL && !missingFields.isEmpty()){
                return JSON.serialize(obj);
            }
            obj.objAccount = getDuplicateAccount(objLead, individualLeadRecordTypeId, organizationLeadRecordTypeId);
            if(obj.objAccount != NULL){
                obj.hasDuplicateAccount = true;
                obj.message = 'An existing account found with the selected details, do you want to proceed with the existing account?';
                return JSON.serialize(obj);
            }
            obj.isEligibleToConvert = true;
        }catch(System.exception ex){
            throw new AuraHandledException('Error: '+ ex.getMessage());   
        }
        jsonData = JSON.serialize(obj);
        return jsonData;
    }
    
    private static List<String> validateLeadBeforeConvert(Lead objLead, Id individualLeadRecordTypeId, Id organizationLeadRecordTypeId){
        List<String> missingFields = new List<String>();
        if(objLead.RecordTypeId == individualLeadRecordTypeId){
            if(String.isBlank(objLead.Salutation)){
                missingFields.add('Salutation');
            }
            if(String.isBlank(objLead.FirstName)){
                missingFields.add('First Name');
            }
            if(String.isBlank(objLead.LastName)){
                missingFields.add('Last Name');
            }
            if(String.isBlank(objLead.Email)){
                missingFields.add('Email');
            }
            if(String.isBlank(objLead.NameArabic__c)){
                missingFields.add('Arabic Name');
            }
            if(String.isBlank(objLead.MaritalStatus__c)  && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Marital Status');
            }
            if(String.isBlank(objLead.nationality__c)){
                missingFields.add('Nationality');
            }
            if(String.isBlank(objLead.ResidentStatus__c)){
                missingFields.add('Resident Status');
            }
            if(objLead.Birthdate__c == NULL){
                missingFields.add('Birthdate');
            }
            if(String.isBlank(objLead.CustomerType__c)){
                missingFields.add('Customer Type');
            }
            if(String.isBlank(objLead.CustomerSubType__c)){
                missingFields.add('Customer Sub Type');
            }
            if(String.isBlank(objLead.Project__c)){
                missingFields.add('Project');
            }
            if(String.isBlank(objLead.PropertyUsage__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Property Usage');
            }
            if(String.isBlank(objLead.BuyRent__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Buy Rent');
            }
            if(String.isBlank(objLead.UnitType__c)){
                missingFields.add('Unit Type');
            }
            if(objLead.LeadTeam__c == 'Sales' && String.isBlank(objLead.CustomerBudget__c)){
                missingFields.add('Customer Budget');
            }
            if(objLead.LeadTeam__c == 'Leasing' && (objLead.BudgetRangeFrom__c == null || objLead.BudgetRangeTo__c == null)){
                missingFields.add('Budget Range');
            }
            if(String.isBlank(objLead.AreaSqmt__c)){
                missingFields.add('Area Sqmt');
            }
            if(String.isBlank(objLead.NumberOfBedrooms__c)){
                missingFields.add('Number of Bedrooms');
            }
            if(String.isBlank(objLead.PropertyReadiness__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Property Readiness');
            }
            if(String.isBlank(objLead.Street) && (objLead.LeadTeam__c == 'Sales' || objLead.LeadTeam__c == 'Leasing')){
                missingFields.add('Address - Street');
            }
            if(String.isBlank(objLead.City) && (objLead.LeadTeam__c == 'Sales' || objLead.LeadTeam__c == 'Leasing')){
                missingFields.add('Address - City');
            }
            if(String.isBlank(objLead.State) && (objLead.LeadTeam__c == 'Sales' || objLead.LeadTeam__c == 'Leasing')){
                missingFields.add('Address - State');
            }
            if(String.isBlank(objLead.PostalCode) && (objLead.LeadTeam__c == 'Sales' || objLead.LeadTeam__c == 'Leasing')){
                missingFields.add('Address - Postal Code');
            }
            //-- added KYC fields
            if(String.isBlank(objLead.EmploymentStatus__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Employment Status');
            }
            if(String.isBlank(objLead.CompanyIndustry__c) && objLead.LeadTeam__c == 'Sales' && objLead.EmploymentStatus__c != 'Retired'){
                missingFields.add('Company Industry');
            }
            if(String.isBlank(objLead.YearsOfEmployment__c) && objLead.LeadTeam__c == 'Sales' && objLead.EmploymentStatus__c != 'Retired'){
                missingFields.add('Years of Employment');
            }
            if(String.isBlank(objLead.CompanyEmirates__c) && objLead.LeadTeam__c == 'Sales' && objLead.EmploymentStatus__c != 'Retired'){
                missingFields.add('Company Emirates');
            }
            if(String.isBlank(objLead.CompanyName__c) && objLead.LeadTeam__c == 'Sales' && objLead.EmploymentStatus__c != 'Retired'){
                missingFields.add('Company Name');
            }
            if(String.isBlank(objLead.Position__c) && objLead.LeadTeam__c == 'Sales' && objLead.EmploymentStatus__c != 'Retired'){
                missingFields.add('Position');
            }
            if(objLead.AnnualIncome__c == null && objLead.LeadTeam__c == 'Sales'  && objLead.EmploymentStatus__c != 'Retired'){
                missingFields.add('Annual Income');
            }
            if(String.isBlank(objLead.SourceOfFunds__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Source of Funds');
            }
            if(String.isBlank(objLead.Emirates_Id__c) && (objLead.CustomerType__c == LEAD_CUSTOMER_TYPE_RESIDENT || objLead.CustomerType__c == LEAD_CUSTOMER_TYPE_UAE_NATIONAL)){
                missingFields.add('Emirates ID');
            }
            if(String.isBlank(objLead.Passport_Number__c) && (objLead.CustomerType__c == LEAD_CUSTOMER_TYPE_INTERNATIONAL || objLead.CustomerType__c == LEAD_CUSTOMER_TYPE_GCC)){
                missingFields.add('Passport Details');
            }
            if(String.isBlank(objLead.nationality__c) && (objLead.CustomerType__c == LEAD_CUSTOMER_TYPE_INTERNATIONAL || objLead.CustomerType__c == LEAD_CUSTOMER_TYPE_GCC)){
                missingFields.add('Nationality');
            }
            if(String.isNotBlank(objLead.BrokerAgency__c) && String.isBlank(objLead.BrokerAgent__c)){
                missingFields.add('Broker Agent');
            }
            if(String.isBlank(objLead.CompanyName__c) && objLead.LeadTeam__c == 'Leasing'){
                missingFields.add('Company Name');
            }
            if(String.isBlank(objLead.Position__c) && objLead.LeadTeam__c == 'Leasing'){
                missingFields.add('Position');
            }
            if(objLead.AnnualIncome__c == null && objLead.LeadTeam__c == 'Leasing'){
                missingFields.add('Annual Income');
            }
            if(objLead.Project__c == 'Bloom Living'){
                missingFields.add('Please select correct project name');
            }
            if(String.isBlank(objLead.LeasingDocumentsReceived__c) && objLead.LeadTeam__c == 'Leasing'){
                missingFields.add('Documents Received');
            }
            if(String.isBlank(objLead.BPType__c) && objLead.LeadTeam__c == 'Leasing'){
                missingFields.add('BP Type');
            }
            if(!String.isBlank(objLead.Emirates_Id__c) && objLead.EmiratesIDExpiryDate__c == NULL ){
                missingFields.add('Emirates ID Expiry Date');
            }
            if(!String.isBlank(objLead.Emirates_Id__c) && objLead.EmiratesIDIssueDate__c == NULL ){
                missingFields.add('Emirates ID Issue Date');
            }
            if(!String.isBlank(objLead.Passport_Number__c ) && objLead.PassportExpiryDate__c == NULL ){
                missingFields.add('Passport Expiry Date');
            }
            if(!String.isBlank(objLead.Passport_Number__c ) && objLead.PassportIssueDate__c == NULL ){
                missingFields.add('Passport Issue Date');
            }
            if(!String.isBlank(objLead.ApplicationNumber__c ) && objLead.Unit__c == NULL){
                missingFields.add('Unit');
            }
            if(!String.isBlank(objLead.ApplicationNumber__c) && String.isBlank(objLead.AlternateContactName__c)){
                missingFields.add('Alternate Contact Name');
            }
            if(!String.isBlank(objLead.ApplicationNumber__c) && String.isBlank(objLead.AlternateContactNumber__c)){
                missingFields.add('Alternate Contact Number');
            }
            if(!String.isBlank(objLead.ApplicationNumber__c) && String.isBlank(objLead.AlternateContactRelationship__c)){
                missingFields.add('Alternate Contact Relationship');
            }
        }else if(objLead.RecordTypeId == organizationLeadRecordTypeId){
            if(String.isBlank(objLead.FirstName)){
                missingFields.add('Representative First Name');
            }
            if(String.isBlank(objLead.TaxRegistrationNumber__c )){
                missingFields.add('Tax Registration Number');
            }
            if(String.isBlank(objLead.LastName)){
                missingFields.add('Representative Last Name');
            }
            if(String.isBlank(objLead.nationality__c)){
                missingFields.add('Nationality');
            }
            if(String.isBlank(objLead.Email)){
                missingFields.add('Email');
            }
            if(String.isBlank(objLead.NameArabic__c)){
                missingFields.add('Arabic Name');
            }
            if(String.isBlank(objLead.CustomerType__c)){
                missingFields.add('Customer Type');
            }
            if(String.isBlank(objLead.CustomerSubType__c)){
                missingFields.add('Customer Sub Type');
            }
            if(String.isBlank(objLead.Project__c)){
                missingFields.add('Project');
            }
            if(String.isBlank(objLead.PropertyUsage__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Property Usage');
            }
            if(String.isBlank(objLead.BuyRent__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Buy Rent');
            }
            if(String.isBlank(objLead.UnitType__c)){
                missingFields.add('Unit Type');
            }
            if(objLead.LeadTeam__c == 'Sales' && String.isBlank(objLead.CustomerBudget__c)){
                missingFields.add('Customer Budget');
            }
            if(objLead.LeadTeam__c == 'Leasing' && (objLead.BudgetRangeFrom__c == null || objLead.BudgetRangeTo__c == null)){
                missingFields.add('Budget Range');
            }
            if(String.isBlank(objLead.AreaSqmt__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Area Sqmt');
            }
            if(String.isBlank(objLead.NumberOfBedrooms__c)){
                missingFields.add('Number of Bedrooms');
            }
            if(String.isBlank(objLead.PropertyReadiness__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Property Readiness');
            }
            if(String.isBlank(objLead.Street) && (objLead.LeadTeam__c == 'Sales' || objLead.LeadTeam__c == 'Leasing')){
                missingFields.add('Address - Street');
            }
            if(String.isBlank(objLead.City) && (objLead.LeadTeam__c == 'Sales' || objLead.LeadTeam__c == 'Leasing')){
                missingFields.add('Address - City');
            }
            if(String.isBlank(objLead.State) && (objLead.LeadTeam__c == 'Sales' || objLead.LeadTeam__c == 'Leasing')){
                missingFields.add('Address - State');
            }
            if(String.isBlank(objLead.PostalCode) && (objLead.LeadTeam__c == 'Sales'|| objLead.LeadTeam__c == 'Leasing')){
                missingFields.add('Address - Postal Code');
            }
            if(String.isBlank(objLead.TradeLicenseNumber__c)){
                missingFields.add('TradeLicense Number');
            }
            if(objLead.TradeLicenseExpiryDate__c == NULL){
                missingFields.add('Trade License Expiry Date');
            }
            if(objLead.TradeLicenseIssueDate__c == NULL){
                missingFields.add('Trade License Issue Date');
            }
            if(String.isBlank(objLead.RegistrationAuthority__c)){
                missingFields.add('Registration Authority');
            }
            if(String.isNotBlank(objLead.BrokerAgency__c) && String.isBlank(objLead.BrokerAgent__c)){
                missingFields.add('Broker Agent');
            }
            if(String.isBlank(objLead.BPType__c) && objLead.LeadTeam__c == 'Leasing'){
                missingFields.add('BP Type');
            }
            //--- added KYC fields
            if(String.isBlank(objLead.EmploymentStatus__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Employment Status');
            }
            if(String.isBlank(objLead.CompanyIndustry__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Company Industry');
            }
            if(String.isBlank(objLead.YearsOfEmployment__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Years of Employment');
            }
            if(String.isBlank(objLead.CompanyEmirates__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Company Emirates');
            }
            if(String.isBlank(objLead.CompanyName__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Company Name');
            }
            if(String.isBlank(objLead.Position__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Position');
            }
            if(objLead.AnnualIncome__c == null && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Annual Income');
            }
            if(String.isBlank(objLead.SourceOfFunds__c) && objLead.LeadTeam__c == 'Sales'){
                missingFields.add('Source of Funds');
            }
            //---------
            
        }
        return missingFields;
    }
    @TestVisible
    private static Account getDuplicateAccount(Lead objLead, Id individualLeadRecordTypeId, Id organizationLeadRecordTypeId){
        Account objAccount;
        AccountService objAccountService = AccountService.getInstance();
        List<Account> accountList = new List<Account>();
        if(objLead.RecordTypeId == individualLeadRecordTypeId ){
            accountList = objAccountService.getDuplicatePersonAccounts(objLead.Emirates_Id__c, objLead.Passport_Number__c, objLead.nationality__c);
        }else if(objLead.RecordTypeId == organizationLeadRecordTypeId){
            accountList = objAccountService.getDuplicateOrganizationAccounts(objLead.TradeLicenseNumber__c, objLead.RegistrationAuthority__c);
        }
        objAccount = !accountList.isEmpty() ? accountList[0] : null;
        return objAccount;
    }
    
    private static void updateOrganizationAccount(Boolean isExistingAccount, Lead objLead, Id accountId){
        AccountService objAccountService = AccountService.getInstance();
        if(!isExistingAccount){
            Account objAccount = new Account(Id = accountId);
            objAccount.RecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
            objAccount.Name = objLead.Company;
            objAccount.PhoneCountryCode__c = objLead.PhoneCountryCode__c;
            objAccount.Phone__c = objLead.PhoneNumber__c;
            objAccount.TaxRegistrationNumber__c = objLead.TaxRegistrationNumber__c;
            objAccount.IsSales__c = (objLead.LeadTeam__c == 'Sales');
            objAccount.IsLeasing__c = (objLead.LeadTeam__c == 'Leasing');
            objAccount.BillingCity = objLead.City;
            objAccount.BillingCountry = objLead.Country;
            objAccount.BillingCountryCode = objLead.CountryCode;
            objAccount.BillingLatitude = objLead.Latitude;
            objAccount.BillingLongitude = objLead.Longitude;
            objAccount.BillingPostalCode = objLead.PostalCode;
            objAccount.BillingState = objLead.State;
            objAccount.BillingStateCode = objLead.StateCode;
            objAccount.Trade_License_No__c = objLead.TradeLicenseNumber__c ;
            objAccount.Trade_License_Expiry_Date__c = objLead.TradeLicenseExpiryDate__c ;
            objAccount.Trade_License_Issue_Date__c = objLead.TradeLicenseIssueDate__c ;
            objAccount.BillingStreet = objLead.Street;
            objAccountService.updateAccountWithoutDuplicateRule(objAccount);
        }
    }
    
    private static void updatePersonAccount(Boolean isExistingAccount, Lead objLead, Id accountId){
        AccountService objAccountService = AccountService.getInstance();
        Account objAccount = new Account(Id = accountId);
        if(!isExistingAccount){
            objAccount.PersonMailingCity = objLead.City;
            objAccount.PersonMailingCountry = objLead.Country;
            objAccount.PersonMailingCountryCode = objLead.CountryCode;
            objAccount.PersonMailingLatitude = objLead.Latitude;
            objAccount.PersonMailingLongitude = objLead.Longitude;
            objAccount.PersonMailingPostalCode = objLead.PostalCode;
            objAccount.PersonMailingState = objLead.State;
            objAccount.PersonMailingStateCode = objLead.StateCode;
            objAccount.PersonMailingStreet = objLead.Street;
            objAccount.PersonGenderIdentity = objLead.GenderIdentity;
            objAccount.PersonBirthdate = objLead.Birthdate__c;
            objAccount.PrimaryMobileCountryCode__pc = objLead.MobileCountryCode__c;
            objAccount.PrimaryMobilePhone__pc = objLead.MobilePhoneNumber__c;
            objAccount.PassportNumber__pc = objLead.Passport_Number__c ;
            objAccount.PassportExpiryDate__pc = objLead.PassportExpiryDate__c ;
            objAccount.PassportIssueDate__pc = objLead.PassportIssueDate__c ;
            objAccount.Emirates_Id__pc = objLead.Emirates_Id__c ;
            objAccount.EID_Issue_Date__pc = objLead.EmiratesIDIssueDate__c ;
            objAccount.EID_Expiry_Date__pc = objLead.EmiratesIDExpiryDate__c ;
        }
        if(objLead.LeadTeam__c == 'Sales'){
            objAccount.IsSales__c = true;
        }
        else if(objLead.LeadTeam__c == 'Leasing'){
            objAccount.IsLeasing__c = true;
        }
        objAccountService.updateAccountWithoutDuplicateRule(objAccount);
    }
    
    private static void updateOrganizationContact(Boolean isExistingAccount, Lead objLead, Id contactId){
        ContactService objContactService = ContactService.getInstance();
        Contact con = new Contact(Id = contactId);
        if(!isExistingAccount){
            con.FirstName = objLead.FirstName;
            con.LastName = objLead.LastName;
            con.Email = objLead.Email;
            con.PassportNumber__c = objLead.Passport_Number__c;
            con.Emirates_Id__c = objLead.Emirates_Id__c;
            con.EID_Expiry_Date__c = objLead.EmiratesIDExpiryDate__c;
            con.PrimaryMobileCountryCode__c = objLead.MobileCountryCode__c;
            con.PrimaryMobilePhone__c = objLead.MobilePhoneNumber__c;
        }
        con.PrimaryContact__c = true ; 
        objContactService.updateContactWithoutTrigger(con);
    }
    
    private static void updateOpportunity(Lead objLead, Id contactId, Id OpportunityId){
        Id individualLeadRecordTypeId = Utility.getRecordTypeIdByDevName(Lead.SObjectType, LEAD_RT_DEV_NAME_INDIVIDUAL_LEAD);
        OpportunityService objOpportunityService = OpportunityService.getInstance();
        Opportunity opp = new Opportunity(Id = OpportunityId);
        if(objLead.RecordTypeId != individualLeadRecordTypeId){
            opp.Contact__c = contactId;
        }
        if(objLead.IsConverted == true && objLead.ConvertedOpportunityId != null){
            opp.Lead_CC_Description__c = objLead.Description != null ? objLead.Description : '';
        }
        opp.OpportunityType__c = objLead.LeadTeam__c;
        opp.AgentType__c = (objLead.LeadSource == LEAD_SOURCE_BROKER) ? OPPORTUNITY_AGENT_TYPE_INDIRECT : OPPORTUNITY_AGENT_TYPE_DIRECT;
        opp.Lead__c = objLead.Id;
        opp.StageName = 'Assigned';
        opp.OpportunityType__c = objLead.LeadTeam__c;
        opp.LoanAmount__c = objLead.LoanAmount__c;
        objOpportunityService.updateOpportunityWithoutTrigger(opp);
        //Send Leasing Email to Customer if the opp type is Leasing 
        if(opp.OpportunityType__c == 'Leasing' && objLead.LeasingDocumentsReceived__c == 'No'){
            sendDocUploadLinkToCustomer(opp.Id);
        } 
    }
    
    private static void updateTask(Lead objLeadRec){
        Set<Id> setLeadIds = new Set<Id>();
        List<Task> taskList = new List<Task>();
        List<Task> taskUpdateList = new List<Task>();
        LeadService objLeadService = LeadService.getInstance();
        ActivityService objActivityService = ActivityService.getInstance();
        
        List<Lead> leadWithTaskList = objLeadService.getLeadWithOpenActivity(new Set<Id>{objLeadRec.Id});
        
        for(Lead objLead : leadWithTaskList){
            if((objLead.IsConverted && objLead.ConvertedOpportunityId != null)){
                for(Task objTask : objLead.Tasks){
                    if(objTask != null){
                        objTask.Description = 'Completed Task';
                        objTask.Status = 'Completed';
                        taskUpdateList.add(objTask);
                    } 
                }
            }
        }
        objActivityService.updateTasks(taskUpdateList);
    }

    private static void updateLeadBookingStatus(Lead objLead){
        if(String.isNotBlank(objLead.ApplicationNumber__c)){
            LeadService objLeadService = LeadService.getInstance();
            Lead leadToUpdate = new Lead(Id = objLead.Id, BookingStatus__c = LEAD_BOOKING_STATUS_OPPORTUNITY_CREATED);
            objLeadService.updateLeadWithoutTrigger(leadToUpdate);
        }
    }

    private static void updateUnitBlockedForCustomer(Lead objLead, Id accountId){
        if(objLead.Unit__c != null && accountId != null){
            UnitService objUnitService = UnitService.getInstance();
            Unit__c unitToUpdate = new Unit__c(Id = objLead.Unit__c, BlockedForCustomer__c = accountId);
            objUnitService.updateUnitWithoutTrigger(unitToUpdate);
        }
    }

    @AuraEnabled
    public static String convertLead(Id leadId, Id accountId){
        String jsonData;
        Boolean isExistingAccount = false;
        LeadConvertWrapper obj = new LeadConvertWrapper();
        Savepoint sp = Database.setSavePoint();
        try{
            Id individualLeadRecordTypeId = Utility.getRecordTypeIdByDevName(Lead.SObjectType, LEAD_RT_DEV_NAME_INDIVIDUAL_LEAD);
            Id organizationLeadRecordTypeId = Utility.getRecordTypeIdByDevName(Lead.SObjectType, LEAD_RT_DEV_NAME_ORGANIZATION_LEAD);
            
            LeadService objLeadService = LeadService.getInstance();
            Lead objLead = objLeadService.getLeadById(leadId);
            
            Database.LeadConvert lc = new Database.LeadConvert();
            if(String.isNotBlank(accountId)){
                lc.setAccountId(accountId);
                isExistingAccount = true;
            }
            lc.setLeadId(leadId);
            lc.setConvertedStatus('Converted');
            if(objLead.RecordTypeId == individualLeadRecordTypeId){
                lc.setOpportunityName(objLead.Name + '-' + System.now().format('dd-MMM-yyyy'));
            }else{
                lc.setOpportunityName(objLead.Company + '-' + System.now().format('dd-MMM-yyyy'));
            }
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            
            if(lcr.isSuccess()){
                if(objLead.RecordTypeId == organizationLeadRecordTypeId){
                    updateOrganizationAccount(isExistingAccount, objLead, lcr.getAccountId());
                    updateOrganizationContact(isExistingAccount, objLead, lcr.getContactId());
                }else{
                    updatePersonAccount(isExistingAccount, objLead, lcr.getAccountId());
                }
                updateOpportunity(objLead, lcr.getContactId(), lcr.getOpportunityId());
                updateTask(objLead);
                updateLeadBookingStatus(objLead);
                updateUnitBlockedForCustomer(objLead, lcr.getAccountId());
                obj.message = 'Lead was converted successfully.';
                obj.opportunityId = lcr.getOpportunityId();
                sendEmailToLeadOwner(objLead, obj.opportunityId);
                // BAPP Send email to Broker Agent
                if (objLead.BrokerAgency__c != null && objLead.BrokerAgent__c != null && objLead.LeadTeam__c == 'Sales' && objLead.lead_channel__c == 'Broker Portal') {
                    sendEmailToBrokerAgent(objLead, obj.opportunityId);
                }
            }else{
                string errorMessage;
                for(Database.Error error :lcr.getErrors()){
                    errorMessage += error.getMessage();
                }
                obj.message = errorMessage;
            }
        }catch(System.exception ex){
            Database.rollback(sp);
            throw new AuraHandledException('Error: '+ ex.getMessage());   
        }
        jsonData = JSON.serialize(obj);
        return jsonData;
    }
    
    private static void sendEmailToLeadOwner(Lead objLead, Id opportunityId){
        
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        Id leadConvertEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_LEAD_CONVERT_EMAIL_TEMPLATE_ID);
        Id noReplySalesITOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_SALES_IT_ID);
        
        if(String.isNotBlank(objLead.OwnerId) && objLead.Owner.Email != NULL){
            emailList.add(objEmailService.getSingleEmailMessageWithoutTargetObjectAsRecipient(new List<String>{objLead.Owner.Email}, leadConvertEmailTemplateId, opportunityId, objLead.Id, noReplySalesITOWDId)); 
            objEmailService.sendEmail(emailList);
        } 
    }
    
    //Send Leasing document upload Link 
    @testVisible
    private static void sendDocUploadLinkToCustomer(Id opportunityId) {
        EmailTemplate tmpl = EmailTemplateService.getEmailTemplateByDeveloperName('LeasingDocumentsUpload');
        MetadataService objMetadataService = MetadataService.getInstance();
        Id noReplyBloomLeasingOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID);
        Opportunity opp =  OpportunityService.getInstance().getOpportunityById(opportunityId);
        Map<Id, Contact> primaryByAcct = new Map<Id, Contact>();
        if (!opp.Account.IsPersonAccount) {
            for (Contact c : ContactService.getInstance().getPrimaryContactByAccountId(opp.AccountId,True)) {
                if (!primaryByAcct.containsKey(c.AccountId)) {
                    primaryByAcct.put(c.AccountId, c);
                }
            }
        }
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        String documentUploadUrlInstnace =  objMetadataService.getAppSettingTextValue('LeasingDocumentUploadLinkURL');
        
        String toAddr = opp.Account.IsPersonAccount ? opp.Account.PersonEmail : primaryByAcct?.get(opp.AccountId)?.Email ;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        String uploadUrl = documentUploadUrlInstnace+opp.id;           
        String hyperlink = '<a href=\' ' + uploadUrl + '  \' target=\'_blank\'>Click here to upload documents</a>';
        mail = EmailService.getInstance().getSingleEmailMessage(new String[]{toAddr} ,
                                                                tmpl.Subject,
                                                                tmpl.HtmlValue.replace('uploadhere', hyperlink),
                                                                noReplyBloomLeasingOWDId);
        mail.setSaveAsActivity(true);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setWhatId(opportunityId);
        mails.add(mail);
        EmailService.getInstance().sendEmail(mails);        
    }
    
    private class LeadConvertWrapper{
        private Lead objLead {get;set;}
        private Account objAccount {get;set;}
        private String message {get;set;}
        private List<String> missingFields {get;set;}
        private Id opportunityId {get;set;}
        private Boolean hasDuplicateAccount {get;set;}
        private Boolean isIndividualLead {get;set;}
        private Boolean isEligibleToConvert {get;set;}
    }
    
    // BAPP Send email to Broker Agent
    private static void sendEmailToBrokerAgent(Lead objLead, Id opportunityId) {
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        Id brokerAgentEmailTemplateId = objMetadataService.getAppSettingTextValue(BAPP_BROKER_AGENT_CONVERT_EMAIL_TEMPLATE);
        Id noReplyBloomHolding = objMetadataService.getAppSettingTextValue(BAPP_ORG_WIDE_EMAIL_ADDRESS);
        Contact brokerAgent = ContactService.getInstance().getContactById(objLead.BrokerAgent__c);
        
        if (brokerAgent != null && String.isNotBlank(brokerAgent.Email)) {
            Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(
                brokerAgentEmailTemplateId,     
                noReplyBloomHolding,            
                opportunityId,                     
                brokerAgent.Id,                  
                null,                            
                null,                            
                null                             
            );
            
            emailList.add(email);
            objEmailService.sendEmail(emailList);
        }
    }
}