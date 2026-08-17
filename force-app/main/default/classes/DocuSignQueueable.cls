/*****************************************************************************************
Class       : DocuSignQueueable
Author      :  Jhilik
Description : 
test Class  : DocuSignQueueableTest
Created Date: 29-Jul-2026
*****************************************************************************************/
public without sharing class DocuSignQueueable implements Queueable, Database.AllowsCallouts {
    public String objectName;
    public String template;
    public String description;
    public Id documentRecId;
    public Id recordId;
    public String documentoutputname;
    public String emailSubject;

    public DocuSignQueueable(String objectName, String template, String description, Id documentRecId, Id recordId, String documentoutputname,String emailSubject) {
        this.objectName = objectName;
        this.template = template;
        this.description = description;
        this.documentRecId = documentRecId;
        this.recordId = recordId;
        this.documentoutputname = documentoutputname;
        this.emailSubject = emailSubject;
    }

    public void execute(QueueableContext context) {
        DocuSignService objDocuSignService = DocuSignService.getInstance();

        documentoutputname = '%'+ documentoutputname + '%';

        dfsle.Notifications notifySigner = new dfsle.Notifications(
            true, // Indicates that the recipient should be reminded to sign
            10, // Number of days to wait before sending a reminder
            10, // Number of days between reminders
            true, // Whether or not the envelope expires and is voided
            999, // How many days before the envelope expires
            10, // Number of days before expiration to remind the recipient
            false // Placeholder for deprecated field
        );
        
        dfsle.Envelope myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(
            new dfsle.Entity(recordId)
        );
        
        // Get Salesforce Doc to use as a replacement     
        ContentDocumentLink cdl = [select id, ContentDocument.title, ContentDocumentId from ContentDocumentLink where LinkedEntityId = :documentRecId Order by SystemModstamp desc LIMIT 1]; //and ContentDocument.Title like :documentoutputname 
        Id myDocumentId = Id.valueOf(cdl.ContentDocumentId);
        ContentVersion cv = [SELECT FileType, Title, ContentDocumentId From ContentVersion where ContentDocumentId = :myDocumentId LIMIT 1];

        if (!Test.isRunningTest()) {
            // Include DocuSign template & document
            dfsle.UUID myTemplateId = dfsle.UUID.parse(template); 
            dfsle.Document myDocument = dfsle.Document.fromTemplate(
                myTemplateId, // templateId in dfsle.UUID format
                description); // name of the template
            myDocument.withReplacement(dfsle.Document.fromFile(cv));
            myEnvelope = myEnvelope.withDocuments(new List<dfsle.Document> { myDocument });
        } else {
            dfsle.Document myDocument = dfsle.Document.fromFile(cv);
            myEnvelope = myEnvelope.withDocuments(new List<dfsle.Document> { myDocument });
        }

        
        // Update envelope with template & replacement document
        myEnvelope = myEnvelope.withEmail(emailSubject,null);
        myEnvelope =  myEnvelope.withNotifications(notifySigner);

        List<dfsle.Recipient> allrecipients = new List<dfsle.Recipient>();
        switch on objectName {
            when 'Sales Order' {
                if(documentoutputname.Contains('KYC Declaration Form')){
                    allrecipients = DocuSignService.SalesOrderGetRecipientsForBloomSignerOne(recordId, documentoutputname);
                } else {
                    allrecipients = DocuSignService.SalesOrderGetRecipients(recordId, documentoutputname); 
                }
            }
            when 'Handover' {
                allrecipients = DocuSignService.HandoverGetRecipients(recordId, documentoutputname);
            }
            when 'Case' {
                if(documentoutputname.Contains('Client Information Sheet (KYC)')) {
                    allrecipients = DocuSignService.CaseGetRecipientsforCIS(recordId, documentoutputname);
                }else{
                    allrecipients = DocuSignService.CaseGetRecipients(recordId);
                }
            }
            when 'Broker Application' {
                allrecipients = DocuSignService.BAPPGetRecipients(recordId, documentoutputname);
            }
            when else {
            }
        } 
        
        myEnvelope = myEnvelope.withRecipients(allrecipients);
        
        if(!Test.isRunningTest()){
            myEnvelope = dfsle.EnvelopeService.sendEnvelope(
                myEnvelope,
                true
            );
        } else {
            System.debug('Skipping DocuSign send in test context');
        } 
    }
}