public with sharing class BAPPAgencyInfoUpdateHandler {
    
    // -----------------------------
    // Request Wrapper
    // -----------------------------
    public class AgencyInfoUpdateRequest {
        public Id accountId;
        public Id contactId;
        public Id caseId;              
        public String caseStatus;      
        public String approvalStatus;
        public String serviceRequestType; 
        public String caseDescription;
        public String category;
        public String subCategory;
        public String subject;
        public String origin;
        public AgencyInformation agencyInformation;
        public AddressDetails addressDetails;
        public BankDetails bankDetails;
    }
    public class AgencyInformation {
        public Date tradeLicenseExpiryDate;
        public Date commercialLicenseExpiryDate;
        public Boolean isVatRegistered;
        public Date vatUndertakingIssueDate;
        public String taxRegistrationNumber;
        public String agencyName;
        public String agencyType;
    }
    public class AddressDetails {
        public String addressLine01;
        public String addressLine02;
        public String companyPhoneNumber;
        public String countryCode;
    }
    public class BankDetails {
        public String bankName;
        public String accountNumber;
        public String bankBranchAddress;
        public String iban;   
        public String swiftCode;
    }
    
    // -----------------------------
    // Response Wrapper
    // -----------------------------
    public class AgencyInfoUpdateResponse {
        public Id caseId;             // NEW
        public String caseStatus;     // NEW
        public String serviceRequestType; // NEW
        
        public Id accountId;
        public String accountName;
        public Id contactId;
        public String contactName;
        public String description;
        public String status;
        public String approvalStatus;
        public String approvalComments;
        public String rejectionComments;
        public String category;
        public String subCategory;
        public AgentDetails agentDetails;
        public AgencyDetails agencyDetails;
    }
    public class AgentDetails {
        public String mobileNumber;
        public Date nationalIdExpiryDate;
        public Date passportExpiryDate;
        public Date brnReraExpiryDate;
        public String roleToUpdate;
        public Id contactIdToUpdate;
        public String contactToUpdateName;
        public List<Map<String, String>> documents;
    }
    public class AgencyDetails {
        public AgencyInformation agencyInformation;
        public AddressDetails addressDetails;
        public BankDetails bankDetails;
        public List<Map<String, String>> documents;
    }
    
    // -----------------------------
    // Main Method
    // -----------------------------
    public static void handleAgencyInfoUpdate(String requestBodyString) {
        try {
            AgencyInfoUpdateRequest input =
                (AgencyInfoUpdateRequest) JSON.deserialize(requestBodyString, AgencyInfoUpdateRequest.class);
            
            if (input == null || input.accountId == null || input.contactId == null) {
                sendError('Invalid request. accountId and contactId are required.');
                return;
            }
            
            Contact contact = [SELECT Id, Name,AccountId, BrokerContactRole__c FROM Contact WHERE Id = :input.contactId LIMIT 1];
            
            
            // --- Verify contact belongs to the account ---
            if (contact.AccountId != input.accountId) {
                RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'status' => 'error',
                        'message' => 'The provided contactId does not belong to the specified accountId.'
                        }));
                RestContext.response.statusCode = 403;
                return;
            }
            
            // Access control check for multipicklist field
            if (String.isBlank(contact.BrokerContactRole__c)) {
                RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'status' => 'error',
                        'message' => 'Access Denied: Only Admins and Super Admin can perform this action.'
                        }));
                RestContext.response.statusCode = 403;
                return;
            }
            
            // Split multipicklist values by ';' and normalize to lower case
            Set<String> roles = new Set<String>();
            for (String role : contact.BrokerContactRole__c.split(';')) {
                roles.add(role.trim().toLowerCase());
            }
            
            // Deny access if user is neither Admin nor SuperAdmin
            if (!(roles.contains('admin') || roles.contains('superadmin'))) {
                RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'status' => 'error',
                        'message' => 'Access Denied: Only Admins can perform this action.'
                        }));
                RestContext.response.statusCode = 403;
                return;
            }
            
            
            // Get the Types of establishment
            Account agencyType = [
                SELECT Id, Name, TypeofEstablishment__c 
                FROM Account 
                WHERE Id = :input.accountId 
                LIMIT 1
            ];
            
            // --- Fetch matching Service Catalog record ---
            ServiceCatalog__c sc;
            if (!String.isBlank(input.subCategory)) {
                List<ServiceCatalog__c> scList = [
                    SELECT Id, Name, RecordTypeDevName__c
                    FROM ServiceCatalog__c
                    WHERE SubCategory__c = :input.subCategory
                    LIMIT 1
                ];
                if (!scList.isEmpty()) {
                    sc = scList[0];
                }
            }
            
            Id bloomQueueId;
            try {
                bloomQueueId = [
                    SELECT Id 
                    FROM Group 
                    WHERE Type = 'Queue'
                    AND DeveloperName = 'Bloom_Broker_Management_BBM' 
                    LIMIT 1
                ].Id;
            } catch (Exception e) {
                bloomQueueId = null;
            }
            
            Case caseRec;
            if (String.isBlank((String)input.caseId)) {
                // -------- CREATE CASE --------
                Id brokerRegistrationRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'BrokerAgencyDetailsUpdate');
                caseRec = new Case();
                caseRec.ServiceCatalog__c = sc != null ? sc.Id : null;
                caseRec.RecordTypeId = brokerRegistrationRecordTypeId;
                caseRec.AccountId = input.accountId;
                caseRec.ContactId = input.contactId;
                caseRec.Status = 'New';
                caseRec.Draft__c = true;
                caseRec.ApprovalStatus__c = 'Not Approved';
                caseRec.TypeofEstablishment__c = agencyType.TypeofEstablishment__c;
                caseRec.Subject = input.subCategory;
            	caseRec.Origin = 'Portal';
                caseRec.OwnerId = bloomQueueId;
            } else {
                // -------- UPDATE CASE --------
                caseRec = [
                    SELECT Id,
                    OwnerId,
                    AccountId,
                    ContactId,
                    Description,
                    Status,
                    ApprovalStatus__c,
                    Category__c,
                    Sub_category__c,
                    Type,
                    ApprovalComments__c,
                    RejectionComments__c,
                    TradeLicenseExpiryDate__c,
                    CommercialLicenseExpiryDate__c,
                    IsVATRegistered__c,
                    VATUndertakingIssue_Date__c,
                    TaxRegistrationNumber__c,
                    Address1__c,
                    Address2__c,
                    BankName__c,
                    AccountNumber__c,
                    BankAddress__c,
                    IBANNumber__c,
                    SwiftCode__c,
                    Subject,
                    Origin,
                    Step__c,
                    CaseType__c,
                    Draft__c, AgencyName__c, AgencyType__c
                    FROM Case
                    WHERE Id = :input.caseId
                    LIMIT 1
                ];
                
                // --- Access check ---
                if (caseRec.AccountId != input.accountId || caseRec.ContactId != input.contactId) {
                    sendError('Access Denied. You can update cases only from your own Agency.');
                    return;
                }
                
                // --- Status check ---
                if (caseRec.Draft__c == false) {
                    sendError('You cannot update the Service Request once Submitted.');
                    return;
                }
                
                caseRec.Status = input.caseStatus;
            }
            
            
            //Assign Bloom_Broker_Management queue as Owner on update
            if (bloomQueueId  != null) {
                caseRec.OwnerId = bloomQueueId;
                
            }
            
            // Common fields for Create/Update
            caseRec.Description = input.caseDescription;
            // caseRec.Category__c = input.category;
             caseRec.SubType__c  = input.serviceRequestType;
            //caseRec.ApprovalStatus__c = input.caseStatus;
            //caseRec.Status = input.caseStatus;
            caseRec.Type = input.category;
            caseRec.ServiceCatalog__c = sc != null ? sc.Id : null;
            
            if (input.agencyInformation != null) {
                caseRec.TradeLicenseExpiryDate__c = input.agencyInformation.tradeLicenseExpiryDate;
                caseRec.CommercialLicenseExpiryDate__c = input.agencyInformation.commercialLicenseExpiryDate;
                caseRec.AgencyName__c = input.agencyInformation.agencyName;
                caseRec.AgencyType__c = input.agencyInformation.agencyType;
                // caseRec.IsVATRegistered__c = input.agencyInformation.isVatRegistered;
                // Assign only if not null to avoid INVALID_TYPE_ON_FIELD_IN_RECORD
                if (input.agencyInformation.isVatRegistered != null) {
                    caseRec.IsVATRegistered__c = input.agencyInformation.isVatRegistered;
                }
                
                caseRec.VATUndertakingIssue_Date__c = input.agencyInformation.vatUndertakingIssueDate;
                caseRec.TaxRegistrationNumber__c = input.agencyInformation.taxRegistrationNumber;
            }
            if (input.addressDetails != null) {
                caseRec.Address1__c = input.addressDetails.addressLine01;
                caseRec.Address2__c = input.addressDetails.addressLine02;
                caseRec.PhoneNumber__c = input.addressDetails.companyPhoneNumber;
                caseRec.Mobile_Country_Code__c = input.addressDetails.countryCode;
            }
            if (input.bankDetails != null) {
                caseRec.BankName__c = input.bankDetails.bankName;
                caseRec.AccountNumber__c = input.bankDetails.accountNumber;
                caseRec.BankAddress__c = input.bankDetails.bankBranchAddress;
                caseRec.IBANNumber__c = input.bankDetails.IBAN;
                caseRec.SwiftCode__c = input.bankDetails.swiftCode;
            }
            
            Boolean isSubmitted = false;

            if (input.caseStatus == 'Submitted') {
                //caseRec.Status = 'New';
                caseRec.Draft__c = false;
                caseRec.ApprovalStatus__c = 'Pending';
                isSubmitted = true;
            }
            
            if (String.isBlank((String)input.caseId)) {
            
                insert caseRec;
            
            } else {
            
                Case updatedCase = CaseService.getInstance().updateCase(caseRec);
            }
            
            // Update Account phone directly
            // if (input.addressDetails != null && !String.isBlank(input.addressDetails.companyPhoneNumber)) {
            //     Account accToUpdate = new Account(Id = input.accountId, Phone = input.addressDetails.companyPhoneNumber);
            //     update accToUpdate;
            // }
            
            // Update Account phone and country code directly
            system.debug('input.addressDetails>>>>'+input.addressDetails);
            if (input.addressDetails != null 
                && (!String.isBlank(input.addressDetails.companyPhoneNumber) || !String.isBlank(input.addressDetails.countryCode))) {
                    
                    Account accToUpdate = new Account(Id = input.accountId);
                    
                    if (!String.isBlank(input.addressDetails.companyPhoneNumber)) {
                        accToUpdate.Phone = input.addressDetails.companyPhoneNumber;
                    }
                    if (!String.isBlank(input.addressDetails.countryCode)) {
                        accToUpdate.PhoneCountryCode__c = input.addressDetails.countryCode;
                    }
                    
                    update accToUpdate;
                }
            
            
            // Build Response
            Account acc = [SELECT Id, Name, PhoneCountryCode__c, Phone FROM Account WHERE Id = :input.accountId LIMIT 1];
            Contact con = [SELECT Id, Name FROM Contact WHERE Id = :input.contactId LIMIT 1];
            
            Map<String, Object> respMap = buildAgencyInfoUpdateResponse(caseRec, acc, con, input);
            sendSuccess(respMap);
            
        } catch (Exception e) {
            sendError('Error processing request: ' + e.getMessage());
        }
    }
    
    private static void sendSuccess(Object resp) {
        RestContext.response.addHeader('Content-Type','application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp));
        RestContext.response.statusCode = 200;
    }
    private static void sendError(String msg) {
        RestContext.response.addHeader('Content-Type','application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(
            new Map<String, Object>{ 'status' => 'error', 'message' => msg }
        ));
        RestContext.response.statusCode = 400;
    }
    
    @TestVisible
    private static Map<String, Object> buildAgencyInfoUpdateResponse(Case caseRec, Account acc, Contact con, BAPPAgencyInfoUpdateHandler.AgencyInfoUpdateRequest input) {
        
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put('caseId', caseRec.Id);
        responseMap.put('caseStatus', caseRec.Status);
        responseMap.put('serviceRequestType', caseRec.Type);
        responseMap.put('accountId', acc.Id);
        responseMap.put('accountName', acc.Name);
        responseMap.put('contactId', con.Id);
        responseMap.put('contactName', con.Name);
        responseMap.put('description', caseRec.Description);
        responseMap.put('status', caseRec.Status);
        responseMap.put('approvalStatus', caseRec.ApprovalStatus__c);
        responseMap.put('approvalComments', caseRec.ApprovalComments__c);
        responseMap.put('rejectionComments', caseRec.RejectionComments__c);
        responseMap.put('category', caseRec.Category__c);
        responseMap.put('subCategory', caseRec.Sub_category__c);
        
        // Build Agency Details Map
        Map<String, Object> agencyDetailsMap = new Map<String, Object>();
        
        // Agency Information
        Map<String, Object> agencyInfoMap = new Map<String, Object>();
        agencyInfoMap.put('tradeLicenseExpiryDate', caseRec.TradeLicenseExpiryDate__c);
        agencyInfoMap.put('commercialLicenseExpiryDate', caseRec.CommercialLicenseExpiryDate__c);
        agencyInfoMap.put('vatUndertakingIssueDate', caseRec.VATUndertakingIssue_Date__c);
        agencyInfoMap.put('taxRegistrationNumber', caseRec.TaxRegistrationNumber__c);
        agencyInfoMap.put('agencyName', caseRec.AgencyName__c);
        agencyInfoMap.put('agencyType', caseRec.AgencyType__c);
        if (input.serviceRequestType != 'Legal Documents Update' && caseRec.IsVATRegistered__c != null) {
            agencyInfoMap.put('isVatRegistered', caseRec.IsVATRegistered__c);
        }
        agencyDetailsMap.put('agencyInformation', agencyInfoMap);
        
        // Address Details
        Map<String, Object> addrDetails = new Map<String, Object>();
        addrDetails.put('addressLine01', caseRec.Address1__c);
        addrDetails.put('addressLine02', caseRec.Address2__c);
        addrDetails.put('companyPhoneNumber', acc.Phone);
        addrDetails.put('countryCode', acc.PhoneCountryCode__c);
        agencyDetailsMap.put('addressDetails', addrDetails);
        
        // Bank Details
        agencyDetailsMap.put('bankDetails', input.bankDetails);
        
        // Documents
        List<Map<String, String>> accDocuments = new List<Map<String, String>>();
        List<Document__c> relatedDocs = DocumentService.getInstance()
            .getExistingDocuments(new Set<Id>{caseRec.Id});
        for (Document__c doc : relatedDocs) {
            accDocuments.add(new Map<String, String>{
                'id' => doc.Id,
                    'type' => doc.DocumentType__r != null ? doc.DocumentType__r.Type__c : null
                        });
        }
        agencyDetailsMap.put('documents', accDocuments);
        
        // Assign agencyDetails to response
        responseMap.put('agencyDetails', agencyDetailsMap);
        
        return responseMap;
    }

}