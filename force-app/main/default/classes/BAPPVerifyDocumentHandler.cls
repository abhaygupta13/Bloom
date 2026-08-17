public with sharing class BAPPVerifyDocumentHandler {
    
    // ====== Request Wrapper ======
    public class VerifyDocumentRequest {
        public String documentParentId;
        public String documentId;
        public String accountId;
        public String contactId;
        public String applicationId;
        public String brokerApplicantId;
    }
    
    // ====== Entry Method ======
    public static void handleVerifyDocument(String requestBodyString) {
        try {
            if (String.isBlank(requestBodyString)) {
                sendErrorResponse('Missing request body', null, 400);
                return;
            }

            VerifyDocumentRequest req;
            try {
                req = (VerifyDocumentRequest) JSON.deserialize(requestBodyString, VerifyDocumentRequest.class);
            } catch (Exception e) {
                sendErrorResponse('Invalid JSON format: ' + e.getMessage(), null, 400);
                return;
            }

            // ==== Validate Input ====
            List<Map<String, String>> errors = validateVerifyParams(req);
            if (!errors.isEmpty()) {
                sendErrorResponse('Missing or invalid required fields', errors, 400);
                return;
            }

            // ==== Validate Account/Contact existence if brokerApplicationId is blank ====
            if (String.isBlank(req.applicationId)) {
                if (!Utility.recordExists(req.accountId)) {
                    sendErrorResponse(Label.BAPP_InvalidAccountId, errors, 400);
                    return;
                }
                if (!Utility.recordExists(req.contactId)) {
                    sendErrorResponse(Label.BAPP_InvalidContactId, errors, 400);
                    return;
                }

                Contact con = ContactService.getInstance().getContactById(req.contactId);
                if (con == null || con.AccountId != req.accountId) {
                    sendErrorResponse(Label.BAPP_InvalidAccountContactRelation, errors, 400);
                    return;
                }
            }

            // ==== Fetch Document ====
            Document__c doc = DocumentService.getInstance().getDocumentByIdBAPP(req.documentId);
            if (doc == null) {
                sendErrorResponse('Document not found', null, 404);
                return;
            }

            // ==== Verify Linkage ====
            Id parentId = Id.valueOf(req.documentParentId);
            Id accountId = String.isNotBlank(req.accountId) ? Id.valueOf(req.accountId) : null;
            String parentType = parentId.getSObjectType().getDescribe().getName();

            Boolean linked = false;
            Boolean accountMatch = true;
            Boolean applicationMatch = true;
            String matchedField;

            switch on parentType {
                when 'Case' {
                    linked = (doc.Case__c == parentId);
                    accountMatch = (doc.Case__r != null && doc.Case__r.AccountId == accountId);
                    matchedField = 'Case__c';
                }
                when 'BrokerCommission__c' {
                    linked = (doc.BrokerCommission__c == parentId);
                    accountMatch = (doc.BrokerCommission__r != null &&
                        doc.BrokerCommission__r.SalesOrder__r.Opportunity__r.AccountId == accountId);
                    matchedField = 'BrokerCommission__c';
                }
                when 'Contact' {
                    linked = (doc.Contact__c == parentId);
                    accountMatch = (doc.Contact__r != null && doc.Contact__r.AccountId == accountId);
                    matchedField = 'Contact__c';
                }
                when 'Account' {
                    linked = (doc.Account__c == parentId);
                    accountMatch = (doc.Account__c == accountId);
                    matchedField = 'Account__c';
                }
                when 'BrokerApplication__c' {
                    linked = (doc.BrokerApplication__c == parentId);
                    applicationMatch = (doc.BrokerApplication__c != null &&
                        doc.BrokerApplication__c == req.applicationId);
                    matchedField = 'BrokerApplication__c';
                }
                when 'BrokerApplicant__c' {
                    linked = (doc.BrokerApplicant__c == parentId);
                    applicationMatch = (doc.BrokerApplicant__r != null &&
                        doc.BrokerApplicant__r.BrokerApplication__c == req.applicationId);
                    matchedField = 'BrokerApplicant__c';
                }
                when else {
                    sendErrorResponse('Unsupported parent type: ' + parentType, null, 400);
                    return;
                }
            }

            // ==== Link Validation ====
            if (!linked) {
                sendErrorResponse('Document is not linked with the provided parent record.', null, 403);
                return;
            }

            // ==== Separate Validation Messages ====
            if (parentType == 'BrokerApplication__c' || parentType == 'BrokerApplicant__c') {
                if (!applicationMatch) {
                    sendErrorResponse('Application mismatch: Document does not belong to the provided application.', null, 403);
                    return;
                }
            } else {
                if (!accountMatch) {
                    sendErrorResponse('Account mismatch: Document does not belong to the provided account.', null, 403);
                    return;
                }
            }

            // ==== SUCCESS ====
            sendSuccessResponse(new Map<String, Object>{
                'status'          => 'success',
                'message'         => 'Document verification successful',
                'documentId'      => doc.Id,
                'documentParentId'=> req.documentParentId,
                'linkedField'     => matchedField
            });

        } catch (Exception ex) {
            sendErrorResponse('An unexpected error occurred: ' + ex.getMessage(), null, 500);
        }
    }

    // ====== Validation ======
    private static List<Map<String, String>> validateVerifyParams(VerifyDocumentRequest req) {
        List<Map<String, String>> errors = new List<Map<String, String>>();
        checkRequired(req.documentParentId, 'documentParentId', 'Document Parent Id is required', errors);
        checkRequired(req.documentId, 'documentId', 'Document Id is required', errors);

        Boolean hasAcctContact = !String.isBlank(req.accountId) && !String.isBlank(req.contactId);
        Boolean hasBrokerApp = !String.isBlank(req.applicationId);

        if (hasAcctContact && hasBrokerApp) {
            errors.add(new Map<String, String>{
                'field' => 'applicationId',
                'message' => 'applicationId must be null when accountId and contactId are provided'
            });
        } else if (hasAcctContact) {
            checkRequired(req.accountId, 'accountId', 'Account Id is required', errors);
            checkRequired(req.contactId, 'contactId', 'Contact Id is required', errors);
        } else if (hasBrokerApp) {
            checkRequired(req.applicationId, 'applicationId', 'Broker Application Id is required', errors);
        }

        return errors;
    }

    private static void checkRequired(String val, String field, String msg, List<Map<String, String>> errors) {
        if (String.isBlank(val)) {
            errors.add(new Map<String, String>{ 'field' => field, 'message' => msg });
        }
    }

    // ====== Response Helpers ======
    private static void sendSuccessResponse(Map<String, Object> result) {
        RestContext.response.statusCode = 200;
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(result));
    }

    private static void sendErrorResponse(String message, List<Map<String, String>> errors, Integer statusCode) {
        Map<String, Object> resp = new Map<String, Object>{
            'status'  => 'error',
            'message' => message
        };
        if (errors != null && !errors.isEmpty()) {
            resp.put('errors', errors);
        }
        RestContext.response.statusCode = statusCode == null ? 400 : statusCode;
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(resp));
    }
}