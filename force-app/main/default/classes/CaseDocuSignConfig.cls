public class CaseDocuSignConfig {
    public static List<dfsle.Recipient> getRecipients(Id caseId){
        List<dfsle.Recipient> recipients = new List<dfsle.Recipient>();
        
        Case cs = [SELECT Id,AccountId,Account.CompanyEmail__c,Account.Name FROM Case Where Id =:caseId];
        
        /*******************************
* Recipient 1 - BloomSigner1
*******************************/
        dfsle.Tab signer1Tab = new dfsle.SignHereTab()
            .withRequired(true)
            .withScale(1)
            .withAnchor(new dfsle.Tab.Anchor(
                'Agency:',
                false,
                false,
                'right',
                true,
                true,
                'pixels',
                0,
                0
            ));
        
        dfsle.SignHereTab.Stamp agencyStamp = new dfsle.SignHereTab.Stamp('stamp',null,null,null,null,null,null,null);
        dfsle.Tab agencyStampTab = new dfsle.SignHereTab().withStamp(agencyStamp)
            .withScale(2) // 1.5 scale
            .withRequired(true) // Signing mandatory
            .withAnchor(new dfsle.Tab.Anchor(
                'Agency Stamp:', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'right', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                30, // X offset
                0)); // Y offset
        
        dfsle.Recipient signer1 =
            dfsle.Recipient.fromSource(
                cs.Account.Name,
                cs.Account.CompanyEmail__c,
                null,
                'BloomSigner1:',
                null
            )
            .withTabs(new List<dfsle.Tab>{
                signer1Tab,
                    agencyStampTab
                    })
            .withRoutingOrder(1);
        
        recipients.add(signer1);
        
        
        /*******************************
* Recipient 2 - BloomSigner2
*******************************/
        dfsle.Tab signer2Tab = new dfsle.SignHereTab()
            .withRequired(true)
            .withScale(1)
            .withAnchor(new dfsle.Tab.Anchor(
                'BloomSigner2:',
                false,
                false,
                'right',
                true,
                true,
                'pixels',
                0,
                0
            ));
        
        dfsle.Recipient signer2 =
            dfsle.Recipient.fromSource(
                System.Label.DocusignBloomSigner2Name,
                System.Label.DocusignBloomSigner2Email,
                null,
                'BloomSigner2:',
                null
            )
            .withTabs(new List<dfsle.Tab>{
                signer2Tab
                    })
            .withRoutingOrder(2);
        
        recipients.add(signer2);
        
        
        /*******************************
* Recipient 3 - BBM Stamp
*******************************/
        dfsle.SignHereTab.Stamp bbmStamp = new dfsle.SignHereTab.Stamp('stamp',null,null,null,null,null,null,null);
        dfsle.Tab bbmStampTab = new dfsle.SignHereTab().withStamp(bbmStamp)
            .withScale(2) // 1.5 scale
            .withRequired(true) // Signing mandatory
            .withAnchor(new dfsle.Tab.Anchor(
                'BBM Stamp:', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'right', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                30, // X offset
                0)); // Y offset
        
        dfsle.Recipient signer3 =
            dfsle.Recipient.fromSource(
                System.Label.DocusignBloomSigner1Name,
                System.Label.DocusignBloomSigner1Email,
                null,
                'BBM Stamp:',
                null
            )
            .withTabs(new List<dfsle.Tab>{
                bbmStampTab
                    })
            .withRoutingOrder(3);
        
        recipients.add(signer3);
        
        System.debug('Recipients ==> ' + recipients);
        
        return recipients;
    }    
     public static List<dfsle.Recipient>  getRecipientsforCIS(Id caseId, String documentoutputname) 
    {
        system.debug('documentoutputname');
        system.debug(documentoutputname);
        List<dfsle.Recipient> allrecipients = new List<dfsle.Recipient> () ;
        Case cs = [SELECT Id,AccountId,Account.CompanyEmail__c,Account.Name,Sales_Order__c FROM Case Where Id =:caseId];
      
        
        List<Contact> Contactlst = [SELECT id, Name, MobileCountryCode__c, MobilePhone, Email From Contact Where AccountId IN (select AccountId from Case where id = :caseId) ];
        system.debug(Contactlst);
         List<Contact> JOContactlst = [SELECT id, Name, MobileCountryCode__c, MobilePhone, Email From Contact Where Accountid IN (SELECT Account__c from JointOwner__c where SalesOrder__c = :cs.Sales_Order__c)];
        integer i = 1; 
        integer j = 1;
        
        for (Contact MainBuyerrec : Contactlst) {   
            // Create a Sign Here tab
            dfsle.Tab mainbuyerSignHereTab = new dfsle.SignHereTab()
                .withScale(1) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'MainBuyer:', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    'right', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0))// Y offset
                .withPosition(new dfsle.Tab.Position(
                    1, 
                    null,
                    null,
                    null,
                    null,
                    null));
            system.debug('mainbuyertab');
            dfsle.Tab initialHereTab = new dfsle.InitialHereTab()
                .withScale(1) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'MBIni:', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    'right', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0))// Y offset
                ;
            
            dfsle.Tab mainCustomerDateSignedTab = new dfsle.DateSignedTab()
                .withAnchor(new dfsle.Tab.Anchor(
                    'MainBuyerSignedDate:',
                    false,
                    false,
                    'right',
                    true,
                    true,
                    'pixels',
                    0,
                    0))
                .withPosition(new dfsle.Tab.Position(
                    1,
                    null,
                    null,
                    null,
                    null,
                    null));            
            system.debug('mainbuyersignedtab');
            
            string mainbuyermobilenum = MainBuyerrec.MobileCountryCode__c + MainBuyerrec.MobilePhone ;
            system.debug(mainbuyermobilenum);
            system.debug(i);
            If (System.Label.DocusignInitialsReqd == 'True')
            {dfsle.Recipient mainbuyerRecipient = dfsle.Recipient.fromSource(
                MainBuyerrec.Name,
                MainBuyerrec.Email,
                mainbuyermobilenum , 
                'MainBuyer:',
                null)
                .withTabs(new List<dfsle.Tab> {
                    mainbuyerSignHereTab, mainCustomerDateSignedTab, initialHereTab
                        }).withRoutingOrder(i);
             system.debug('add mainbuyerreceipient');
             allrecipients.add (mainbuyerRecipient);
            }
            else
            {
                dfsle.Recipient mainbuyerRecipient = dfsle.Recipient.fromSource(
                    MainBuyerrec.Name,
                    MainBuyerrec.Email,
                    mainbuyermobilenum , 
                    'MainBuyer:',
                    null)
                    .withTabs(new List<dfsle.Tab> {
                        mainbuyerSignHereTab, mainCustomerDateSignedTab
                            }).withRoutingOrder(i);
                system.debug('add mainbuyerreceipient');
                allrecipients.add (mainbuyerRecipient);
            }
            system.debug(allrecipients);
        }
         return allrecipients;
    }
    @future(callout=true)
    public static void sendCaseEnvelopes(String template,String description,Id recordId,Id caseId,String documentoutputname,String emailSubject){
        
        documentoutputname = '%' + documentoutputname + '%';
        
        System.debug('recordId: ' + recordId);
        System.debug('caseId: ' + caseId);
        System.debug('template: ' + template);
         System.debug('documentoutputname: ' + documentoutputname);
        
        dfsle.Notifications notifySigner = new dfsle.Notifications(
            true,
            2,
            1,
            true,
            999,
            10,
            false
        );
        
        dfsle.Envelope myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(
            new dfsle.Entity(caseId)
        );
        
        dfsle.UUID myTemplateId = dfsle.UUID.parse(template);
        
        dfsle.Document myDocument = dfsle.Document.fromTemplate(
            myTemplateId,
            description
        );
        
        // Get ContentDocumentLink
        List<ContentDocumentLink> cdlList = [SELECT Id,ContentDocumentId,ContentDocument.Title FROM ContentDocumentLink WHERE 
                                             LinkedEntityId = :recordId ORDER BY SystemModstamp DESC];
        
        if (cdlList.isEmpty()) {
            System.debug('No ContentDocumentLink found.');
            return;
        }
        
        ContentDocumentLink cdl = cdlList[0];
        
        System.debug('ContentDocumentLink: ' + cdl);
        
        // Get ContentVersion
        List<ContentVersion> versions = [SELECT Id,Title, FileType,ContentDocumentId FROM ContentVersion WHERE
                                         ContentDocumentId = :cdl.ContentDocumentId];
        
        if (versions.isEmpty()) {
            System.debug('No ContentVersion found.');
            return;
        }
        
        ContentVersion cv = versions[0];
        
        myDocument.withReplacement(dfsle.Document.fromFile(cv));
        myEnvelope = myEnvelope.withDocuments(new List<dfsle.Document>{ myDocument });
        myEnvelope = myEnvelope.withEmail(emailSubject, 'Sign In Document');
        myEnvelope = myEnvelope.withNotifications(notifySigner);
        
        List<dfsle.Recipient> recipients = new List<dfsle.Recipient>();
        
        if(documentoutputname.Contains('Client Information Sheet (KYC)')){
            recipients = getRecipientsforCIS(caseId, documentoutputname);
        }else{
            recipients = getRecipients(caseId);
        }
        System.debug('recipients>>'+recipients);
        if (recipients == null || recipients.isEmpty()) {
            System.debug('Recipients not found.');
            return;
        }
        
        myEnvelope = myEnvelope.withRecipients(recipients);
        
        myEnvelope = dfsle.EnvelopeService.sendEnvelope(
            myEnvelope,
            true
        );
    }   
}