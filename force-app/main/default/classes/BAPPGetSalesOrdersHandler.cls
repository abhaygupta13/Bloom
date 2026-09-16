public with sharing class BAPPGetSalesOrdersHandler {

    // ===== Request DTO =====
    public class SalesOrderFilterRequest {
        public String accountId;
        public String contactId;
        public String searchKey;     // search on OrderNumber & CustomerName
        public FilterCriteria filters;
    }

    public class FilterCriteria {
        public String status;           // e.g. "Booked;Sold"
        public String salesManagerId;   // multiple allowed, separated by ;
        public Date   updatedOnFrom;
        public Date   updatedOnTo;
    }

    // ===== Response DTO =====
    public class GetSalesOrdersResponse {
        public String status;
        public List<SalesOrderRecord> salesOrders;
    }
    public class DocumentRecord {
        public String id;
        public String contentDocumentId;
        public String contentVersionId;
        public String name;
    }
    public class CommissionRecord {
        public String id;
        public Decimal commissionAmount;
        public Decimal commissionPercentage;
        public Decimal vatPercentage;
        public Decimal totalCommissionAmountWithVAT;
        public String status;
        public Decimal installmentNumber; // from InstallmentLine__r.InstallmentNumber__c
        public Boolean isFullPayment;
        public String invoiceNumber;
        public List<DocumentRecord> documents;
    }

    public class SalesOrderRecord {
        public String id;
        public String orderNumber;
        public String salesManagerId;
        public String salesManagerName;
        public String customerName;
        public String status;
        public String projectName;
        public String unitType;
        public String unitName;
        public Datetime lastModifiedDate;
        public List<CommissionRecord> commissions;
    }

    // ===== Entry Point =====
    public static void handleSalesOrderFilters() {
        try {
            String body = RestContext.request.requestBody == null ? null : RestContext.request.requestBody.toString();
            SalesOrderFilterRequest input = (SalesOrderFilterRequest) JSON.deserialize(body, SalesOrderFilterRequest.class);
			System.debug('Rushi 60' + input.accountId);
            if (input == null || String.isBlank(input.accountId) || String.isBlank(input.contactId)) {
                returnError(Label.BAPP_AccountAndContactRequired, 400);
                return;
            }
            // ---- Check record existence ----
            if (!Utility.recordExists(input.accountId)) {
                returnError(Label.BAPP_InvalidAccountId, 404);
                return;
            }
            if (!Utility.recordExists(input.contactId)) {
                returnError(Label.BAPP_InvalidContactId, 404);
                return;
            }
    
            // ---- Check Contact belongs to Account ----
            Contact con = ContactService.getInstance().getContactById(input.contactId);
            if (con.AccountId != input.accountId) {
                returnError(Label.BAPP_InvalidAccountContactRelation, 400);
                return;
            }


            // ===== Validate date range =====
            if (input.filters != null) {
                // Check if updatedOnFrom is in the future
                if (input.filters.updatedOnFrom != null && input.filters.updatedOnFrom > System.today()) {
                    returnError(Label.BAPP_UpdatedOnFromFuture, 400);
                    return;
                }
                if (input.filters.updatedOnTo != null && input.filters.updatedOnTo > System.today()) {
                    returnError(Label.BAPP_UpdatedOnToFuture, 400);
                    return;
                }
            
                // Require updatedOnTo if updatedOnFrom is provided
                if (input.filters.updatedOnFrom != null && input.filters.updatedOnTo == null) {
                    returnError(Label.BAPP_UpdatedOnToRequired, 400);
                    return;
                }
            
                // Ensure updatedOnFrom is not after updatedOnTo
                if (input.filters.updatedOnFrom != null && input.filters.updatedOnTo != null) {
                    if (input.filters.updatedOnFrom > input.filters.updatedOnTo) {
                        returnError(Label.BAPP_UpdatedOnRangeInvalid, 400);
                        return;
                    }
                }
            }

            // Call Service
            String soql = buildSalesOrderQuery(input.accountId,input.contactId,input.searchKey,input.filters);
            // Call Service only to execute
			List<SalesOrder__c> salesOrders = SalesOrderService.runFilteredSalesOrderQuery(soql);
			// Business logic: Collect commissions & fetch related documents
            List<BrokerCommission__c> allBrokerCommissions = new List<BrokerCommission__c>();
            for (SalesOrder__c so : salesOrders) {
                if (so.Broker_Commissions__r != null) {
                    allBrokerCommissions.addAll(so.Broker_Commissions__r);
                }
            }

            DocumentService docService = DocumentService.getInstance();
            List<Document__c> generatedInvoiceDocs = docService.getBrokerCommissionDocuments(allBrokerCommissions, 'Generated Invoice');

            Map<Id, List<Document__c>> docsByCommissionId = new Map<Id, List<Document__c>>();
            for (Document__c doc : generatedInvoiceDocs) {
                if (!docsByCommissionId.containsKey(doc.BrokerCommission__c)) {
                    docsByCommissionId.put(doc.BrokerCommission__c, new List<Document__c>());
                }
                docsByCommissionId.get(doc.BrokerCommission__c).add(doc);
            }
            // Map to response DTO
            List<SalesOrderRecord> result = new List<SalesOrderRecord>();
            for (SalesOrder__c so : salesOrders) {
                result.add(toRecord(so, docsByCommissionId));
            }

            GetSalesOrdersResponse resp = new GetSalesOrdersResponse();
            resp.status = 'success';
            resp.salesOrders = result;

            RestContext.response.statusCode = 200;
            RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
            RestContext.response.responseBody = Blob.valueOf(serializeResponse(resp));

        } catch (Exception e) {
            returnError('Unexpected error: ' + e.getMessage(), 500);
        }
    }

    // ===== Mapper =====
    private static SalesOrderRecord toRecord(SalesOrder__c so,Map<Id, List<Document__c>> docsByCommissionId) {
        SalesOrderRecord r = new SalesOrderRecord();
        r.id = so.Id;
        r.orderNumber = so.Sales_Order_Number__c;
        r.salesManagerId = so.SalesManager__c;
        r.status = mapStatus(so.Status__c);  // Mapped status
        r.salesManagerName = (so.SalesManager__r != null) ? so.SalesManager__r.Name : null;
        r.customerName = (so.Opportunity__r != null && so.Opportunity__r.Account != null)
                            ? so.Opportunity__r.Account.Name : null;
        r.projectName = (so.Unit__r != null) ? so.Unit__r.ProjectName__c : null;
        r.unitType = (so.Unit__r != null) ? so.Unit__r.UnitType__c : null;
        r.unitName = (so.Unit__r != null) ? so.Unit__r.Name : null;
        r.lastModifiedDate = so.lastModifiedDate;
        // ===== Map Commissions =====
        r.commissions = new List<CommissionRecord>();
        if (so.Broker_Commissions__r != null) {
            for (BrokerCommission__c bc : so.Broker_Commissions__r) {
                CommissionRecord c = new CommissionRecord();
                c.id = bc.Id;
                c.commissionAmount = bc.CommissionAmount__c;
                c.commissionPercentage = bc.CommissionPercentage__c;
                c.vatPercentage = bc.VATPercentage__c;
                c.totalCommissionAmountWithVAT = bc.TotalCommissionAmountWithVAT__c;
                c.status  = bc.Status__c;
                c.installmentNumber = bc.InstallmentLine__r.InstallmentNumber__c;
                c.isFullPayment = bc.IsFullPayment__c;
                c.invoiceNumber = bc.Name;
                c.documents = new List<DocumentRecord>();
                if (docsByCommissionId.containsKey(bc.Id)) {
                    for (Document__c doc : docsByCommissionId.get(bc.Id)) {
                        DocumentRecord dr = new DocumentRecord();
                        dr.id = doc.Id;
                        dr.contentDocumentId = doc.ContentDocumentId__c;
                        dr.contentVersionId = doc.Content_Version_Id__c;
                        dr.name = (doc.DocumentType__r != null) ? doc.DocumentType__r.Type__c : null;
                        c.documents.add(dr);
                    }
                }
                r.commissions.add(c);
            }
        }
        return r;
    }
    // ===== Status Mapping =====
    @TestVisible
    private static String mapStatus(String rawStatus) {
        if (rawStatus == null) return null;

        Set<String> bookedSet   = new Set<String>{ 'Booked', 'Validation In Progress', 'Approve Pending', 'Reserved' };
        Set<String> soldSet     = new Set<String>{ 'Sold' };
        Set<String> cancelledSet= new Set<String>{ 'Cancelled', 'Book Cancelled' };

        if (bookedSet.contains(rawStatus)) return 'Booked';
        if (soldSet.contains(rawStatus)) return 'Sold';
        if (cancelledSet.contains(rawStatus)) return 'Cancelled';

        return rawStatus; // fallback if unmapped
    }
    
    // ===== JSON Serialization =====
    @TestVisible
    private static String serializeResponse(GetSalesOrdersResponse wrapper) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        writeStringOrNull(gen, 'status', wrapper.status);
        gen.writeFieldName('salesOrders');
        gen.writeStartArray();
        for (SalesOrderRecord so : wrapper.salesOrders) {
            gen.writeStartObject();
            writeStringOrNull(gen, 'id', so.id);
            writeStringOrNull(gen, 'orderNumber', so.orderNumber);
            writeStringOrNull(gen, 'salesManagerId', so.salesManagerId);
            writeStringOrNull(gen, 'status', so.status);
            writeStringOrNull(gen, 'salesManagerName', so.salesManagerName);
            writeStringOrNull(gen, 'customerName', so.customerName);
            writeStringOrNull(gen, 'projectName', so.projectName);
            writeStringOrNull(gen, 'unitType', so.unitType);
            writeStringOrNull(gen, 'unitName', so.unitName);
            writeDatetimeOrNull(gen, 'lastModifiedDate', so.lastModifiedDate);
            gen.writeFieldName('commissions');
            gen.writeStartArray();
            for (CommissionRecord c : so.commissions) {
                gen.writeStartObject();
                writeStringOrNull(gen, 'id', c.id);
                writeStringOrNull(gen, 'status', c.status);
                writeStringOrNull(gen, 'invoiceNumber', c.invoiceNumber);
                writeNumberOrNull(gen, 'commissionAmount', c.commissionAmount);
                writeNumberOrNull(gen, 'commissionPercentage', c.commissionPercentage);
                writeNumberOrNull(gen, 'vatPercentage', c.vatPercentage);
                writeNumberOrNull(gen, 'totalCommissionAmountWithVAT', c.totalCommissionAmountWithVAT);
                writeNumberOrNull(gen, 'installmentNumber', c.installmentNumber);
                writeBooleanOrNull(gen, 'isFullPayment', c.isFullPayment);
                //  Documents Array
                gen.writeFieldName('documents');
                gen.writeStartArray();
                for (DocumentRecord d : c.documents) {
                    gen.writeStartObject();
                    writeStringOrNull(gen, 'id', d.id);
                    writeStringOrNull(gen, 'contentDocumentId', d.contentDocumentId);
                    writeStringOrNull(gen, 'contentVersionId', d.contentVersionId);
                    writeStringOrNull(gen, 'name', d.name);
                    gen.writeEndObject();
                }
                gen.writeEndArray(); // End of documents
                gen.writeEndObject(); // End of commission
            }
            gen.writeEndArray(); // End of commissions
            gen.writeEndObject(); // End of sales order
         }
        gen.writeEndArray();
        gen.writeEndObject();
        return gen.getAsString();
    }

    // ===== JSON Helper Methods =====
    private static void writeStringOrNull(JSONGenerator gen, String field, String val) {
        if (val != null) gen.writeStringField(field, val); else gen.writeNullField(field);
    }
    private static void writeDateOrNull(JSONGenerator gen, String field, Date val) {
        if (val != null) gen.writeStringField(field, String.valueOf(val)); else gen.writeNullField(field);
    }
    private static void writeDatetimeOrNull(JSONGenerator gen, String field, Datetime val) {
        if (val != null) gen.writeStringField(field, String.valueOf(val)); else gen.writeNullField(field);
    }
    private static void writeNumberOrNull(JSONGenerator gen, String field, Decimal val) {
        if (val != null) gen.writeNumberField(field, val); else gen.writeNullField(field);
    }
    private static void writeBooleanOrNull(JSONGenerator gen, String field, Boolean val) {
        if (val != null) gen.writeBooleanField(field, val); else gen.writeNullField(field);
    }
    // ===== Build SOQL Query =====
    private static String buildSalesOrderQuery(String accountId, String contactId, String searchKey, FilterCriteria filters) {
        List<String> whereClause = new List<String>();
    
        Contact queryingContact = ContactService.getInstance().getContactById(contactId);
        //List<String> whereClause = new List<String>();
		// Privileged roles
		Set<String> privilegedRoles = new Set<String>{ 'Admin', 'Super Admin', 'CEO', 'Owner', 'Partner', 'AuthorizedSignatoryOfficer' };
        // Split the Contact’s roles
        Set<String> contactRoles = new Set<String>();
        if (String.isNotBlank(queryingContact.BrokerContactRole__c)) {
            contactRoles.addAll(queryingContact.BrokerContactRole__c.split(';'));
        }
       // Check if contact has any privileged role
        Boolean isPrivileged = false;
        for (String role : contactRoles) {
            if (privilegedRoles.contains(role.trim())) {
                isPrivileged = true;
                break;
            }
        }
       // Account filter
        if (String.isNotBlank(accountId)) {
            whereClause.add('Opportunity__r.BrokerAgencyAccount__c = \'' + String.escapeSingleQuotes(accountId) + '\'');
        }
        // Lead Channel filter (Broker Portal)
        whereClause.add(
            'Opportunity__r.Lead__r.lead_channel__c = \'Broker Portal\''
        );
        // If the user is NOT privileged, restrict to only their own records
        if (!isPrivileged) {
            whereClause.add('Opportunity__r.BrokerAgentContact__c = \'' + String.escapeSingleQuotes(contactId) + '\'');
        }

    
    
        // Search filter (Order Number + Customer Name)
        if (String.isNotBlank(searchKey)) {
            String likeSearchKey = '%' + String.escapeSingleQuotes(searchKey) + '%';
            whereClause.add('(Sales_Order_Number__c LIKE \'' + likeSearchKey + '\' OR Opportunity__r.Account.Name LIKE \'' + likeSearchKey + '\')');
        }
    
         // Status filter with mapping
        if (filters != null && String.isNotBlank(filters.status)) {
            Set<String> expandedStatuses = new Set<String>();
            for (String statusToken : filters.status.split(';')) {
                statusToken = statusToken.trim();
                expandedStatuses.addAll(BAPPGetSalesOrdersHandler.expandStatus(statusToken));
            }
            if (!expandedStatuses.isEmpty()) {
                List<String> quoted = new List<String>();
                for (String s : expandedStatuses) {
                    quoted.add('\'' + String.escapeSingleQuotes(s) + '\'');
                }
                whereClause.add('Status__c IN (' + String.join(quoted, ',') + ')');
            }
        }
    
        // Sales Manager filter
        if (filters != null && String.isNotBlank(filters.salesManagerId)) {
            Set<String> mgrIds = new Set<String>();
            for (String mgr : filters.salesManagerId.split(';')) {
                if (String.isNotBlank(mgr)) mgrIds.add(mgr.trim());
            }
            if (!mgrIds.isEmpty()) {
                List<String> quotedMgrs = new List<String>();
                for (String m : mgrIds) {
                    quotedMgrs.add('\'' + String.escapeSingleQuotes(m) + '\'');
                }
                whereClause.add('SalesManager__c IN (' + String.join(quotedMgrs, ',') + ')');
            }
        }
        // Date range filter (LastModifiedDate)
        if (filters != null) {
            if (filters.updatedOnFrom != null) {
                Datetime fromDT = Datetime.newInstance(filters.updatedOnFrom, Time.newInstance(0,0,0,0));
                whereClause.add('LastModifiedDate >= ' + fromDT.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            }
            if (filters.updatedOnTo != null) {
                Datetime toDT = Datetime.newInstance(filters.updatedOnTo, Time.newInstance(23,59,59,999));
                whereClause.add('LastModifiedDate <= ' + toDT.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            }
        }
    
        // Build base query
        String soql = 'SELECT Id, Sales_Order_Number__c, Status__c, SalesManager__c, LastModifiedDate, ' +
                      'SalesManager__r.Name, Opportunity__r.Account.Name, ' +
                      'Unit__r.Name, Unit__r.UnitType__c, Unit__r.ProjectName__c, ' +
                      '(SELECT Id, Name, CommissionAmount__c, CommissionPercentage__c, VATPercentage__c, ' +
                      'TotalCommissionAmountWithVAT__c, InstallmentLine__r.InstallmentNumber__c, ' +
                      'IsFullPayment__c, Status__c ' +
                      'FROM Broker_Commissions__r ' +
                      'WHERE Status__c IN (\'Shared\', \'Posted\', \'Payment Initiated\', \'Paid\')) ' +
                      'FROM SalesOrder__c';
    
        if (!whereClause.isEmpty()) {
            soql += ' WHERE ' + String.join(whereClause, ' AND ');
        }
    
        soql += ' ORDER BY LastModifiedDate DESC';
        return soql;
    }
    
    // ===== Helper: expand logical status to raw statuses =====
    public static Set<String> expandStatus(String logicalStatus) {
        Set<String> result = new Set<String>();
        if (String.isBlank(logicalStatus)) return result;
    
        if (logicalStatus.equalsIgnoreCase('Booked')) {
            result.addAll(new List<String>{ 'Booked', 'Validation In Progress', 'Approve Pending', 'Reserved' });
        } else if (logicalStatus.equalsIgnoreCase('Sold')) {
            result.add('Sold');
        } else if (logicalStatus.equalsIgnoreCase('Cancelled')) {
            result.addAll(new List<String>{ 'Cancelled', 'Book Cancelled' });
        } else {
            result.add(logicalStatus); // fallback
        }
        return result;
    }
    

    // ===== Error Response =====
    private static void returnError(String msg, Integer code) {
        RestContext.response.statusCode = code;
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(
            JSON.serializePretty(new Map<String, Object>{
                'status' => 'error',
                'message' => msg
            })
        );
    }
}