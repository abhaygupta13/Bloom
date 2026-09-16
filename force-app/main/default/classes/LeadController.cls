/*****************************************************************************************
Class       : LeadController
Author      : Biswajeet
Description : Lead controller class
Created Date: 29 AUG 2024
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0             29AUG2024           Initial Version 
*****************************************************************************************/
public class LeadController {
    
    private static final string LEAD_RT_DEV_NAME_INDIVIDUAL_LEAD { get { return 'IndividualLead'; } }
    private static final string LEAD_RT_DEV_NAME_ORGANIZATION_LEAD { get { return 'OrganizationLead'; } }
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } }
    private static final string LEAD_STATUS_WORKING { get { return 'In Progress'; } }
    private static final string DIGITAL_LEAD_CREATED_BY_Profile_IDS { get { return 'DigitalLeadCreatedByProfileIds'; } }  
    private static final string LEASING_LEAD_PROFILE_ID { get { return 'LeasingLeadProfileIds'; } }
    
    @AuraEnabled
    public static String createLeadFromAccount(Id accountId){
        String jsonData;
        LeadService leadService = LeadService.getInstance();
        AccountService accService = AccountService.getInstance();
        ContactService ConService = ContactService.getInstance();
        Savepoint sp = Database.setSavePoint();
        try{
            if(String.isNotBlank(accountId)){
                Account objAcc = accService.getAccountById(accountId);
                if(objAcc != NULL){
                    Lead objLead = new Lead();
                    if(objAcc.RecordTypeID == Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT)){
                        objLead.RecordTypeId  = Utility.getRecordTypeIdByDevName(Lead.SObjectType, LEAD_RT_DEV_NAME_INDIVIDUAL_LEAD);
                        objLead.Salutation = objAcc.Salutation;
                        objLead.FirstName = objAcc.FirstName;
                        objLead.MiddleName = objAcc.MiddleName;
                        objLead.LastName = objAcc.LastName;
                        objLead.nationality__c = objAcc.Nationality__c;                          
                        objLead.NameArabic__c = objAcc.NameinArabic__c;
                        objLead.City = objAcc.PersonMailingCity;
                        objLead.Country = objAcc.PersonMailingCountry;
                        objLead.CountryCode = objAcc.PersonMailingCountryCode;
                        objLead.Latitude = objAcc.PersonMailingLatitude;
                        objLead.Longitude = objAcc.PersonMailingLongitude;
                        objLead.PostalCode = objAcc.PersonMailingPostalCode;
                        objLead.State = objAcc.PersonMailingState;
                        objLead.StateCode = objAcc.PersonMailingStateCode;
                        objLead.Street = objAcc.PersonMailingStreet;
                        objLead.Birthdate__c  = objAcc.PersonBirthdate;
                        objLead.GenderIdentity = objAcc.PersonGenderIdentity;
                        objLead.RegistrationAuthority__c = objAcc.Registration_Authority__pc;
                        objLead.countryofresidence__c = objAcc.CountryOfResidence__pc;
                        objLead.Emirates_Id__c = objAcc.Emirates_Id__pc;
                        objLead.EmiratesIDExpiryDate__c = objAcc.EID_Expiry_Date__pc;
                        objLead.EmiratesIDIssueDate__c = objAcc.EID_Issue_Date__pc;
                        objLead.EmploymentStatus__c = objAcc.EmploymentStatus__pc;
                        objLead.LanguagePreference__c = objAcc.LanguagePreference__pc;
                        objLead.MobileCountryCode__c = objAcc.MobileCountryCode__pc;
                        objLead.PassportExpiryDate__c = objAcc.PassportExpiryDate__pc;
                        objLead.PassportIssueDate__c = objAcc.PassportIssueDate__pc;
                        objLead.Passport_Number__c = objAcc.PassportNumber__pc;
                        objLead.PlaceOfIssue__c = objAcc.PlaceofIssue__pc; 
                        objLead.Position__c = objAcc.Position__pc;
                        objLead.Religion__c = objAcc.Religion__pc;
                        objLead.ResidentStatus__c = objAcc.ResidentStatus__pc;
                        objLead.ExistingAccount__c = accountId;
                        objLead.MobilePhone = objAcc.PersonMobilePhone ;
                        objLead.Email = objAcc.PersonEmail ;
                        objLead.Rating = objAcc.Rating ;
                        objLead.CustomerType__c = objAcc.CustomerType__c ;
                        objLead.IsCreatedFromAccount__c = true;
                        objLead.Gender__c = objAcc.Gender__pc ;
                        objLead.GenderIdentity = objAcc.PersonGenderIdentity ;
                        objLead.AnnualIncome__c = objAcc.AnnualIncome__pc ;
                        objLead.SourceOfFunds__c = objAcc.SourceofFunds__pc ;
                        objLead.POAExist__c = objAcc.PoaExist__c ;
                        objLead.LeadSource = NULL;
                        objLead.leadsubsource__c = NULL;
                        objLead.lead_channel__c = NULL;
                        objLead.Project__c = NULL;
                        objLead.BuyRent__c = NULL;
                        objLead.PropertyUsage__c = NULL;
                    }
                    else if(objAcc.RecordTypeID== Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT)){
                        List<Contact> conList = ConService.getContactByAccountId(objAcc.id);
                        
                        if(conList != NULL && !conList.isEmpty()){
                            objLead.FirstName = conList[0].FirstName;
                            objLead.MiddleName = conList[0].MiddleName;
                            objLead.LastName = conList[0].LastName;
                            objLead.Email = conList[0].Email;
                            objLead.Passport_Number__c =  conList[0].PassportNumber__c;
                            objLead.Emirates_Id__c = conList[0].Emirates_Id__c;
                            objLead.EmiratesIDExpiryDate__c =  conList[0].EID_Expiry_Date__c;
                        }else{
                            objLead.LastName = objAcc.Name ;
                        }
                        objLead.RecordTypeId  = Utility.getRecordTypeIdByDevName(Lead.SObjectType,LEAD_RT_DEV_NAME_ORGANIZATION_LEAD);
                        objLead.NameArabic__c = objAcc.NameinArabic__c ;
                        objLead.Company = objAcc.Name ;
                        objLead.Phone = objAcc.Phone;
                        
                        objLead.nationality__c = objAcc.Nationality__c;
                        objLead.RegistrationAuthority__c = objAcc.Registration_Authority__c;
                        objLead.TradeLicenseExpiryDate__c = objAcc.Trade_License_Expiry_Date__c;
                        objLead.TradeLicenseIssueDate__c = objAcc.Trade_License_Issue_Date__c;
                        objLead.TradeLicenseNumber__c = objAcc.Trade_License_No__c;
                        
                        objLead.PercentageOfSharePurchased__c = objAcc.Percentage_Of_Share_Purchased__c;
                        objLead.PercentageOfSharePurchased__c = objAcc.Percentage_of_Share_Purchased__c;
                        objLead.PlaceOfIssuance__c = objAcc.Place_of_Issuance__c;
                        objLead.PlaceOfRegistration__c = objAcc.PlaceofRegistration__c;
                        objLead.POAExist__c = objAcc.PoaExist__c;
                        
                        objLead.Bloom_Staff_Email__c = objAcc.BloomStaffEmail__c;
                        objLead.CompanyEmail__c = objAcc.CompanyEmail__c;
                        objLead.CustomerClassification__c = objAcc.CustomerClassification__c;
                        objLead.CustomerSubType__c = objAcc.CustomerSubType__c;
                        objLead.IsCreatedFromAccount__c = true;
                        objLead.MobileCountryCode__c = objAcc.MobileCountryCode__c;
                        objLead.ExistingAccount__c = accountId;
                        objLead.LeadSource = NULL;
                        objLead.leadsubsource__c = NULL;
                        objLead.lead_channel__c = NULL;
                        objLead.Project__c = NULL;
                        objLead.BuyRent__c = NULL;
                        objLead.PropertyUsage__c = NULL;
                    }
                    Database.SaveResult sr = leadService.insertLeadWithoutDuplicateRule(objLead);
                    if(sr.isSuccess()){
                        return sr.getId();
                    }
                }
            }
        }catch(System.exception ex){
            Database.rollback(sp);
            throw new AuraHandledException('Error: '+ ex.getMessage());
        }
        return jsonData;
    }
    
    @AuraEnabled
    public static String validateBeforeLeadCreation(Id accountId){
        AccountService accService = AccountService.getInstance();
        Account objAcc = accService.getAccountById(accountId);
        String msg;
        if(objAcc.RecordTypeId == Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT)){
            if(objAcc.PassportExpiryDate__pc != NULL && objAcc.PassportExpiryDate__pc < System.today()){
                msg = 'Passport has been expired, please update it to create a Lead';
            }else if(objAcc.EID_Expiry_Date__pc != NULL && objAcc.EID_Expiry_Date__pc < System.today()){
                msg = 'Emirates ID has been expired, please update it to create a Lead';
            }
        }
        return msg;
    }
    
    @AuraEnabled
    public static void handleLeadUnHold(Id leadId){
        try{
            Lead objLead = new Lead(Id = leadId, Status = LEAD_STATUS_WORKING, IsOnHold__c = false, LastUnholdDate__c = System.now());
            LeadService objLeadService = LeadService.getInstance();
            objLeadService.updateLeadWithoutTrigger(objLead);
            
        }catch(System.exception ex){
            throw new AuraHandledException('Error: '+ ex.getMessage());   
        }
    }
    
    @AuraEnabled
    public static Map<String,String> getSalutation(){
        return Utility.getPicklistValues(Lead.SObjectType, 'Salutation');
    }
    
    @AuraEnabled
    public static Map<String,String> getNationality(){
        return Utility.getPicklistValues(Lead.SObjectType, 'nationality__c');
    }
    
    @AuraEnabled
    public static Map<String,String> getMobileCountryCode(){
        return Utility.getPicklistValues(Lead.SObjectType, 'MobileCountryCode__c');
    }
    
    @AuraEnabled
    public static Map<String,String> getMaritalStatus(){
        return Utility.getPicklistValues(Lead.SObjectType, 'MaritalStatus__c');
    }
    
    @AuraEnabled
    public static Map<String,String> getGenderIdentity(){
        return Utility.getPicklistValues(Lead.SObjectType, 'GenderIdentity');
    }
    
    @AuraEnabled
    public static Id createLeadFromEID(String saluation, String firstName, String middleName, String lastName, String fullNameInArabic,
                                       Date birthdate, String gender, String maritalStatus, String mobileCountryCode, String mobile, String email,
                                       String nationality, String passport, Date passportExpiryDate, String placeOfIssue, String eid, Date eidExpiryDate){
                                           Id leadId;
                                           //MetadataService objMetadataService = ;
                                           //String leasingLeadProfileIds = ;
                                           
                                           List<Id> leasingLeadProfileIdsList = MetadataService.getInstance().getAppSettingTextValue(LEASING_LEAD_PROFILE_ID).split(',');
                                           //Id currentUserId = UserInfo.getUserId();                         
                                           
                                           
                                           Savepoint sp = Database.setSavePoint();
                                           try{
                                               Lead objLead = new Lead();
                                               objLead.Salutation = saluation;
                                               objLead.FirstName = firstName;
                                               objLead.MiddleName = middleName;
                                               objLead.LastName = lastName;
                                               objLead.NameArabic__c = fullNameInArabic;
                                               objLead.Birthdate__c = birthdate;
                                               objLead.GenderIdentity = gender;
                                               objLead.MaritalStatus__c = maritalStatus;
                                               objLead.MobileCountryCode__c = mobileCountryCode;
                                               objLead.MobilePhone = mobile;
                                               objLead.Email = email;
                                               objLead.nationality__c = nationality;
                                               objLead.Passport_Number__c = passport;
                                               objLead.PassportExpiryDate__c = passportExpiryDate;
                                               objLead.PlaceOfIssue__c = placeOfIssue;
                                               objLead.Emirates_Id__c = eid;
                                               objLead.EmiratesIDExpiryDate__c = eidExpiryDate;
                                               objLead.LeadSource = NULL;
                                               objLead.leadsubsource__c = NULL;
                                               objLead.lead_channel__c = NULL;
                                               objLead.Project__c = NULL;
                                               objLead.BuyRent__c = NULL;
                                               objLead.PropertyUsage__c = NULL;
                                               
                                               objLead.LeadTeam__c = leasingLeadProfileIdsList.contains(UserInfo.getProfileId()) ? 'Leasing' : 'Sales'; 
                                               LeadService objLS = LeadService.getInstance();
                                               Database.SaveResult sr = objLS.insertLeadWithoutDuplicateRule(objLead);
                                               if(sr.isSuccess()){
                                                   leadId = sr.getId();
                                               }
                                           }catch(System.exception ex){
                                               Database.rollback(sp);
                                               throw new AuraHandledException(ex.getMessage());
                                           }
                                           return leadId;
                                       }
    
    /*@AuraEnabled
public static void qualifyLead(Id leadId) {
System.debug('leadId'+leadId);
Lead objLead  = [SELECT Id,Status,Owner.Name FROM Lead WHERE Id =:leadId];
System.debug('objLead'+objLead);
objLead.Status = 'In Progress';
objLead.ContactCentreLeadStatus__c = 'Qualified';
objLead.QualifiedBy__c = UserInfo.getUserId();
objLead.QualifiedDate__c = DateTime.now();
try{
update objLead;    
}catch(Exception e){
List<String> sfs = e.getMessage().split(',');
sfs.remove(0);
String errorMessage = String.join(sfs, ', ');
errorMessage = errorMessage.removeEnd(': []');
throw new Auraexception(errorMessage);
}
}

@AuraEnabled
public static void disqualifyLead(Id leadId) {
System.debug('leadId'+leadId);
Lead objLead  = [SELECT Id,Status,Owner.Name FROM Lead WHERE Id =:leadId];
System.debug('objLead'+objLead);
objLead.Status = 'Closed';
objLead.ContactCentreLeadStatus__c = 'Disqualified';
objLead.DisqualifiedBy__c = UserInfo.getUserId();
objLead.DisqualifiedDate__c = DateTime.now();
try{
update objLead;    
}catch(Exception e){
List<String> sfs = e.getMessage().split(',');
sfs.remove(0);
String errorMessage = String.join(sfs, ', ');
errorMessage = errorMessage.removeEnd(': []');
throw new Auraexception(errorMessage);
}
}*/
    
    
    @AuraEnabled
    public static void qualifyLead(Id leadId) {
        try{
            Lead objLead = new Lead(Id = leadId);
            objLead.Status = 'In Progress';
            objLead.ContactCentreLeadStatus__c = 'Qualified';
            objLead.QualifiedBy__c = UserInfo.getUserId();
            objLead.QualifiedDate__c = DateTime.now();
            LeadService.getInstance().updateLead(objLead);
        }catch(System.Exception ex){
            throw new Auraexception(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String vaidateLead(Id leadId){
        String jsonData;
        List<String> missingFields = new List<String>();
        try{
            Id individualLeadRecordTypeId = Utility.getRecordTypeIdByDevName(Lead.SObjectType, LEAD_RT_DEV_NAME_INDIVIDUAL_LEAD);
            Id organizationLeadRecordTypeId = Utility.getRecordTypeIdByDevName(Lead.SObjectType, LEAD_RT_DEV_NAME_ORGANIZATION_LEAD);
            LeadService objLeadService = LeadService.getInstance();
            Lead objLead = objLeadService.getLeadById(leadId);
            missingFields = validateLeadBeforeQualify(objLead, individualLeadRecordTypeId, organizationLeadRecordTypeId);
            if(missingFields != NULL && !missingFields.isEmpty()){
                return JSON.serialize(missingFields);
            }
        }catch(System.exception ex){
            throw new AuraHandledException('Error: '+ ex.getMessage());   
        }
        return jsonData;
    }
    
    private static List<String> validateLeadBeforeQualify(Lead objLead, Id individualLeadRecordTypeId, Id organizationLeadRecordTypeId){
        List<String> missingFields = new List<String>();
        if(objLead.RecordTypeId == individualLeadRecordTypeId){
            if(String.isBlank(objLead.LeadTeam__c)){
                missingFields.add('Lead Team');
            }
            if(String.isBlank(objLead.FirstName)){
                missingFields.add('First Name');
            }
            if(String.isBlank(objLead.LastName)){
                missingFields.add('Last Name');
            }
            if(String.isBlank(objLead.comments__c)){
                missingFields.add('Contact Center Comments');
            }
            if(String.isBlank(objLead.MobileCountryCode__c)){
                missingFields.add('Mobile Country Code');
            }
            if(String.isBlank(objLead.MobilePhoneNumber__c)){
                missingFields.add('Mobile Phone Number');
            }
            if(String.isBlank(objLead.PreferredCommunicationMethodology__c	)){
                missingFields.add('Preferred Communication Methodology');
            }
            if(String.isBlank(objLead.LeadSource)){
                missingFields.add('Lead Source');
            }
            if(String.isBlank(objLead.leadsubsource__c)){
                missingFields.add('Lead Sub Source');
            }
            if(String.isBlank(objLead.lead_channel__c)){
                missingFields.add('Lead Channel');
            }
            if(String.isBlank(objLead.SecondaryLeadSource__c)){
                missingFields.add('Secondary Lead Source');
            }
            if(String.isBlank(objLead.SecondaryLeadSubSource__c)){
                missingFields.add('Secondary Lead Sub Source');
            }
            if(String.isBlank(objLead.Project__c)){
                missingFields.add('Project');
            }
            if(String.isBlank(objLead.UnitType__c)){
                missingFields.add('Unit Type');
            }
            if(objLead.LeadTeam__c == 'Sales'){
                if(String.isBlank(objLead.PropertyUsage__c)){
                    missingFields.add('Property Usage');
                }
                if(String.isBlank(objLead.BuyRent__c)){
                    missingFields.add('Buy Rent');
                }
            }
        }else if(objLead.RecordTypeId == organizationLeadRecordTypeId){
            if(String.isBlank(objLead.Company)){
                missingFields.add('Company Name');
            }
            if(String.isBlank(objLead.FirstName)){
                missingFields.add('Representative First Name');
            }
            if(String.isBlank(objLead.LastName)){
                missingFields.add('Representative Last Name');
            }
            if(String.isBlank(objLead.Project__c)){
                missingFields.add('Project');
            }
            if(String.isBlank(objLead.UnitType__c)){
                missingFields.add('Unit Type');
            }
            if(objLead.LeadTeam__c == 'Sales'){
                if(String.isBlank(objLead.PropertyUsage__c)){
                    missingFields.add('Property Usage');
                }
                if(String.isBlank(objLead.BuyRent__c)){
                    missingFields.add('Buy Rent');
                }
            }
        }
        return missingFields;
    }
}