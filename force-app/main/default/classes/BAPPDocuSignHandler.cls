/*****************************************************************************************
Class       : BAPPDocuSignHandler
Author      : Raza
Description : Docusign Handler class
Test Class  : BAPPDocuSignHandlerTest
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0             April 2025           Initial Version 
*****************************************************************************************/
public class BAPPDocuSignHandler {
    public static List<dfsle.Recipient>  getRecipients(Id recordid, String documentoutputname) 
    {
        List<dfsle.Recipient> allrecipients = new List<dfsle.Recipient> () ;
        List<BrokerApplication__c> balist = [
            SELECT Id,Name, CompanyPhone_Number__c,(SELECT Id, Email__c, BrokerContactRole__c FROM BrokerApplicants__r WHERE BrokerContactRole__c INCLUDES ('AuthorizedSignatoryOfficer'))
            FROM BrokerApplication__c WHERE Id = :recordid LIMIT 1];
        Integer signatoryIndex = 1;
        if(!balist.isEmpty()){
            for(BrokerApplication__c ba : balist){
                for (BrokerApplicant__c applicant : ba.BrokerApplicants__r) {
                    
                    if (signatoryIndex > 4) {
                        break;
                    }
                    
                    // -------- Signature Tab --------
                    dfsle.Tab signHereTab = new dfsle.SignHereTab()
                        .withRequired(true)
                        .withScale(1.25)
                        .withAnchor(new dfsle.Tab.Anchor(
                            '\\AS' + signatoryIndex + '_SIGN\\',
                            false,   // case sensitive
                            true,   // whole word
                            'left',
                            false,   // match spaces EXACTLY OFF
                            false,   // do NOT ignore if not found
                            'pixels',
                            0,0
                        ));
                    
                    
                    // -------- Date Signed --------
                    dfsle.Tab dateSignedTab = new dfsle.DateSignedTab()
                        .withAnchor(new dfsle.Tab.Anchor(
                            '\\AS' + signatoryIndex + '_DATE\\',
                            false,false,'left',true,true,'pixels',0,0
                        ));
                    
                    // -------- Initials --------
                    dfsle.Tab initialsTab = new dfsle.InitialHereTab()
                        .withRequired(true)
                        .withScale(1.2)
                        .withAnchor(new dfsle.Tab.Anchor(
                            '\\AS' + signatoryIndex + '_INIT\\',
                            false,   // case sensitive OFF
                            true,    // whole word ON
                            'left',
                            false,   // do NOT match spaces exactly
                            false,   // do NOT ignore if not found
                            'pixels',
                            10, 0
                        ));
                    
                    // -------- Stamp --------
                    dfsle.Tab stampTab;
                    if(signatoryIndex == 1){
                        
                        dfsle.SignHereTab.Stamp stamp =
                            new dfsle.SignHereTab.Stamp('stamp', null,null,null,null,null,null,null);
                        
                        stampTab = new dfsle.SignHereTab()
                            .withStamp(stamp)
                            .withRequired(true)
                            .withScale(1.3)
                            .withAnchor(new dfsle.Tab.Anchor(
                                '\\AS' + signatoryIndex + '_STAMP\\',
                                false, true, 'left', false, false, 'pixels', 0, 0
                            ));
                    }
                    List<dfsle.Tab> tabs = new List<dfsle.Tab>{
                        signHereTab,
                            dateSignedTab,
                            stampTab
                            };
                                
                                if (initialsTab != null) {
                                    tabs.add(initialsTab);
                                }
                    
                    dfsle.Recipient authorizedRecipient =
                        dfsle.Recipient.fromSource(
                            ba.Name,
                            applicant.Email__c,
                            ba.CompanyPhone_Number__c,
                            'Authorized Signatory ' + signatoryIndex + ':',
                            null
                        )
                        .withTabs(tabs)
                        .withRoutingOrder(1);
                    
                    allRecipients.add(authorizedRecipient);
                    signatoryIndex++;
                }
            }
        }

            // Add Bloom Signatory Recipient
        String bloomEmail = System.Label.BAPP_Bloom_Signatory;
        Set<String> emailSet = new Set<String>{ bloomEmail };
        List<User> bloomUsers = UserService.getInstance().getUsersByEmails(emailSet);
        User bloomUser;
        if (!bloomUsers.isEmpty()) {
            bloomUser = bloomUsers[0];
        }

            
            dfsle.Tab bloomSignHereTab = new dfsle.SignHereTab()
            .withScale(1.25)
            .withRequired(true)
            .withAnchor(new dfsle.Tab.Anchor(
                'Bloom Signatory:', // Anchor text in the PDF
                false,
                false,
                'right',
                true,
                true,
                'pixels',
                30,
                0))
            .withPosition(new dfsle.Tab.Position(
                1,
                null,
                null,
                null,
                null,
                null));
        System.debug('bloomSignHereTab added');

        dfsle.Tab bloomDateSignedTab = new dfsle.DateSignedTab()
            .withAnchor(new dfsle.Tab.Anchor(
                'BloomSignedDate:',
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


        dfsle.Recipient bloomSignatory = dfsle.Recipient.fromSource(
            bloomUser.Name,
            bloomUser.Email,
            null,
            'Bloom Signatory:',
            null
        ).withTabs(new List<dfsle.Tab> {
            bloomSignHereTab,
            bloomDateSignedTab
            //myBLStampTab
        }).withRoutingOrder(2); // Assuming second signer


        allrecipients.add(bloomSignatory);

        
        
        
        
        
        Id bloomUserId = BrokerApplicationService.getInstance().getApplicationById(recordid).BBMId__c; 
        User bloomStampUser;
        if (bloomUserId != null) {
            Set<Id> userIdSet = new Set<Id>{ bloomUserId };
                List<User> bloomStampUsers = UserService.getInstance().getUsersByIds(userIdSet);
            if (!bloomStampUsers.isEmpty()) {
                bloomStampUser = bloomStampUsers[0];
            }
        }
        
        // Add Stamp Tab
        dfsle.SignHereTab.Stamp BBMStamp = new dfsle.SignHereTab.Stamp('stamp', null, null, null, null, null, null, null);
        dfsle.Tab myBBMStampTab = new dfsle.SignHereTab()
            .withStamp(BBMStamp)
            .withScale(1.5)
            .withRequired(true)
            .withAnchor(new dfsle.Tab.Anchor(
                'BMStamp:',
                false,
                false,
                'right',
                true,
                true,
                'pixels',
                80,
                0));
        
        dfsle.Tab bloomBBMSignHereTab = new dfsle.SignHereTab()
            .withScale(1.25)
            .withRequired(true)
            .withAnchor(new dfsle.Tab.Anchor(
                'Bloom Signatory:', // Anchor text in the PDF
                false,
                false,
                'right',
                true,
                true,
                'pixels',
                30,
                0))
            .withPosition(new dfsle.Tab.Position(
                1,
                null,
                null,
                null,
                null,
                null));
        System.debug('bloomSignHereTab added');
        
        dfsle.Tab bloomBBMDateSignedTab = new dfsle.DateSignedTab()
            .withAnchor(new dfsle.Tab.Anchor(
                'BloomSignedDate:',
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
        System.debug('bloomDateSignedTab added');
        
        if(bloomStampUser != null && bloomStampUser.Email != null && bloomStampUser.Name != null) {
            dfsle.Recipient bloomStampAuthority = dfsle.Recipient.fromSource(
                bloomStampUser.Name,
                bloomStampUser.Email,
                null,
                'BBM Signatory:',
                null
            ).withTabs(new List<dfsle.Tab> {
                    myBBMStampTab
                    }).withRoutingOrder(3); // Assuming Third signer
            
            
            allrecipients.add(bloomStampAuthority);
        }
        return allrecipients;
    }

    @future(callout=true)
    public static void BlsendSPAEnvelope(String template, String description, Id recordId, Id bappId, String documentoutputname,String emailSubject) {
        if (String.isBlank(description)) {
            description = 'Generated Document';
        }
        documentoutputname = '%'+ documentoutputname + '%';

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
            new dfsle.Entity(bappId)
        );
        dfsle.UUID myTemplateId = dfsle.UUID.parse(template); 
        dfsle.Document myDocument = dfsle.Document.fromTemplate(
            myTemplateId,
            description);

        ContentDocumentLink cdl = ContentDocumentLinkService.getLatestContentDocumentLinkByRecordAndTitle(recordId, documentOutputName);
        Id myDocumentId = Id.valueOf(cdl.ContentDocumentId);
        ContentVersion cv = [SELECT FileType, Title, ContentDocumentId From ContentVersion where ContentDocumentId = :myDocumentId LIMIT 1];
        myDocument = myDocument.withReplacement(dfsle.Document.fromFile(cv));

        myEnvelope = myEnvelope.withDocuments(new List<dfsle.Document> { myDocument });
        myEnvelope = myEnvelope.withEmail(emailSubject,'Sign In Document');
        myEnvelope = myEnvelope.withNotifications(notifySigner);

        List<dfsle.Recipient> allrecipients = getRecipients(bappId, documentoutputname); 
        myEnvelope = myEnvelope.withRecipients(allrecipients);		
        if (Test.isRunningTest()) {
            return; //  Skip the actual call during tests
        }
        
        myEnvelope = dfsle.EnvelopeService.sendEnvelope(
            myEnvelope,
            true
        );
    } 
}