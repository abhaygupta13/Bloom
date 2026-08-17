public class BldocusignSpacls {
    public static List<dfsle.Recipient>  getRecipients(Id recordid, String documentoutputname) 
    {
        system.debug('recordid');
        system.debug(recordid);
        system.debug('documentoutputname');
        system.debug(documentoutputname);
        List<dfsle.Recipient> allrecipients = new List<dfsle.Recipient> () ;
        List<SalesOrder__c> Salesmangerlist = [select id,SalesManager__r.Name,SalesManager__r.Email, Opportunity__c,
                                                Opportunity__r.BrokerAgentContact__c, Opportunity__r.BrokerAgentContact__r.Name,
                                                Opportunity__r.BrokerAgentContact__r.Email, Opportunity__r.AgentType__c, 
                                                ReferrersName__c, ReferrersEmail__c 
                                                FROM SalesOrder__c
                                                WHERE id =: recordid ];
        
        List<Contact> Contactlst = [SELECT id, Name, MobileCountryCode__c, MobilePhone, Email From Contact Where AccountId IN (select Account__c from SalesOrder__c where id = :recordId) ];
        system.debug(Contactlst);
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
            system.debug('Referrertab');
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
            system.debug('referrerSignedtab');
            
            //string mainbuyermobilenum = MainBuyerrec.MobileCountryCode__c + MainBuyerrec.MobilePhone ;
            //system.debug(mainbuyermobilenum);
            system.debug(i);
            If (System.Label.DocusignInitialsReqd == 'True'){
                dfsle.Recipient referrerRecipient = dfsle.Recipient.fromSource(
                Salesmangerlist[0].ReferrersName__c,
                Salesmangerlist[0].ReferrersEmail__c,
                null , 
                'Referrer:',
                null)
                .withTabs(new List<dfsle.Tab> {
                    referrerSignHereTab, mainCustomerDateSignedTab, initialHereTab
                        }).withRoutingOrder(i);
             system.debug('add mainbuyerreceipient');
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
                system.debug('add referrerRecipient');
                allrecipients.add (referrerRecipient);
            }
            system.debug(allrecipients);
        }
       
        if(!documentoutputname.Contains('Broker') && !documentoutputname.Contains('Referral')){
            system.debug('get jos');
            List<Contact> JOContactlst = [SELECT id, Name, MobileCountryCode__c, MobilePhone, Email From Contact Where Accountid IN (SELECT Account__c from JointOwner__c where SalesOrder__c = :recordId)];
            system.debug(JOContactlst);
            integer j = 1;
            for (Contact JOContactrec : JOContactlst) {
                i = i + 1;
                system.debug('jos inside');
                system.debug(i);
                string jobuyermobilenum = JOContactrec.MobileCountryCode__c + JOContactrec.MobilePhone ;
                string jobuyeranchor = 'JointOwner' + j + ':' ;
                string jobuyeranchorsigneddate = 'JointOwner' + j + 'SignedDate:' ;
                j++;
                system.debug(jobuyermobilenum);
                system.debug(jobuyeranchor);
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
                
                system.debug('jo tab added');
                
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
                
                system.debug('jo signeddate tab added');
                
                system.debug(i);
                dfsle.Recipient myJORecipient = dfsle.Recipient.fromSource(
                    JOContactrec.Name,
                    JOContactrec.Email,
                    jobuyermobilenum, 
                    jobuyeranchor,
                    null)
                    .withTabs(new List<dfsle.Tab> {
                        JointOwnertab, JOCustomerDateSignedTab
                            }).withRoutingOrder(i);
                
                system.debug(myJORecipient);
                allrecipients.add (myJORecipient);
                system.debug('added');
            }
        }
        
        if (documentoutputname.Contains ('SPA')){
            system.debug('contains SPA yes');

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
                
                    //  system.debug(i+3);
                
                dfsle.Recipient mybrokeragentrecipient = dfsle.Recipient.fromSource(
                    Salesmangerlist[0].Opportunity__r.BrokerAgentContact__r.Name,
                    Salesmangerlist[0].Opportunity__r.BrokerAgentContact__r.Email,
                    null,
                    'BrokerAgent:',
                    null).withTabs(new List<dfsle.Tab> {
                        mybrokeragentTab
                            }).withRoutingOrder(11);
                
                system.debug('mybrokeragentrecipient :::::' + mybrokeragentrecipient);
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

            system.debug(i+3);
        
            // Create the Sales Manager Recipient
            dfsle.Recipient mySalesManagerMgrrecipient = dfsle.Recipient.fromSource(
            System.Label.DocusignBloomSMgrName,
            System.Label.DocusignBloomSMgrEmail,
            null, 
            'SalesManagerMgr:',
            null).withTabs(new List<dfsle.Tab> {
                mySalesManagerMgrTab
            }).withRoutingOrder(12);
        
            system.debug(mySalesManagerMgrrecipient);
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

            system.debug(i+3);
             
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
            system.debug('approve tab added');

            system.debug('add approver tab');
            dfsle.Recipient myapproverrecipient = dfsle.Recipient.fromSource(
                System.Label.DocusignApproverName,
                System.Label.DocusignApproverEmail,
                null, 
                'Approver',
                null).withTabs(new List<dfsle.Tab> {
                    myApproveTab, approverSignatureTab
                        }).withRoutingOrder(13);
            
            system.debug(myapproverrecipient);
            allrecipients.add (myapproverrecipient);
            
            /*dfsle.Tab myBloomSignHereTab0 = new dfsle.SignHereTab()
                .withScale(1.25) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'BloomSigner0:', // Anchor string
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
            */
            
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
            system.debug(i+2);
            dfsle.Recipient myBloomSignrecipient1 = dfsle.Recipient.fromSource(
                System.Label.DocusignBloomSigner1Name,
                System.Label.DocusignBloomSigner1Email,
                null, 
                'BloomSigner1:',
                null).withTabs(new List<dfsle.Tab> {
                    myBloomSignHereTab1
                        }).withRoutingOrder(14);
            
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
            system.debug('signed 2 tab added');

            system.debug('add bloom signer 2tab');
            system.debug(i+3);
            dfsle.Recipient myBloomSignrecipient2 = dfsle.Recipient.fromSource(
                System.Label.DocusignBloomSigner2Name,
                System.Label.DocusignBloomSigner2Email,
                null, 
                'BloomSigner2:',
                null).withTabs(new List<dfsle.Tab> {
                    myBloomSignHereTab2
                        }).withRoutingOrder(15);
            
            system.debug(myBloomSignrecipient2);
            allrecipients.add (myBloomSignrecipient2);

            dfsle.SignHereTab.Stamp myStamp = new dfsle.SignHereTab.Stamp('stamp',null,null,null,null,null,null,null);      
                system.debug('sign here stamp tab PhysicalStamp:');
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
                
                system.debug('project id tab');
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
                
                system.debug('final stamp date tab');
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
                
                
                system.debug('final stamper recipient');
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
                system.debug('eseal true');
                system.debug(i+4);

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
                system.debug('eseal tab added');

                dfsle.Recipient mysealrecipient = dfsle.Recipient.fromSource(
                    null,
                    System.Label.DocusigneSealEmail,
                    null, 
                    'BloomHoldingeSeal',
                    null).withTabs(new List<dfsle.Tab> {
                        myesealTab 
                            }).withRoutingOrder(18);
                
                system.debug('eseal recipient done');
                system.debug(mysealrecipient);
                allrecipients.add (mysealrecipient);
            }

            /* Added Mahmoud in the Signing Order */ 
            /*dfsle.Recipient myBloomSignrecipient0 = dfsle.Recipient.fromSource(
                System.Label.DocusignBloomSigner0Name,
                System.Label.DocusignBloomSigner0Email,
                null, 
                'BloomSigner0:',
                null).withTabs(new List<dfsle.Tab> {
                    myBloomSignHereTab0
                        }).withRoutingOrder(11);
            
            system.debug(myBloomSignrecipient0);
            allrecipients.add (myBloomSignrecipient0);*/
            /*****/
            
            /*If (System.Label.DocusigneSeal == 'True')
            {
                system.debug('eseal true');
                system.debug(i+4);
                dfsle.Recipient mysealrecipient = dfsle.Recipient.fromSource(
                    null,
                    System.Label.DocusigneSealEmail,
                    null, 
                    'BloomHoldingeSeal',
                    null).withTabs(new List<dfsle.Tab> {
                        myesealTab 
                            }).withRoutingOrder(15);
                
                system.debug('eseal recipient done');
                system.debug(mysealrecipient);
                
                
                
                allrecipients.add (mysealrecipient);
                      
                system.debug('project id tab');
                dfsle.Tab projectIdTab = new dfsle.TextTab().withRequired(true) // Signing mandatory
                    .withAnchor(new dfsle.Tab.Anchor(
                        'ProjectID:', // Anchor string
                        false, // Do not allow white space in anchor string
                        false, // Anchor string is not case sensitive
                        'right', // Horizontal alignment in relation to the anchor text
                        true, // Ignore if the anchor text is not present in the document
                        true, // Must match the value of the anchor string in its entirety
                        'pixels', // Unit of the x and y offset properties
                        20, // X offset
                        0)); // Y offset
                system.debug('final stamp date tab');
                dfsle.Tab FinalStampdateTab = new dfsle.DateTab().withFormatting(new dfsle.Tab.Formatting(
                    'Helvetica', // Font
                    'default', // Font color
                    14, // 14pt size,
                    true, // Bold
                    false, // Italic
                    false, // Underline
                    false, // Conceal value
                    false)).withRequired(true) // 1.5 scale  // Signing mandatory
                    .withAnchor(new dfsle.Tab.Anchor(
                        'FinalStampDate:', // Anchor string
                        false, // Do not allow white space in anchor string
                        false, // Anchor string is not case sensitive
                        'right', // Horizontal alignment in relation to the anchor text
                        true, // Ignore if the anchor text is not present in the document
                        true, // Must match the value of the anchor string in its entirety
                        'pixels', // Unit of the x and y offset properties
                        0, // X offset
                        0)); // Y offset
                system.debug('stamper receipieint');
                dfsle.Recipient myStamperRecipient = dfsle.Recipient.fromSource(
                    System.Label.DocusigneStamperName,
                    System.Label.DocusigneStamperEmail,
                    null, 
                    'FinalStamper:',
                    null)
                    .withTabs(new List<dfsle.Tab> {
                        projectIdTab, FinalStampdateTab
                            }).withRoutingOrder(16);
                
                allrecipients.add (myStamperRecipient);
                system.debug('stamper receipieint added');
                
            }
            else
            {
                system.debug('Not eseal');
                system.debug('sign here stamp');
                dfsle.SignHereTab.Stamp myStamp = new dfsle.SignHereTab.Stamp('stamp',null,null,null,null,null,null,null);      
                system.debug('sign here stamp tab PhysicalStamp:');
                dfsle.Tab myStampTab = new dfsle.SignHereTab().withStamp(myStamp)
                    .withScale(2) // 1.5 scale
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
                
                system.debug('project id tab');
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
                
                system.debug('final stamp date tab');
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
                
                
                system.debug('final stamper recipient');
                dfsle.Recipient mystamperRecipient = dfsle.Recipient.fromSource(
                    System.Label.DocusigneStamperName,
                    System.Label.DocusigneStamperEmail,
                    null, 
                    'FinalStamper:',
                    null)
                    .withTabs(new List<dfsle.Tab> {
                        myStampTab  , projectIdTab, dateTab
                            }).withRoutingOrder(16);
                
                allrecipients.add (mystamperRecipient);
                
            }*/
        }

        if (documentoutputname.Contains('Sales Purchase Agreement') || documentoutputname.Contains('Booking Form')){
            system.debug('contains Sales Purchase Agreement yes');
            
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
            system.debug(i+2);
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
            system.debug('signed 1 tab added');
            
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
            system.debug('signed 2 tab added');
            
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
            
            system.debug('add bloom signer 2tab');
            system.debug(i+3);
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
        }

        if (documentoutputname.Contains('Broker')) {
            System.debug('::::: Inside Broker block :::::');
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
             
           //  system.debug(i+3);
             
             dfsle.Recipient mybrokeragentrecipient = dfsle.Recipient.fromSource(
                 Salesmangerlist[0].Opportunity__r.BrokerAgentContact__r.Name,
                 Salesmangerlist[0].Opportunity__r.BrokerAgentContact__r.Email,
                 null,
                 'BrokerAgent:',
                 null).withTabs(new List<dfsle.Tab> {
                     mybrokeragentTab
                         }).withRoutingOrder(11);
             
             system.debug('mybrokeragentrecipient :::::' + mybrokeragentrecipient);
             
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

            system.debug(i+3);
        
            // Create the Sales Manager Recipient
            dfsle.Recipient mySalesManagerMgrrecipient = dfsle.Recipient.fromSource(
            System.Label.DocusignBloomSMgrName,
            System.Label.DocusignBloomSMgrEmail,
            null, 
            'SalesManagerMgr:',
            null).withTabs(new List<dfsle.Tab> {
                mySalesManagerMgrTab
            }).withRoutingOrder(12);
        
            system.debug(mySalesManagerMgrrecipient);
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

            system.debug(i+3);
        
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

            system.debug('approve tab added');
        
            // Create the Approver Recipient
            dfsle.Recipient myapproverrecipient = dfsle.Recipient.fromSource(
            System.Label.DocusignApproverName,
            System.Label.DocusignApproverEmail,
            null, 
            'Approver',
            null).withTabs(new List<dfsle.Tab> {
                myApproveTab, approverSignatureTab
            }).withRoutingOrder(13);
        
            system.debug(myapproverrecipient);
            allrecipients.add(myapproverrecipient);
        
            // Optionally, you can include debug logs for tracking
            system.debug('Sales Manager and Approver recipients added.');                       
        }
        return allrecipients;

    }
    
    /*@InvocableMethod(label='Bloom Run Docusign template')
    public static void BlsendSPAEnvelopeInv(List<String> Ids) 
    {
        String[] docusignsubmissionidlst = Ids[0].split(',');
        system.debug('concatparams');
        system.debug(docusignsubmissionidlst);
        List <Bloom_Docusign_Submissions__c> docusignlst = [select id, description__c, Docusign_Envelope_Template_ID__c, Sales_Order_ID__r.ProjectName__c,Sales_Order_ID__r.UnitNumber__c,Document_Output_Name__c
                                                            from Bloom_Docusign_Submissions__c where id IN :docusignsubmissionidlst];
        for (Bloom_Docusign_Submissions__c docusignrec : docusignlst)
        {
            system.debug(docusignlst);
            string docusignenvid = docusignrec.Docusign_Envelope_Template_ID__c;
            id salesorderid = docusignrec.Sales_Order_ID__c;
            String PropertyName = docusignrec.Sales_Order_ID__r.ProjectName__c;
            String unitNumber = docusignrec.Sales_Order_ID__r.UnitNumber__c;
            String emailSubject = 'Documents for your Signature |'+' '+PropertyName+'-'+unitNumber;
            string docoutputname = docusignrec.Document_Output_Name__c;
            string descrip = docusignrec.description__c;
            System.debug('docoutputname'+docoutputname);
            BlsendSPAEnvelope(docusignenvid, descrip, salesorderid, docoutputname,emailSubject) ;
        }
    }*/

    public static List<dfsle.Recipient> getRecipientsForBloomSignerOne(Id recordId, String documentOutputName) {
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
        system.debug('sign here stamp tab PhysicalStamp:');
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
        
    @future(callout=true)
    public static void BlsendSPAEnvelope(String template, String description, Id recordId, Id salesorderid, String documentoutputname,String emailSubject) 
    {
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
            new dfsle.Entity(salesorderid)
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
        
         /*
        ContentDocumentLink documentLink = [SELECT Id, ContentDocumentId
                                            FROM ContentDocumentLink
                                            WHERE LinkedEntityId = 'a0WKO000001Gh0W2AS' LIMIT 1];
        ContentDocument doc = [SELECT Id, Title FROM ContentDocument WHERE Id = :documentLink.ContentDocumentId];
        System.debug('Document title: ' + doc.Title);
        Id myFileId = [SELECT id from ContentVersion where ContentDocumentId = :doc.Id LIMIT 1].id;
        myEnvelope = myEnvelope.withDocuments(dfsle.DocumentService.getDocuments(ContentVersion.getSObjectType(), new Set<Id> { myFileId }));
        */
        
        ///
            
            
        List<dfsle.Recipient> allrecipients = new List<dfsle.Recipient>();
        if(documentoutputname.Contains('KYC Declaration Form')){
            allrecipients = getRecipientsForBloomSignerOne(salesorderid, documentoutputname);
        } else {
            allrecipients = getRecipients(salesorderid, documentoutputname); 
        }
        
        system.debug('recipients received');
        system.debug(allrecipients.size());
        myEnvelope = myEnvelope.withRecipients(allrecipients);
        system.debug('Envelope' + myEnvelope);
        
        myEnvelope = dfsle.EnvelopeService.sendEnvelope(
            myEnvelope,
            true
        );
        
        system.debug('send envelope done');
        System.debug(String.valueOf(myEnvelope.docuSignId));
        // Return string value of DocuSign envelope ID
        //return String.valueOf(myEnvelope.docuSignId);
    }    
}