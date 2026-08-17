@isTest
public class HandoverEmailControllerTest {
    
   @isTest
    static void testSendNOCAndDesnaggingReport() {
         Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        
          Account ac = new Account();
        ac.LastName = 'Test Acc';
        ac.RecordTypeId = recordTypeInfo.getRecordTypeId();
        ac.PersonEmail = 'test@gmail.com';
        insert ac;        
         
        User u = new User();
        
        SalesOrder__c so = new SalesOrder__c(Name = 'Test SalesOrder', Account__c = ac.Id);
        insert so;
        
        Unit__c unt = new Unit__c(Name = 'Unit Test A1435', Status__c = 'Unassigned');
        insert unt;
        
        Handover__c handover = new Handover__c(
            Unit__c = unt.Id,  
            Customer_Email__c = 'test@example.com',
            Sub_Status__c ='Home Orientation Sent',
            Is_BCC_Announcement_Sent__c = true,
            Customer_Availability_for_CHO__c = 'Customer Available',
            Sales_Order__c = so.Id);
        insert handover;
       
        
        Event evn = new Event();
        evn.WhatId = handover.Id;
        evn.Subject = 'Other';
        evn.StartDateTime = DateTime.newInstance(2024, 6, 20, 8, 43, 38); 
        evn.EndDateTime = DateTime.newInstance(2024, 6, 22, 8, 43, 38); 
        evn.CurrencyIsoCode ='AED';
        insert evn;
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Full Guideline Document';
        contentVersion.PathOnClient = 'FullGuidelineDocument.pdf';
        contentVersion.VersionData = Blob.valueOf('Full Guideline Document');
        insert contentVersion;
        
        ContentVersion con = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        System.debug('ContentVersion'+con);
        Document__c dc = new Document__c();
        dc.Document_Name__c = Constants.HO_CHO_DeSnagging_Report;
        dc.Handover__c = handover.Id;
        dc.ContentDocumentId__c = con.ContentDocumentId;
        dc.Content_Version_Id__c = con.Id;
        insert dc;
        
          Document__c dqsn = new Document__c();
        dqsn.Document_Name__c = HandoverConstants.HO_QA_DeSnagging_Report;
        dqsn.Handover__c = handover.Id;
        dqsn.ContentDocumentId__c = con.ContentDocumentId;
        dqsn.Content_Version_Id__c = con.Id;
        insert dqsn;
        
        Document__c dcm = new Document__c();
        dcm.Document_Name__c = Constants.HO_SOA;
        dcm.Handover__c = handover.Id;
        dcm.ContentDocumentId__c = con.ContentDocumentId;
        dcm.Content_Version_Id__c = con.Id;
        insert dcm;
        
        Document__c bloomTitleDeed = new Document__c();
        bloomTitleDeed.Document_Name__c = HandoverConstants.bloomTitleDeed;
        bloomTitleDeed.Handover__c = handover.Id;
        bloomTitleDeed.ContentDocumentId__c = con.ContentDocumentId;
        bloomTitleDeed.Content_Version_Id__c = con.Id;
        insert bloomTitleDeed;
    
        
        HandoverEmailController.sendNOCAndDesnaggingReport(handover.Id);
       

    }
   
}