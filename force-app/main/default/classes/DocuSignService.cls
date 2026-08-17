/*****************************************************************************************
Class       : DocuSignService
Author      :  Jhilik
Description : 
test Class  : DocuSignServiceTest
Created Date: 29-Jul-2026
*****************************************************************************************/
public inherited sharing class DocuSignService {
    private static DocuSignService inst;
    public static DocuSignService getInstance() {
        if (inst == null) inst = new DocuSignService();
        return inst;
    }
    
    public DocuSignService() {
    }
    
    public static List<dfsle.Recipient> SalesOrderGetRecipients(Id recordid, String documentoutputname) {
        List<dfsle.Recipient> allrecipients = new List<dfsle.Recipient> () ;
        List<SalesOrder__c> Salesmangerlist = [select id,SalesManager__r.Name,SalesManager__r.Email, Opportunity__c,
                                               Opportunity__r.BrokerAgentContact__c, Opportunity__r.BrokerAgentContact__r.Name,
                                               Opportunity__r.BrokerAgentContact__r.Email, Opportunity__r.AgentType__c, 
                                               ReferrersName__c, ReferrersEmail__c 
                                               FROM SalesOrder__c
                                               WHERE id =: recordid ];
        
        List<Contact> Contactlst = [SELECT id, Name, MobileCountryCode__c, MobilePhone, Email From Contact Where AccountId IN (select Account__c from SalesOrder__c where id = :recordId) ];
        integer i = 1;   
        
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
            
            string mainbuyermobilenum = MainBuyerrec.MobileCountryCode__c + MainBuyerrec.MobilePhone ;
            if(System.Label.DocusignInitialsReqd == 'True') {
                dfsle.Recipient mainbuyerRecipient = dfsle.Recipient.fromSource(
                MainBuyerrec.Name,
                MainBuyerrec.Email,
                mainbuyermobilenum , 
                'MainBuyer:',
                null)
                .withTabs(new List<dfsle.Tab> {
                    mainbuyerSignHereTab, mainCustomerDateSignedTab, initialHereTab
                        }).withRoutingOrder(i);
             allrecipients.add (mainbuyerRecipient);
            
            } else {
                dfsle.Recipient mainbuyerRecipient = dfsle.Recipient.fromSource(
                    MainBuyerrec.Name,
                    MainBuyerrec.Email,
                    mainbuyermobilenum , 
                    'MainBuyer:',
                    null)
                    .withTabs(new List<dfsle.Tab> {
                        mainbuyerSignHereTab, mainCustomerDateSignedTab
                            }).withRoutingOrder(i);
                allrecipients.add (mainbuyerRecipient);
            }
        }
        
        if(documentoutputname.Contains('Referral')){
            // Create a Sign Here tab
            dfsle.Tab referrerSignHereTab = new dfsle.SignHereTab()
                .withScale(1) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'Referrer:', // Anchor string
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
            
            dfsle.Tab initialHereTab = new dfsle.InitialHereTab()
                .withScale(1) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'ReferrerIni:', // Anchor string
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
                    'ReferrerSignedDate:',
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
            
            //string mainbuyermobilenum = MainBuyerrec.MobileCountryCode__c + MainBuyerrec.MobilePhone ;

            if(System.Label.DocusignInitialsReqd == 'True'){
                dfsle.Recipient referrerRecipient = dfsle.Recipient.fromSource(
                    Salesmangerlist[0].ReferrersName__c,
                    Salesmangerlist[0].ReferrersEmail__c,
                    null , 
                    'Referrer:',
                    null)
                    .withTabs(new List<dfsle.Tab> {
                        referrerSignHereTab, mainCustomerDateSignedTab, initialHereTab
                            }).withRoutingOrder(i);

                allrecipients.add (referrerRecipient);
            }
            else {
                dfsle.Recipient referrerRecipient = dfsle.Recipient.fromSource(
                    Salesmangerlist[0].ReferrersName__c,
                    Salesmangerlist[0].ReferrersEmail__c,
                    null , 
                    'Referrer:',
                    null)
                    .withTabs(new List<dfsle.Tab> {
                        referrerSignHereTab, mainCustomerDateSignedTab
                            }).withRoutingOrder(i);

                allrecipients.add (referrerRecipient);
            }
        }
        
        if(!documentoutputname.Contains('Broker') && !documentoutputname.Contains('Referral')){

            List<Contact> JOContactlst = [SELECT id, Name, MobileCountryCode__c, MobilePhone, Email From Contact Where Accountid IN (SELECT Account__c from JointOwner__c where SalesOrder__c = :recordId)];
            
            integer j = 1;
            for (Contact JOContactrec : JOContactlst) {
                i = i + 1;
                
                string jobuyermobilenum = JOContactrec.MobileCountryCode__c + JOContactrec.MobilePhone ;
                string jobuyeranchor = 'JointOwner' + j + ':' ;
                string jobuyeranchorsigneddate = 'JointOwner' + j + 'SignedDate:' ;
                j++;
                
                dfsle.Tab JointOwnertab = new dfsle.SignHereTab()
                    .withScale(1) // 1.5 scale
                    .withRequired(true) // Signing mandatory
                    .withAnchor(new dfsle.Tab.Anchor(
                        jobuyeranchor, // Anchor string
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
                
                dfsle.Tab JOCustomerDateSignedTab = new dfsle.DateSignedTab()
                    .withAnchor(new dfsle.Tab.Anchor(
                        jobuyeranchorsigneddate,
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
                
                dfsle.Recipient myJORecipient = dfsle.Recipient.fromSource(
                    JOContactrec.Name,
                    JOContactrec.Email,
                    jobuyermobilenum, 
                    jobuyeranchor,
                    null)
                    .withTabs(new List<dfsle.Tab> {
                        JointOwnertab, JOCustomerDateSignedTab
                            }).withRoutingOrder(i);
                
                allrecipients.add (myJORecipient);
            }
        }
        
        if (documentoutputname.Contains ('SPA')){
            
            if(Salesmangerlist[0].Opportunity__c != NULL && Salesmangerlist[0].Opportunity__r.BrokerAgentContact__c != NULL
               && Salesmangerlist[0].Opportunity__r.BrokerAgentContact__r.Email != NULL){
                   dfsle.Tab mybrokeragentTab = new dfsle.SignHereTab()
                       .withScale(1) // 1.5 scale
                       .withRequired(true) // Signing mandatory
                       .withAnchor(new dfsle.Tab.Anchor(
                           'BrokerAgent:', // Anchor string
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
                   
                    dfsle.Recipient mybrokeragentrecipient = dfsle.Recipient.fromSource(
                        Salesmangerlist[0].Opportunity__r.BrokerAgentContact__r.Name,
                        Salesmangerlist[0].Opportunity__r.BrokerAgentContact__r.Email,
                        null,
                        'BrokerAgent:',
                        null).withTabs(new List<dfsle.Tab> {
                            mybrokeragentTab
                                }).withRoutingOrder(11);
                    
                    allrecipients.add (mybrokeragentrecipient);
               }
            
            // Define the Sales Manager Signature Tab
            dfsle.Tab mySalesManagerMgrTab = new dfsle.SignHereTab()
                .withScale(1) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'SalesManagerMgr:', // Anchor string
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
            
            // Create the Sales Manager Recipient
            dfsle.Recipient mySalesManagerMgrrecipient = dfsle.Recipient.fromSource(
                System.Label.DocusignBloomSMgrName,
                System.Label.DocusignBloomSMgrEmail,
                null, 
                'SalesManagerMgr:',
                null).withTabs(new List<dfsle.Tab> {
                    mySalesManagerMgrTab
                        }).withRoutingOrder(12);
            
            allrecipients.add(mySalesManagerMgrrecipient);
            
            
            // Define the Approver Signature Tab
            dfsle.Tab approverSignatureTab = new dfsle.SignHereTab()
                .withScale(1) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'ApproverSignature:', // Anchor string
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
            
            dfsle.Tab myApproveTab = new dfsle.ApproveTab().withAnchor(new dfsle.Tab.Anchor(
                'Approver', // Anchor string
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
                    null)); 
            
            dfsle.Recipient myapproverrecipient = dfsle.Recipient.fromSource(
                System.Label.DocusignApproverName,
                System.Label.DocusignApproverEmail,
                null, 
                'Approver',
                null).withTabs(new List<dfsle.Tab> {
                    myApproveTab, approverSignatureTab
                        }).withRoutingOrder(13);
            
            allrecipients.add (myapproverrecipient);
            
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
            
            dfsle.Recipient myBloomSignrecipient1 = dfsle.Recipient.fromSource(
                System.Label.DocusignBloomSigner1Name,
                System.Label.DocusignBloomSigner1Email,
                null, 
                'BloomSigner1:',
                null).withTabs(new List<dfsle.Tab> {
                    myBloomSignHereTab1
                        }).withRoutingOrder(14);
            
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
                        }).withRoutingOrder(15);
            
            allrecipients.add (myBloomSignrecipient2);
            
            dfsle.SignHereTab.Stamp myStamp = new dfsle.SignHereTab.Stamp('stamp',null,null,null,null,null,null,null);      

            dfsle.Tab myStampTab = new dfsle.SignHereTab().withStamp(myStamp)
                .withScale(1.5) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'PhysicalStamp:', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    'right', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    30, // X offset
                    0)); // Y offset
            
            dfsle.Tab projectIdTab = new dfsle.TextTab().withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'ProjectID:', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    'right', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    60, // X offset
                    0)); // Y offset
            
            dfsle.Tab dateTab = new dfsle.DateTab().withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'FinalStampDate:', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    'right', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    80, // X offset
                    0)); // Y offset
            
            
            /* dfsle.Recipient mystamperRecipient = dfsle.Recipient.fromSource(
            System.Label.DocusigneStamperName,
            System.Label.DocusigneStamperEmail,
            null, 
            'FinalStamper:',
            null)
            .withTabs(new List<dfsle.Tab> {
            myStampTab  , projectIdTab, dateTab
            }).withRoutingOrder(15); */
            
            MetadataService objMetadataService = MetadataService.getInstance();
            // Define the Signing Group object
            dfsle.SigningGroup sg = new dfsle.SigningGroup(objMetadataService.getAppSettingNumberValue('DocuSignSPAStamperGroup'),objMetadataService.getAppSettingTextValue('DocuSignSPAStamperGroup'));
            // Construct the Recipient using the full constructor
            dfsle.Recipient mystamperRecipient = new dfsle.Recipient(
                null,                  // Id (not needed for signing group)
                'signingGroup',        // type
                1,                     // sequence
                1,                     // routingOrder
                new dfsle.Recipient.Role('FinalStamper:', null),                  // role
                null,                  // name (not needed)
                null,                  // email (not needed)
                sg,                    // signingGroup object
                null,                  // phone
                null,                  // authentication
                'Please sign on behalf of the group', // note
                null,                  // emailSettings
                null,                  // hostName
                null,                  // hostEmail
                false,                 // signNow
                new dfsle.Entity(recordid), // source entity
                false,                 // readOnly
                true                   // required
            ).withTabs(new List<dfsle.Tab> {
                myStampTab  , projectIdTab, dateTab
                    }).withRoutingOrder(16);
            
            allrecipients.add (mystamperRecipient);
            
            
            if(System.Label.DocusigneSeal == 'True') {
                
                dfsle.Tab myesealTab = new dfsle.SignHereTab()
                    .withScale(1) // 1.5 scale
                    .withRequired(true) // Signing mandatory
                    .withAnchor(new dfsle.Tab.Anchor(
                        'BloomHoldingeSeal', // Anchor string
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
                            null));
                
                dfsle.Recipient mysealrecipient = dfsle.Recipient.fromSource(
                    null,
                    System.Label.DocusigneSealEmail,
                    null, 
                    'BloomHoldingeSeal',
                    null).withTabs(new List<dfsle.Tab> {
                        myesealTab 
                            }).withRoutingOrder(18);
                
                allrecipients.add (mysealrecipient);
            }
        }
        
        if(documentoutputname.Contains ('Offer')){
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
            
            dfsle.Recipient myBloomSignrecipient1 = dfsle.Recipient.fromSource(
                System.Label.DocusignBloomSigner1Name,
                System.Label.DocusignBloomSigner1Email,
                null, 
                'BloomSigner1:',
                null).withTabs(new List<dfsle.Tab> {
                    myBloomSignHereTab1
                        }).withRoutingOrder(13);
            
            allrecipients.add (myBloomSignrecipient1);
            
            dfsle.Recipient myBloomSignrecipient2 = dfsle.Recipient.fromSource(
                System.Label.DocusignBloomSigner2Name,
                System.Label.DocusignBloomSigner2Email,
                null, 
                'BloomSigner2:',
                null).withTabs(new List<dfsle.Tab> {
                    myBloomSignHereTab2
                        }).withRoutingOrder(14);
            
            allrecipients.add (myBloomSignrecipient2);
        }
        
        if (documentoutputname.Contains('Broker')) {
            dfsle.Tab mybrokeragentTab = new dfsle.SignHereTab()
                .withScale(1) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'BrokerAgent:', // Anchor string
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
            
            
            dfsle.Recipient mybrokeragentrecipient = dfsle.Recipient.fromSource(
                Salesmangerlist[0].Opportunity__r.BrokerAgentContact__r.Name,
                Salesmangerlist[0].Opportunity__r.BrokerAgentContact__r.Email,
                null,
                'BrokerAgent:',
                null).withTabs(new List<dfsle.Tab> {
                    mybrokeragentTab
                        }).withRoutingOrder(11);
            
            allrecipients.add (mybrokeragentrecipient);
            
            
            // Define the Sales Manager Signature Tab
            dfsle.Tab mySalesManagerMgrTab = new dfsle.SignHereTab()
                .withScale(1) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'SalesManagerMgr:', // Anchor string
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
            
            // Create the Sales Manager Recipient
            dfsle.Recipient mySalesManagerMgrrecipient = dfsle.Recipient.fromSource(
                System.Label.DocusignBloomSMgrName,
                System.Label.DocusignBloomSMgrEmail,
                null, 
                'SalesManagerMgr:',
                null).withTabs(new List<dfsle.Tab> {
                    mySalesManagerMgrTab
                        }).withRoutingOrder(12);
            
            allrecipients.add(mySalesManagerMgrrecipient);
            
            // Define the Approver Signature Tab
            dfsle.Tab approverSignatureTab = new dfsle.SignHereTab()
                .withScale(1) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'ApproverSignature:', // Anchor string
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
            
            // Define the Approve Tab
            dfsle.Tab myApproveTab = new dfsle.ApproveTab().withAnchor(new dfsle.Tab.Anchor(
                'Approver', // Anchor string
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
                    null)); 
            
            // Create the Approver Recipient
            dfsle.Recipient myapproverrecipient = dfsle.Recipient.fromSource(
                System.Label.DocusignApproverName,
                System.Label.DocusignApproverEmail,
                null, 
                'Approver',
                null).withTabs(new List<dfsle.Tab> {
                    myApproveTab, approverSignatureTab
                        }).withRoutingOrder(13);
            
            allrecipients.add(myapproverrecipient);
                                
        }
        return allrecipients;
    }
    
    public static List<dfsle.Recipient> SalesOrderGetRecipientsForBloomSignerOne(Id recordId, String documentOutputName) {
        // Signature tab
        dfsle.Tab signHereTab = new dfsle.SignHereTab()
            .withRequired(true)
            .withAnchor(new dfsle.Tab.Anchor(
                'BloomSigner1:',
                false, false, 'right',
                true, true, 'pixels',
                0, 0));
        
        // Stamp tab
        dfsle.SignHereTab.Stamp myStamp = new dfsle.SignHereTab.Stamp('stamp',null,null,null,null,null,null,null);      

        dfsle.Tab myStampTab = new dfsle.SignHereTab().withStamp(myStamp)
            .withRequired(true)
            .withScale(1.5)
            .withAnchor(new dfsle.Tab.Anchor(
                'PhysicalStamp:',
                false, false, 'right',
                true, true, 'pixels',
                30, 0));
        
        // Recipient with both tabs
        dfsle.Recipient bloomSigner = dfsle.Recipient.fromSource(
            System.Label.DocusignBloomSigner1Name,
            System.Label.DocusignBloomSigner1Email,
            null,
            'FinalStamper:', // must match your DocuSign role
            null
        ).withTabs(new List<dfsle.Tab>{ signHereTab, myStampTab })
            .withRoutingOrder(1);
        
        return new List<dfsle.Recipient>{ bloomSigner };
    }
    
    public static List<dfsle.Recipient> HandoverGetRecipients(Id recordid, String documentoutputname){
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
        
        dfsle.Recipient myBloomSignrecipient1 = dfsle.Recipient.fromSource(
            System.Label.DocusignBloomSigner1Name,
            System.Label.DocusignBloomSigner1Email,
            null, 
            'BloomSigner1:',
            null).withTabs(new List<dfsle.Tab> {
                myBloomSignHereTab1
                    }).withRoutingOrder(13);
        
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
        
        allrecipients.add (myBloomSignrecipient2);
        return allrecipients;
    }
    
    public static List<dfsle.Recipient> BAPPGetRecipients(Id recordid, String documentoutputname) {
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

     public static List<dfsle.Recipient> CaseGetRecipients(Id caseId){
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
    
    public static List<dfsle.Recipient> CaseGetRecipientsforCIS(Id caseId, String documentoutputname) {
        List<dfsle.Recipient> allrecipients = new List<dfsle.Recipient> () ;
        Case cs = [SELECT Id,AccountId,Account.CompanyEmail__c,Account.Name,Sales_Order__c FROM Case Where Id =:caseId];
        
        
        List<Contact> Contactlst = [SELECT id, Name, MobileCountryCode__c, MobilePhone, Email From Contact Where AccountId IN (select AccountId from Case where id = :caseId) ];
        
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
            
            string mainbuyermobilenum = MainBuyerrec.MobileCountryCode__c + MainBuyerrec.MobilePhone ;
            
            if (System.Label.DocusignInitialsReqd == 'True') {
                dfsle.Recipient mainbuyerRecipient = dfsle.Recipient.fromSource(
                MainBuyerrec.Name,
                MainBuyerrec.Email,
                mainbuyermobilenum , 
                'MainBuyer:',
                null)
                .withTabs(new List<dfsle.Tab> {
                    mainbuyerSignHereTab, mainCustomerDateSignedTab, initialHereTab
                        }).withRoutingOrder(i);

                allrecipients.add (mainbuyerRecipient);
            
            } else {
                dfsle.Recipient mainbuyerRecipient = dfsle.Recipient.fromSource(
                    MainBuyerrec.Name,
                    MainBuyerrec.Email,
                    mainbuyermobilenum , 
                    'MainBuyer:',
                    null)
                    .withTabs(new List<dfsle.Tab> {
                        mainbuyerSignHereTab, mainCustomerDateSignedTab
                            }).withRoutingOrder(i);

                allrecipients.add (mainbuyerRecipient);
            }
        }
        return allrecipients;
    }
}