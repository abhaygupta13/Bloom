/***
Class       : OpportunityUnitSearchHandler
Author      : Smaartt
Description : 
TestClass   : opportunityUnitSearchHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/07/23           Initial Version  
2.          V2.0              27/10/23           Added conditons for ADM Fee Amount && ADM Fee Waived Amount
calculation on conditon having offer or not.
****************************************************************************************************************/


public with sharing class OpportunityUnitSearchHandler {
    
    private static final string MTD_NO_ADM_Fee_Calculation_Value { get { return 'Adm_Fee_calculation_value'; } }
    
    @AuraEnabled(cacheable=false)
    public static map<id,SalesOfferUtilityHandler.SalesOfferDetails> generateSalesOffer(list<SalesOfferUtilityHandler.SaleOfferInputParam> saleOfferInputParam, Id opportunityId,integer SelectedUnitCount){
        
        map<Id,Id> unitIdToOffer = new map<Id,Id>();
        map<Id,String> unitIdToFinishtypeOption = new map<Id,String>();
        map<Id,boolean>unitIdToAdmFeeIncluded = new map<Id,boolean>();
        map<Id,boolean> unitToMultiPurposeAmountApplicableMap = new map<Id,boolean>();
        map<Id,ID> unitWithDesignMap = new  map<Id,ID>();
        map<id,set<Id>> unitToSelectedPaymentPlanMap=  new map<id,set<Id>>();
        System.debug('saleOfferInputParam'+saleOfferInputParam);
        for(SalesOfferUtilityHandler.SaleOfferInputParam tempPramObj : saleOfferInputParam){
            System.debug('tempPramObj'+tempPramObj);
            unitIdToOffer.put(tempPramObj.unitId,tempPramObj.offerId);
            unitIdToFinishtypeOption.put(tempPramObj.unitId,tempPramObj.finishingtypeValue);
            unitIdToAdmFeeIncluded.put(tempPramObj.unitId,tempPramObj.admincludedfee);
            System.debug('unitIdToAdmFeeIncluded'+unitIdToAdmFeeIncluded);
            if(tempPramObj.multiPurposeAmountApplicable!=null){
                unitToMultiPurposeAmountApplicableMap.put(tempPramObj.unitId,tempPramObj.multiPurposeAmountApplicable);
            }
            
            if(tempPramObj.designId!=null ){
                unitWithDesignMap.put(tempPramObj.unitId,tempPramObj.designId);
            }
            
            if(tempPramObj.selectedPayments!=null){
                unitToSelectedPaymentPlanMap.put(tempPramObj.unitId,new set<ID>(tempPramObj.selectedPayments) );
                System.debug('unitToSelectedPaymentPlanMap'+unitToSelectedPaymentPlanMap);
            }
        }
        
        return SalesOfferUtilityHandler.generateSalesOfferMap(unitIdToOffer,unitToMultiPurposeAmountApplicableMap,unitToSelectedPaymentPlanMap,unitWithDesignMap,opportunityId,SelectedUnitCount,unitIdToFinishtypeOption,unitIdToAdmFeeIncluded);
        
    }
    
    
    
    
    
    //to get the list of all projects
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getAllProjects(){
        list<map<String,string>> filtersToReturn = new list<map<String,string>>();
        
        for(Project__c tempProject: [select id,Name from Project__c where IsActive__c = true AND IsAvailableForSales__c = true  WITH SECURITY_ENFORCED order by Name])//ProjectService.getAllActiveProjects())
        {
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempProject.Name);
            tempMap.put('value',tempProject.id);
            filtersToReturn.add(tempMap);
        }
        return filtersToReturn;
    }
    
    //to get the list of buildings based on the selected project
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getAllBuildings(string projectId){
        list<map<String,string>> filtersToReturn = new list<map<String,string>>();
        
        for(BuildingSection__c  tempBuilding: prepareBuildingsNames(projectId) ){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempBuilding.Name);
            tempMap.put('value',tempBuilding.id);
            filtersToReturn.add(tempMap);
        }
        return filtersToReturn;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<BuildingSection__c> prepareBuildingsNames(String projectId){ 
        list<BuildingSection__c> lstLocationName = new list<BuildingSection__c>();
        for(BuildingSection__c objP : [Select Id,Name from BuildingSection__c where Project__c   =: projectId WITH SECURITY_ENFORCED order by Name]){
            lstLocationName.add(objP);
        }
        return lstLocationName;
    }
    
    public with sharing class UnitWrapper{
        @AuraEnabled
        public list<map<String,string>> propertyUsageList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
            @AuraEnabled
            public list<map<String,string>> unitTypesSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
                @AuraEnabled
                public list<map<String,string>> unitModelSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
                    @AuraEnabled
                    public list<map<String,string>> floorNumberSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
                        @AuraEnabled
                        public list<map<String,string>> unitBedRoomsSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
                            @AuraEnabled
                            public list<map<String,string>> unitViewSetList = new list<map<String,string>>{new map<string,string>{'label' =>'All' , 'value' => ''}};
                                @AuraEnabled
                                public list<UnitDetilsWrapper> unitDetailList=new list<UnitDetilsWrapper>();
        public UnitWrapper(list<Unit__c> unitData){
            set<String> propertyUsageSet=new Set<String>();
            set<String> unitTypesSet=new Set<String>();
            set<String> unitModelSet=new Set<String>();
            set<String> floorNumberSet=new Set<String>();
            set<String> unitBedRoomsSet=new Set<String>();
            set<String> unitViewSet=new Set<String>();
            System.debug(unitData);
            for(Unit__c tempUnit : unitData){
                System.debug('Log: Inside propusage');
                if(tempUnit.PropertyUsage__c !=null ){
                    propertyUsageSet.add(tempUnit.PropertyUsage__c );
                }
                if(tempUnit.UnitType__c !=null ){
                    unitTypesSet.add(tempUnit.UnitType__c );
                }
                if(tempUnit.UnitModel__c !=null ){
                    unitModelSet.add(tempUnit.UnitModel__c );
                }
                if(tempUnit.FloorNumber__c !=null ){
                    floorNumberSet.add(tempUnit.FloorNumber__c );
                }
                if(tempUnit.NumberOfBedrooms__c !=null ){
                    unitBedRoomsSet.add(String.ValueOf(tempUnit.NumberOfBedrooms__c ));
                }
                if(tempUnit.UnitView__c !=null ){
                    unitViewSet.add(tempUnit.UnitView__c );
                }
                unitDetailList.add( new UnitDetilsWrapper(tempUnit) );
                
            }
            List<String> sortedPropertyUsageSet = new List<String>(propertyUsageSet);
            sortedPropertyUsageSet.sort();
            for(String tempS : sortedPropertyUsageSet){
                propertyUsageList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedunitTypesSet = new List<String>(unitTypesSet);
            sortedunitTypesSet.sort();
            for(String tempS : sortedunitTypesSet){
                unitTypesSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedunitModelSet = new List<String>(unitModelSet);
            sortedunitModelSet.sort();
            for(String tempS : sortedunitModelSet){
                unitModelSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedfloorNumberSet = new List<String>(floorNumberSet);
            sortedfloorNumberSet.sort();
            for(String tempS : sortedfloorNumberSet){
                floorNumberSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedunitBedRoomsSet = new List<String>(unitBedRoomsSet);
            sortedunitBedRoomsSet.sort();
            for(String tempS :sortedunitBedRoomsSet){
                unitBedRoomsSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
            List<String> sortedunitViewSet = new List<String>(unitViewSet);
            sortedunitViewSet.sort();
            for(String tempS : sortedunitViewSet){
                unitViewSetList.add(new map<string,string>{'label' =>tempS , 'value' => tempS});
            }
        }
        
    }
    
    public with sharing class UnitDetilsWrapper{
        @AuraEnabled
        public boolean isSelected; 
        
        @AuraEnabled
        public Unit__c unitDetails;
        public UnitDetilsWrapper(Unit__c tempUnit){
            isSelected=false;
            unitDetails=tempUnit;
        }
    }
    
    // to show the details of units selected
    @AuraEnabled(cacheable=true)
    public static UnitWrapper getUnitDetails(ID buildingsId,String directIndirectvalue, Id opportunityId){ 
        UnitWrapper unitsToReturn;
        unitsToReturn = new UnitWrapper(getAllAvailableUnitsUnderBuilding(new set<ID>{buildingsId},directIndirectvalue, opportunityId));
        return unitsToReturn;
    }
    
    public static list<Unit__c> getAllAvailableUnitsUnderBuilding(set<ID> buildingsIds,String directIndirectvalue, Id opportunityId){
        System.debug('Log: Inside getAllAvailableUnitsUnderBuilding');
        
        Opportunity opp = OpportunityService.getOpportunityDetailsbyId(opportunityId);
        Id blockedForCustomer =opp.AccountId;
        Id blockedForBrokerId = opp.BrokerAgencyAccount__c;
        
        list<Unit__c> lstUnittoreturn= new List<Unit__c>();
        if(String.isNotBlank(directIndirectvalue)){
            lstUnittoreturn = [select id,Name,NumberOfBedrooms__c,hasValidSalesorder__c,ADM_Fee_Included__c,Internal_Saleable_Area__c,UnitType__c,MeasuredArea__c,PropertyUsage__c,UnitModel__c,FloorNumber__c,UnitView__c,PropertyStatus__c,SaleableArea__c,TotalRooms__c,UnitCategory__c,MeasuredInternalArea__c,TerraceArea__c,TotalArea__c,UnitPlotArea__c,SellingPrice__c,AffectionPlan__c,MarketingPlan__c,AnticipatedServiceCharges__c,BuildingSectionName__c,BuildingSectionName__r.PropertyManagementFee__c,External_Saleable_Area__c,Direct_Indirect__c from Unit__c where BuildingSectionName__c in :buildingsIds  and IsActive__c =true AND (Direct_Indirect__c =:directIndirectvalue OR Direct_Indirect__c='') AND ( Status__c='Available' OR (Status__c= 'In-Progress' AND LockedBy__c = :UserInfo.getUserId()) OR (Status__c= 'Blocked' AND BlockedBy__c = :UserInfo.getUserId() AND ((Blocked_For_Broker__c = :blockedForBrokerId OR BlockedForCustomer__c =: blockedForCustomer) OR (Blocked_For_Broker__c = null AND BlockedForCustomer__c =null))))
                               ORDER BY Name];
        }else{
            lstUnittoreturn = [select id,Name,NumberOfBedrooms__c,hasValidSalesorder__c,ADM_Fee_Included__c,Internal_Saleable_Area__c,UnitType__c,MeasuredArea__c,PropertyUsage__c,UnitModel__c,FloorNumber__c,UnitView__c,PropertyStatus__c,SaleableArea__c,TotalRooms__c,UnitCategory__c,MeasuredInternalArea__c,TerraceArea__c,TotalArea__c,UnitPlotArea__c,SellingPrice__c,AffectionPlan__c,MarketingPlan__c,AnticipatedServiceCharges__c,BuildingSectionName__c,BuildingSectionName__r.PropertyManagementFee__c,External_Saleable_Area__c,Direct_Indirect__c from Unit__c where BuildingSectionName__c in :buildingsIds  and IsActive__c =true AND ( Status__c='Available' OR (Status__c= 'In-Progress' AND LockedBy__c = :UserInfo.getUserId()) OR (Status__c= 'Blocked' AND BlockedBy__c = :UserInfo.getUserId() AND ((Blocked_For_Broker__c = :blockedForBrokerId OR BlockedForCustomer__c =: blockedForCustomer) OR (Blocked_For_Broker__c = null AND BlockedForCustomer__c =null))))
                               ORDER BY Name];
            
        }
        return lstUnittoreturn ;
    } 
    
    public static list<Unit__c> getAllUnitsById(set<ID> unitIds){
        return [select UnitModel__c,TotalRooms__c ,id,Name,status__c,ADM_Fee_Included__c,InventoryCategory__c,GFAArea__c,Project__r.Name,AnticipatedServiceCharges__c,SaleableArea__c,MeasuredArea__c,
                BuildingSectionName__r.PropertyManagementFee__c,PropertyStatus__c,CompletionDate__c,Project__c,BuildingSectionName__c,CurrencyIsoCode,SellingPrice__c,MarketPrice__c,
                NumberOfBedrooms__c,UnitType__c,TotalArea__c,TerraceArea__c,LockedBy__c,LockExpiryTime__c,NumberOfCarParks__c,
                Project__r.VirtualTour__c,UnitCategory__c,Project__r.VideoLink__c from Unit__c where id in :unitIds];
    }
    
    //To send the Booking Agreement PDF via email
    @AuraEnabled
    public static void UpdateUnitSellingPrice(Map<String,String> unitInfo){
        List<Unit__c> tobeUpdateUnitList = new List<Unit__c>();
        List<UnitDesign__c> unitDesignDetail = [Select id,Unit__c,DesignType__c,SellingPrice__c From UnitDesign__c Where Unit__c=:unitInfo.keySet() ];
        
        for(UnitDesign__c design:unitDesignDetail){
            if(unitInfo.containsKey(design.Unit__c) && unitInfo.get(design.Unit__c)==design.DesignType__c){
                Unit__c unit = new Unit__c();
                unit.id = design.Unit__c;
                unit.SellingPrice__c = design.SellingPrice__c;
                tobeUpdateUnitList.add(unit);
                System.debug('tobeUpdateUnitList'+tobeUpdateUnitList);
            }
        }
        if(tobeUpdateUnitList.size()>0){
            update tobeUpdateUnitList;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static void sendBookingAgreementAttachment(id oppId,String customerName, List<id> unitlist,List<id> paymentList,List<id> offerList,String paymentjsonString){
        
        String selectedUnitString = String.join(unitlist, ',');
        String selectedPayments = String.join(paymentList, '|');
        String selectedOffers = String.join(offerList, ',');
        
        PageReference vfPage = Page.BookingForm;
        Blob pdfBlob;
        
        vfPage.getParameters().put('id', oppId);
        vfPage.getParameters().put('selectedUnits', selectedUnitString);
        vfPage.getParameters().put('customerName', customerName);
        vfPage.getParameters().put('currentOffer', selectedOffers);
        vfPage.getParameters().put('selectedPayments', selectedPayments);
        vfPage.getParameters().put('unitVsPaymentMap', paymentjsonString);
        
        
        
        //pdfBlob = vfPage.getContent();
        
        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
        emailAttachment.setFileName('BookingAgreement.pdf');
        
        emailAttachment.setBody(Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :vfPage.getContent());
        
        String htmlBody='<html><body>';
        htmlBody=htmlBody+'<p>Dear Customer,</p><p>Greetings of the day.</p><p>Please find the attached Booking Agreement.</p>';
        
        htmlBody=htmlBody+'<br/><p>Thanks and Regards,</p><p>Bloom</p>';
        htmlBody=htmlBody+'</html></body>';
        
        String subject='Bloom Booking Agreement';
        
        List<Opportunity>oppList =[Select id,AccountId,Account.PersonContactId,ContactId,Contact__c,Account.PersonEmail,Contact__r.Email  From Opportunity Where Id=:oppId];
        List<String>topersonAddress = new List<String>();
        List<String>toOrganizationAddress = new List<String>();
        topersonAddress.add(oppList[0].Account.PersonEmail);
        toOrganizationAddress.add(oppList[0].Contact__r.Email);
        String targetObj;
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSaveAsActivity(True);
        //email.setTargetObjectId(targetObj);
        email.setSubject(subject);
        
        if(oppList[0].Account.PersonContactId!=null && oppList[0].Account.PersonEmail!=null ){
            email.setToAddresses(topersonAddress);
            targetObj=oppList[0].Account.PersonContactId;
        }
        else{
            email.setToAddresses(toOrganizationAddress);
            targetObj=oppList[0].Contact__c;
        }
        email.setTargetObjectId(targetObj);
        if(oppId!=null){
            email.setWhatId(oppId);
        }
        
        email.setHtmlBody(htmlBody);
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {emailAttachment});
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        
    }
    
    //To send the salesOffer PDF via email
    @AuraEnabled(cacheable=false)
    public static void sendSalesOfferPDF(list<SalesOfferUtilityHandler.SaleOfferInputParam> saleOfferInputParam, Id opportunityId, String customerName, Id singleUnitId){
        
        boolean hasLead=false;
        map<id,Messaging.EmailFileAttachment> unitToAttachmentDetails = new map<id,Messaging.EmailFileAttachment>();
        map<id,Unit__c> allUnitIds = new map<id,Unit__c>();
        for(SalesOfferUtilityHandler.SaleOfferInputParam tempPramObj : saleOfferInputParam){
            allUnitIds.put(tempPramObj.unitId,null);
        }
        allUnitIds = new map<id,Unit__c>(getAllUnitsById(allUnitIds.keySet()));
        Messaging.SingleEmailMessage tempEmailInstance = new Messaging.SingleEmailMessage();
        for(SalesOfferUtilityHandler.SaleOfferInputParam tempPramObj : saleOfferInputParam){
            Id currentUnit=tempPramObj.unitId;
            Id currentOffer=(tempPramObj.offerId!=null)?tempPramObj.offerId:null;
            String otherUnits='';
            String selectedPayments='';
            String designIdVal='';
            boolean multiPurposeAmount =tempPramObj.multiPurposeAmountApplicable!=null ? tempPramObj.multiPurposeAmountApplicable : false;
            if( tempPramObj.selectedPayments !=null && !tempPramObj.selectedPayments.isEmpty() ){
                for(string tempPaymentID : tempPramObj.selectedPayments) {
                    selectedPayments = selectedPayments + (selectedPayments!=''?'|':'') +tempPaymentID;
                }
            }
            for(String tempID :  allUnitIds.keySet()){
                if(tempID!=currentUnit){
                    otherUnits = otherUnits + (otherUnits!=''?'|':'') + tempID;
                }
            }
            if(singleUnitId !=null && singleUnitId != currentUnit){
                continue;
            }
            if(tempPramObj.designId!=null ){
                designIdVal=tempPramObj.designId;
            }
            PageReference pdf = Page.OfferDetailsPDF;
            pdf.getParameters().put('id',(opportunityId!=null?opportunityId:''));
            pdf.getParameters().put('currentUnit',currentUnit);
            pdf.getParameters().put('otherUnits',otherUnits);
            pdf.getParameters().put('currentOffer',currentOffer);
            pdf.getParameters().put('selectedPayments',selectedPayments);
            pdf.getParameters().put('multiPurposeAmount',string.ValueOf(multiPurposeAmount));
            pdf.getParameters().put('customerName',(customerName!=null?customerName:''));
            pdf.getParameters().put('selectedDesign',designIdVal);
            
            pdf.setRedirect(true);
            
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName('Offer-'+allUnitIds.get(currentUnit).Name+'-'+customerName+'-'+System.today().format()+'.pdf');
            efa.setBody(Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :pdf.getContent());
            unitToAttachmentDetails.put(currentUnit,efa);
            
            
            //********to get the brochure links-- added********//
            set<id> unitIdSet=new set<id>();
            for(id unitIds:unitToAttachmentDetails.keySet()){
                unitIdSet.add(unitIds);
            }
            list<Unit__c> buildingList=[select id,BuildingSectionName__r.Brochure_URL__c,BuildingSectionName__r.Name from Unit__c where id IN:unitIdSet];
            Map<String,String> buildingToBrochure=new Map<String,String>();
            for(Unit__c unit:buildingList){
                if(!buildingToBrochure.containsKey(unit.BuildingSectionName__r.Name)){
                    buildingToBrochure.put(unit.BuildingSectionName__r.Name,unit.BuildingSectionName__r.Brochure_URL__c);
                }
            }
            String htmlBody='<html><body>';
            htmlBody=htmlBody+'<p>Dear Customer,</p><p>Greetings of the day.</p><p>Please find the attached offer letter.</p>';
            for(String bname:buildingToBrochure.keySet()){
                htmlBody=htmlBody+'<p>To view Brochure URL '+'<a href="'+buildingToBrochure.get(bname)+'">Click Here</a></p>';
            }
            htmlBody=htmlBody+'<br/><p>Thanks and Regards,</p><p>Bloom</p>';
            htmlBody=htmlBody+'</html></body>';
            
            String subject='Bloom Offer Letter';
            //***********************************************//
            
            
            string emailTemplateId = '';
            string emailTemplateLeadId = '';
            string relatedCustomerId = '';
            string orgWideEmailAddress = '';
            list<Opportunity> opportunityRecords = new list<Opportunity>();
            
            for(Emailtemplate tempRec:  [select id, DeveloperName from emailtemplate where DeveloperName = :Constants.OFFER_LETTER limit 1]){
                emailTemplateId=tempRec.Id;
            }
            
            for(Emailtemplate tempRec:  [select id, DeveloperName from emailtemplate where DeveloperName = :Constants.OFFER_LETTER_LEAD limit 1]){
                emailTemplateLeadId=tempRec.Id;
            }
            if(opportunityId!=null ){
                if(opportunityId.getsobjecttype() == Lead.sobjecttype){
                    hasLead=true;
                }else{
                    hasLead=false;
                }
                
                opportunityRecords=[select id,Contact__c,StageName from opportunity where id =:opportunityId limit 1];
                if(!opportunityRecords.isEmpty()){
                    relatedCustomerId = opportunityRecords[0].Contact__c;
                    if(opportunityRecords[0].StageName == Constants.STAGE_NEW ||  opportunityRecords[0].StageName == Constants.STAGE_IN_PROGRESS){
                        opportunityRecords[0].StageName= Constants.STAGE_PROPOSAL;
                        update opportunityRecords;
                    }
                }
            }
            
            for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.PROPERTIES_ORGWIDEEMAIL limit 1]){
                orgWideEmailAddress=tempRec.Id;
            }
            
            //Messaging.SingleEmailMessage tempEmailInstance = new Messaging.SingleEmailMessage();
            
            List<Opportunity>oppList =[Select id,AccountId,Account.PersonContactId,ContactId,Contact__c,Account.PersonEmail,Contact__r.Email  From Opportunity Where Id=:opportunityId];
            List<String>topersonAddress = new List<String>();
            List<String>toOrganizationAddress = new List<String>();
            topersonAddress.add(oppList[0].Account.PersonEmail);
            toOrganizationAddress.add(oppList[0].Contact__r.Email);
            if(oppList[0].Account.PersonContactId!=null && oppList[0].Account.PersonEmail!=null ){
                tempEmailInstance = getEmailInstance(oppList[0].Account.PersonContactId,emailTemplateId,opportunityId,topersonAddress,null,null,subject,null,htmlBody,unitToAttachmentDetails.values(),orgWideEmailAddress);
                System.debug('tempEmailInstance'+tempEmailInstance);
            }else{
                tempEmailInstance = getEmailInstance(oppList[0].Contact__c,emailTemplateId,opportunityId,toOrganizationAddress,null,null,subject,null,htmlBody,unitToAttachmentDetails.values(),orgWideEmailAddress);
            }
            
            //tempEmailInstance.setSaveAsActivity(true);
            //System.debug('length:'+tempEmailInstance);
            //sendEmail(new list<Messaging.SingleEmailMessage>{tempEmailInstance});
            
        }
        sendEmail(new list<Messaging.SingleEmailMessage>{tempEmailInstance});
    }
    
    public static Messaging.SingleEmailMessage getEmailInstance( string targetObject, string templateID,string whatId , List<String> toRecipients,List<String> bccRecipients,List<String> ccRecipients,String emailSubject,String body,string htmlBody,List<Messaging.EmailFileAttachment> fileAttachments,string orgWideEmailAddressID) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
        mail.setSaveAsActivity(True);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        if(targetObject!=null && targetObject!=''){
            mail.setTargetObjectId(targetObject);
        }
        if(whatId!=null && whatId!=''){
            mail.setWhatId(whatId);
        }
        /*if(templateID!=null && templateID!=''){
mail.setTemplateID(templateID);
}*/
        //if(emailSubject!=null && emailSubject!=''){
        mail.setSubject(emailSubject);
        //}
        if(toRecipients!=null && !toRecipients.isEmpty() ){
            mail.setToAddresses(toRecipients);
        }
        if(bccRecipients != null && !bccRecipients.isEmpty() ){
            mail.setccAddresses(bccRecipients);
        }
        if(ccRecipients != null && !ccRecipients.isEmpty()){
            mail.setbccAddresses(ccRecipients);
        }
        if (body!=null && body!='') {
            mail.setPlainTextBody(body);
        } 
        if (htmlBody!=null && htmlBody!='') {
            mail.setHtmlBody(htmlBody);
        }
        if(OrgWideEmailAddressID != null && OrgWideEmailAddressID!=''){
            mail.setOrgWideEmailAddressId(OrgWideEmailAddressID);
        }
        // Specify FileAttachments
        if(fileAttachments != null && !fileAttachments.isEmpty()) {
            mail.setFileAttachments(fileAttachments);
        }
        return mail;
    }
    
    public static list<Messaging.SendEmailResult> sendEmail(list<Messaging.SingleEmailMessage> mails) {
        System.debug('entered sendEmail');
        System.debug('mails:'+mails);
        return Messaging.sendEmail(mails); 
    }
    
    @AuraEnabled(cacheable=true)
    public static map<String,object> getsObjectType(Id recordID){
        System.debug('recordID:'+recordID);
        map<String,sObject> mapToReturn = new map<String,sObject>();
        Schema.SObjectType sobjectType = recordID.getSObjectType();
        string sobjectName = sobjectType.getDescribe().getName();
        
        if(sobjectName.equalsIgnoreCase('Opportunity')){
            mapToReturn.put(sobjectName,[select id, Project__c, CustomerResidentStatus__c,Name,SaleType__c,DealType__c,BookingType__c,AgentType__c,ReferralType__c,BrokerAgentName__c,BrokerAgencyAccount__c,EmployeeName__c,BrokerAgencyAccount__r.Name from Opportunity where id = :recordID limit 1]);
        }else if(sobjectName.equalsIgnoreCase('Unit__c')){
            mapToReturn.put(sobjectName,[select id,Project__r.Name,Name from Unit__c where id = :recordID limit 1]);
        }else if(sobjectName.equalsIgnoreCase('SalesOrder__c')){
            mapToReturn.put(sobjectName,[select id,Opportunity__c,Opportunity__r.CustomerResidentStatus__c from SalesOrder__c where id = :recordID limit 1]);
        }
        
        return mapToReturn;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getWinReasonPickList(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = Opportunity.WinReason__c.getDescribe();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
    
    
    
    @AuraEnabled(cacheable=false)
    public static List<OfferLines__c> getOfferLinesQuery(String query) {
        List<OfferLines__c> records = Database.query(query);
        return records;
    }
    
    @AuraEnabled(cacheable=false)
    public static String getVFDomainURL(){
        String currentDomainURL = '';
        string baseURL = URL.getOrgDomainUrl().toExternalForm();
        currentDomainURL = baseURL.split('.sandbox.')[0] + '--c.' + 'sandbox.vf.force.com'; 
        return currentDomainURL ;     
    }
    
    
    
    
    @AuraEnabled(cacheable=false)
    public static string validateRegistrationAllowed( Id opportunityId){
        opportunity optyRecord = [select id,AccountId from opportunity where id= :opportunityId limit 1];
        String opportunityValidation = OpportunityService.opportunityFieldsValidation(opportunityId);
        String accountValidation = '';
        opportunityValidation = '';
        accountValidation = '';
        //TODO check if opportunity already have reserved unit
        if(opportunityValidation!=null && opportunityValidation!='' ){
            return 'Please populate values for '+opportunityValidation +' field(s) on related Opportunity record';
        }else if(accountValidation!=null && accountValidation !=''){
            return 'Please populate values for '+accountValidation +' field(s) on related Account record';
        }
        return null;
    }
    
    @AuraEnabled
    public static list<Opportunity> getCustomerInfo(String recId){
        return [select id,name,Account.Name from Opportunity where id=:recId];
    }
    
    @AuraEnabled
    public static void updateUserField(String selectedUnit,Integer noDays){
        USER userData = [SELECT Id,name,ManagerId,Email FROM USER WHERE Id=:UserInfo.getUserId()];
        Unit__c tempUnit=new Unit__c();
        tempUnit.Id=selectedUnit;
        tempUnit.Submitted_for_Approval__c=true;
        tempUnit.BlockedBy__c=userData.Id;
        tempUnit.Holding_Days__c=noDays;
        try{
            update tempUnit; 
        }
        catch(Exception ex){
            throw ex ;
        }
        
    }
    
    
    @AuraEnabled
    public static String submitforApproval(Unit__c selectedUnit){
        String str='Error';
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(selectedUnit.Id);
        USER userData = [SELECT Id,name,ManagerId,Email FROM USER WHERE Id=:UserInfo.getUserId()];
        List<Id> param1=new List<Id>();
        param1.add(userData.ManagerId);
        req1.setSubmitterId(userData.Id);
        req1.setNextApproverIds(param1);
        req1.setProcessDefinitionNameOrId(System.Label.UnitApprovalProcessLabel);
        req1.setSkipEntryCriteria(true);
        try{
            Approval.ProcessResult result = Approval.process(req1);
            str='Success';
        }
        catch(Exception e){
            list<string> sfs = e.getMessage().split(',');
            sfs.remove(0);
            String errorMessage = String.join(sfs, ', ');
            str=errorMessage;
            errorMessage = errorMessage.removeEnd(': []');
            throw new Auraexception(errorMessage);
        }
        
        return str;
        
    }
    
    
    
    
    
    
    @AuraEnabled
    public static String UnitBookTimeExtendApproval(String OpportunityId, List<String> unitIds) {
        System.debug('OpportunityId' + OpportunityId);
        System.debug('OpportunityId' + OpportunityId);
        /*  String ExtendOppBookTimeapprovalStatus= OpportunityUnitSearchHandler.GetUnitBookTimeExtApprovStatus(OpportunityId);
if(!String.IsBlank(ExtendOppBookTimeapprovalStatus)){
throw new AuraHandledException('Request for extension only once allowed');
}*/
        String str = 'Error';
        List<Opportunity> OppList = [SELECT Id, TimeExtendApprovalUnits__c FROM Opportunity WHERE Id = :OpportunityId];
        List<Unit__c> unitList = [SELECT Id, Name FROM Unit__c WHERE Id IN :unitIds];
        System.debug('OppList'+OppList);
        System.debug('unitList'+unitList);
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(OpportunityId);
        User userData = [SELECT Id, Name, ManagerId, Email FROM User WHERE Id = :UserInfo.getUserId()];
        List<Id> param1 = new List<Id>();
        param1.add(userData.ManagerId);
        req1.setSubmitterId(userData.Id);
        req1.setNextApproverIds(param1);
        req1.setProcessDefinitionNameOrId(System.Label.UnitBookingTimeExtendApproval);
        req1.setSkipEntryCriteria(true);
        
        try {
            Approval.ProcessResult result = Approval.process(req1);
            if (result.isSuccess()) {
                str = 'Success';
                if (!OppList.isEmpty() && !unitList.isEmpty()) {
                    for (Opportunity opp : OppList) {
                        System.debug('inside opplist');
                        if (opp.TimeExtendApprovalUnits__c == null || opp.TimeExtendApprovalUnits__c == '') {
                            // Initialize a string to store concatenated unit names
                            String unitNames = '';
                            
                            // Iterate through the unitList to concatenate unit names
                            for (Unit__c unit : unitList) {
                                unitNames += unit.Name + ', '; // Add unit name and comma
                                System.debug('inside unitList');
                            }
                            
                            // Remove the trailing comma
                            unitNames = unitNames.removeEnd(', ');
                            
                            // Set the concatenated unit names to the TimeExtendApprovalUnits__c field
                            opp.TimeExtendApprovalUnits__c = unitNames;
                        }
                    }
                    System.debug('OppList'+OppList);
                    update OppList;
                }
            } else {
                str = 'Approval process request failed';
            }
        } catch (Exception e) {
            str = e.getMessage();
            throw new AuraException(str);
        }
        
        return str;
    }
    @InvocableMethod(label='Auto Update Unit Book Extend Time Approval')
    public static void autoUpdateUnitBookExtendTimeApproval(List<String> recordIds) {
        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id, ProcessInstanceId, ProcessInstance.Status 
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :recordIds 
        ];
        
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        
        for(ProcessInstanceWorkitem workItem : workItems){
            if(workItem.ProcessInstance.Status == 'Pending'){ // Check if the process status is pending
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                //Valid values are: Approve, Reject, or Removed. 
                //Only system administrators can specify Removed.
                req.setAction('Reject');
                req.setComments('Auto Reject.');
                requests.add(req);
            }
        }
        
        if(!requests.isEmpty()) {
            Approval.ProcessResult[] processResults = Approval.process(requests);
            // You can handle the process results here if needed
        }
    }
    
    
    
    @AuraEnabled
    public static String GetUnitBookTimeExtApprovStatus(String OpportunityId){
        System.debug('OpportunityId'+OpportunityId);
        List<Opportunity> approvalStatusList = [Select id,Time_Extend_Approval_Status__c From Opportunity Where id=:OpportunityId];
        String approvalStatus = approvalStatusList[0].Time_Extend_Approval_Status__c;
        return approvalStatus;
    }
    
    @AuraEnabled
    public static String UpdateUnitBookTimeExtApprovStatus(String OpportunityId, list<String>TobeInCreasedLockedUnits,integer increasedTime,String approvalResult){
        System.debug('TobeInCreasedLockedUnits'+TobeInCreasedLockedUnits);
        System.debug('OppBookingExtendedTimer'+increasedTime);
        
        List<Opportunity> approvalStatusList = [Select id,Time_Extend_Approval_Status__c From Opportunity Where id=:OpportunityId];
        List<Unit__c> tobeUpdateUnitlist = new List<Unit__c>();
        if(approvalStatusList.size()>0){
            for(Opportunity opp:approvalStatusList){
                if(opp.Time_Extend_Approval_Status__c!=null ){
                    opp.Time_Extend_Approval_Status__c ='';
                }
            }
            
        }
        if(TobeInCreasedLockedUnits.size()>0 && approvalResult=='Approved'){
            for(Unit__c unit:[Select id,LockExpiryTime__c From Unit__c Where id=:TobeInCreasedLockedUnits]){
                unit.LockExpiryTime__c = unit.LockExpiryTime__c.addMinutes(increasedTime);
                
                tobeUpdateUnitlist.add(unit);
                System.debug('tobeUpdateUnitlist'+tobeUpdateUnitlist);
            }
        }
        if(tobeUpdateUnitlist.size()>0){
            update tobeUpdateUnitlist;
        }
        update approvalStatusList;
        
        return approvalResult;
    }
    
    
    
    @AuraEnabled
    public static List<Unit__c> lockUnit(List<Unit__c> lstUnits, String timerName){
        try{
            Decimal timerDetails = Utilities.getTimer(timerName).Timer__c;
            System.debug('timerDetails:'+timerDetails+'---'+lstUnits);
            String timerUnit = Utilities.getTimer(timerName).Time__c;
            for(Unit__c objUnit : lstUnits){
                objUnit.LockedBy__c = UserInfo.getUserId();
                objUnit.LockTime__c = system.now();
                objUnit.Status__c = Constants.UNIT_STATUS_BOOKING_INPROGRESS;       
                if (timerUnit == Constants.HOURS) {
                    timerDetails = timerDetails * 60;
                    objUnit.LockExpiryTime__c = system.now().addMinutes(Integer.valueOf(timerDetails));
                } else {
                    objUnit.LockExpiryTime__c = system.now().addMinutes(Integer.valueOf(timerDetails));
                    System.debug('LockTime__c:'+objUnit.LockTime__c);
                    System.debug('LockExpiryTime__c:'+objUnit.LockExpiryTime__c);
                }
            }
            update lstUnits;
            
        }catch(Exception ex){
            throw ex ;
        }
        return lstUnits ;
    }
    
    
    @AuraEnabled(cacheable=false)
    public static string lockUnits(list<String> unitIds){
        string msg =Constants.SUCCESS_MESSAGE;
        list<Unit__c> unitsToLock = new list<Unit__c>();
        list<Unit__c> verifyUnits=[select id,Name,LockedBy__c, LockedBy__r.Name,BlockedBy__c,BlockedBy__r.Name, Status__c from unit__c where id in :unitIds];
        if(verifyUnits.isEmpty()){
            msg='Selected Unit is no longer available';
        }
        for(unit__c tempUnitRec : verifyUnits){
            if(tempUnitRec.Status__c == Constants.UNIT_STATUS_AVAILABLE || (tempUnitRec.Status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS && tempUnitRec.LockedBy__c == UserInfo.getUserId() ) ){
                unitsToLock.add(new Unit__c(id= tempUnitRec.Id));
            }else{
                if(tempUnitRec.BlockedBy__c!=null ){
                    if(tempUnitRec.BlockedBy__c == UserInfo.getUserId()){
                        msg='Success'; 
                        unitsToLock.add(new Unit__c(id= tempUnitRec.Id));
                        
                    }else{
                        msg='Selected Unit '+tempUnitRec.Name+' is blocked by '+tempUnitRec.BlockedBy__r.Name;
                    }
                }
                else{
                    msg='Selected Unit '+tempUnitRec.Name+' is locked by '+tempUnitRec.LockedBy__r.Name;
                }
                
                break;
            }
        }
        if(msg == Constants.SUCCESS_MESSAGE ){          
            lockUnit(unitsToLock,constants.RESERVATION_TIMMERNAME);
        }
        return msg;
    }
    
    @AuraEnabled(cacheable=false)
    public static Opportunity getOpportunityDetailsbyId(String opportunityID){
        
        Opportunity opportunityObj = [select AccountId, Name, CloseDate, StageName, createdDate, OwnerId, SaleType__c, DealType__c, BookingType__c, AgentType__c, ReferralType__c, BrokerAgentName__c,BrokerAgencyAccount__c, EmployeeName__c,CanAllowBooking__c  from Opportunity where Id =: opportunityID limit 1];
        
        return opportunityObj;
    }
    
    
    @AuraEnabled(cacheable=false)
    public static map<string,string> reserveUnit(list<SalesOfferUtilityHandler.SaleOfferInputParam> saleOfferInputParam, Id opportunityId, string action, string winReason,string selectedEOI,boolean downPayment,integer SelectedUnitCount){
        MetadataService objMetadataService = MetadataService.getInstance();
        String AdmFeeCalValue = objMetadataService.getAppSettingTextValue(MTD_NO_ADM_Fee_Calculation_Value);
        map<string,string> valueToReturn = new map<string,string>();
        Savepoint sp = Database.setSavepoint();
        try{    
            
            
            set<String> applicableVoucher = new set<String>();
            map<id,SalesOfferUtilityHandler.SalesOfferDetails> reservationWrapper = generateSalesOffer(saleOfferInputParam,opportunityId,SelectedUnitCount);
            System.debug(reservationWrapper);
            map<ID,SalesOfferUtilityHandler.SaleOfferInputParam> unitToInputParam = new map<ID,SalesOfferUtilityHandler.SaleOfferInputParam>();
            
            map<Unit__c,SalesOfferUtilityHandler.PaymentPlanWrapper> unitPaymentPlanWrapper = new map<Unit__c,SalesOfferUtilityHandler.PaymentPlanWrapper>();
            Set<Id> unitsProject = new Set<Id>(); 
            
            Decimal admFeeTobeChargedSalesOOthercharge;            
            for(SalesOfferUtilityHandler.SaleOfferInputParam tempIncomingParam : saleOfferInputParam ){
                unitToInputParam.put(tempIncomingParam.unitId,tempIncomingParam);
            }
            map<id,Unit__c> unitsToReserve = new map<id,Unit__c>(); 
            map<id,SalesOrder__c> opportunityUnitsToCreate = new map<id,SalesOrder__c>();
            map<id,list<InstallmentLines__c>> installmentLines = new map<id,list<InstallmentLines__c>>();
            map<id,list<OpportunityOfferLine__c>> offerLines = new map<id,list<OpportunityOfferLine__c>>();
            map<id,ReceiptAcknowledgement__c> createPaymentLines = new map<id,ReceiptAcknowledgement__c>();
            map<id,List<CommissionLineItem__c>> createCommissionMap = new map<id,List<CommissionLineItem__c>>();
            map<ID,list<SalesOrderOtherCharges__c>> unitToOtherSalesOrderCharges = new  map<ID,list<SalesOrderOtherCharges__c>> ();
            Opportunity opportunityRecord = new Opportunity(id= opportunityId);
            map<string,CommissionLineItem__c> externalCommisionMap = new map<string,CommissionLineItem__c>();
            Opportunity opportunityDetails = getOpportunityDetailsbyId(opportunityId);
            list<OpportunityEOI__c> EOIList = [select id,BuildingSectionName__c,ProjectName__c, Payments__c from OpportunityEOI__c where id = :selectedEOI];
            list<ReceiptAcknowledgement__c> eoiRAtoReparent = new list<ReceiptAcknowledgement__c>();
            if(!EOIList.isEmpty()){
                id receiptacknowledgement = EOIList[0].Payments__c;
                eoiRAtoReparent = [select id from ReceiptAcknowledgement__c where id = :receiptacknowledgement];
            }
            System.debug(reservationWrapper.keySet());
            
            //BISWAJEET - 5th SEPT 2024
            /*Set<Id> paymentPlanIds = new Set<Id>();
            Map<Id, Id> paymentPlanOfferMap = new Map<Id, Id>();
            for(Id tempUnitKey : reservationWrapper.keySet()){
            SalesOfferUtilityHandler.SalesOfferDetails tempOfferRecord = reservationWrapper.get(tempUnitKey);
            for( SalesOfferUtilityHandler.PaymentPlanWrapper tempPaymentPlan :  tempOfferRecord.applicablePaymentPlansCalculated){
            if(tempPaymentPlan.paymentPlanDetails != null){
            paymentPlanIds.add(tempPaymentPlan.paymentPlanDetails.Id);
            }
            }
            }
            for(Payment_Plan_Offer__c objPaymentPlanOffer :[SELECT Id, Payment_Plan__c, Offer_Promotion__c FROM Payment_Plan_Offer__c WHERE Payment_Plan__c IN :paymentPlanIds]){
            paymentPlanOfferMap.put(objPaymentPlanOffer.Payment_Plan__c, objPaymentPlanOffer.Offer_Promotion__c);
            }*/
            
            for(Id tempUnitKey : reservationWrapper.keySet()){
                SalesOfferUtilityHandler.SalesOfferDetails tempOfferRecord = reservationWrapper.get(tempUnitKey);
                System.debug(tempOfferRecord.unitRecord);
                
                if(tempOfferRecord.unitRecord !=null && (tempOfferRecord.unitRecord.status__c == Constants.UNIT_STATUS_AVAILABLE || tempOfferRecord.unitRecord.status__c == Constants.UNIT_STATUS_BOOKING_INPROGRESS ||(tempOfferRecord.unitRecord.status__c=='Blocked' && tempOfferRecord.unitRecord.BlockedBy__c == UserInfo.getUserId()))){
                    //adding created salesorder ordername
                    String unitNumber = tempOfferRecord.unitRecord.Name;
                    String salesOrderName = unitNumber +'-'+ DateTime.now().format('yyMMdd');
                    SalesOrder__c tempOpportunityUnit = new SalesOrder__c();
                    tempOpportunityUnit.Name = salesOrderName;
                    opportunityRecord.Amount= tempOfferRecord.totalOfAllUnitNetSellingPrice!=null? tempOfferRecord.totalOfAllUnitNetSellingPrice : 0;
                    tempOpportunityUnit.Account__c = tempOfferRecord.opportunityRecord !=null ? tempOfferRecord.opportunityRecord.AccountId : null;
                    tempOpportunityUnit.Contact__c = tempOfferRecord.opportunityRecord !=null ? tempOfferRecord.opportunityRecord.Contact__c : null;
                    tempOpportunityUnit.CustomerType__c = tempOfferRecord.opportunityRecord !=null ? tempOfferRecord.opportunityRecord.Account.CustomerType__c : null;
                    tempOpportunityUnit.CustomerSubType__c = tempOfferRecord.opportunityRecord !=null ? tempOfferRecord.opportunityRecord.Account.CustomerSubType__c : null;
                    tempOpportunityUnit.Email__c = (tempOfferRecord.opportunityRecord !=null && tempOfferRecord.opportunityRecord.Contact__c!=null) ? tempOfferRecord.opportunityRecord.Contact__r.Email : null;
                    tempOpportunityUnit.Offer__c = tempOfferRecord.offerId;
                    tempOpportunityUnit.Opportunity__c = tempOfferRecord.opportunityId;
                    tempOpportunityUnit.OwnerManger__c = (tempOfferRecord.opportunityRecord !=null ) ? tempOfferRecord.opportunityRecord.Owner.ManagerId : null;
                    tempOpportunityUnit.ReferralType__c = opportunityDetails.ReferralType__c;
                    tempOpportunityUnit.SalesManager__c = (tempOfferRecord.opportunityRecord !=null ) ? tempOfferRecord.opportunityRecord.OwnerId : null;
                    tempOpportunityUnit.Broker_Agencyy__c = tempOfferRecord.opportunityRecord !=null ? tempOfferRecord.opportunityRecord.BrokerAgencyAccount__c : null;
                    
                    
                    
                    tempOpportunityUnit.Unit__c = tempUnitKey;
                    //tempOpportunhttps://bloomholding--preprod.sandbox.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage#ityUnit.mortgageApplicable__c = unitToInputParam.get(tempUnitKey).mortgageApplicable!=null && unitToInputParam.get(tempUnitKey).mortgageApplicable ? Constants.YES : Constants.NO ;
                    //tempOpportunityUnit.mortgageBank__c = unitToInputParam.get(tempUnitKey).mortgageBank;
                    /*  if(!EOIList.isEMpty() && EOIList[0].BuildingSectionName__c==tempOfferRecord.unitRecord.BuildingSectionName__c && EOIList[0].ProjectName__c ==tempOfferRecord.unitRecord.Project__c ){

                    //EOIList.remove(0);
                    } */
                    
                    List<CommissionLineItem__c> commissionLineList = new List<CommissionLineItem__c>();
                    installmentLines.put(tempUnitKey, new list<InstallmentLines__c>() ); 
                    System.debug(tempOfferRecord.applicablePaymentPlansCalculated);
                    for( SalesOfferUtilityHandler.PaymentPlanWrapper tempPaymentPlan :  tempOfferRecord.applicablePaymentPlansCalculated){
                        System.debug('tempPaymentPlan:'+tempPaymentPlan);
                        
                        if(tempPaymentPlan.isSelected){
                            /*//BISWAJEET - 5th SEPT 2024
                            if(tempPaymentPlan.paymentPlanDetails.Id != NULL && tempPaymentPlan != NULL){
                            tempOpportunityUnit.Offer__c = paymentPlanOfferMap.get(tempPaymentPlan.paymentPlanDetails.Id);
                            }*/
                            
                            tempOpportunityUnit.PaymentPlan__c = tempPaymentPlan.paymentPlanDetails.Id;
                            tempOpportunityUnit.SellingPrice__c = tempOfferRecord.unitRecord.SellingPrice__c;
                            tempOpportunityUnit.SellingPriceInWords__c = Utilities.amountInWords(tempOpportunityUnit.SellingPrice__c,'Dirham','Fils');
                            tempOpportunityUnit.Discount__c = tempPaymentPlan.discountAmount;
                            tempOpportunityUnit.AmountPayable__c= tempPaymentPlan.netSalesPrice.setScale(2);
                            tempOpportunityUnit.Amount_Payable_in_English__c = Utilities.amountInWords(tempOpportunityUnit.AmountPayable__c,'Dirham','Fils');
                            
                            tempOpportunityUnit.TaxableAmount__c = (tempOfferRecord.unitRecord.BuildingSectionName__r.TaxPercentage__c !=null ) ? (tempPaymentPlan.netSalesPrice * tempOfferRecord.unitRecord.BuildingSectionName__r.TaxPercentage__c)/100 : 0;
                            tempOpportunityUnit.Tax_Amount_in_English__c = Utilities.amountInWords(tempOpportunityUnit.TaxableAmount__c,'Dirham','Fils');
                            
                            tempOpportunityUnit.NetAmount__c = (tempOpportunityUnit.TaxableAmount__c+tempOpportunityUnit.AmountPayable__c).setScale(2);
                            tempOpportunityUnit.NetAmountInWords__c = Utilities.amountInWords(tempOpportunityUnit.NetAmount__c,'Dirham','Fils');
                            tempOpportunityUnit.BulkDiscount__c = tempPaymentPlan.bulkDiscountAmount;
                            tempOpportunityUnit.CorporateDiscount__c = tempPaymentPlan.corporateDiscountAmount;
                            tempOpportunityUnit.PaymentPlanDiscount__c = tempPaymentPlan.paymentPlanDiscountAmount;//tempPaymentPlan.paymentPlanDetails.PaymentPlanDiscount__c;
                            tempOpportunityUnit.PremiumAmount__c = tempPaymentPlan.premiumAmmount;
                            
                            tempOpportunityUnit.OtherRebateAmount__c = tempPaymentPlan.rebateAmount!=null?tempPaymentPlan.rebateAmount.setScale(2):tempPaymentPlan.rebateAmount;
                            tempOpportunityUnit.ADMFeeWaivedAmount__c = tempPaymentPlan.admFeeWaiverAmount!=null?tempPaymentPlan.admFeeWaiverAmount.setScale(2):tempPaymentPlan.admFeeWaiverAmount;
                            
                            tempOpportunityUnit.ServiceChargeWaivedAmount__c = tempPaymentPlan.serviceChargeAmount!=null?tempPaymentPlan.serviceChargeAmount.setScale(2):tempPaymentPlan.serviceChargeAmount;
                            tempOpportunityUnit.ServiceChargeWaivedYears__c = tempPaymentPlan.serviceChargeWaivedYears;
                            
                            tempOpportunityUnit.PMFeesWaivedAmount__c = tempPaymentPlan.pmWavedFee;
                            //  tempOpportunityUnit.HomeMaintenanceWaivedAmount__c = tempPaymentPlan.homeMaintenanceWaiverFee!=null?tempPaymentPlan.homeMaintenanceWaiverFee.setScale(2):tempPaymentPlan.homeMaintenanceWaiverFee;
                            tempOpportunityUnit.PMFeesWaivedYears__c = tempPaymentPlan.pmWavedFeeYears;
                            
                            //  tempOpportunityUnit.HomeMaintenanceWaivedAmount__c = tempPaymentPlan.homeMaintenanceWaiverFee!=null?tempPaymentPlan.homeMaintenanceWaiverFee.setScale(2):tempPaymentPlan.homeMaintenanceWaiverFee;
                            tempOpportunityUnit.HomeMaintenanceWaivedYears__c = tempPaymentPlan.homeMaintenanceWavierYears!=null?tempPaymentPlan.homeMaintenanceWavierYears.setScale(2):tempPaymentPlan.homeMaintenanceWavierYears;
                            tempOpportunityUnit.ExternalCommissionAmount__c = tempPaymentPlan.externalComissionAmount!=null?tempPaymentPlan.externalComissionAmount.setScale(2):tempPaymentPlan.externalComissionAmount;
                            
                            
                            tempOpportunityUnit.InternalCommissionAmount__c = tempPaymentPlan.internalComissionAmount!=null?tempPaymentPlan.internalComissionAmount.setScale(2):tempPaymentPlan.internalComissionAmount;
                            
                            unitsProject.add(tempOfferRecord.unitRecord.Project__c);
                            System.debug('tempOfferRecord.unitRecord'+tempOfferRecord);
                            System.debug('admFeeTobeChargedPercentage'+tempOfferRecord.admFeeTobeChargedPercentage);
                            System.debug('admFeeTobeChargedAmount'+ tempOfferRecord.admFeeTobeChargedAmount);
                            admFeeTobeChargedSalesOOthercharge = tempOfferRecord.admFeeTobeChargedAmount;
                            
                            unitPaymentPlanWrapper.put(tempOfferRecord.unitRecord , tempPaymentPlan);
                            Decimal ADMToBeCharged;
                            Decimal ADMTTobeCombined;
                            Decimal ADMAdminFeetoBeCharged;
                            if(tempOfferRecord.admFeeTobeChargedPercentage!=null && tempOfferRecord.admFeeTobeChargedAmount!=null){
                                ADMAdminFeetoBeCharged =  tempOfferRecord.admFeeTobeChargedAmount;
                                
                                ADMToBeCharged =  (tempPaymentPlan.netSalesPrice * tempOfferRecord.admFeeTobeChargedPercentage).setScale(2);
                                System.debug('ADMTTobeCombined'+Decimal.valueOf(AdmFeeCalValue));
                                //  ADMTTobeCombined = ((tempPaymentPlan.netSalesPrice/Decimal.valueOf(AdmFeeCalValue)) * tempOfferRecord.admFeeTobeChargedPercentage).setScale(2);
                                ADMTTobeCombined = ((tempPaymentPlan.netSalesPrice-ADMAdminFeetoBeCharged)/(Decimal.valueOf(AdmFeeCalValue)) * tempOfferRecord.admFeeTobeChargedPercentage).setScale(2);
                                System.debug('ADMTTobeCombined'+ADMTTobeCombined);
                                
                            }
                            //tempOpportunityUnit.ADMFeeAmount__c = ADMToBeCharged;
                            
                            
                            ADMToBeCharged = (ADMToBeCharged - tempOpportunityUnit.ADMFeeWaivedAmount__c).setScale(2);
                            list<SalesOrderOtherCharges__c> lstSOOtherCharges =  new list<SalesOrderOtherCharges__c>();
                            
                            if(tempOfferRecord.admFeeTobeChargedAmount!=null){
                                
                                if(tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal.containsKey(tempUnitKey) && tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal.get(tempUnitKey)==true){
                                    tempOpportunityUnit.ADM_Fee_Combined__c =ADMTTobeCombined+ADMAdminFeetoBeCharged;
                                }
                            }
                            // commented by Antriksh for almeria offer adm calculation
                            System.debug(''+tempPaymentPlan.unitIdToAdmFeeIncludeValue.containskey(tempUnitKey));
                            System.debug(''+tempPaymentPlan.unitIdToAdmFeeIncludeValue.get(tempUnitKey));
                            if(tempOpportunityUnit.ADMFeeWaivedAmount__c>0 && tempPaymentPlan.unitIdToAdmFeeIncludeValue.containskey(tempUnitKey) && tempPaymentPlan.unitIdToAdmFeeIncludeValue.get(tempUnitKey)==true){
                                
                                System.debug('ADM_Fee_Combined__c'+tempOpportunityUnit.ADM_Fee_Combined__c); 
                                lstSOOtherCharges.add(new SalesOrderOtherCharges__c(Amount__c = ADMTTobeCombined.setScale(2),TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE, Opportunity__c=opportunityId , Account__c=tempOpportunityUnit.Account__c));
                                System.debug('lstSOOtherCharges'+lstSOOtherCharges);
                            }
                            if(tempOpportunityUnit.ADMFeeWaivedAmount__c==0){
                                tempOpportunityUnit.ADMFeeAmount__c =ADMToBeCharged+ADMAdminFeetoBeCharged;//to get total
                                lstSOOtherCharges.add(new SalesOrderOtherCharges__c(Amount__c = ADMToBeCharged.setScale(2),TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE, Opportunity__c=opportunityId , Account__c=tempOpportunityUnit.Account__c));
                                
                            }
                            
                            if(tempOpportunityUnit.ADMFeeWaivedAmount__c>0){
                                tempOpportunityUnit.ADMFeeAmount__c =0;
                                tempOpportunityUnit.ADMFeeWaivedAmount__c = tempOpportunityUnit.ADMFeeWaivedAmount__c +ADMAdminFeetoBeCharged;
                            }
                            
                            if(tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal.containsKey(tempUnitKey)&& tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal.get(tempUnitKey)==true){
                                tempOpportunityUnit.Sales_Price_Excluding_ADMs__c=   tempOpportunityUnit.SellingPrice__c- tempOpportunityUnit.ADM_Fee_Combined__c-tempOpportunityUnit.Discount__c;
                                tempOpportunityUnit.Sales_Price_Excluding_ADM_Englsih__c= Utilities.amountInWords(tempOpportunityUnit.Sales_Price_Excluding_ADMs__c,'Dirham','Fils');
                            }
                            else if(tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal.containsKey(tempUnitKey)&& tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal.get(tempUnitKey)==false){
                                tempOpportunityUnit.Sales_Price_Excluding_ADMs__c=   tempOpportunityUnit.SellingPrice__c-tempOpportunityUnit.Discount__c;
                                tempOpportunityUnit.Sales_Price_Excluding_ADM_Englsih__c= Utilities.amountInWords(tempOpportunityUnit.Sales_Price_Excluding_ADMs__c,'Dirham','Fils');
                            }
                            
                            /* if(ADMAdminFeetoBeCharged>0){
                            System.debug('Entered ADMAdminFeetoBeCharged');
                            lstSOOtherCharges.add(new SalesOrderOtherCharges__c(Amount__c = ADMAdminFeetoBeCharged.setScale(2),TypeOfCharge__c = Constants.BUDGET_LINE_ADMADMINFEE, Opportunity__c=opportunityId , Account__c=tempOpportunityUnit.Account__c));
                            }*/
                            
                            if(!lstSOOtherCharges.isEmpty()){
                                unitToOtherSalesOrderCharges.put(tempUnitKey,lstSOOtherCharges);
                                
                            }
                            
                            System.debug('Log: if internalStaffComissionAmount'+tempPaymentPlan);
                            if (tempPaymentPlan.internalStaffComissionAmount != null && tempPaymentPlan.internalStaffComissionAmount != 0) {
                                CommissionLineItem__c commissionLineRecord = new CommissionLineItem__c();
                                commissionLineRecord.CommissionAmount__c = tempPaymentPlan.internalStaffComissionAmount.setScale(2);
                                commissionLineRecord.CommissionPercentage__c = 100;// tempPaymentPlan.internalStaffComissionAmount / tempOpportunityUnit.NetAmount__c;
                                commissionLineRecord.CommissionType__c = Constants.COMMISSION_LINE_INTERNAL_COMMISSION;
                                commissionLineRecord.BrokerAgent__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgentContact__c:null;
                                commissionLineRecord.BrokerAgency__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgencyAccount__c:null;
                                commissionLineRecord.SalesManager__c = (tempOfferRecord.opportunityRecord !=null ) ? tempOfferRecord.opportunityRecord.OwnerId : null;
                                commissionLineList.add(commissionLineRecord);
                            }
                            System.debug('Log: if internalReferralComissionAmount');
                            if (tempPaymentPlan.internalReferralComissionAmount != null && tempPaymentPlan.internalReferralComissionAmount != 0) {
                                CommissionLineItem__c commissionLineRecord = new CommissionLineItem__c();
                                commissionLineRecord.CommissionAmount__c = tempPaymentPlan.internalReferralComissionAmount!=null?tempPaymentPlan.internalReferralComissionAmount.setScale(2):tempPaymentPlan.internalReferralComissionAmount;
                                commissionLineRecord.CommissionPercentage__c = 100;//tempPaymentPlan.internalReferralComissionAmount / tempOpportunityUnit.NetAmount__c;
                                commissionLineRecord.BrokerAgent__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgentContact__c:null;
                                commissionLineRecord.BrokerAgency__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgencyAccount__c:null;
                                commissionLineRecord.SalesManager__c = (tempOfferRecord.opportunityRecord !=null ) ? tempOfferRecord.opportunityRecord.OwnerId : null;    
                                commissionLineRecord.CommissionType__c = Constants.COMMISSION_LINE_INTERNAL_COMMISSION;
                                commissionLineList.add(commissionLineRecord);
                            }
                            
                            //Populate Opportunity Instalment Lines
                            System.debug('Log: Installmentdetailsloop');
                            // Antriksh -20/09/2024 for update adm fee include checkbox
                            for(SalesOfferUtilityHandler.PaymentInstallmentWrapper tempInstallmentLine : tempPaymentPlan.installmentDetails){
                                InstallmentLines__c newInstallmentLine=  new InstallmentLines__c( 
                                    BrokerPayoutPercentage__c= tempInstallmentLine.installmentRecord.BrokerPayoutPercentage__c,
                                    Description__c= tempInstallmentLine.installmentRecord.Description__c,
                                    InstallmentNumber__c = tempInstallmentLine.installmentRecord.InstallmentNumber__c,
                                    InstallmentPercentage__c= tempInstallmentLine.installmentRecord.InstallmentPercentage__c,
                                    InstallmentDate__c= tempInstallmentLine.installmentRecord.InstallmentDate__c, 
                                    InstallmentAmount__c= tempInstallmentLine.totalValue!=null?tempInstallmentLine.totalValue.setScale(2):tempInstallmentLine.totalValue,
                                    InstallmentAmountintheWords__c = Utilities.amountInWords( (tempInstallmentLine.totalValue!=null?tempInstallmentLine.totalValue.setScale(2):tempInstallmentLine.totalValue),'Dhirams','Fils'),
                                    PaymentInstallments__c= tempInstallmentLine.installmentRecord.Id,
                                    PaymentPlan__c= tempInstallmentLine.installmentRecord.PaymentPlan__c,
                                    Type__c= tempInstallmentLine.installmentRecord.InstallmentType__c
                                ); 
                                System.debug('tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal1'+tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal.containsKey(tempUnitKey));
                                System.debug('tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal2'+tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal.get(tempUnitKey));
                                if (tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal.containsKey(tempUnitKey) && tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal.get(tempUnitKey)==true) {
                                    newInstallmentLine.ADM_Fee_Included__c = tempPaymentPlan.unitIdToOfferAdmFeeIncludeVal.get(tempUnitKey);
                                }
                                
                                // Add the new installment line to the appropriate list
                                installmentLines.get(tempUnitKey).add(newInstallmentLine);
                                
                                
                                
                                //Create Commission
                                //split based on the payout 
                                System.debug('tempOpportunityUnit'+tempOpportunityUnit);
                                if (tempOpportunityUnit.ExternalCommissionAmount__c != null && tempOpportunityUnit.ExternalCommissionAmount__c != 0 && tempInstallmentLine.installmentRecord.BrokerPayoutPercentage__c!=null && tempInstallmentLine.installmentRecord.BrokerPayoutPercentage__c!=0) {
                                    CommissionLineItem__c commissionLineExtenalRecord = new CommissionLineItem__c();
                                    commissionLineExtenalRecord.BrokerAgent__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgentContact__c:null;
                                    commissionLineExtenalRecord.BrokerAgency__c = tempOfferRecord.opportunityRecord!=null ? tempOfferRecord.opportunityRecord.BrokerAgencyAccount__c:null;
                                    commissionLineExtenalRecord.CommissionAmount__c = (tempOpportunityUnit.ExternalCommissionAmount__c * (tempInstallmentLine.installmentRecord.BrokerPayoutPercentage__c/100)).setScale(2);
                                    commissionLineExtenalRecord.CommissionPercentage__c =  tempInstallmentLine.installmentRecord.BrokerPayoutPercentage__c;
                                    commissionLineExtenalRecord.PercentageWRTNetPrice__c =((commissionLineExtenalRecord.CommissionAmount__c/tempOpportunityUnit.NetAmount__c)*100).setScale(2);  //tempInstallmentLine.installmentRecord.BrokerPayoutPercentage__c;
                                    commissionLineExtenalRecord.CommissionType__c = Constants.COMMISSION_LINE_EXTERNAL_COMMISSION;
                                    commissionLineExtenalRecord.SalesManager__c = (tempOfferRecord.opportunityRecord !=null ) ? tempOfferRecord.opportunityRecord.OwnerId : null;
                                    commissionLineExtenalRecord.ExternalCommissionAmountBasis__c = tempPaymentPlan.externalComissionAmountBasis;
                                    externalCommisionMap.put(''+tempUnitKey + tempInstallmentLine.installmentRecord.InstallmentNumber__c , commissionLineExtenalRecord);
                                }
                                
                            }
                        }
                    }
                    //Offer lines
                    
                    offerLines.put(tempUnitKey , new list<OpportunityOfferLine__c>());
                    System.debug(tempOfferRecord.applicableOfferLinesCalculated);
                    for(OfferLines__c tempOfferLine : tempOfferRecord.applicableOfferLinesCalculated){
                        if(tempOfferLine.OfferType__c.equalsIgnoreCase(Constants.OFFER_TYPE_VOUCHER) && tempOfferLine.Bulk__c){
                            if(applicableVoucher.contains(tempOfferLine.Id)){continue;}
                            applicableVoucher.add(tempOfferLine.Id);
                        }
                        offerLines.get(tempUnitKey).add(new OpportunityOfferLine__c(name= tempOfferLine.Name,
                                                                                    OfferLine__c = tempOfferLine.Id,
                                                                                    OfferValue__c = tempOfferLine.OfferValue__c));
                    }
                    createCommissionMap.put(tempUnitKey, commissionLineList);
                    if(action=='BOOKING'){
                        tempOpportunityUnit.Status__c = constants.OPPO_UNIT_STATUS_PENDING; 
                        tempOpportunityUnit.SubStatus__c = constants.OPPO_UNIT_SUBSTATUS_PENDING_SM; 
                        tempOpportunityUnit.BookingDate__c = system.Today();
                        tempOpportunityUnit.ExpectedEndDate__c =  Date.today().addDays(Integer.valueOf(CustomLabelUtility.salesClosureDays));      
                    }
                    
                    //populate unit details based on Action
                    Unit__c unitToUpdate = new Unit__c(id=tempUnitKey );
                    /*if(action=='RESERVE'){
                    unitToUpdate.Status__c=  Constants.STATUS_RESERVED;
                    }else*/ if(action=='BOOKING'){
                        unitToUpdate.Status__c=  Constants.UNIT_STATUS_BOOKED;
                        unitToUpdate.AllocationGroup__c =null;
                        unitToUpdate.AssignedToUser__c = UserInfo.getUserId();
                        opportunityRecord.CloseDate = system.today();
                        opportunityRecord.WinReason__c=winReason;
                        if(downPayment!=null){
                            opportunityRecord.DownPayment_Received__c=downPayment;
                        }
                        
                    }
                    update opportunityRecord;
                    // Add Unit
                    unitsToReserve.put(tempUnitKey,unitToUpdate);
                    //Add SO
                    opportunityUnitsToCreate.put(tempUnitKey, tempOpportunityUnit);
                    
                }else{
                    valueToReturn.put('result','Unit not available for '+action);
                    return valueToReturn;
                }
                
            }
            if(!unitsToReserve.isEmpty()){
                /* for(id tempUnitKey : unitsToReserve.keySet()){
                unitsToReserve.get(tempUnitKey).RelatedSalesOrder__c = opportunityUnitsToCreate.get(tempUnitKey).Id;
                }*/
                update unitsToReserve.values();
            }
            
            //Create Opportunity Unit
            if(!opportunityUnitsToCreate.isEmpty()){
                insert opportunityUnitsToCreate.values();
                List<Id> salesOrderIds = new List<Id>();
                for (SalesOrder__c salesOrder : opportunityUnitsToCreate.values()) {
                    salesOrderIds.add(salesOrder.Id);
                    System.debug('salesOrderIds'+salesOrderIds);
                }
                
                // Pass the list of SalesOrder IDs to the method
                ConverNumbertoArabicText.fetchConvertedResponse(salesOrderIds);
                
                
            }
            
            //Reparent EOI records
            if(!eoiRAtoReparent.isEmpty()  ){
                for(ReceiptAcknowledgement__c ra : eoiRAtoReparent){
                    ra.SalesOrder__c = opportunityUnitsToCreate.values()[0].id;
                }
                update eoiRAtoReparent;
            }
            //Update Unit
            if(!unitsToReserve.isEmpty()){
                for(id tempUnitKey : unitsToReserve.keySet()){
                    unitsToReserve.get(tempUnitKey).RelatedSalesOrder__c = opportunityUnitsToCreate.get(tempUnitKey).Id;
                }
                update unitsToReserve.values();
            }
            //****************************************************// 
            
            
            
            
            //*****************************************************//
            //Create Opportunity Unit Installments
            if(!installmentLines.isEmpty()){
                list<InstallmentLines__c> finalListToInsert = new list<InstallmentLines__c>();
                map<ID,ID> salesOrderToUnitMap = new map<Id,Id>();
                for(id tempUnitKey : installmentLines.keySet()){
                    for(InstallmentLines__c tempInstallmentRecord : installmentLines.get(tempUnitKey)){
                        
                        /* Remove ADM Cmbined Fee from the Installment Amount */
                        System.debug('--->' + tempInstallmentRecord.InstallmentAmount__c);
                        System.debug('--->' + (opportunityUnitsToCreate.get(tempUnitKey).ADM_Fee_Combined__c));
                        if(tempInstallmentRecord.InstallmentAmount__c != null 
                           && opportunityUnitsToCreate.containsKey(tempUnitKey) 
                           && tempInstallmentRecord.ADM_Fee_Included__c == true ){
                               if(opportunityUnitsToCreate.get(tempUnitKey).ADM_Fee_Combined__c != null){
                                   if(tempInstallmentRecord.InstallmentNumber__c == 1){
                                       tempInstallmentRecord.Installment_Amount_Excluding_ADM__c = tempInstallmentRecord.InstallmentAmount__c -  opportunityUnitsToCreate.get(tempUnitKey).ADM_Fee_Combined__c;
                                   }else{
                                       tempInstallmentRecord.Installment_Amount_Excluding_ADM__c = tempInstallmentRecord.InstallmentAmount__c;
                                       
                                   }
                               }
                           }
                        /**/
                        
                        tempInstallmentRecord.SalesOrder__c = opportunityUnitsToCreate.get(tempUnitKey).Id;
                        
                        salesOrderToUnitMap.put(opportunityUnitsToCreate.get(tempUnitKey).Id , tempUnitKey);
                        finalListToInsert.add(tempInstallmentRecord);
                    }
                }
                insert finalListToInsert;
                //Populate external commission
                for(InstallmentLines__c tempLineItem : finalListToInsert){
                    if(externalCommisionMap.containsKey(''+salesOrderToUnitMap.get(tempLineItem.SalesOrder__c)+tempLineItem.InstallmentNumber__c)){
                        externalCommisionMap.get(''+salesOrderToUnitMap.get(tempLineItem.SalesOrder__c)+tempLineItem.InstallmentNumber__c).InstallmentLine__c = tempLineItem.Id;
                        
                        if(!createCommissionMap.containsKey(salesOrderToUnitMap.get(tempLineItem.SalesOrder__c))){
                            createCommissionMap.put(salesOrderToUnitMap.get(tempLineItem.SalesOrder__c), new list<CommissionLineItem__c>());
                        }
                        createCommissionMap.get(salesOrderToUnitMap.get(tempLineItem.SalesOrder__c) ).add(externalCommisionMap.get(''+salesOrderToUnitMap.get(tempLineItem.SalesOrder__c)+tempLineItem.InstallmentNumber__c));
                    }
                }
            }
            
            
            // Create Other Sales Charges
            if (!unitToOtherSalesOrderCharges.isEmpty()) {
                list<SalesOrderOtherCharges__c> finalListToInsert = new list<SalesOrderOtherCharges__c>();
                for (id tempUnitKey : unitToOtherSalesOrderCharges.keySet()) {
                    Set<Id> uniqueSalesOrderIds = new Set<Id>(); // Set to track unique SalesOrder__c ID
                    
                    for (SalesOrderOtherCharges__c tempOtherChargeRecord : unitToOtherSalesOrderCharges.get(tempUnitKey)) {
                        Id salesOrderId = opportunityUnitsToCreate.get(tempUnitKey).Id;
                        
                        // Check if the SalesOrder__c ID is already in the Set
                        if (!uniqueSalesOrderIds.contains(salesOrderId)) {
                            SalesOrderOtherCharges__c tempOther = new SalesOrderOtherCharges__c();
                            // Decimal ADMAdminFeetoBeCharged =  decimal.valueOf(Label.ADMAdminFee);
                            
                            tempOther.Amount__c = tempOtherChargeRecord.Amount__c + admFeeTobeChargedSalesOOthercharge;
                            tempOther.TypeOfCharge__c = tempOtherChargeRecord.TypeOfCharge__c;
                            tempOther.Account__c = tempOtherChargeRecord.Account__c;
                            tempOther.SalesOrder__c = salesOrderId;
                            if( tempOther.Amount__c!=admFeeTobeChargedSalesOOthercharge){
                                finalListToInsert.add(tempOther);
                            }
                            // Add the SalesOrder__c ID to the Set
                            uniqueSalesOrderIds.add(salesOrderId);
                        }
                    }
                }
                insert finalListToInsert;
            }
            //Create Commission Lines
            if(!createCommissionMap.isEmpty()){
                list<CommissionLineItem__c> finalListToInsert = new list<CommissionLineItem__c>();
                list<CommissionLineItem__c> clListToInsert = new list<CommissionLineItem__c>();
                for(id tempUnitKey : createCommissionMap.keySet()){
                    for(CommissionLineItem__c tempCommissionLineRecord : createCommissionMap.get(tempUnitKey)){
                        tempCommissionLineRecord.SalesOrder__c = opportunityUnitsToCreate.get(tempUnitKey).Id;
                        finalListToInsert.add(tempCommissionLineRecord);
                    }
                }
                clListToInsert.addAll(finalListToInsert);
                insert clListToInsert;
            }
            
            //Create Opportunity Unit Offers
            if(!offerLines.isEmpty()){
                list<OpportunityOfferLine__c> finalListToInsert = new list<OpportunityOfferLine__c>();
                for(id tempUnitKey : installmentLines.keySet()){
                    for(OpportunityOfferLine__c tempOfferRecord : offerLines.get(tempUnitKey)){
                        tempOfferRecord.SalesOrder__c = opportunityUnitsToCreate.get(tempUnitKey).Id;
                        finalListToInsert.add(tempOfferRecord);
                    }
                }
                insert finalListToInsert;
            }
            
            //Create Opportunity Unit Payment Lines
            if(!createPaymentLines.isEmpty()){
                for(id tempUnitKey : createPaymentLines.keySet()){
                    createPaymentLines.get(tempUnitKey).SalesOrder__c = opportunityUnitsToCreate.get(tempUnitKey).Id;
                }
                insert createPaymentLines.values();
            }
            
            // Update Sales Order to call Sales Order API
            if(!opportunityUnitsToCreate.isEmpty()){
                
                TriggerHandler.processedIds = new Set<Id>();
                update opportunityUnitsToCreate.values();
            }
            //For reservation send for approval
            /*   if(action=='RESERVEx'){
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Reservation Approval Request for units ');
            req1.setObjectId(opportunityId);
            req1.setSubmitterId(UserInfo.getUserId());
            req1.setProcessDefinitionNameOrId('Reservation_Approval');
            req1.setSkipEntryCriteria(true);
            Approval.ProcessResult result = Approval.process(req1);
            }*/
            valueToReturn.put('result','success');
            valueToReturn.put('id',opportunityUnitsToCreate.values()[0].id);
            
        }catch(exception e){
            Database.rollback(sp);
            valueToReturn.put('result','Exception : '+e.getMessage());
        }
        return valueToReturn;
    }
    
}