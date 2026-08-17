/*****************************************************************************************
Class       : DocGenController
Author      : Antriksh
Description : Docgen document generation controller
Created Date: 29 AUG 2024
Test Class  : UnitControllerTest
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0             13Jan2025           Initial Version 
*****************************************************************************************/
public class DocGenController {
    @AuraEnabled(cacheable=true)
    public static SalesOrder__c getSalesOrderRec(Id recordId){
        SalesOrderService service = SalesOrderService.getInstance();
        List<SalesOrder__c> soList = service.getSalesOrdersByIds(new Set<Id>{recordId});
        
        // Ensure the list is not empty and contains valid data
        if (!soList.isEmpty()) {
            SalesOrder__c salesOrder = soList[0];
            return salesOrder;
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static List<DocumentType__c> getDocgenSetupRecords(Id recordId) {
        List<DocumentType__c> docGenSetups = new List<DocumentType__c>();
        // Validate if the recordId is of type SalesOrder__c
        if (recordId != null && recordId.getSObjectType() == SalesOrder__c.SObjectType) {
            SalesOrderService service = SalesOrderService.getInstance();
            List<SalesOrder__c> soList = service.getSalesOrdersByIds(new Set<Id>{recordId});
            
            // Ensure the list is not empty and contains valid data
            if (!soList.isEmpty()) {
                SalesOrder__c salesOrder = soList[0];

                if (salesOrder.Unit__r != null && salesOrder.Unit__r.Project__c != null && salesOrder.Account__r.RecordType.DeveloperName != null) {
                    Boolean isResaleOrder = false;
                    if(salesOrder.IsDraftOrder__c || salesOrder.PreviousSalesOrder__c != NULL || salesOrder.Resale__c){
                        isResaleOrder = true;
                    }           
                    docGenSetups = [
                        SELECT Id, DeliveryOption__c, DocGenPackage__c, ObjectType__c, Active__c, Type__c, 
                            Project__r.Name, Project__c, ProcessType__c, Customer_Type__c, //Docusign_Envelope_Configuration_Document__c,
                            Docusign_Envelope_Docusign_Id__c, Docusign_Envelope_Template__c, Docusign_Envelope_Template__r.dfsle__DocuSignId__c, 
                            Document_Digital_Name__c, Document_Output_Name__c, Docusign_Envelope__c
                        FROM DocumentType__c 
                        WHERE Project__c = :salesOrder.Unit__r.Project__c 
                            AND Active__c = true AND IsDocgen__c = true
                            AND ObjectType__c = 'Sales Order' 
                            AND Resale__c = :isResaleOrder
                            AND (Customer_Type__c = :salesOrder.Account__r.RecordType.DeveloperName OR Customer_Type__c = 'All')
                    ];
                }
            }
        } else if(recordId != null && recordId.getSObjectType() == Handover__c.SObjectType){
            HandoverService hoService = HandoverService.getInstance();
            Handover__c hoRec = hoService.getHandoverRecordById(recordId);
            Id profileId = UserInfo.getProfileId();
            Profile userProfile = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
            if(hoRec.Project__c != NULL){
                docGenSetups = [
                        SELECT Id, DeliveryOption__c, DocGenPackage__c, ObjectType__c, Active__c, Type__c, 
                        Project__r.Name, Project__c, ProcessType__c, Customer_Type__c, //Docusign_Envelope_Configuration_Document__c,
                        Docusign_Envelope_Docusign_Id__c, Docusign_Envelope_Template__c, Docusign_Envelope_Template__r.dfsle__DocuSignId__c, 
                        Document_Digital_Name__c, Document_Output_Name__c, Docusign_Envelope__c
                        FROM DocumentType__c 
                        WHERE Active__c = true AND IsDocgen__c= true
                        	  //AND DigitalSignature__c = false
                              AND ObjectType__c = 'Handover'
                              //AND (HandoverStatus__c = :hoRec.Sub_Status__c OR HandoverStatus__c= '')
                              //AND (CurrentUserProfile__c = :userProfile.Name OR CurrentUserProfile__c= '')
                    ];
            }
        } else if(recordId != null && recordId.getSObjectType() == BrokerApplication__c.SObjectType){
            BrokerApplicationService service = BrokerApplicationService.getInstance();
            BrokerApplication__c baRec = service.getApplicationById(recordId);  // CORRECT

            
            docGenSetups = [
                SELECT Id, DeliveryOption__c, DocGenPackage__c, ObjectType__c, Active__c, Type__c, 
                Project__r.Name, Project__c, ProcessType__c, Customer_Type__c,
                Docusign_Envelope_Docusign_Id__c, Docusign_Envelope_Template__c, Docusign_Envelope_Template__r.dfsle__DocuSignId__c, 
                Document_Digital_Name__c, Document_Output_Name__c, Docusign_Envelope__c
                FROM DocumentType__c 
                WHERE Active__c = true AND IsDocgen__c= true
                AND DigitalSignature__c = false
                AND ObjectType__c = 'Broker Application' 
            ];
            
        } else if(recordId != null && recordId.getSObjectType() == Case.SObjectType){
            CaseService objCaseService = CaseService.getInstance();
            Case caseRec = objCaseService.getCaseById(recordId);

            List<String> resaleRecordTypeDevNameList = new List<String>{'Property_Transfer_Resale','Resale','Resale_Property_For_Completed_Project','Resale_Property_Under_Construction','Resale_Property_with_Post_Handover_Payment_Plan','Resale_Master'};
            
            String queryStr = 'SELECT Id, DeliveryOption__c, DocGenPackage__c, ObjectType__c, Active__c, Type__c, '
                                + 'Project__r.Name, ProjectCity__c, Project__c, ProcessType__c, Customer_Type__c, '
                                + 'Docusign_Envelope_Docusign_Id__c, Docusign_Envelope_Template__c, '
                                + 'Docusign_Envelope_Template__r.dfsle__DocuSignId__c, '
                                + 'Document_Digital_Name__c, Document_Output_Name__c, Docusign_Envelope__c '
                                + 'FROM DocumentType__c '
                                + 'WHERE Active__c = true AND IsDocgen__c= true '
                                + 'AND DigitalSignature__c = false '
                                + 'AND ObjectType__c = \'Case\' '
                                + 'AND RecordTypeDevName__c = \'' +caseRec.RecordType.DeveloperName+'\'';

            if(caseRec.CustomerType__c != NULL){
                String customerType = caseRec.CustomerType__c == 'Person' ? 'PersonAccount' : 'OrganizationAccount';
                queryStr  += ' AND (Customer_Type__c = \'' + customerType +'\' OR Customer_Type__c = \'All\')';
            } else {
                queryStr  += ' AND Customer_Type__c = \'All\'';
            }

            if(resaleRecordTypeDevNameList.contains(caseRec.RecordType.DeveloperName)){
                queryStr += ' AND (ProjectStatus__c = \'' + caseRec.ProjectStatus__c +'\' OR ProjectStatus__c = \'\')'
                            + ' AND (RegistrationStatus__c = \'' + caseRec.RegistrationStatus__c + '\' OR RegistrationStatus__c = \'\')'
                            + ' AND (TypeOfResale__c = \'' + caseRec.TypeOfResale__c + '\' OR TypeOfResale__c = \'\')';

                if(caseRec.Unit__r.Project__r.City__c == 'Dubai'){
                    //queryStr += ' AND ((ProjectCity__c = \'Dubai\' AND Type__c IN (\'NOC\', \'Buyers Undertaking\')) OR (Type__c IN (\'CIF\', \'Lost SPA Undertaking\')))';
                    queryStr += 'AND ((ProjectCity__c = \'Dubai\' AND (Type__c IN (\'NOC\', \'Buyers Undertaking\', \'Gifting NOC\', \'Gifting - Buyers Undertaking\') OR (Type__c  = \'JOPD\' AND (Project__c = \'' + caseRec.Project__c +'\' OR Project__c = null)))) OR (Type__c IN (\'CIF\', \'Lost SPA Undertaking\')))';
                } else {
                    //queryStr += ' AND ProjectCity__c = \'\'';
                    queryStr += ' AND ((Type__c = \'Community Management Statement\' AND (Project__c = \'' + caseRec.Project__c + '\' OR Project__c = null)) OR (Type__c NOT IN (\'Community Management Statement\') AND ProjectCity__c = \'\'))';
                }
            } else {
                queryStr += ' AND (Project__c = \'' + caseRec.Project__c +'\' OR Project__c = null)';
            }

            docGenSetups = Database.query(queryStr);
            
        } else if(recordId != null && recordId.getSObjectType() == Account.SObjectType){
            //AccountService accServiceObj = AccountService.getInstance();
            //Account accRec = accServiceObj.getAccountById(recordId);
            docGenSetups = [
                    SELECT Id, DeliveryOption__c, DocGenPackage__c, ObjectType__c, Active__c, Type__c, 
                    Project__r.Name, Project__c, ProcessType__c, Customer_Type__c, //Docusign_Envelope_Configuration_Document__c,
                    Docusign_Envelope_Docusign_Id__c, Docusign_Envelope_Template__c, Docusign_Envelope_Template__r.dfsle__DocuSignId__c, 
                    Document_Digital_Name__c, Document_Output_Name__c, Docusign_Envelope__c
                    FROM DocumentType__c 
                    WHERE Active__c = true AND IsDocgen__c= true
                            AND DigitalSignature__c = false
                            AND ObjectType__c = 'Account'
                ];
        }

        return docGenSetups;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<DocumentType__c> getDocumentTypeRecords(Id recordId) {
        List<DocumentType__c> docGenSetups = new List<DocumentType__c>();
        
        // Validate if the recordId is of type SalesOrder__c
        if (recordId != null && recordId.getSObjectType() == SalesOrder__c.SObjectType) {
            SalesOrderService service = SalesOrderService.getInstance();
            List<SalesOrder__c> soList = service.getSalesOrdersByIds(new Set<Id>{recordId});
            
            // Ensure the list is not empty and contains valid data
            if (!soList.isEmpty()) {
                SalesOrder__c salesOrder = soList[0];

                if (salesOrder.Unit__r != null && salesOrder.Unit__r.Project__c != null && salesOrder.Account__r.RecordType.DeveloperName != null) {
                    Boolean isResaleOrder = false;
                    if(salesOrder.IsDraftOrder__c || salesOrder.PreviousSalesOrder__c != NULL || salesOrder.Resale__c){
                        isResaleOrder = true;
                    }
                  
                    docGenSetups = [
                        SELECT Id, DeliveryOption__c, DocGenPackage__c, ObjectType__c, Active__c, Type__c, 
                        Project__r.Name, Project__c, ProcessType__c, Customer_Type__c, //Docusign_Envelope_Configuration_Document__c,
                        Docusign_Envelope_Docusign_Id__c, Docusign_Envelope_Template__c, Docusign_Envelope_Template__r.dfsle__DocuSignId__c, 
                        Document_Digital_Name__c, Document_Output_Name__c, Docusign_Envelope__c
                        FROM DocumentType__c 
                        WHERE Project__c = :salesOrder.Unit__r.Project__c 
                              AND Active__c = true AND IsDocgen__c= false
                        	  AND DigitalSignature__c = true
                              AND ObjectType__c = 'Sales Order' 
                              AND Resale__c = :isResaleOrder
                              AND (Customer_Type__c = :salesOrder.Account__r.RecordType.DeveloperName OR Customer_Type__c = 'All')
                    ];
                }
            }
        } else if (recordId != null && recordId.getSObjectType() == BrokerApplication__c.SObjectType) {
            BrokerApplicationService baService = BrokerApplicationService.getInstance();
            List<BrokerApplication__c> baList = baService.getApplicationByIds(new Set<Id>{recordId});
            BrokerApplication__c baRec = baList[0];
            

            // Extract the establishment type
            String establishmentType = baRec.TypeofEstablishment__c;
            
            // Ensure the list is not empty and contains valid data
            if (!baList.isEmpty()) {
                docGenSetups = [
                    SELECT Id, DeliveryOption__c, DocGenPackage__c, ObjectType__c, Active__c, Type__c, 
                    Project__r.Name, Project__c, ProcessType__c, Customer_Type__c, //Docusign_Envelope_Configuration_Document__c,
                    Docusign_Envelope_Docusign_Id__c, Docusign_Envelope_Template__c, Docusign_Envelope_Template__r.dfsle__DocuSignId__c, 
                    Document_Digital_Name__c, Document_Output_Name__c, Docusign_Envelope__c
                    FROM DocumentType__c 
                    WHERE Active__c = true AND IsDocgen__c= false
                    AND DigitalSignature__c = true
                    AND ObjectType__c = 'Broker Application' 
                    AND TypeofEstablishment__c = :establishmentType 
                ];
            }
        } else if(recordId != null && recordId.getSObjectType() == Handover__c.SObjectType){
            HandoverService hoService = HandoverService.getInstance();
            Handover__c hoRec = hoService.getHandoverRecordById(recordId);
            Id profileId = UserInfo.getProfileId();
            Profile userProfile = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
            if(hoRec.Project__c != NULL){
                docGenSetups = [
                        SELECT Id, DeliveryOption__c, DocGenPackage__c, ObjectType__c, Active__c, Type__c, 
                        Project__r.Name, Project__c, ProcessType__c, Customer_Type__c, //Docusign_Envelope_Configuration_Document__c,
                        Docusign_Envelope_Docusign_Id__c, Docusign_Envelope_Template__c, Docusign_Envelope_Template__r.dfsle__DocuSignId__c, 
                        Document_Digital_Name__c, Document_Output_Name__c, Docusign_Envelope__c
                        FROM DocumentType__c 
                        WHERE Active__c = true //AND IsDocgen__c= false
                        	  AND DigitalSignature__c = true
                              AND ObjectType__c = 'Handover'
                              //AND (HandoverStatus__c = :hoRec.Sub_Status__c OR HandoverStatus__c= '')
                              //AND (CurrentUserProfile__c = :userProfile.Name OR CurrentUserProfile__c= '')
                    ];
            }
        } else if(recordId != null && recordId.getSObjectType() == Case.SObjectType){
            Case caseRec = CaseService.getInstance().getCaseById(recordId);
            docGenSetups = [SELECT Id,DeliveryOption__c,DocGenPackage__c,ObjectType__c,Active__c,Type__c, Project__r.Name,
                            Project__c, ProcessType__c,Customer_Type__c,Docusign_Envelope_Docusign_Id__c,Docusign_Envelope_Template__c,
                            Docusign_Envelope_Template__r.dfsle__DocuSignId__c,Document_Digital_Name__c,Document_Output_Name__c,Docusign_Envelope__c
                            FROM DocumentType__c WHERE Active__c = true AND DigitalSignature__c = true AND ObjectType__c = 'Case' AND (Project__c = :caseRec.Project__c OR Project__c = NULL)];
        }
        
        return docGenSetups;
    }

    @AuraEnabled
    public static void generateDocument(Id deliveryOptionId, Id templateId, Id recordId, String documentName) {
		/***
		 * Generate Broker Agreement Number for the Agreement Document getting generated from Broker Application record
		 * during the onboarding of the Domestic or International Agency.
		 **/
        if(recordId != null && recordId.getSObjectType() == BrokerApplication__c.SObjectType){ 
        	generateAgreementNumberBrokerApplication(recordId);
        }
        
        String salesOrderReceivedAmountinwords = '';
        try {
            // Validate input parameters
            if (deliveryOptionId == null || templateId == null || recordId == null || documentName == null) {
                throw new IllegalArgumentException('Required parameters cannot be null.');
            }

            if(recordId != null && recordId.getSObjectType() == SalesOrder__c.SObjectType){
                SalesOrderService salesOrderService = SalesOrderService.getInstance();
                Map<Id,Salesorder__c> soMap = salesOrderService.getSalesOrdersMap(new Set<Id>{recordId});
                List<Document__c> docList = [SELECT Id, SalesOrder__c, Document_Name__c FROM Document__c WHERE SalesOrder__c =:recordId AND Document_Name__c =:documentName LIMIT 1];
                if(docList != NULL && docList.size() > 0){
                    String drawloopNextVal =  'SFSalesorder__c:'+recordId+';SFDocument__c:'+docList[0].Id+';DDPId:'+templateId+';Deploy:'+deliveryOptionId;
                    if(soMap != NULL && soMap.containsKey(recordId) && soMap.get(recordId).Drawloop_Next_1__c != NULL 
                        && soMap.get(recordId).Drawloop_Next_1__c.equalsIgnoreCase(drawloopNextVal)){
                        SalesOrder__c sorder1 = new SalesOrder__c(Id= recordId, Drawloop_Next_1__c = '');
                        SalesOrderTriggerHandler.isTriggerDisabled = true;
                        salesOrderService.updateSalesOrders(new List<SalesOrder__c>{sorder1});
                        SalesOrderTriggerHandler.isTriggerDisabled = false;
                    }
                    SalesOrder__c sorder = new SalesOrder__c(Id= recordId, Drawloop_Next_1__c = drawloopNextVal);
                    if(documentName.equalsIgnoreCase('Cancellation & Termination Agreement')){
                        salesOrderReceivedAmountinwords = DocGenController.getSalesOrderReceivedAmountInWords(recordId);
                        if(salesOrderReceivedAmountinwords != ''){
                            sorder.SalesOrderReceivedAmountinwords__c = salesOrderReceivedAmountinwords;
                        }
                    }
                    if(sorder!=null){
                        SalesOrderTriggerHandler.isTriggerDisabled = true;
                        salesOrderService.updateSalesOrders(new List<SalesOrder__c>{sorder});
                        SalesOrderTriggerHandler.isTriggerDisabled = false;
                    }
                }
            } else if(recordId != null && recordId.getSObjectType() == Handover__c.SObjectType){
                HandoverService hoService = HandoverService.getInstance();
                Handover__c hoRec = hoService.getHandoverRecordById(recordId);
                List<Document__c> docList = [SELECT Id, SalesOrder__c, Document_Name__c FROM Document__c WHERE Handover__c =:recordId AND Document_Name__c =:documentName LIMIT 1];
                if(docList != NULL && docList.size() > 0){
                    String drawloopNextVal =  'SFHandover__c:'+recordId+';SFDocument__c:'+docList[0].Id+';DDPId:'+templateId+';Deploy:'+deliveryOptionId;
                    if(hoRec != NULL && hoRec.Drawloop_Next_1__c != NULL && hoRec.Drawloop_Next_1__c.equalsIgnoreCase(drawloopNextVal)){
                        Handover__c hoRec1 = new Handover__c(Id= recordId, Drawloop_Next_1__c = '');
                        HandoverTriggerHandler.isTriggerDisabled = true;
                        hoService.updateHandovers(new List<Handover__c>{hoRec1});
                        HandoverTriggerHandler.isTriggerDisabled = false;
                    }
                    Handover__c hoRec2 = new Handover__c(Id= recordId, Drawloop_Next_1__c = drawloopNextVal);
                    if(hoRec2 !=null){
                        HandoverTriggerHandler.isTriggerDisabled = true;
                        hoService.updateHandovers(new List<Handover__c>{hoRec2});
                        HandoverTriggerHandler.isTriggerDisabled = false;
                    }
                }
            }
            else if(recordId != null && recordId.getSObjectType() == BrokerApplication__c.SObjectType){
                BrokerApplicationService baService = BrokerApplicationService.getInstance();
                //BrokerApplication__c brokerApp = [SELECT Id, Drawloop_Next_1__c FROM BrokerApplication__c WHERE Id = :recordId LIMIT 1];
                
                BrokerApplicationService service = BrokerApplicationService.getInstance();
                BrokerApplication__c brokerApp = service.getApplicationById(recordId);

                List<Document__c> docList = [SELECT Id, BrokerApplication__c, Document_Name__c FROM Document__c WHERE BrokerApplication__c =:recordId AND Document_Name__c =:documentName LIMIT 1];
                if(docList != null && docList.size() > 0){
                    String drawloopNextVal =  'SFBrokerApplication__c:'+recordId+';SFDocument__c:'+docList[0].Id+';DDPId:'+templateId+';Deploy:'+deliveryOptionId;
                    if(brokerApp != null && brokerApp.Drawloop_Next_1__c != null && brokerApp.Drawloop_Next_1__c.equalsIgnoreCase(drawloopNextVal)){
                        /*BrokerApplication__c baReset = new BrokerApplication__c(Id = recordId, Drawloop_Next_1__c = '');
                        update baReset;*/
                        baService.resetDrawloopNext(recordId);

                    }
                    /*BrokerApplication__c baUpdate = new BrokerApplication__c(Id = recordId, Drawloop_Next_1__c = drawloopNextVal);
                    update baUpdate;*/
                    baService.updateDrawloopNext(recordId, drawloopNextVal);
                }
            } else if(recordId != null && recordId.getSObjectType() == Case.SObjectType){
                CaseService objCaseService = CaseService.getInstance();
                Case caseRec = objCaseService.getCaseById(recordId);
                List<Document__c> docList = [SELECT Id, SalesOrder__c, Case__c, Document_Name__c FROM Document__c WHERE Case__c =:recordId AND Document_Name__c =:documentName LIMIT 1];
                if(docList != NULL && docList.size() > 0){
                    String drawloopNextVal =  'SFCase:'+recordId+';SFDocument__c:'+docList[0].Id+';DDPId:'+templateId+';Deploy:'+deliveryOptionId;
                    if(caseRec != NULL && caseRec.Drawloop_Next_1__c != NULL && caseRec.Drawloop_Next_1__c.equalsIgnoreCase(drawloopNextVal)){
                        Case caseRec1 = new Case(Id= recordId, Drawloop_Next_1__c = '');
                        objCaseService.updateCaseWithoutTrigger(new List<Case>{caseRec1});
                    }
                    Case caseRec2 = new Case(Id= recordId, Drawloop_Next_1__c = drawloopNextVal);
                    if(caseRec2 !=null){
                        objCaseService.updateCaseWithoutTrigger(new List<Case>{caseRec2});
                    }
                }
            } else if(recordId != null && recordId.getSObjectType() == Account.SObjectType){
                AccountService accServiceObj = AccountService.getInstance();
                Account accRec = accServiceObj.getAccountById(recordId);
                List<Document__c> docList = [SELECT Id, SalesOrder__c, Account__c, Document_Name__c FROM Document__c WHERE Account__c =:recordId AND Document_Name__c =:documentName LIMIT 1];
                if(docList != NULL && docList.size() > 0){
                    String drawloopNextVal =  'SFAccount:'+recordId+';SFDocument__c:'+docList[0].Id+';DDPId:'+templateId+';Deploy:'+deliveryOptionId;
                    if(accRec != NULL && accRec.Drawloop_Next_1__c != NULL && accRec.Drawloop_Next_1__c.equalsIgnoreCase(drawloopNextVal)){
                        Account accRec1 = new Account(Id= recordId, Drawloop_Next_1__c = '');
                        AccountTriggerHandler.isTriggerDisabled = true;
                        accServiceObj.updateAccounts(new List<Account>{accRec1});
                        AccountTriggerHandler.isTriggerDisabled = false;
                    }
                    Account accRec2 = new Account(Id= recordId, Drawloop_Next_1__c = drawloopNextVal);
                    if(accRec2 !=null){
                        AccountTriggerHandler.isTriggerDisabled = true;
                        accServiceObj.updateAccounts(new List<Account>{accRec2});
                        AccountTriggerHandler.isTriggerDisabled = false;
                    }
                }
            }
        } catch (Exception ex) {
            // Catch-all for any other exceptions
            throw new AuraHandledException('An unexpected error occurred. Please contact your administrator.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static SalesOrder__c getSalesOrderRecord(Id recordId){
        try {
            SalesOrderService service = SalesOrderService.getInstance();
            List<SalesOrder__c> soList = service.getSalesOrdersByIds(new Set<Id>{recordId});
            return soList[0];
        } catch (Exception e) {
            //throw new AuraHandledException(e.getMessage());
            return (new SalesOrder__c());
        }
    }
     // BAPP
     @AuraEnabled(cacheable=true)
    public static BrokerApplication__c getBrokerApplicationRecord(Id recordId){
        try {
        
            BrokerApplicationService service = BrokerApplicationService.getInstance();
            List<BrokerApplication__c> baList = service.getApplicationByIds(new Set<Id>{ recordId });

            return baList[0];
        } catch (Exception e) {
            //throw new AuraHandledException(e.getMessage());
            return (new BrokerApplication__c());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Handover__c getHandoverRecord(Id recordId){
        try {
            HandoverService objHandoverService = HandoverService.getInstance();
            List<Handover__c> hoList = objHandoverService.getHandoverByIds(new Set<Id>{recordId});
            return hoList[0];
        } catch (Exception e) {
            //throw new AuraHandledException(e.getMessage());
            return (new Handover__c());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Case getCaseRecord(Id recordId){
        try {
            CaseService objCaseService = CaseService.getInstance();
            List<Case> caseList = objCaseService.getCaseByIds(new Set<Id>{recordId});
            return caseList[0];
        } catch (Exception e) {
            return (new Case());
        }
    }

    @AuraEnabled
    public static List<Document_and_Email_Templates__c> getDocumentAndEmailTemplateRecords(SalesOrder__c salesOrderRec){
        List<Document_and_Email_Templates__c> docEmailTemp = new List<Document_and_Email_Templates__c>();
        try {
            docEmailTemp = [
                        SELECT Id
                        FROM Document_and_Email_Templates__c 
                        WHERE Project__c = :salesOrderRec.Unit__r.Project__c 
                              //AND Docomotion_Form_Type__c = 
                    ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return docEmailTemp;
    }

    public static String getSalesOrderReceivedAmountInWords(Id recordId){
        String salesOrderReceivedAmountinwords = '';
        SalesOrderService service = SalesOrderService.getInstance();
        List<SalesOrder__c> soList = service.getSalesOrdersByIds(new Set<Id>{recordId});
        if (!soList.isEmpty()) {
            SalesOrder__c salesOrder = soList[0];
            if (salesOrder.Sales_Order_Received_Amount__c != null) {
                //salesOrder.SalesOrderReceivedAmountinwords__c=   Utilities.amountInWords(salesOrder.Sales_Order_Received_Amount__c,'Dirham','Fils');
                salesOrderReceivedAmountinwords = Utilities.amountInWords(salesOrder.Sales_Order_Received_Amount__c,'Dirham','Fils');
                ConverNumbertoArabicText.fetchConvertedResponse(new List<id>{recordId});
            }
            //update salesOrder;
        }
        return salesOrderReceivedAmountinwords;
    }

    @AuraEnabled
    public static void sendForSignature(SalesOrder__c salesOrderRec, List<DocumentType__c> documentTypeRecords) {
        MetadataService objMetadataService = MetadataService.getInstance();
        //String projectList = objMetadataService.getAppSettingTextValue('DocuSignProjectsRoutingRule');
        
        Map<Id,String> documentTypeIdToDocumentNameMap = new Map<Id, String>();
        
        for(DocumentType__c dtRec : documentTypeRecords){
            documentTypeIdToDocumentNameMap.put(dtRec.Id, dtRec.Type__c);
        }

        List<Document__c> documentsList = [select Id, ContentDocumentId__c, Document_Name__c FROM Document__c 
                                            WHERE SalesOrder__c =: salesOrderRec.Id 
                                            AND Document_Name__c =: documentTypeIdToDocumentNameMap.values() ];
        Map<String, Id> documentIdToDocumentNameMap = new Map<String, Id>();
        for(Document__c docRec : documentsList){
            documentIdToDocumentNameMap.put(docRec.Document_Name__c, docRec.Id);
        }

        for(DocumentType__c dtRec : documentTypeRecords){
            String docusignenvid = dtRec.Docusign_Envelope_Template__r.dfsle__DocuSignId__c; //dtRec.Docusign_Envelope__c; //dtRec.Docusign_Envelope_Template__c;
            Id documentRecId = documentIdToDocumentNameMap.get(dtRec.Type__c); 
            Id salesorderid = salesOrderRec.Id;
            String PropertyName = salesOrderRec.ProjectName__c;
            String unitNumber = salesOrderRec.UnitNumber__c;
            String emailSubject = 'Documents for your Signature |'+' '+PropertyName+'-'+unitNumber;
            string docoutputname = dtRec.Document_Output_Name__c;
            string descrip = dtRec.Document_Digital_Name__c; // Needs to be changed.
            
            /* if(PropertyName != NULL){
                if(projectList.containsIgnoreCase(PropertyName)){
                    System.debug('ALMERIA ROUTING');
                    BldocusignSpacls.BlsendSPAEnvelope(docusignenvid, descrip, documentRecId, salesorderid, docoutputname,emailSubject);
                } else {
                    Bldocusigncls.BlsendSPAEnvelope(docusignenvid, descrip, documentRecId, salesorderid, docoutputname,emailSubject);
                }
            } */

            System.enqueueJob(new DocuSignQueueable('Sales Order', docusignenvid, descrip, documentRecId, salesorderid, docoutputname, emailSubject));
        }
    }

    // BAPP : Generate Agreement Number
    /**
     * Generate Agreement Number and update the same on Broker Application record 
     * @param brokerAppId Broker Application record Id that is under consideration
     * @return None
     */
    @AuraEnabled
    public static void generateAgreementNumberBrokerApplication(Id brokerAppId) {
        BrokerApplication__c objBrokerApplication = BrokerApplicationService.getInstance().getApplicationById(brokerAppId);
        if(objBrokerApplication != null ) {
            //For Domestic Agency
        	if ( objBrokerApplication.TradeLicenseNumber__c != null || objBrokerApplication.CommercialLicenseNumber__c != null ) {
                objBrokerApplication.Id = objBrokerApplication.Id; 
                objBrokerApplication.AgreementNumber__c = createAgreementNumberBrokerApplication(objBrokerApplication);
                If(objBrokerApplication.AgreementInitiationdate__c==null) {
                	objBrokerApplication.AgreementInitiationdate__c = Date.TODAY();    
                }
                List<BrokerApplication__c> brokerApplicationsToUpdate = new List<BrokerApplication__c>();
                brokerApplicationsToUpdate.add(objBrokerApplication);
                BrokerApplicationService.getInstance().updateBrokerApplications(brokerApplicationsToUpdate);
            }    
        }   
        
    }
    
    // BAPP : Create Agreement Number
    /**
     * Create Agreement Number with combination of Agency Name and Trade License and current date 
     * @param objBrokerApplication Broker Application that is under consideration
     * @return Broker Agreement Number
     */
    public static String createAgreementNumberBrokerApplication(BrokerApplication__c objBrokerApplication) {
        String agreementNumber='';
        if(objBrokerApplication.TypeofEstablishment__c == 'Domestic' && String.isNotBlank(objBrokerApplication.Name) && String.isNotBlank(objBrokerApplication.TradeLicenseNumber__c)) {
        	// Get first 4 characters of Agency Name in UPPERCASE without space
        	String agencyName = objBrokerApplication.Name.replaceAll('\\s+', '').trim();
            String firstPart = agencyName.length() >= 4 
            ? agencyName.substring(0,4).toUpperCase()
            : agencyName.toUpperCase(); 
    
            // Get last 4 characters of Trade License Number
            String secondPart = objBrokerApplication.TradeLicenseNumber__c.trim().length() >= 4 
                ? objBrokerApplication.TradeLicenseNumber__c.trim().substring(objBrokerApplication.TradeLicenseNumber__c.length()-4)
                : objBrokerApplication.TradeLicenseNumber__c.trim(); // if trade license < 4 chars
    
            // Get current date in DDMMYY format
            //Date today = Date.today();
            String thirdPart = Datetime.now().format('ddMMyy');
            
            agreementNumber = firstPart + secondPart + thirdPart;          
                
        }  // International
        else if (objBrokerApplication.TypeofEstablishment__c == 'International' 
             && String.isNotBlank(objBrokerApplication.Name) 
             && String.isNotBlank(objBrokerApplication.CommercialLicenseNumber__c)) {
        
            // Remove spaces before picking first 4 chars
            String agencyName = objBrokerApplication.Name.replaceAll('\\s+', '').trim();
            
            String firstPart = agencyName.length() >= 4 
                ? agencyName.substring(0,4).toUpperCase()
                : agencyName.toUpperCase(); 
            
            String secondPart = objBrokerApplication.CommercialLicenseNumber__c.trim().length() >= 4 
                ? objBrokerApplication.CommercialLicenseNumber__c.trim().substring(objBrokerApplication.CommercialLicenseNumber__c.length()-4)
                : objBrokerApplication.CommercialLicenseNumber__c.trim();
            
            String thirdPart = Datetime.now().format('ddMMyy');
            
            agreementNumber = firstPart + secondPart + thirdPart;
        }
        
        return agreementNumber;
    }
    
       // BappDocuSign-
    @AuraEnabled
    public static void sendForBappSignature(Id brokerAppId, List<DocumentType__c> documentTypeRecords) {
    

        if (brokerAppId == null) {
            throw new AuraHandledException('BrokerApplication Id was not provided.');
        }

        List<BrokerApplication__c> bappList = BrokerApplicationService.getInstance().getApplicationByIds(new Set<Id>{ brokerAppId });

        BrokerApplication__c BappRec = bappList.isEmpty() ? null : bappList[0];

        MetadataService objMetadataService = MetadataService.getInstance();
        String projectList = objMetadataService.getAppSettingTextValue('DocuSignProjectsRoutingRule');
        
        Map<Id,String> documentTypeIdToDocumentNameMap = new Map<Id, String>();
        for(DocumentType__c dtRec : documentTypeRecords){
            documentTypeIdToDocumentNameMap.put(dtRec.Id, dtRec.Type__c);
        }
        List<Document__c> documentsList = [select Id, ContentDocumentId__c, Document_Name__c FROM Document__c 
                                            WHERE BrokerApplication__c =: BappRec.Id 
                                            AND Document_Name__c IN :documentTypeIdToDocumentNameMap.values() ];
        
        Map<String, Id> documentIdToDocumentNameMap = new Map<String, Id>();
        for(Document__c docRec : documentsList){
            documentIdToDocumentNameMap.put(docRec.Document_Name__c, docRec.Id);
        }

        for(DocumentType__c dtRec : documentTypeRecords){
            String docusignenvid = dtRec.Docusign_Envelope_Template__r.dfsle__DocuSignId__c; //dtRec.Docusign_Envelope__c; //dtRec.Docusign_Envelope_Template__c;
            Id documentRecId = documentIdToDocumentNameMap.get(dtRec.Type__c); 
            Id bappId = BappRec.Id;
            String emailSubject = 'Documents for your Signature ';
            string docoutputname = dtRec.Document_Output_Name__c;
            string descrip = dtRec.Document_Digital_Name__c;
            
            //BAPPDocuSignHandler.BlsendSPAEnvelope(docusignenvid, descrip, documentRecId, bappId, docoutputname,emailSubject) ;
            System.enqueueJob(new DocuSignQueueable('Broker Application', docusignenvid, descrip, documentRecId, bappId, docoutputname, emailSubject));
        }
    }
    @AuraEnabled
    public static void updateApprovalStatusToUnderAgreement(Id brokerAppId) {
        BrokerApplication__c bapp = [SELECT Id, ApprovalStatus__c FROM BrokerApplication__c WHERE Id = :brokerAppId LIMIT 1];
        bapp.ApprovalStatus__c = 'Under Agreement';
        update bapp;
    }

    @AuraEnabled
    public static void sendHandoverDocForSignature(Id handoverId, List<DocumentType__c> documentTypeRecords) {
    

        if (handoverId == null) {
            throw new AuraHandledException('Handover Id was not provided.');
        }

        HandoverService objHandoverService = HandoverService.getInstance();
        List<Handover__c> hoList = objHandoverService.getHandoverByIds(new Set<Id>{handoverId});
        
        Handover__c hoRec = hoList.isEmpty() ? null : hoList[0];
        
        Map<Id,String> documentTypeIdToDocumentNameMap = new Map<Id, String>();
        for(DocumentType__c dtRec : documentTypeRecords){
            documentTypeIdToDocumentNameMap.put(dtRec.Id, dtRec.Type__c);
        }
        List<Document__c> documentsList = [select Id, ContentDocumentId__c, Document_Name__c FROM Document__c 
                                            WHERE Handover__c =: hoRec.Id 
                                            AND Document_Name__c IN :documentTypeIdToDocumentNameMap.values() ];
        
        Map<String, Id> documentIdToDocumentNameMap = new Map<String, Id>();
        for(Document__c docRec : documentsList){
            documentIdToDocumentNameMap.put(docRec.Document_Name__c, docRec.Id);
        }

        for(DocumentType__c dtRec : documentTypeRecords){
            String docusignenvid = dtRec.Docusign_Envelope_Template__r.dfsle__DocuSignId__c; //dtRec.Docusign_Envelope__c; //dtRec.Docusign_Envelope_Template__c;
            Id documentRecId = documentIdToDocumentNameMap.get(dtRec.Type__c); 
            Id hoId = hoRec.Id;
            String emailSubject = 'Documents for your Signature ';
            string docoutputname = dtRec.Document_Output_Name__c;
            string descrip = dtRec.Document_Digital_Name__c;
            
            //HandoverDocuSignConfig.sendHandoverEnvelopes(docusignenvid, descrip, documentRecId, hoId, docoutputname, emailSubject) ;
            System.enqueueJob(new DocuSignQueueable('Handover', docusignenvid, descrip, documentRecId, hoId, docoutputname, emailSubject));
        }
    }
    
    @AuraEnabled
    public static void sendCaseDocForSignature(Id caseId, List<DocumentType__c> documentTypeRecords) {    

        if (caseId == null) {
            throw new AuraHandledException('Case Id was not provided.');
        }

        CaseService objCaseService = CaseService.getInstance();
        List<Case> caseList = objCaseService.getCaseByIds(new Set<Id>{caseId});
        
        Case caseRec = caseList.isEmpty() ? null : caseList[0];
        Map<Id,String> documentTypeIdToDocumentNameMap = new Map<Id, String>();
        for(DocumentType__c dtRec : documentTypeRecords){
            documentTypeIdToDocumentNameMap.put(dtRec.Id, dtRec.Type__c);
        }
        List<Document__c> documentsList = [select Id, ContentDocumentId__c, Document_Name__c FROM Document__c 
                                            WHERE Case__c =: caseRec.Id 
                                            AND Document_Name__c IN :documentTypeIdToDocumentNameMap.values() ];

        Map<String, Id> documentIdToDocumentNameMap = new Map<String, Id>();
        for(Document__c docRec : documentsList){
            documentIdToDocumentNameMap.put(docRec.Document_Name__c, docRec.Id);
        }

        for(DocumentType__c dtRec : documentTypeRecords){
            String docusignenvid = dtRec.Docusign_Envelope_Template__r.dfsle__DocuSignId__c; //dtRec.Docusign_Envelope__c; //dtRec.Docusign_Envelope_Template__c;
            Id documentRecId = documentIdToDocumentNameMap.get(dtRec.Type__c); 
            Id recordId = caseRec.Id;
            String emailSubject = 'Documents for your Signature ';
            string docoutputname = dtRec.Document_Output_Name__c;
            string descrip = dtRec.Document_Digital_Name__c;
            
            //CaseDocuSignConfig.sendCaseEnvelopes(docusignenvid, descrip, documentRecId, recordId, docoutputname, emailSubject) ;
            System.enqueueJob(new DocuSignQueueable('Case', docusignenvid, descrip, documentRecId, recordId, docoutputname, emailSubject));
        }
    }
}