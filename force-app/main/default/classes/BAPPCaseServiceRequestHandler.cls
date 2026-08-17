public with sharing class BAPPCaseServiceRequestHandler {
    
    // ===== Constants =====
    private static final String CONTENT_TYPE_JSON = 'application/json;charset=UTF-8';
    private static final String STATUS_SUCCESS = 'success';
    private static final String STATUS_ERROR = 'error';
 	private static final String ORIGIN_PORTAL = 'Portal';
    
    // ===== Request DTOs =====
    public class CaseRequest {
        public Id accountId;
        public Id contactId;
        public String caseDescription;
        public String category;
        public String subCategory;
        public String origin;
        public String caseStatus;
        public String brokerInvoiceNumber;
    }
    
    public class CaseGetRequest {
        public Id accountId;
        public Id contactId;
    }
    
    // ===== Response DTOs =====
    public class CaseResponse {
        public String caseStatus;
        public String caseId;
        public String caseNumber;
        public String message;
        public String status;
    }
    
    public class CaseGetResponse {
        public Id accountId;
        public String accountName;
        public Id contactId;
        public Id caseId;
        public String contactName;
        public String description;
        public String caseStatus;
        public String approvalStatus;
        public String approvalComments;
        public String rejectionComments;
        public String category;
        public String subcategory;
        public String caseNumber;
        public String createdOnDate;
        public String typeOfEstablishment;
        public Map<String, Object> agentDetails;
        public Map<String, Object> agencyDetails;
        public Map<String, Object> other;
    }
    
    public class DocumentResponse {
        public Id parentId;
        public Id parentDocId;
        public String fileType;
        public String fileSizeMB;
        public String fileName;
        public String documentName;
        public Id contentVersionId;
        public Id contentDocumentId;
    }
    
    public class AccountContactWrapper {
        public Account accountRec { get; set; }
        public Contact contactRec { get; set; }
    }
    
    // ===== Public REST Methods =====
    public static void getServiceRequests() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        setJsonHeader();
        
        try {
            CaseGetRequest input = (CaseGetRequest) parseBody(req.requestBody, CaseGetRequest.class);
            AccountContactWrapper wrapper = validateAccountAndContact(input != null ? String.valueOf(input.accountId) : null, input != null ? String.valueOf(input.contactId) : null);
            if (wrapper == null) return;
            
            Account acc = wrapper.accountRec;
            Contact contact = wrapper.contactRec;
            
            List<Case> cases = CaseService.getInstance().getCasesByContactId(input.contactId);
            if (cases == null || cases.isEmpty()) {
                sendResponse(200, new Map<String,Object>{
                    'status'  => STATUS_SUCCESS,
                        'message' => Label.BAPP_NoServiceRequestsFound,
                        'cases'   => null
                        });
                return;
            }
            
            // Collect related contact IDs
            Set<Id> contactIdsToUpdate = new Set<Id>();
            for (Case c : cases) {
                if (String.isNotBlank(c.Broker_Agent__c)) {
                    contactIdsToUpdate.add(Id.valueOf(c.Broker_Agent__c));
                }
            }
            
            Map<Id, Contact> contactToUpdateMap = new Map<Id, Contact>();
            if (!contactIdsToUpdate.isEmpty()) {
                contactToUpdateMap = ContactService.getInstance().getContactsByIds(contactIdsToUpdate);
            }
            
            // Collect related documents
            Set<Id> caseIds = new Map<Id, Case>(cases).keySet();
            Map<Id, List<DocumentResponse>> docMap = new Map<Id, List<DocumentResponse>>();
            
            if (!caseIds.isEmpty()) {
                List<Document__c> docs = DocumentService.getInstance().getExistingDocumentsByCaseId(caseIds);
                for (Document__c doc : docs) {
                    if (!docMap.containsKey(doc.Case__c)) {
                        docMap.put(doc.Case__c, new List<DocumentResponse>());
                    }
                    DocumentResponse d = new DocumentResponse();
                    d.parentId = doc.Case__c;
                    d.parentDocId = doc.Id;
                    d.fileType = doc.FileType__c;
                    d.fileSizeMB = doc.FileSizeMB__c != null ? String.valueOf(doc.FileSizeMB__c) : null;
                    d.fileName = doc.FileName__c;
                    d.documentName = doc.DocumentType__r != null ? doc.DocumentType__r.Type__c : null;
                    d.contentVersionId = doc.Content_Version_Id__c;
                    d.contentDocumentId = doc.ContentDocumentId__c;
                    docMap.get(doc.Case__c).add(d);
                }
            }
            
            // Build responses
            List<CaseGetResponse> caseResponses = new List<CaseGetResponse>();
            for (Case c : cases) {
                CaseGetResponse responseObj = new CaseGetResponse();
                responseObj.accountId = acc.Id;
                responseObj.accountName = acc.Name;
                responseObj.contactId = contact.Id;
                responseObj.contactName = contact.Name;
                responseObj.description = c.Description;
                responseObj.caseStatus = c.Status;
                responseObj.approvalStatus = c.ApprovalStatus__c;
                responseObj.approvalComments = c.ApprovalComments__c;
                responseObj.rejectionComments = c.RejectionComments__c;
                responseObj.category = c.ServiceCatalog__r != null ? c.ServiceCatalog__r.Category__c : null;
                responseObj.subcategory = c.ServiceCatalog__r != null ? c.ServiceCatalog__r.SubCategory__c : null;
                if (responseObj.subcategory == 'Other Service Request') {
                    responseObj.subcategory = 'Other';
                }
                responseObj.caseNumber = c.CaseNumber;
                responseObj.caseId = c.Id;
                responseObj.createdOnDate = c.CreatedDate != null 
                    ? String.valueOf(Date.newInstance(c.CreatedDate.year(), c.CreatedDate.month(), c.CreatedDate.day())) 
                    : null;
                responseObj.typeOfEstablishment = c.TypeofEstablishment__c;
                
                List<DocumentResponse> relatedDocs = docMap.containsKey(c.Id) ? docMap.get(c.Id) : new List<DocumentResponse>();
                String subCat = responseObj.subcategory;
                
                if (subCat == 'Broker Agent Details Update') {
                    responseObj.agentDetails = buildAgentDetails(c, contact, relatedDocs, contactToUpdateMap);
                } else if (subCat == 'Broker Agency Details Update') {
                    responseObj.agencyDetails = buildAgencyDetails(c, acc, relatedDocs);
                } else if (subCat == 'Delayed Commission Payment' || subCat == 'Incorrect Commission Amount' || subCat == 'Other Service Request') {
                    responseObj.other = buildOtherDetails(c, relatedDocs);
                }
                
                caseResponses.add(responseObj);
            }
            
            sendResponse(200, caseResponses);
            
        } catch (Exception e) {
            returnError('Unexpected error: ' + e.getMessage(), 500);
        }
    }
    
    
    public static void handleCaseServiceRequest() {
        try {
            CaseRequest input = (CaseRequest) parseBody(RestContext.request.requestBody, CaseRequest.class);
            if (input == null) input = new CaseRequest();
            
            AccountContactWrapper wrapper = validateAccountAndContact(String.valueOf(input.accountId), String.valueOf(input.contactId));
            if (wrapper == null) return;
            
            Account acc = wrapper.accountRec;
            Contact contact = wrapper.contactRec;
            
            if (String.isBlank(input.subCategory)) {
                returnError(Label.BAPP_SubCategoryRequired, 400);
                return;
            }
            if (String.isBlank(input.category)) {
                returnError(Label.BAPP_CategoryRequired, 400);
                return;
            }
            
            String requestedSubCategory = input.subCategory;

            String normalizedSubType = requestedSubCategory.replaceAll('\\s+', '');
            
            if (requestedSubCategory.equalsIgnoreCase('Incorrect Commission Amount')) {
                normalizedSubType = 'BrokerCommissionIssue';
            } 
            else if (requestedSubCategory.equalsIgnoreCase('Delayed Commission Payment')) {
                normalizedSubType = 'BrokerCommissionIssue';
            } 
            else if (requestedSubCategory.equalsIgnoreCase('Other')) {
                // internally use this label
                requestedSubCategory = 'Other Service Request';
                normalizedSubType = 'BrokerGeneralServiceRequest';
            }
            
            Id caseRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, normalizedSubType);
            
            if (caseRecordTypeId == null) {
                returnError(Label.BAPP_InvalidSubCategory, 400);
                return;
            }
            
            ServiceCatalog__c sc = ServiceCatalogService.getInstance().getBySubCategory(normalizedSubType, requestedSubCategory);
            
            if (sc == null) {
                returnError(Label.BAPP_NoServiceCatalogFound, 400);
                return;
            }
            Id bbmQueueId;
                try {
                    bbmQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Bloom_Broker_Management_BBM' LIMIT 1].Id;
                } catch (Exception e) {
                    bbmQueueId = null;
                }
            
            Id commissionId;
            if (String.isNotBlank(input.brokerInvoiceNumber)) {
                BrokerCommission__c commission = BrokerCommissionService.getInstance().getByInvoiceNumber(input.brokerInvoiceNumber);
                
                if (commission == null) {
                    returnError(Label.BAPP_BrokerCommissionNotFound + input.brokerInvoiceNumber, 400);
                    return;
                }
                commissionId = commission.Id;
            }
            
            Case caseRecord = new Case(
                
                ContactId           = input.contactId,
                AccountId			= input.accountId,
                Description         = input.caseDescription,
                Origin              = ORIGIN_PORTAL,
                Status              = input.caseStatus,
                Type				= input.category,
                RecordTypeId        = caseRecordTypeId,
                ServiceCatalog__c   = sc.Id,
                SubType__c			= requestedSubCategory,
                BrokerCommission__c = commissionId,
                Subject				= requestedSubCategory,
                OwnerId             = bbmQueueId,
                ApprovalStatus__c   = 'Not Approved'
            );
            
            List<Case> inserted = CaseService.getInstance().insertCaseWithTrigger(new List<Case>{ caseRecord });
            if (inserted.isEmpty()) {
                returnError(Label.BAPP_CaseNotCreated, 500);
                return;
            }
            
            Case created = CaseService.getInstance().getCaseById(inserted[0].Id);
            if (created == null) {
                returnError(Label.BAPP_CaseNotRetrieved, 500);
                return;
            }
            Case createdCase = CaseService.getInstance().getCaseById(inserted[0].Id);
            
            Case latestCase = CaseService.getInstance().getCaseById(created.Id);
            latestCase.ApprovalStatus__c = 'Pending';
            CaseService.getInstance().updateCase(latestCase);

            List<Document__c> relatedDocs = DocumentService.getInstance().getExistingDocuments(new Set<Id>{ created.Id });
            List<Map<String, String>> agentDocs = new List<Map<String, String>>();
            for (Document__c doc : relatedDocs) {
                agentDocs.add(new Map<String, String>{
                    'id'   => doc.Id,
                        'type' => (doc.DocumentType__r != null ? doc.DocumentType__r.Type__c : null)
                        });
            }
            
            Map<String, Object> responseMap = new Map<String, Object>{
                'status'     => STATUS_SUCCESS,
                    'message'    => Label.BAPP_CaseCreatedSuccess,
                    'caseNumber' => created.CaseNumber,
                    'caseId'     => created.Id,
                    'caseStatus' => created.Status,
                    'documents'  => agentDocs.isEmpty() ? null : agentDocs
                        };
                            
                            sendResponse(201, responseMap);
            
        } catch (Exception e) {
            returnError('Unexpected error: ' + e.getMessage(), 500);
        }
    }
    
    
    // ===== Helper Methods =====
    private static Map<String, Object> buildAgentDetails(Case c, Contact contact, List<DocumentResponse> docs, Map<Id, Contact> contactToUpdateMap) {
        Contact contactToUpdate;
        if (String.isNotBlank(c.Broker_Agent__c)) {
            Id cid = Id.valueOf(c.Broker_Agent__c);
            if (contactToUpdateMap.containsKey(cid)) contactToUpdate = contactToUpdateMap.get(cid);
        }
        
        return new Map<String, Object>{
            'mobileNumber'        => contact.PrimaryMobilePhone__c,
                'nationalIDExpiryDate'=> c.NationalIDExpiryDate__c,
                'passportExpiryDate'  => c.PassportExpiryDate__c,
                'brnReraExpiryDate'   => c.BRN_RERA_Expiry_Date__c,
                'contactIdToUpdate'   => c.Broker_Agent__c,
                'contactToUpdateName' => contactToUpdate != null ? contactToUpdate.Name : null,
                    'roleToUpdate'        => contactToUpdate != null ? contactToUpdate.BrokerContactRole__c : null,
                        'countryCode'         => contact.MobileCountryCode__c,
                        'documents'           => docs
                        };
                            }
    
    private static Map<String, Object> buildAgencyDetails(Case c, Account acc, List<DocumentResponse> docs) {
        Map<String, Object> agencyInformation = new Map<String, Object>{
            'tradeLicenseExpiryDate'      => c.TradeLicenseExpiryDate__c,
                'commercialLicenseExpiryDate' => c.CommercialLicenseExpiryDate__c,
                'vatUndertakingIssueDate'     => c.VATUndertakingIssue_Date__c,
                'taxRegistrationNumber'       => c.TaxRegistrationNumber__c,
                'agencyName'     => c.AgencyName__c,
                'agencyType'       => c.AgencyType__c
                };
                    
                    if (c.Type == 'VAT Details Update' && c.IsVATRegistered__c != null) {
                        agencyInformation.put('isVATRegistered', c.IsVATRegistered__c);
                    }
        
        return new Map<String, Object>{
            'agencyInformation' => agencyInformation,
                'addressDetails' => new Map<String, Object>{
                    'addressLine01'      => c.Address1__c,
                        'addressLine02'      => c.Address2__c,
                        'companyPhoneNumber' => c.PhoneNumber__c,
                        'countryCode'        => c.Mobile_Country_Code__c
                        },
                            'bankDetails' => new Map<String, Object>{
                                'bankBranchAddress' => c.BankAddress__c,
                                    'iban'              => c.IBANNumber__c,
                                    'swiftCode'         => c.SwiftCode__c,
                                    'bankName'          => c.BankName__c,
                                    'accountNumber'     => c.AccountNumber__c
                                    },
                                        'documents' => docs
                                        };
                                            }
    
    private static Map<String, Object> buildOtherDetails(Case c, List<DocumentResponse> docs) {
        return new Map<String, Object>{
            'commissionId' => c.BrokerCommission__c,
                'documents'    => docs
                };
                    }
    
    
    // ===== Common Utility Methods =====
    private static void setJsonHeader() {
        RestContext.response.addHeader('Content-Type', CONTENT_TYPE_JSON);
    }
    
    private static void sendResponse(Integer statusCode, Object body) {
        RestContext.response.statusCode = statusCode;
        setJsonHeader();
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(body));
    }
    
    private static void returnError(String msg, Integer code) {
        sendResponse(code, new Map<String, Object>{
            'status'  => STATUS_ERROR,
                'message' => msg
                });
    }
    
    private static AccountContactWrapper validateAccountAndContact(String accountId, String contactId) {
        // Validate required parameters
        if (String.isBlank(accountId) || String.isBlank(contactId)) {
            returnError(Label.BAPP_AccountAndContactRequired, 400);
            return null;
        }
        
        // Keep original existence checks to preserve behavior
        if (!Utility.recordExists(accountId)) {
            returnError(Label.BAPP_InvalidAccountId, 400);
            return null;
        }
        if (!Utility.recordExists(contactId)) {
            returnError(Label.BAPP_InvalidContactId, 400);
            return null;
        }
        
        Account acc = AccountService.getInstance().getAccountById(accountId);
        Contact con = ContactService.getInstance().getContactById(contactId);
        
        if (con == null || con.AccountId != accountId) {
            returnError(Label.BAPP_InvalidAccountContactRelation, 403);
            return null;
        }
        
        AccountContactWrapper wrapper = new AccountContactWrapper();
        wrapper.accountRec = acc;
        wrapper.contactRec = con;
        return wrapper;
    }
    
    private static Object parseBody(Blob body, Type targetType) {
        String jsonBody = body == null ? null : body.toString();
        return String.isNotBlank(jsonBody) ? JSON.deserialize(jsonBody, targetType) : null;
    }
}