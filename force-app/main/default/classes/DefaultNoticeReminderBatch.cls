/*****************************************************************************************
Class       : DefaultNoticeReminderBatch
Author      :  Jhilik
Description : 
test Class  : DefaultNoticeReminderBatchTest
Created Date: 11-Jun-2025
*****************************************************************************************/
public without sharing class DefaultNoticeReminderBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_GENERAL_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'DefaultNoticeGeneralPaymentReminderTemp'; } }
    private static final string MTD_GENERAL_BOUNCE_CHEQUE_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'DefaultNoticeGenBounceChequeReminderTemp'; } }
    private static final string MTD_LAST_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'DefaultNoticeLastPaymentReminderTemp'; } }
    private static final string MTD_LAST_BOUNCE_CHEQUE_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'DefaultNoticeLastBounceChequeReminderTem'; } }
    
    private static final string MTD_SALES_ORDER_STATUS_VALUE { get { return 'SalesOrderStatusforPendingPayment'; } }
    private static final string MTD_COLLECTION_TEAM_QUEUE_ID { get { return 'CollectionTeamQueueId'; } }
    private static final string SERVICE_CATALOG_NAME_FOR_DEFAULT_UNIT { get { return 'Service-Request-Default-Unit'; } }
    private static final string ADHOC_RUN_INSTALMENT_IDS { get { return 'DefaultNoticeBatchAdHocRun'; } }

    public Database.QueryLocator start(Database.BatchableContext bc) { 
        MetadataService objMetadataService = MetadataService.getInstance();
        //String salesOrderStatusValue = objMetadataService.getAppSettingTextValue(MTD_SALES_ORDER_STATUS_VALUE);
        //List<String> salesOrderStatusValueList = salesOrderStatusValue.split(',');
        String batchAdHocRunIds = objMetadataService.getAppSettingTextValue(ADHOC_RUN_INSTALMENT_IDS);
        List<String> installmentIdList = batchAdHocRunIds != NULL && batchAdHocRunIds != '' ? batchAdHocRunIds.split(',') : NULL;
        String queryInstalmentLines = 'SELECT Id, Name, Description__c, SalesOrder__c FROM InstallmentLines__c WHERE SalesOrder__r.Status__c = \'Sold\' AND SalesOrder__r.LegalStatus__c != \'With Legal\' AND SalesOrder__r.Unit__r.Project__r.SendDefaultNotice__c = TRUE AND Due_Date__c <= TODAY AND PendingAmount__c > 1';
        
        if(installmentIdList != NULL){
            queryInstalmentLines += ' AND Id IN :installmentIdList';
        }
        queryInstalmentLines += ' Order By SalesOrder__c';

        List<InstallmentLines__c> installmentLinesList = Database.query(queryInstalmentLines);

        Set<Id> salesOrderIdSet = new Set<Id>();
        for (InstallmentLines__c instalmentLineRec : installmentLinesList) {
            salesOrderIdSet.add(instalmentLineRec.SalesOrder__c);
        }

        List<Case> resaleCaseList = [SELECT Id, RecordType.Name,RecordType.DeveloperName,Sales_Order__c 
                                        FROM Case 
                                        WHERE Sales_Order__c IN :salesOrderIdSet 
                                        AND RecordType.DeveloperName IN ('Resale', 'Resale_Master', 'Resale_Property_For_Completed_Project', 'Resale_Property_Under_Construction', 'Resale_Property_with_Post_Handover_Payment_Plan')];

        for(Case resaleCaseRec : resaleCaseList){
            if(salesOrderIdSet.contains(resaleCaseRec.Sales_Order__c)){
                salesOrderIdSet.remove(resaleCaseRec.Sales_Order__c);
            }
        }

        String query = 'SELECT Id, Unit__c, Account__c, Drawloop_Next_1__c, Name,'
                        +' Unit__r.Project__r.DefaultUnpaidAmount__c, Unit__r.Project__r.ResaleUnitAdminFeeVilla__c,'
                        +' Unit__r.Project__r.ResaleUnitEvaluationFeeVilla__c, Unit__r.Project__r.ResaleUnitAdminFeeApt__c,'
                        +' Unit__r.Project__r.ResaleUnitEvaluationFeeApt__c,Unit__r.Project__r.ResaleWithMortgageAdminFeeVilla__c,'
                        +' Unit__r.Project__r.ResaleWithMortgageMortgageFeeVilla__c,'
                        +' Unit__r.Project__r.ResaleWithMortgageEvaluationFeeVilla__c,'
                        +' Unit__r.Project__r.ResaleWithMortgageAdminFeeApt__c,'
                        +' Unit__r.Project__r.ResaleWithMortgageMortgageFeeApt__c,Unit__r.Project__r.ResaleWithMortgageEvaluationFeeApt__c,'
                        +' Unit__r.Project__r.DefaultUnpaidAmountPercentage__c, PostDueDateReminderSentDate__c,'
                        +' Sales_Order_Pending_Amount__c, DefaultCustomerLastReminderSentDate__c,'
                        +' Unit__r.Project__r.Name, PHPP__c, Unit__r.Project__r.City__c, Unit__r.Project__r.SendDefaultNotice__c,'
                        +' Unit__r.Name, Account__r.Name, Account__r.isPersonAccount, Account__r.PersonContactId,'
                        +' Account__r.PersonContact.Name, Account__r.NameinArabic__c, Account__r.PersonMobilePhone, Contact__c,'
                        +' Contact__r.Name, Status__c, Unit__r.Project__c, Unit__r.Project__r.ProjectNameArabic__c,'
                        +' Unit__r.BuildingSectionName__r.Primary_Account_Installment__c,'
                        +' Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c,'
                        +' Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c,'
                        +' CustomerDefaultStatus__c, Unit__r.Project__r.DefaultNotificationDays__c, Unit__r.Project__r.AdminFee__c,'
                        +' SellingPrice__c,Resale__c'
                        +' FROM SalesOrder__c '
                        +' WHERE Id IN :salesOrderIdSet';
        
        return Database.getQueryLocator(query);
    }

    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DefaultNoticeReminderBatch(), 1);
    }

    public void execute(Database.BatchableContext bc, List<SalesOrder__c> scope){
        
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        BankAccountService objBankAccountService = BankAccountService.getInstance();
        SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
        CaseService objCaseService = CaseService.getInstance();
        AccountService objAccountService = AccountService.getInstance();
        DocumentService objDocumentService = DocumentService.getInstance();
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        Id regularPaymentReminderETId = objMetadataService.getAppSettingTextValue(MTD_GENERAL_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID);
        Id finalPaymentReminderETId = objMetadataService.getAppSettingTextValue(MTD_LAST_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID);
        Id regularBounceChequeReminderETId = objMetadataService.getAppSettingTextValue(MTD_GENERAL_BOUNCE_CHEQUE_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID);
        Id finalBounceChequeReminderETId = objMetadataService.getAppSettingTextValue(MTD_LAST_BOUNCE_CHEQUE_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID);
        Id collectionTeamId = objMetadataService.getAppSettingTextValue(MTD_COLLECTION_TEAM_QUEUE_ID);

        Map<Id,List<InstallmentLines__c>> salesOrderIdToInstallmentListMap = new Map<Id,List<InstallmentLines__c>>();
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();
        Map<Id, BankAccount__c> bankMap = new Map<Id, BankAccount__c>();
        Map<Id,Double> salesOrderIdToPendingAmountMap = new Map<Id,Double>();
        Map<Id,Date> salesOrderIdToOldestInstallmentDueDateMap = new Map<Id,Date>();
        Set<Id> setBankAccountIds = new Set<Id>();
        Date currentDate = Date.today();
        Set<Id> salesordersToupdateSet = new Set<Id>();
        Map<Id,SalesOrder__c> salesordersToupdateMap = new Map<Id,SalesOrder__c>();
        List<Account> accountsToUpdate = new List<Account>();
        Map<Id,Case> soIdToCaseToInsert = new Map<Id,Case>();
        Map<Id,Case> soIdToCaseToUpdate = new Map<Id,Case>();
        Map<Id,ReceiptAllocation__c> installmentIdToReceiptAllocationMap = new Map<Id,ReceiptAllocation__c>();
        Map<Id,ReceiptAllocation__c> salesOrderIdToReceiptAllocationMap = new Map<Id, ReceiptAllocation__c>();
        Set<Id> relatedDefaultUnitSRToBeUpdated = new Set<Id>();
        Set<Id> salesOrderIdsForRegularReminder = new Set<Id>();
        Set<Id> salesOrderIdsForLastReminder = new Set<Id>();
        List<Case> defaultCases = new List<Case>();
        Set<Id> installmentLineIds = new Set<Id>();
        Map<Id,Case> salesOrderIdToExistingDefaultUnitCaseMap = new Map<Id,Case>();
        Set<Id> salesOrderIdList = new Set<Id>();
        Map<Id,SalesOrder__c> salesOrderMap = new Map<Id,SalesOrder__c>();

        EmailTemplate regularPaymentReminderTemplate = objEmailService.getEmailTemplateById(regularPaymentReminderETId);
        EmailTemplate regularBounceChequeReminderTemplate = objEmailService.getEmailTemplateById(regularBounceChequeReminderETId);
        EmailTemplate finalPaymentReminderTemplate = objEmailService.getEmailTemplateById(finalPaymentReminderETId);
        EmailTemplate finalBounceChequeReminderTemplate = objEmailService.getEmailTemplateById(finalBounceChequeReminderETId);
        List<ServiceCatalog__c> seviceCatalogRecord = servObj.getServiceCatalogByName(SERVICE_CATALOG_NAME_FOR_DEFAULT_UNIT);

        for(SalesOrder__c so : scope){
            salesOrderIdList.add(so.Id);
            salesOrderMap.put(so.Id,so);
        }

        List<InstallmentLines__c> installmentLinesList = [SELECT Id, Name, Description__c, SalesOrder__c, 
                                                            SalesOrder__r.Unit__r.Project__r.DefaultUnpaidAmount__c, 
                                                            SalesOrder__r.Unit__r.Project__r.DefaultUnpaidAmountPercentage__c, 
                                                            SalesOrder__r.PostDueDateReminderSentDate__c, 
                                                            SalesOrder__r.Sales_Order_Pending_Amount__c, 
                                                            SalesOrder__r.Unit__r.Project__r.Name, SalesOrder__r.PHPP__c, 
                                                            SalesOrder__r.Unit__r.Project__r.City__c, 
                                                            SalesOrder__r.Unit__r.Project__r.SendDefaultNotice__c, 
                                                            SalesOrder__r.Unit__r.Name, SalesOrder__r.Account__c, 
                                                            SalesOrder__r.Account__r.Name, SalesOrder__r.Account__r.isPersonAccount, 
                                                            SalesOrder__r.Account__r.PersonContactId, 
                                                            SalesOrder__r.Account__r.PersonContact.Name, 
                                                            SalesOrder__r.Account__r.NameinArabic__c, 
                                                            SalesOrder__r.Account__r.PersonMobilePhone, 
                                                            SalesOrder__r.Contact__c, SalesOrder__r.Contact__r.Name, 
                                                            SalesOrder__r.Status__c, PendingAmount__c, InstallmentDate__c, 
                                                            Due_Date__c, SalesOrder__r.Unit__r.Project__c, 
                                                            SalesOrder__r.Unit__r.Project__r.ProjectNameArabic__c, InstallmentNumber__c, 
                                                            SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c, 
                                                            SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c, 
                                                            SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c, 
                                                            Type__c, SalesOrder__r.CustomerDefaultStatus__c, 
                                                            SalesOrder__r.Unit__r.Project__r.DefaultNotificationDays__c 
                                                            FROM InstallmentLines__c 
                                                            WHERE SalesOrder__c IN :salesOrderIdList];
        for (InstallmentLines__c pi : installmentLinesList) {
            if(!salesOrderIdToInstallmentListMap.containsKey(pi.SalesOrder__c)){
                salesOrderIdToInstallmentListMap.put(pi.SalesOrder__c, new List<InstallmentLines__c>());
            }
            salesOrderIdToInstallmentListMap.get(pi.SalesOrder__c).add(pi);

            //if(pi.PendingAmount__c > 0) {
            if(!salesOrderIdToPendingAmountMap.containsKey(pi.SalesOrder__c)){
                salesOrderIdToPendingAmountMap.put(pi.SalesOrder__c, pi.PendingAmount__c);
            } else {
                Double pendingAmount = salesOrderIdToPendingAmountMap.get(pi.SalesOrder__c);
                salesOrderIdToPendingAmountMap.put(pi.SalesOrder__c, (pendingAmount + pi.PendingAmount__c));
            }
            //}

            if(!salesOrderIdToOldestInstallmentDueDateMap.containsKey(pi.SalesOrder__c)){
                salesOrderIdToOldestInstallmentDueDateMap.put(pi.SalesOrder__c, pi.Due_Date__c);
            } else {
                Date previousDueDate = salesOrderIdToOldestInstallmentDueDateMap.get(pi.SalesOrder__c);
                if(pi.Due_Date__c < previousDueDate){
                    salesOrderIdToOldestInstallmentDueDateMap.put(pi.SalesOrder__c, pi.Due_Date__c);
                }
            }

            if(pi.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c != null){
                setBankAccountIds.add(pi.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c);
            }

            installmentLineIds.add(pi.Id);
        }

        if(!setBankAccountIds.isEmpty()){
            bankMap = new Map<Id, BankAccount__c>(objBankAccountService.getBankAccountByIds(setBankAccountIds));
        }

        List<ReceiptAllocation__c> receiptAllocationList = [SELECT Id, ReceiptAcknowledgement__c, ReceiptAcknowledgement__r.ReceiptReversalCategory__c, ReceiptAcknowledgement__r.Status__c, ReceiptAcknowledgement__r.Amount__c, ReceiptAcknowledgement__r.ReferenceNumber__c, ReceiptAcknowledgement__r.Reason__c, ReceiptAcknowledgement__r.ChequeBouncedDate__c, SalesOrder__c,  InstallmentLine__c FROM ReceiptAllocation__c WHERE ReceiptAcknowledgement__r.Status__c = 'Reversed' AND ReceiptAcknowledgement__r.ReceiptReversalCategory__c = 'Bounced Cheque' AND InstallmentLine__c IN :installmentLineIds];

        for(ReceiptAllocation__c rcptAll : receiptAllocationList){
            installmentIdToReceiptAllocationMap.put(rcptAll.InstallmentLine__c, rcptAll);
            salesOrderIdToReceiptAllocationMap.put(rcptAll.SalesOrder__c, rcptAll);
        }

        //Map<Id,SalesOrder__c> salesOrderMap = objSalesOrderService.getSalesOrdersMap(salesOrderIdToInstallmentListMap.keySet());
        List<Case> existingCaseList = objCaseService.getOpenCasesByRecordTypeAndSalesOrder(salesOrderMap.keySet(), Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DefaultUnit').getRecordTypeId());

        for(Case cseRec : existingCaseList){
            if(!salesOrderIdToExistingDefaultUnitCaseMap.containsKey(cseRec.Sales_Order__c)){
                salesOrderIdToExistingDefaultUnitCaseMap.put(cseRec.Sales_Order__c, cseRec);
            }
        }
        for(Id soRecId : salesOrderIdToInstallmentListMap.keySet()){
            Double pendingAmount = salesOrderIdToPendingAmountMap.get(soRecId);
            for (InstallmentLines__c pi : salesOrderIdToInstallmentListMap.get(soRecId)) {
                if(pendingAmount > 1 && ((currentDate >= pi.Due_Date__c.addDays((Integer)pi.SalesOrder__r.Unit__r.Project__r.DefaultNotificationDays__c)
                    && salesOrderMap.get(pi.SalesOrder__c).PostDueDateReminderSentDate__c == null) 
                    || (salesOrderMap.get(pi.SalesOrder__c).PostDueDateReminderSentDate__c != null && currentDate >= salesOrderMap.get(pi.SalesOrder__c).PostDueDateReminderSentDate__c.addDays((Integer)pi.SalesOrder__r.Unit__r.Project__r.DefaultNotificationDays__c)))){
                    System.debug('soRecId TWO ::::: '+ soRecId);
                    salesordersToupdateSet.add(pi.SalesOrder__c);
                    if(!salesOrderIdToExistingDefaultUnitCaseMap.containsKey(pi.SalesOrder__c)){
                        
                        if(!soIdToCaseToInsert.containsKey(pi.SalesOrder__c)){
                            soIdToCaseToInsert.put(pi.SalesOrder__c,new Case(AccountId = pi.SalesOrder__r.Account__c, Sales_Order__c = pi.SalesOrder__c, RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DefaultUnit').getRecordTypeId(), OwnerId = collectionTeamId, RequesterContactNumber__c = pi.SalesOrder__r.Account__r.PersonMobilePhone, ServiceCatalog__c = seviceCatalogRecord[0].Id, CaseType__c = 'Service Request', Subject = 'DefaultNotice-'+pi.SalesOrder__r.Account__r.Name+'-'+pi.SalesOrder__r.Unit__r.Name, CustomerDefaultStatus__c = 'Suspected Defaulter', Origin = 'System Generated', NumberOfDefaultNoticeRemindersSent__c = 1, TotalInstalmentDue__c = pendingAmount, ContactId = (pi.SalesOrder__r.Account__r.isPersonAccount ? null : pi.SalesOrder__r.Account__r.PersonContactId), Project__c = pi.SalesOrder__r.Unit__r.Project__c,
                            DefaultCustomerPaymentOverdueDate__c = salesOrderIdToOldestInstallmentDueDateMap.get(pi.SalesOrder__c)));
                        }
                    }  else {
                        relatedDefaultUnitSRToBeUpdated.add(pi.SalesOrder__c);
                    } 
                }
            }
            
        }

        //Reconsider this logic
        if(!relatedDefaultUnitSRToBeUpdated.isEmpty()){
            /* List<Case> caseListToUpdate = objCaseService.getCasesByRecordTypeAndSalesOrder(relatedDefaultUnitSRToBeUpdated, Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DefaultUnit').getRecordTypeId()); */
            for(Case caseRec : salesOrderIdToExistingDefaultUnitCaseMap.values()){
                if(salesOrderMap.get(caseRec.Sales_Order__c).CustomerDefaultStatus__c != 'Default Customer'){
                    caseRec.NumberOfDefaultNoticeRemindersSent__c += 1;
                    caseRec.TotalInstalmentDue__c = salesOrderIdToPendingAmountMap.get(caseRec.Sales_Order__c);
                    caseRec.DefaultCustomerPaymentOverdueDate__c = salesOrderIdToOldestInstallmentDueDateMap.get(caseRec.Sales_Order__c);
                    soIdToCaseToUpdate.put(caseRec.Sales_Order__c, caseRec);
                    
                    //caseRec.CustomerDefaultStatus__c = 'Default Customer';
                }
            }
        }

        //Update Sales Order Records
        for(Id soRecId : salesordersToupdateSet){

            Double pendingAmount = salesOrderIdToPendingAmountMap.get(soRecId) != NULL ? salesOrderIdToPendingAmountMap.get(soRecId) : 0;

            if(salesOrderMap.get(soRecId).PostDueDateReminderSentDate__c == NULL){
                salesordersToupdateMap.put(soRecId, new SalesOrder__c(Id= soRecId, CustomerDefaultStatus__c = 'Suspected Defaulter', PostDueDateReminderSentDate__c = System.today()));
                salesOrderIdsForRegularReminder.add(soRecId);

            } else if(soIdToCaseToUpdate.containsKey(soRecId) && soIdToCaseToUpdate.get(soRecId).NumberOfDefaultNoticeRemindersSent__c >= 3 && salesOrderMap.get(soRecId).DefaultCustomerLastReminderSentDate__c == NULL){
                if(salesOrderMap.get(soRecId).Unit__r.Project__r.City__c == 'Dubai' && salesOrderMap.get(soRecId).PHPP__c == true){
                    
                    if(((pendingAmount/salesOrderMap.get(soRecId).SellingPrice__c)*100) > salesOrderMap.get(soRecId).Unit__r.Project__r.DefaultUnpaidAmountPercentage__c){

                        salesOrderIdsForLastReminder.add(soRecId);
                        relatedDefaultUnitSRToBeUpdated.add(soRecId);
                        salesordersToupdateMap.put(soRecId, new SalesOrder__c(Id= soRecId, DefaultCustomerLastReminderSentDate__c = currentDate, PostDueDateReminderSentDate__c = currentDate));
                    }
                } else {
                    if(salesOrderMap.get(soRecId).Unit__r.Project__r.DefaultUnpaidAmount__c != NULL && pendingAmount >= salesOrderMap.get(soRecId).Unit__r.Project__r.DefaultUnpaidAmount__c){

                        salesOrderIdsForLastReminder.add(soRecId);
                        //Update related DefaultUnit type cases
                        relatedDefaultUnitSRToBeUpdated.add(soRecId);
                        salesordersToupdateMap.put(soRecId, new SalesOrder__c(Id= soRecId, DefaultCustomerLastReminderSentDate__c = currentDate, PostDueDateReminderSentDate__c = currentDate));
                    }
                    
                }
            } else if(salesOrderMap.get(soRecId).DefaultCustomerLastReminderSentDate__c == NULL) {
                salesordersToupdateMap.put(soRecId, new SalesOrder__c(Id= soRecId, PostDueDateReminderSentDate__c = currentDate));
                salesOrderIdsForRegularReminder.add(soRecId);

            } else if(salesOrderMap.get(soRecId).DefaultCustomerLastReminderSentDate__c != NULL 
                && currentDate >= salesOrderMap.get(soRecId).DefaultCustomerLastReminderSentDate__c.addDays((Integer)salesOrderMap.get(soRecId).Unit__r.Project__r.DefaultNotificationDays__c)
                && salesOrderMap.get(soRecId).CustomerDefaultStatus__c != 'Default Customer'){
                //IF last reminder was sent 15 days back, then mark as Default Customer
                salesordersToupdateMap.put(soRecId, new SalesOrder__c(Id= soRecId, CustomerDefaultStatus__c = 'Default Customer', PostDueDateReminderSentDate__c = currentDate));
                salesOrderIdsForLastReminder.add(soRecId);
                if(soIdToCaseToUpdate.containsKey(soRecId) ){
                    soIdToCaseToUpdate.get(soRecId).CustomerDefaultStatus__c = 'Default Customer';
                    //soIdToCaseToUpdate.get(soRecId).Step__c = '0';
                    defaultCases.add(soIdToCaseToUpdate.get(soRecId));
                }

                accountsToUpdate.add(new Account(Id = salesOrderMap.get(soRecId).Account__c, Blacklisted__c = true, BlacklistReason__c= 'Default'));
            }
        }

        Set<Id> salesOrderIdsForGeneralPaymentReminder = new Set<Id>();
        Set<Id> salesOrderIdsForGeneralBounceChequeReminder = new Set<Id>();
        Set<Id> salesOrderIdsForLastPaymentReminder = new Set<Id>();
        Set<Id> salesOrderIdsForLastBounceChequeReminder = new Set<Id>();
        for(Id soId : salesOrderIdsForRegularReminder){
            if(salesOrderIdToInstallmentListMap.containsKey(soId)) {
                for(InstallmentLines__c ilRec: salesOrderIdToInstallmentListMap.get(soId)){
                    if(installmentIdToReceiptAllocationMap.containsKey(ilRec.Id)){
                        salesOrderIdsForGeneralBounceChequeReminder.add(soId);
                    } else {
                        salesOrderIdsForGeneralPaymentReminder.add(soId);
                    }
                }
            } 
        }
        for(Id soId : salesOrderIdsForLastReminder){
            if(salesOrderIdToInstallmentListMap.containsKey(soId)) {
                for(InstallmentLines__c ilRec: salesOrderIdToInstallmentListMap.get(soId)){
                    if(installmentIdToReceiptAllocationMap.containsKey(ilRec.Id)){
                        salesOrderIdsForLastBounceChequeReminder.add(soId);
                    } else {
                        salesOrderIdsForLastPaymentReminder.add(soId);
                    }
                }
            }    
        }

        objSalesOrderService.updateSalesOrders(salesordersToupdateMap.values());
        objCaseService.updateCases(soIdToCaseToUpdate.values());
        objCaseService.insertCases(soIdToCaseToInsert.values());
        objAccountService.updateAccounts(accountsToUpdate);

        List<Id> salesOrderIdListToUpdate = new List<Id>();
        salesOrderIdListToUpdate.addAll(salesordersToupdateSet);
        List<Document__c> documentListToUpdate = objDocumentService.getAllSalesOrderDocuments(salesOrderIdListToUpdate);
        for(Document__c docRec : documentListToUpdate){
            if(soIdToCaseToUpdate.containsKey(docRec.SalesOrder__c)){
                docRec.Case__c = soIdToCaseToUpdate.get(docRec.SalesOrder__c).Id;
            } else if(soIdToCaseToInsert.containsKey(docRec.SalesOrder__c)){
                docRec.Case__c = soIdToCaseToInsert.get(docRec.SalesOrder__c).Id;
            }   
        }
        //update documentListToUpdate;
        objDocumentService.updateDocuments(documentListToUpdate);

        soIdToCaseToUpdate.putAll(soIdToCaseToInsert);

        for(Id soId : salesOrderIdsForGeneralBounceChequeReminder){
            Messaging.SingleEmailMessage objEmailMessage = new Messaging.SingleEmailMessage();
            ReceiptAllocation__c rcptAlloRec = salesOrderIdToReceiptAllocationMap != NULL && salesOrderIdToReceiptAllocationMap.containsKey(soId) ? salesOrderIdToReceiptAllocationMap.get(soId) : null;
            objEmailMessage = getEmailContent(salesOrderMap.get(soId), rcptAlloRec, soIdToCaseToUpdate, getLatestInstallmentDueDate(salesOrderIdToInstallmentListMap.get(soId)), objEmailService, regularBounceChequeReminderTemplate, bankMap, bloomNoReplySalesOWEId);
            msgList.add(objEmailMessage);   
        }
        for(Id soId : salesOrderIdsForGeneralPaymentReminder){
            Messaging.SingleEmailMessage objEmailMessage = new Messaging.SingleEmailMessage();
            objEmailMessage = getEmailContent(salesOrderMap.get(soId), null, soIdToCaseToUpdate, getLatestInstallmentDueDate(salesOrderIdToInstallmentListMap.get(soId)), objEmailService, regularPaymentReminderTemplate, bankMap, bloomNoReplySalesOWEId);
            msgList.add(objEmailMessage);   
        }
        for(Id soId : salesOrderIdsForLastBounceChequeReminder){
            Messaging.SingleEmailMessage objEmailMessage = new Messaging.SingleEmailMessage();
            ReceiptAllocation__c rcptAlloRec = salesOrderIdToReceiptAllocationMap != NULL && salesOrderIdToReceiptAllocationMap.containsKey(soId) ? salesOrderIdToReceiptAllocationMap.get(soId) : null;
            objEmailMessage = getEmailContent(salesOrderMap.get(soId), rcptAlloRec, soIdToCaseToUpdate, getLatestInstallmentDueDate(salesOrderIdToInstallmentListMap.get(soId)), objEmailService, finalBounceChequeReminderTemplate, bankMap, bloomNoReplySalesOWEId);
            msgList.add(objEmailMessage);   
        }
        for(Id soId : salesOrderIdsForLastPaymentReminder){
            Messaging.SingleEmailMessage objEmailMessage = new Messaging.SingleEmailMessage();
            objEmailMessage = getEmailContent(salesOrderMap.get(soId), null, soIdToCaseToUpdate, getLatestInstallmentDueDate(salesOrderIdToInstallmentListMap.get(soId)), objEmailService, finalPaymentReminderTemplate, bankMap, bloomNoReplySalesOWEId);
            msgList.add(objEmailMessage);   
        }
        
        objEmailService.sendEmail(msgList);
        
        for(Case caseRecord : defaultCases){
            DefaultUnitCaseHandler defaultUnitCaseHandlerobj = DefaultUnitCaseHandler.getInstance();
            if(!Test.isRunningTest()){
                defaultUnitCaseHandlerobj.handleNextSteps(caseRecord);
            }
        }
    }

    // Helper method to generate dynamic email content
    private Messaging.SingleEmailMessage getEmailContent(SalesOrder__c so, ReceiptAllocation__c rcptAlloRec, Map<Id,Case> soIdToCaseToUpdate, Date dueDate, EmailService objEmailService, EmailTemplate emailTemplate, Map<Id, BankAccount__c> bankMap, Id bloomNoReplySalesOWEId) {
        String emailSubject = emailTemplate.Subject;
        String emailBody = emailTemplate.HtmlValue;
        
        Case caseRec = soIdToCaseToUpdate.containsKey(so.Id) ? soIdToCaseToUpdate.get(so.Id) : null;
        String serialNumber = '';
        if(caseRec != NULL && caseRec.NumberOfDefaultNoticeRemindersSent__c != NULL) {
            serialNumber = String.valueOf(caseRec.NumberOfDefaultNoticeRemindersSent__c) + Utility.getCountingFromNumber(caseRec.NumberOfDefaultNoticeRemindersSent__c);
        }
        
        Datetime installmentDateTime = DateTime.newInstance(dueDate.year(), dueDate.month(), dueDate.day());
        String formattedinstallmentDate = installmentDateTime.format('dd-MM-yyyy');

        Date bounceChequeDate = rcptAlloRec != NULL && rcptAlloRec.ReceiptAcknowledgement__c != NULL && rcptAlloRec.ReceiptAcknowledgement__r.ChequeBouncedDate__c != NULL ? rcptAlloRec.ReceiptAcknowledgement__r.ChequeBouncedDate__c : NULL;
        DateTime bounceChequeDateTime = bounceChequeDate != NULL ? DateTime.newInstance(bounceChequeDate.year(), bounceChequeDate.month(), bounceChequeDate.day()) : NULL;
        String formattedBounceChequeDate = bounceChequeDateTime != NULL ? bounceChequeDateTime.format('dd-MM-yyyy') : '';

        System.debug('serialNumber ::::: '+ serialNumber);
        emailSubject = emailSubject.replace('[Project_Name]', so.Unit__r.Project__r.Name != null ? so.Unit__r.Project__r.Name : '')
            .replace('[SerialNumber]', serialNumber)
            .replace('[Unit_Name]', so.Unit__r.Name != null ? so.Unit__r.Name : '')
            .replace('[Project_Name_Arabic]', so.Unit__r.Project__r.ProjectNameArabic__c != null ? so.Unit__r.Project__r.ProjectNameArabic__c : '');
        emailBody = emailBody.replace('[Customer_Name]', so.Account__r.Name != null ? so.Account__r.Name : '')
            .replace('[Customer_NameArabic]', so.Account__r.NameinArabic__c != null ? so.Account__r.NameinArabic__c : '')
            .replace('[Project_Name]', so.Unit__r.Project__r.Name != null ? so.Unit__r.Project__r.Name : '')
            .replace('[Project_Name_Arabic]', so.Unit__r.Project__r.ProjectNameArabic__c != null ? so.Unit__r.Project__r.ProjectNameArabic__c : '')
            .replace('[Unit_Name]', so.Unit__r.Name != null ? so.Unit__r.Name : '')
            .replace('[Due_Amount]', caseRec != null && String.valueOf(caseRec.TotalInstalmentDue__c) != null ? String.valueOf(caseRec.TotalInstalmentDue__c) : '')
            .replace('[Due_Date]', formattedinstallmentDate != null ? formattedinstallmentDate : '')
            .replace('[Cheque_Number]', rcptAlloRec != NULL && rcptAlloRec.ReceiptAcknowledgement__c != NULL && rcptAlloRec.ReceiptAcknowledgement__r.ReferenceNumber__c != null ? String.valueOf(rcptAlloRec.ReceiptAcknowledgement__r.ReferenceNumber__c) : '')
            .replace('[Cheque_Amount]', rcptAlloRec != NULL && rcptAlloRec.ReceiptAcknowledgement__c != NULL && rcptAlloRec.ReceiptAcknowledgement__r.Amount__c != null ? String.valueOf(rcptAlloRec.ReceiptAcknowledgement__r.Amount__c) : '')
            .replace('[Bounce_Date]', formattedBounceChequeDate)
            .replace('[Bounce_Reason]', rcptAlloRec != NULL && rcptAlloRec.ReceiptAcknowledgement__c != NULL && rcptAlloRec.ReceiptAcknowledgement__r.Reason__c != null ? String.valueOf(rcptAlloRec.ReceiptAcknowledgement__r.Reason__c) : '');        
        
        // Add bank details to the body
        BankAccount__c selectedBank = (so.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c != null ? bankMap.get(so.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c) : null);
        if (selectedBank != null) {
            emailBody = emailBody.replace('[BankName]', selectedBank.BankNameCorporate__c)
                .replace('[BankAccountName]', selectedBank.Name)
                .replace('[BankAccountNumber]', selectedBank.AccountNumberCorporate__c)
                .replace('[BankAccountIBAN]', selectedBank.IBANNoCorporate__c)
                .replace('[BankSwiftCode]', selectedBank.SwiftCodeCorporate__c);
        }
        // Create email message
        return objEmailService.getSingleEmailMessage(null, so.Account__c, 
                                                          (so.Account__r.isPersonAccount ? so.Account__r.PersonContactId : so.Contact__c), 
                                                          emailSubject, emailBody, bloomNoReplySalesOWEId);
    }

    private Date getLatestInstallmentDueDate(List<InstallmentLines__c> installmentLinesList) {
        Date dueDate;
        for(InstallmentLines__c instLineRec : installmentLinesList){
            if(dueDate == null || (instLineRec.Due_Date__c != null && instLineRec.Due_Date__c > dueDate)) {
                dueDate = instLineRec.Due_Date__c;
            }
        }
        return dueDate;
    }

    public void finish(Database.BatchableContext bc){
    }
}