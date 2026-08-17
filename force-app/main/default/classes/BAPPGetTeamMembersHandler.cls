/*
* @Author        : Rushikesh Jadhav
* @CreatedDate  : 22th SEP 2025
* @Description  : Handler class to fetch broker team members
*                 (Contacts and Cases) along with their
*                 associated documents for a broker account.
*/
/*****************************************************************************************************
* Version       Author           Date             Comment                                                                       
* 1.0           Rushikesh        22-SEP-2025      Initial implementation of broker team member handler
*****************************************************************************************************
*/
public class BAPPGetTeamMembersHandler {

    // ---------- Wrapper Classes ----------
    public class GetTeamMemberResponse {
        public String status;
        public String accountId;
        public List<BrokerUser> BrokerUsers;
    }

    public class BrokerUser {
        public String entity;        // Contact or Case
        public String id;
        public String caseNumber;    // Only for Case
        public String title;
        public String firstName;
        public String middleName;
        public String lastName;
        public String fullName;
        public String email;
        public String phoneNumber;
        public String passportNumber;
        public Date passportExpiryDate;
        public String nationalId;
        public Date nationalIdExpiryDate;
        public Integer shareHoldingPercentage;
        public String designation;
        public String typeOfEstablishment;
        public String country;
        public String countryCode;
        public Date dateOfBirth;
        public Datetime updatedOn;
        public String brnOrReraNumber;
        public Date brnOrReraExpiryDate;
        public String role;
        public String approvalStatus;
        public Boolean isSuspended;
        public Boolean blacklisted;
        public Boolean isActive;

        public List<UserDocument> documents;
    }

    public class UserDocument {
        public String id;
        public String fileName;
        public String fileSizeMB; // Decimal to String
        public String fileType;
        public String contentVersionId;
        public String documentTypeLabel;
        public String contentDocumentId;
    }

    // ---------- Public Handler ----------
    public static void handleGetTeamMember(String accountId) {
        try {
            if (String.isBlank(accountId)) {
                setErrorResponse('Missing required parameter: accountId', 400);
                return;
            }

            GetTeamMemberResponse responseWrapper = getTeamMemberResponse(accountId);

            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
            RestContext.response.responseBody = Blob.valueOf(serializeGetTeamMemberResponse(responseWrapper));
            
            // === Validate accountId existence ===
            if (!Utility.recordExists(accountId)) {
                RestContext.response.statusCode = 404;
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(
                    '{"status":"error","message":"Invalid accountId."}'
                );
                return;
            }

        } catch (Exception ex) {
            setErrorResponse('An unexpected error occurred: ' + ex.getMessage(), 500);
        }
    }

    // ---------- Build Wrapper ----------
    public static GetTeamMemberResponse getTeamMemberResponse(String accountId) {
        GetTeamMemberResponse resp = new GetTeamMemberResponse();
        resp.accountId = accountId;
        resp.status = 'success';
        resp.BrokerUsers = new List<BrokerUser>();
    
        // Query contacts and cases first
        List<Contact> contactList = [
            SELECT Id, FirstName, MiddleName, LastName, Title, BrokerContactRole__c,Phone,
                   MobilePhone, Email, PassportNumber__c, PassportExpiryDate__c,
                   Emirates_Id__c, EID_Expiry_Date__c, ShareHoldingPercentage__c,
                   Designation__c, TypeofEstablishment__c, CountryOfResidence__c,PrimaryMobilePhone__c,
                   Birthdate, IsActive__c, PrimaryMobileCountryCode__c, LastModifiedDate,
                   IsSuspended__c, Blacklisted__c, BRN_RERA_Expiry_Date__c, BRN_RERA_Number__c,CaseId__c
            FROM Contact WHERE AccountId = :accountId And IsHiddenFromPortal__c = false
        ];
        // Filter contacts by Case Origin
        Set<Id> caseIdsForContacts = new Set<Id>();
        for (Contact con : contactList) {
            if (con.CaseId__c != null) {
                try {
                    caseIdsForContacts.add((Id) con.CaseId__c);
                } catch (Exception e) {
                    
                }
            }
        }
        
        Set<Id> portalCaseIds = new Set<Id>();
        if (!caseIdsForContacts.isEmpty()) {
            for (Case c : [SELECT Id FROM Case WHERE Id IN :caseIdsForContacts AND Origin = 'Portal']) {
                portalCaseIds.add(c.Id);
            }
        }
        
        List<Contact> conList = new List<Contact>();
        for (Contact con : contactList) {
            if (con.CaseId__c == null || portalCaseIds.contains((Id) con.CaseId__c)) {
                conList.add(con);
            }
        }
    
        List<Case> caseList = [
            SELECT Id, Email_Address__c, PhoneNumber__c, FullName__c, Title__c, First_Name__c, MiddleName__c, Last_Name__c,
                   NationalID__c, NationalIDExpiryDate__c, DateOfBirth__c, ShareHoldingPercentage__c,Draft__c,
                   Designation__c, BrokerContactRole__c, Country__c, PassportNumber__c,Mobile_Country_Code__c,
                   PassportExpiryDate__c, CaseNumber, TypeofEstablishment__c,
                   LastModifiedDate, ApprovalStatus__c, BRN_RERA_Expiry_Date__c, BRN_RERA_Number__c
            FROM Case WHERE AccountId = :accountId AND RecordType.DeveloperName = 'BrokerAgentRegistrationAndUpdate' And Origin = 'Portal' AND SubType__c = 'Broker New Agent Registration'
        ];
    
        // Collect all parent IDs
        Set<Id> parentIds = new Set<Id>();
        for (Contact c : contactList) parentIds.add(c.Id);
        for (Case cs : caseList) parentIds.add(cs.Id);
    
        // Query all documents once
        Map<Id, List<UserDocument>> docsMap = new Map<Id, List<UserDocument>>();
        if (!parentIds.isEmpty()) {
            for (Document__c doc : [
                SELECT Id, FileName__c, FileSizeMB__c, FileType__c,
                       DocumentType__c, DocumentType__r.Type__c,
                       ContentDocumentId__c, Content_Version_Id__c,
                       Contact__c, Case__c
                FROM Document__c
                WHERE Contact__c IN :parentIds OR Case__c IN :parentIds
            ]) {
                Id pid = (doc.Contact__c != null) ? doc.Contact__c : doc.Case__c;
                if (!docsMap.containsKey(pid)) {
                    docsMap.put(pid, new List<UserDocument>());
                }
                UserDocument ud = new UserDocument();
                ud.id = doc.Id;
                ud.fileName = doc.FileName__c;
                ud.fileSizeMB = doc.FileSizeMB__c;
                ud.fileType = doc.FileType__c;
                ud.contentVersionId = doc.Content_Version_Id__c;
                ud.documentTypeLabel = (doc.DocumentType__r != null ? doc.DocumentType__r.Type__c : null);
                ud.contentDocumentId = doc.ContentDocumentId__c;
                docsMap.get(pid).add(ud);
            }
        }
    
        // Build BrokerUsers for contacts
        for (Contact c : contactList) {
            BrokerUser u = new BrokerUser();
            u.entity = 'Contact';
            u.id = c.Id;
            u.firstName = c.FirstName;
            u.middleName = c.MiddleName;
            u.lastName = c.LastName;
            u.fullName = String.join(new List<String>{c.FirstName, c.MiddleName, c.LastName}, ' ').trim();
            u.title = c.Title;
            u.email = c.Email;
            u.phoneNumber = c.PrimaryMobilePhone__c;
            u.passportNumber = c.PassportNumber__c;
            u.passportExpiryDate = c.PassportExpiryDate__c; 
            u.nationalId = c.Emirates_Id__c;
            u.nationalIdExpiryDate = c.EID_Expiry_Date__c;
            u.shareHoldingPercentage = (c.ShareHoldingPercentage__c != null ? Integer.valueOf(c.ShareHoldingPercentage__c) : null);
            u.designation = c.Designation__c;
            u.typeOfEstablishment = c.TypeofEstablishment__c;
            u.country = c.CountryOfResidence__c;
            u.countryCode = c.PrimaryMobileCountryCode__c;
            u.dateOfBirth = c.Birthdate;
            u.updatedOn = c.LastModifiedDate;
            u.brnOrReraNumber = c.BRN_RERA_Number__c;
            u.brnOrReraExpiryDate = c.BRN_RERA_Expiry_Date__c;
            u.role = c.BrokerContactRole__c;
            u.approvalStatus = null;
            u.isSuspended = c.IsSuspended__c;
            u.blacklisted = c.Blacklisted__c;
            u.isActive = c.IsActive__c;
    
            u.documents = docsMap.containsKey(c.Id) ? docsMap.get(c.Id) : new List<UserDocument>();
            resp.BrokerUsers.add(u);
        }
    
        // Build BrokerUsers for cases
        for (Case cs : caseList) {
            BrokerUser u = new BrokerUser();
            u.entity = 'Case';
            u.id = cs.Id;
            u.caseNumber = cs.CaseNumber;
            u.title = cs.Title__c;
            u.firstName = cs.First_Name__c;
            u.middleName = cs.MiddleName__c;
            u.lastName = cs.Last_Name__c;
            u.fullName = cs.FullName__c;
            u.email = cs.Email_Address__c;
            u.phoneNumber = cs.PhoneNumber__c;
            u.passportNumber = cs.PassportNumber__c;
            u.passportExpiryDate = cs.PassportExpiryDate__c;
            u.nationalId = cs.NationalID__c;
            u.nationalIdExpiryDate = cs.NationalIDExpiryDate__c;
            u.shareHoldingPercentage = (cs.ShareHoldingPercentage__c != null ? Integer.valueOf(cs.ShareHoldingPercentage__c) : null);
            u.designation = cs.Designation__c;
            u.typeOfEstablishment = cs.TypeOfEstablishment__c;
            u.country = cs.Country__c;
            u.countryCode = cs.Mobile_Country_Code__c;
            u.dateOfBirth = cs.DateOfBirth__c;
            u.updatedOn = cs.LastModifiedDate;
            u.brnOrReraNumber = cs.BRN_RERA_Number__c;
            u.brnOrReraExpiryDate = cs.BRN_RERA_Expiry_Date__c;
            u.role = cs.BrokerContactRole__c;
            if(cs.Draft__c == true){
                u.approvalStatus = 'Draft';
            }else{
                u.approvalStatus = cs.ApprovalStatus__c;
            }
            u.isSuspended = null;
            u.blacklisted = null;
            u.isActive = null;
            
    
            u.documents = docsMap.containsKey(cs.Id) ? docsMap.get(cs.Id) : new List<UserDocument>();
            resp.BrokerUsers.add(u);
        }
    
        return resp;
    }
    // ---------- JSON Serialization ----------
    private static String serializeGetTeamMemberResponse(GetTeamMemberResponse wrapper) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
    
        writeStringOrNull(gen, 'status', wrapper.status);
        writeStringOrNull(gen, 'accountId', wrapper.accountId);
    
        gen.writeFieldName('BrokerUsers');
        gen.writeStartArray();
        for (BrokerUser u : wrapper.BrokerUsers) {
            gen.writeStartObject();
            writeStringOrNull(gen, 'entity', u.entity);
            writeStringOrNull(gen, 'id', u.id);
            if (u.entity == 'Case') writeStringOrNull(gen, 'caseNumber', u.caseNumber);
            writeStringOrNull(gen, 'title', u.title);
            writeStringOrNull(gen, 'firstName', u.firstName);
            writeStringOrNull(gen, 'middleName', u.middleName);
            writeStringOrNull(gen, 'lastName', u.lastName);
            writeStringOrNull(gen, 'fullName', u.fullName);
            writeStringOrNull(gen, 'email', u.email);
            writeStringOrNull(gen, 'phoneNumber', u.phoneNumber);
            writeStringOrNull(gen, 'passportNumber', u.passportNumber);
            writeDateOrNull(gen, 'passportExpiryDate', u.passportExpiryDate);
            writeStringOrNull(gen, 'nationalId', u.nationalId);
            writeDateOrNull(gen, 'nationalIdExpiryDate', u.nationalIdExpiryDate);
            writeDatetimeOrNull(gen, 'updatedOn', u.updatedOn);
            if (u.shareHoldingPercentage != null) gen.writeNumberField('shareHoldingPercentage', u.shareHoldingPercentage); else gen.writeNullField('shareHoldingPercentage');
            writeStringOrNull(gen, 'designation', u.designation);
            writeStringOrNull(gen, 'typeOfEstablishment', u.typeOfEstablishment);
            writeStringOrNull(gen, 'country', u.country);
            writeStringOrNull(gen, 'countryCode', u.countryCode);
            writeDateOrNull(gen, 'dateOfBirth', u.dateOfBirth);
            writeStringOrNull(gen, 'brnOrReraNumber', u.brnOrReraNumber);
            writeDateOrNull(gen, 'brnOrReraExpiryDate', u.brnOrReraExpiryDate);
            writeStringOrNull(gen, 'role', u.role);
            writeStringOrNull(gen, 'approvalStatus', u.approvalStatus);
            if (u.isSuspended != null) gen.writeBooleanField('isSuspended', u.isSuspended); else gen.writeNullField('isSuspended');
            if (u.blacklisted != null) gen.writeBooleanField('blacklisted', u.blacklisted); else gen.writeNullField('blacklisted');
            if (u.isActive != null) gen.writeBooleanField('isActive', u.isActive); else gen.writeNullField('isActive');
    
            gen.writeFieldName('documents');
            gen.writeObject(u.documents != null ? u.documents : new List<UserDocument>());
    
            gen.writeEndObject();
        }
        gen.writeEndArray();
    
        gen.writeEndObject();
        return gen.getAsString();
    }

    private static void writeDateOrNull(JSONGenerator gen, String fieldName, Date value) {
        if (value != null) gen.writeStringField(fieldName, String.valueOf(value));
        else gen.writeNullField(fieldName);
    }
    private static void writeDatetimeOrNull(JSONGenerator gen, String fieldName, Datetime value) {
        if (value != null) gen.writeStringField(fieldName, String.valueOf(value));
        else gen.writeNullField(fieldName);
    }
    private static void writeStringOrNull(JSONGenerator gen, String fieldName, String value) {
    if (value != null) {
        gen.writeStringField(fieldName, value);
    } else {
        gen.writeNullField(fieldName);
    }
}

    // ---------- Error Response ----------
    private static void setErrorResponse(String message, Integer statusCode) {
        RestContext.response.statusCode = statusCode;
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(
            JSON.serializePretty(new Map<String, Object>{
                'status' => 'error',
                'message' => message
            })
        );
    }
}