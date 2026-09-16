public with sharing class HandoverDocuSignConfig {
    public HandoverDocuSignConfig() {
    }

    public static List<dfsle.Recipient> getRecipients(Id recordid, String documentoutputname){
        List<dfsle.Recipient> allrecipients = new List<dfsle.Recipient>();

        dfsle.Tab myBloomSignHereTab1 = new dfsle.SignHereTab()
            .withScale(1) // 1.5 scale
            .withRequired(true) // Signing mandatory
            .withAnchor(new dfsle.Tab.Anchor(
                'BloomSigner1:', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'right', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                0, // X offset
                0)).withPosition(new dfsle.Tab.Position(
                    1, 
                    null,
                    null,
                    null,
                    null,
                    null)); // Y offset
        system.debug('signed 1 tab added');
        
        system.debug('add bloom signer 1tab');
        dfsle.Recipient myBloomSignrecipient1 = dfsle.Recipient.fromSource(
            System.Label.DocusignBloomSigner1Name,
            System.Label.DocusignBloomSigner1Email,
            null, 
            'BloomSigner1:',
            null).withTabs(new List<dfsle.Tab> {
                myBloomSignHereTab1
                    }).withRoutingOrder(13);
        
        system.debug(myBloomSignrecipient1);
        allrecipients.add (myBloomSignrecipient1);

        dfsle.Tab myBloomSignHereTab2 = new dfsle.SignHereTab()
            .withScale(1) // 1.5 scale
            .withRequired(true) // Signing mandatory
            .withAnchor(new dfsle.Tab.Anchor(
                'BloomSigner2:', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'right', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                0, // X offset
                0)).withPosition(new dfsle.Tab.Position(
                    1, 
                    null,
                    null,
                    null,
                    null,
                    null)); // Y offset

        dfsle.Recipient myBloomSignrecipient2 = dfsle.Recipient.fromSource(
            System.Label.DocusignBloomSigner2Name,
            System.Label.DocusignBloomSigner2Email,
            null, 
            'BloomSigner2:',
            null).withTabs(new List<dfsle.Tab> {
                myBloomSignHereTab2
                    }).withRoutingOrder(14);
        
        system.debug(myBloomSignrecipient2);
        allrecipients.add (myBloomSignrecipient2);
        return allrecipients;
    }

    @future(callout=true)
    public static void sendHandoverEnvelopes(String template, String description, Id recordId, Id handoverId, String documentoutputname,String emailSubject) {
        documentoutputname = '%'+ documentoutputname + '%';
        System.debug('docoutputname'+documentoutputname);
        System.debug('recordId'+recordId);
        System.debug('template'+template);
        system.debug('Start of send envelope');
        
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
            //new dfsle.Entity(recordId)
            new dfsle.Entity(handoverId)
        );
        system.debug('new envelope');
        
       
        // Include DocuSign template & document
        dfsle.UUID myTemplateId = dfsle.UUID.parse(template); 
        dfsle.Document myDocument = dfsle.Document.fromTemplate(
            myTemplateId, // templateId in dfsle.UUID format
            description); // name of the template
        
        // Get Salesforce Doc to use as a replacement     
        
        system.debug('get document');
        ContentDocumentLink cdl = [select id, ContentDocument.title, ContentDocumentId from ContentDocumentLink where LinkedEntityId = :recordId and ContentDocument.Title like :documentoutputname Order by SystemModstamp desc LIMIT 1];
        System.debug('cdl'+cdl);
        Id myDocumentId = Id.valueOf(cdl.ContentDocumentId);
        System.debug(myDocumentId);
        ContentVersion cv = [SELECT FileType, Title, ContentDocumentId From ContentVersion where ContentDocumentId = :myDocumentId LIMIT 1];
        System.debug(cv);
        myDocument.withReplacement(dfsle.Document.fromFile(cv));
        
        // Update envelope with template & replacement document
        system.debug('get document done');
        myEnvelope = myEnvelope.withDocuments(new List<dfsle.Document> { myDocument });
        myEnvelope = myEnvelope.withEmail(emailSubject,null);
        myEnvelope =  myEnvelope.withNotifications(notifySigner);
        system.debug('attached document to envelope');
            
        List<dfsle.Recipient> allrecipients = getRecipients(handoverId, documentoutputname) ; 
        
        system.debug('recipients received');
        system.debug(allrecipients.size());
        myEnvelope = myEnvelope.withRecipients(allrecipients);
        system.debug('Envelope' + myEnvelope);
        
      if(!Test.isRunningTest()){
    myEnvelope = dfsle.EnvelopeService.sendEnvelope(
        myEnvelope,
        true
    );
} else {
    System.debug('Skipping DocuSign send in test context');
}
        system.debug('send envelope done');
        System.debug(String.valueOf(myEnvelope.docuSignId));
    }   
}