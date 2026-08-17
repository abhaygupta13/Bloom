public class Bldocusigncls {
    public static List<dfsle.Recipient>  getRecipients(Id recordid, String documentoutputname) 
    {
        system.debug('recordid');
        system.debug(recordid);
        system.debug('documentoutputname');
        system.debug(documentoutputname);
        List<dfsle.Recipient> allrecipients = new List<dfsle.Recipient> () ;
        List<SalesOrder__c> Salesmangerlist = [select id,SalesManager__r.Name,SalesManager__r.Email, Opportunity__r.BrokerAgentContact__r.Name,Opportunity__r.BrokerAgentContact__r.Email, Opportunity__r.AgentType__c from SalesOrder__c   where id =: recordid ];
        
        List<Contact> Contactlst = [SELECT id, Name, MobileCountryCode__c, MobilePhone, Email From Contact Where AccountId IN (select Account__c from SalesOrder__c where id = :recordId) ];
        system.debug(Contactlst);
        integer i = 1;   
        
        for (Contact MainBuyerrec : Contactlst) 
        {   
            // Create a Sign Here tab
            dfsle.Tab mainbuyerSignHereTab = new dfsle.SignHereTab()
                .withScale(1.25) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'MainBuyer:', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    'right', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    30, // X offset
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
                .withScale(1.5) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'MBIni:', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    'right', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    30, // X offset
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
        
        
        system.debug('get jos');
        List<Contact> JOContactlst = [SELECT id, Name, MobileCountryCode__c, MobilePhone, Email From Contact Where Accountid IN (SELECT Account__c from JointOwner__c where SalesOrder__c = :recordId)];
        system.debug(JOContactlst);
        integer j = 1;
        for (Contact JOContactrec : JOContactlst) 
        {
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
                .withScale(1.25) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    jobuyeranchor, // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    'right', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    30, // X offset
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
        
        if (documentoutputname.Contains ('SPA'))
        {
            system.debug('contains SPA yes');
            dfsle.Tab myApproveTab = new dfsle.ApproveTab().withAnchor(new dfsle.Tab.Anchor(
                'Approver', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'right', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                30, // X offset
                0)).withPosition(new dfsle.Tab.Position(
                    1, 
                    null,
                    null,
                    null,
                    null,
                    null)); 
            system.debug('approve tab added');
            
            dfsle.Tab myBloomSignHereTab1 = new dfsle.SignHereTab()
                .withScale(1.25) // 1.5 scale
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
                .withScale(1.25) // 1.5 scale
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
            
            dfsle.Tab myesealTab = new dfsle.SignHereTab()
                .withScale(1.5) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'BloomHoldingeSeal', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    'right', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    30, // X offset
                    0)).withPosition(new dfsle.Tab.Position(
                        1, 
                        null,
                        null,
                        null,
                        null,
                        null));
            system.debug('eseal tab added');
            
            system.debug('4 tabs added Approver, Bloom signer 1, Bloom signer 2, eSeal');
            system.debug(i+1);
            
            system.debug('System.Label.DocusignApproverName');
            system.debug(System.Label.DocusignApproverName);
            system.debug('System.Label.DocusignApproverEmail');
            system.debug(System.Label.DocusignApproverEmail);
            system.debug('System.Label.DocusignBloomSigner1Name');
            system.debug(System.Label.DocusignBloomSigner1Name);
            system.debug('System.Label.DocusignBloomSigner1Email');
            system.debug(System.Label.DocusignBloomSigner1Email);
            system.debug('System.Label.DocusignBloomSigner2Name');
            system.debug(System.Label.DocusignBloomSigner2Name);
            system.debug('System.Label.DocusignBloomSigner2Email');
            system.debug(System.Label.DocusignBloomSigner2Email);
            system.debug('System.Label.DocusigneSeal');
            system.debug(System.Label.DocusigneSeal);
            system.debug('System.Label.DocusigneStamperName');
            system.debug(System.Label.DocusigneStamperName);
            system.debug('System.Label.DocusigneStamperEmail');
            system.debug(System.Label.DocusigneStamperEmail);
            
            system.debug('add approver tab');
            dfsle.Recipient myapproverrecipient = dfsle.Recipient.fromSource(
                System.Label.DocusignApproverName,
                System.Label.DocusignApproverEmail,
                null, 
                'Approver',
                null).withTabs(new List<dfsle.Tab> {
                    myApproveTab
                        }).withRoutingOrder(11);
            
            system.debug(myapproverrecipient);
            allrecipients.add (myapproverrecipient);
            
            system.debug('add bloom signer 1tab');
            system.debug(i+2);
            dfsle.Recipient myBloomSignrecipient1 = dfsle.Recipient.fromSource(
                System.Label.DocusignBloomSigner1Name,
                System.Label.DocusignBloomSigner1Email,
                null, 
                'BloomSigner1:',
                null).withTabs(new List<dfsle.Tab> {
                    myBloomSignHereTab1
                        }).withRoutingOrder(12);
            
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
                        }).withRoutingOrder(13);
            
            system.debug(myBloomSignrecipient2);
            allrecipients.add (myBloomSignrecipient2);
            If (System.Label.DocusigneSeal == 'True')
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
                            }).withRoutingOrder(14);
                
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
                dfsle.Tab FinalStampdateTab = new dfsle.TextTab().withFormatting(new dfsle.Tab.Formatting(
                    'Helvetica', // Font
                    'default', // Font color
                    14, // 14pt size,
                    true, // Bold
                    false, // Italic
                    false, // Underline
                    false, // Conceal value
                    false)).withRequired(true) // 1.5 scale  // Signing mandatory
                    .withAnchor(new dfsle.Tab.Anchor(
                        'FinalStampdate:', // Anchor string
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
                            }).withRoutingOrder(1);
                
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
                
                /*                
dfsle.Tab dateTab = new dfsle.TextTab().withFormatting(new dfsle.Tab.Formatting(
'Arial', // Font
'default', // Font color
15, // 14pt size,
true, // Bold
false, // Italic
false, // Underline
false, // Conceal value
false)).withRequired(true) // 1.5 scale  // Signing mandatory
.withAnchor(new dfsle.Tab.Anchor(
'FinalStampdate:', // Anchor string
false, // Do not allow white space in anchor string
false, // Anchor string is not case sensitive
'right', // Horizontal alignment in relation to the anchor text
true, // Ignore if the anchor text is not present in the document
true, // Must match the value of the anchor string in its entirety
'pixels', // Unit of the x and y offset properties
0, // X offset
0)); // Y offset
*/              
                system.debug('final stamper recipient');
                dfsle.Recipient mystamperRecipient = dfsle.Recipient.fromSource(
                    System.Label.DocusigneStamperName,
                    System.Label.DocusigneStamperEmail,
                    null, 
                    'FinalStamper:',
                    null)
                    .withTabs(new List<dfsle.Tab> {
                        myStampTab  , projectIdTab, dateTab
                            }).withRoutingOrder(15);
                
                allrecipients.add (mystamperRecipient);
                
            }
        }
        if (documentoutputname.Contains ('Book') || documentoutputname.Contains ('CIS'))            
        {
            /*
dfsle.Tab mySalesManagerTab = new dfsle.SignHereTab()                
.withScale(1.5) // 1.5 scale
.withRequired(true) // Signing mandatory
.withAnchor(new dfsle.Tab.Anchor(
'SalesManager:', // Anchor string
false, // Do not allow white space in anchor string
false, // Anchor string is not case sensitive
'right', // Horizontal alignment in relation to the anchor text
true, // Ignore if the anchor text is not present in the document
true, // Must match the value of the anchor string in its entirety
'pixels', // Unit of the x and y offset properties
30, // X offset
0)).withPosition(new dfsle.Tab.Position(
1,
null,
null,
null,
null,
null)); // Y offset

system.debug(i+3);
dfsle.Recipient mySalesManagerrecipient = dfsle.Recipient.fromSource(
Salesmangerlist[0].SalesManager__r.Name,
Salesmangerlist[0].SalesManager__r.Email,
null,
'SalesManager:',
null).withTabs(new List<dfsle.Tab> {
mySalesManagerTab
}).withRoutingOrder(11);

system.debug(mySalesManagerrecipient);

allrecipients.add (mySalesManagerrecipient);
*/
            dfsle.Tab mySalesManagerMgrTab = new dfsle.SignHereTab()
                .withScale(1.5) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'SalesManagerMgr:', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    'right', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    30, // X offset
                    0)).withPosition(new dfsle.Tab.Position(
                        1, 
                        null,
                        null,
                        null,
                        null,
                        null)); // Y offset
            
            system.debug(i+3);
            dfsle.Recipient mySalesManagerMgrrecipient = dfsle.Recipient.fromSource(
                System.Label.DocusignBloomSMgrName,
                System.Label.DocusignBloomSMgrEmail,
                null, 
                'SalesManagerMgr:',
                null).withTabs(new List<dfsle.Tab> {
                    mySalesManagerMgrTab
                        }).withRoutingOrder(11);
            
            system.debug(mySalesManagerMgrrecipient);
            allrecipients.add (mySalesManagerMgrrecipient);
            /*
dfsle.Tab mySalesOpsTab = new dfsle.SignHereTab()
.withScale(1.5) // 1.5 scale
.withRequired(true) // Signing mandatory
.withAnchor(new dfsle.Tab.Anchor(
'SalesOpsName:', // Anchor string
false, // Do not allow white space in anchor string
false, // Anchor string is not case sensitive
'right', // Horizontal alignment in relation to the anchor text
true, // Ignore if the anchor text is not present in the document
true, // Must match the value of the anchor string in its entirety
'pixels', // Unit of the x and y offset properties
30, // X offset
0)).withPosition(new dfsle.Tab.Position(
1, 
null,
null,
null,
null,
null)); // Y offset

system.debug(i+3);
dfsle.Recipient mySalesOpsrecipient = dfsle.Recipient.fromSource(
System.Label.DocusignBloomSOpsName,
System.Label.DocusignBloomSOpsEmail,
null, 
'SalesOpsName:',
null).withTabs(new List<dfsle.Tab> {
mySalesOpsTab
}).withRoutingOrder(13);


system.debug(mySalesOpsrecipient);
allrecipients.add (mySalesOpsrecipient);
*/
            
            system.debug('Booking form');
            if (Salesmangerlist[0].Opportunity__r.AgentType__c == 'Indirect')
            {            dfsle.Tab mybrokeragentTab = new dfsle.SignHereTab()
                .withScale(1.5) // 1.5 scale
                .withRequired(true) // Signing mandatory
                .withAnchor(new dfsle.Tab.Anchor(
                    'BrokerAgent:', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    'right', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    30, // X offset
                    0)).withPosition(new dfsle.Tab.Position(
                        1,
                        null,
                        null,
                        null,
                        null,
                        null)); // Y offset
             
             system.debug(i+3);
             
             dfsle.Recipient mybrokeragentrecipient = dfsle.Recipient.fromSource(
                 Salesmangerlist[0].Opportunity__r.BrokerAgentContact__r.Name,
                 Salesmangerlist[0].Opportunity__r.BrokerAgentContact__r.Email,
                 null,
                 'BrokerAgent:',
                 null).withTabs(new List<dfsle.Tab> {
                     mybrokeragentTab
                         }).withRoutingOrder(12);
             
             system.debug(mybrokeragentrecipient);
             
             allrecipients.add (mybrokeragentrecipient);
            }
            system.debug('contains SPA no');
            dfsle.Tab myApproveTab = new dfsle.ApproveTab().withAnchor(new dfsle.Tab.Anchor(
                'Approver', // Anchor string
                false, // Do not allow white space in anchor string
                false, // Anchor string is not case sensitive
                'right', // Horizontal alignment in relation to the anchor text
                true, // Ignore if the anchor text is not present in the document
                true, // Must match the value of the anchor string in its entirety
                'pixels', // Unit of the x and y offset properties
                30, // X offset
                0)).withPosition(new dfsle.Tab.Position(
                    1, 
                    null,
                    null,
                    null,
                    null,
                    null)); 
            system.debug('approve tab added');
            
            dfsle.Tab myBloomSignHereTab1 = new dfsle.SignHereTab()
                .withScale(1.25) // 1.5 scale
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
                .withScale(1.25) // 1.5 scale
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
            
            dfsle.Recipient myapproverrecipient = dfsle.Recipient.fromSource(
                System.Label.DocusignApproverName,
                System.Label.DocusignApproverEmail,
                null, 
                'Approver',
                null).withTabs(new List<dfsle.Tab> {
                    myApproveTab
                        }).withRoutingOrder(13);
            
            system.debug(myapproverrecipient);
            allrecipients.add (myapproverrecipient);
            
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
            
        }
        return allrecipients;
    }
    
    /*@InvocableMethod(label='Bloom Run Docusign template')
    public static void BlsendSPAEnvelopeInv(List<String> Ids) 
    {
        String[] docusignsubmissionidlst = Ids[0].split(',');
        system.debug('concatparams');
        system.debug(docusignsubmissionidlst);
        List <Bloom_Docusign_Submissions__c> docusignlst = [select id, description__c, Docusign_Envelope_Template_ID__c, Sales_Order_ID__r.ProjectName__c,
                                                            Sales_Order_ID__r.UnitNumber__c,Document_Output_Name__c
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
    
    @future(callout=true)
    public static void BlsendSPAEnvelope(String template, String description, Id recordId, Id salesorderid, String documentoutputname,String emailSubject) {
        documentoutputname = '%'+ documentoutputname + '%';
        System.debug('docoutputname'+documentoutputname);
        System.debug('recordId'+recordId);
        System.debug('template'+template);
        system.debug('Start of send envelope');
        
         dfsle.Notifications notifySigner = new dfsle.Notifications(
            true, // Indicates that the recipient should be reminded to sign
            2, // Number of days to wait before sending a reminder
            1, // Number of days between reminders
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
        ContentDocumentLink cdl = [select id, ContentDocument.title, ContentDocumentId from ContentDocumentLink where LinkedEntityId = :recordId and ContentDocument.Title like :documentoutputname  Order by SystemModstamp desc LIMIT 1];
        System.debug('cdl'+cdl);
        Id myDocumentId = Id.valueOf(cdl.ContentDocumentId);
        System.debug(myDocumentId);
        ContentVersion cv = [SELECT FileType, Title, ContentDocumentId From ContentVersion where ContentDocumentId = :myDocumentId LIMIT 1];
        System.debug(cv);
        myDocument.withReplacement(dfsle.Document.fromFile(cv));
        
        // Update envelope with template & replacement document
        system.debug('get document done');
        myEnvelope = myEnvelope.withDocuments(new List<dfsle.Document> { myDocument });
        myEnvelope =myEnvelope.withEmail(emailSubject,null);
        myEnvelope=  myEnvelope.withNotifications(notifySigner);
        system.debug('attached document to envelope');
        
        List<dfsle.Recipient> allrecipients = getRecipients(salesorderid, documentoutputname) ; 
        
        system.debug('recipients received');
        system.debug(allrecipients.size());
        myEnvelope = myEnvelope.withRecipients(allrecipients);
        system.debug('add recipients to envelope');
        
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