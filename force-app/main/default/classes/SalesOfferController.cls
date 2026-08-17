/*****************************************************************************************
Class       : SalesOfferController
Author      : Jay
Description : SalesOfferController class
Test class  : SalesOfferControllerTest
Created Date: 29 Sep 2024
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0             29AUG2024           Initial Version 
2.			V1.1			 30MAR2026			 Added Direct/Indirect changes
------------------------------------------------------------------------------------------
*/

public Without Sharing class SalesOfferController {
    
    private static final string MTD_SALES_OFFER_EMAIL_TEMPLATE_ID { get { return 'SalesOfferEmailTemplateId'; } }
    
    public class SelectedUnitWrapper {
        @AuraEnabled public Id unitId { get; set; }
        @AuraEnabled public String unitName { get; set; }
        @AuraEnabled public List<Id> paymentPlanIds { get; set; }
        @AuraEnabled public String paymentPlanName { get; set; }
        @AuraEnabled public Id offerTypeId { get; set; }
        @AuraEnabled public String offerTypeName { get; set; }
        @AuraEnabled public String priceType { get; set; }
    }
    
    @AuraEnabled
    public static List<Project__c> getProjects() {
        ProjectService objProjectService = ProjectService.getInstance();
        return objProjectService.getProjects();
    }
    
    @AuraEnabled
    public static List<String> getUnitModelsByProjectId(Id projectId) {
        UnitService objUnitService = UnitService.getInstance();
        return objUnitService.getUnitModelsByProjectId(projectId);
    }
    
    
    @AuraEnabled
    public static List<Unit__c> getUnits(Id projectId, String unitModel, String directType) {
        UnitService objUnitService = UnitService.getInstance();
        if(String.isNotBlank(unitModel) && unitModel != 'All' && String.isNotBlank(directType)){
            return objUnitService.getAvailableUnitsByProjectAndUnitModel(projectId, unitModel, directType);
        }else{
            return objUnitService.getAvailableUnitsByProjectId(projectId);
        }
    }
    
    @AuraEnabled
    public static List<PaymentPlan__c> getPaymentPlans(Id projectId, String customerType) {
        PaymentPlanService objPaymentPlanService = PaymentPlanService.getInstance();
        return objPaymentPlanService.getPaymentPlans(projectId, customerType); 
    }
    
    @AuraEnabled
    public static List<OffersPromotions__c> getOfferTypes(Id projectId, String customerType, String directType) {
        OfferService objOfferService = OfferService.getInstance();
        return objOfferService.getOffers(projectId, customerType, directType); 
    }
    
    @AuraEnabled
    public static Id generateSalesOffer(Id projectId, SelectedUnitWrapper selectedUnit, String firstName, String lastName, String email, String remarks, String customerType){
        Id salesOfferId;
        String selectedPayments = '';
        String selectedUnitsStr = '';
        String offerTypeId = '';
        String priceType = '';
        
        System.debug('Unit Id: ' + selectedUnit.unitId + ' | Payment Plan: ' + selectedUnit.paymentPlanIds + ' | Offer Type: ' + selectedUnit.offerTypeId + ' | Price Type: ' + selectedUnit.priceType);
        if (selectedUnit.paymentPlanIds != null && !selectedUnit.paymentPlanIds.isEmpty()) {
            selectedPayments = String.join((List<String>)selectedUnit.paymentPlanIds, '|');
        }
        Savepoint sp = Database.setSavePoint();
        try{
            SalesOfferService objSalesOfferService = SalesOfferService.getInstance();
            SalesOffer__c objSO = new SalesOffer__c();
            objSO.Unit__c = selectedUnit.unitId;
            objSO.OfferAndPromotion__c = selectedUnit.offerTypeId;
            objSO.PriceType__c = selectedUnit.priceType;
            objSO.CustomerFirstName__c = firstName;
            objSO.CustomerLastName__c = lastName;
            objSO.CustomerEmail__c = email;
            objSO.Remarks__c = remarks;
            objSO.CustomerType__c = customerType;
            SalesOffer__c objInsertedSO = objSalesOfferService.insertSalesOffer(objSO);
			
            String customerName = '';
            if (!String.isBlank(firstName) && !String.isBlank(lastName)) {
                customerName = firstName + ' ' + lastName;
            } else if (!String.isBlank(firstName)) {
                customerName = firstName;
            } else if (!String.isBlank(lastName)) {
                customerName = lastName;
            } else {
                customerName = 'Valued Customer';
            }
            
            List<SalesOfferPaymentPlan__c> salesOfferPaymentList = new List<SalesOfferPaymentPlan__c>();
            for(Id paymentPlanId : selectedUnit.paymentPlanIds){
                salesOfferPaymentList.add(new SalesOfferPaymentPlan__c(SalesOffer__c = objInsertedSO.Id, PaymentPlan__c = paymentPlanId));
            }
            
            if(!salesOfferPaymentList.isEmpty()) insert salesOfferPaymentList;
            
            salesOfferId = objInsertedSO.Id;
            
            Blob ret;
            objSO = objSalesOfferService.getSalesOfferById(objInsertedSO.Id);
            String url = '/apex/OfferDetailsPDF?id=' + salesOfferId + '&currentUnit=' + selectedUnit.unitId + '&currentOffer=' + selectedUnit.offerTypeId + '&selectedPayments=' + selectedPayments + '&customerName=' + customerName + '&finishingtypeValues=' + selectedUnit.priceType;

            PageReference pageRef = new PageReference(url);
            If(Test.isRunningTest()){
                ret = Blob.valueOf('Test') ;
            }Else{
                ret = pageRef.getContentAsPDF();
            }
            String base64 = EncodingUtil.base64Encode(ret);
            
            ContentVersion cv = new ContentVersion();
            cv.versionData = EncodingUtil.base64Decode(base64);
            cv.title = objSO.Name + '.pdf';
            cv.pathOnClient = objSO.Name + '.pdf';
            insert cv;
            
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = salesOfferId;
            cdl.ShareType = 'I';
            cdl.Visibility = 'AllUsers';
            insert cdl;
        }catch(System.exception ex){
            Database.rollback(sp);
            List<String> msgList = ex.getMessage().split(',');
            msgList.remove(0);
            string msg = String.join(msgList, ', ');
            throw new AuraHandledException(msg);
        }
        return salesOfferId;
    }
    
    @AuraEnabled
    public static Id getDocumentBySalesOfferId(Id salesOfferId){
        Id contentDocumentId;
        try{
            contentDocumentId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :salesOfferId].ContentDocumentId;
        }catch(System.exception ex){
            List<String> msgList = ex.getMessage().split(',');
            msgList.remove(0);
            string msg = String.join(msgList, ', ');
            throw new AuraHandledException(msg);
        }
        return contentDocumentId;
    }
    
    @AuraEnabled
    public static void shareSalesOffer(Id salesOfferId){
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        SalesOfferService objSalesOfferService = SalesOfferService.getInstance();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        
        SalesOffer__c objSO = objSalesOfferService.getSalesOfferById(salesOfferId);
        Id salesOfferEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_SALES_OFFER_EMAIL_TEMPLATE_ID);
        
        List<ContentDocumentLink> cdlList = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink Where LinkedEntityId = :objSO.Id];
        
        if(String.isNotBlank(objSO.CustomerEmail__c) && !cdlList.isEmpty()){
            List<ContentVersion> cvList = [SELECT Id, Title, VersionData, FileType, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :cdlList[0].ContentDocumentId AND IsLatest = True];
            Messaging.SingleEmailMessage objMail = objEmailService.getSingleEmailMessageWithoutTargetObjectId(salesOfferEmailTemplateId, null, salesOfferId, new List<String>{objSO.CustomerEmail__c}, null, null);
            Messaging.EmailFileAttachment objFileAttachment = objEmailService.getEmailAttachment(cvList[0].Title, cvList[0].VersionData, 'application/pdf');
            objMail.setFileAttachments(new Messaging.EmailFileAttachment[] { objFileAttachment}); 
            emailList.add(objMail); 
            objEmailService.sendEmail(emailList);
        } 
    }
}