@isTest
public class HandoverEmailHelperTest {

    @isTest
   public static void HandoverEmailHelperTestMethod(){  
         Project__c project = new Project__c(
            Name = 'Test Project',
             ProjectNameArabic__c='test',
            Office_Location__c = 'Test Location',
            Handover_Community_Guidelines_English__c='https://bloomholding--uat.sandbox.my.salesforce.com/sfc/p/FW00000126lV/a/FW000000ADC5/igY613F8BavkPpbBlRMMgUj6eKZBo3XiFnXEyohCPcU',
             Handover_Community_Guidelines_Arabic__c='https://bloomholding--uat.sandbox.my.salesforce.com/sfc/p/FW00000126lV/a/FW000000ADC5/igY613F8BavkPpbBlRMMgUj6eKZBo3XiFnXEyohCPcU'
        );
        insert project;
        
        Unit__c unit = new Unit__c(
            Name = 'Unit Test A1435',
            SAP_Unit_Number__c = 'SAP12345',
            Status__c = 'Available'
        );
        insert unit;
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
       
       
         Account acc = new Account();
        acc.LastName = 'Test Acc';
        acc.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc.PersonEmail = 'test@gmail.com';
        insert acc;
       
        ServiceCatalog__c  servicecatalog = new ServiceCatalog__c();
        servicecatalog.ProcessFlowType__c= 'Handover';
        servicecatalog.ProcessType__c = 'Sales';
        servicecatalog.Active__c= true;
        servicecatalog.RecordTypeDevName__c = 'Handover';
        insert servicecatalog;

        
        Handover__c handover = new Handover__c(
            Name = 'Test Handover',
            Customer_Email__c = 'test@example.com',
            account__c = acc.id,
            Is_Orientation_Letter_Sent__c = false,
            Is_BCC_Announcement_Sent__c = false,
            Unit__c = unit.Id,
            ServiceCatalog__c = servicecatalog.Id,
            Project__c = project.Id,
            Customer_Availability_for_CHO__c = 'Customer Available',
            HO_Agent_Assigned_User__c = UserInfo.getUserId()
        );
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
        system.debug('contentVersion'+contentVersion);
        ContentVersion con = [SELECT Id, ContentDocumentId FROM ContentVersion where Id = : contentVersion.Id];
        system.debug('con version'+con);
        
        Document__c dc= new Document__c();
        dc.Document_Name__c = 'Full Guideline Document';
        dc.Handover__c = handover.Id;
        dc.ContentDocumentId__c = con.ContentDocumentId;
        dc.Content_Version_Id__c = con.Id;
        insert dc;

        System.debug('DCCCCC=====> ' + dc);
        
        List<String> handoverIds = new List<String>{handover.Id};
       
       HandoverEmailHelper.sendEmailProcess(
    Constants.Appointment_Booked_Template,
    handover.Id, // Replace with actual Handover__c record Id
    new List<String>{'to@example.com'},
    new List<String>{'bcc@example.com'},
    new List<String>{'Full Guideline Document'}
);
         HandoverEmailHelper.sendEmailProcess(
    Constants.Appointment_Booked_Template,
    handover.Id, // Replace with actual Handover__c record Id
    new List<String>{''},
    new List<String>{'bcc@example.com'},
    new List<String>{'Full Guideline Document'}
);
       
       HandoverEmailHelper.getDynamicBody('test',handover);
      

       
   }
}