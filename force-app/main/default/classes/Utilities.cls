public with sharing class Utilities {
    
   //Added by Maaz for converting numeric values into words
   static final Integer DIGITS_PER_SET = 3;
   static final String ZERO = 'Zero';
   private static Map<Integer,String> tens = new Map<Integer,String> {
       20 => 'Twenty',
       30 => 'Thirty',
       40 => 'Forty',
       50 => 'Fifty',
       60 => 'Sixty',
       70 => 'Seventy',
       80 => 'Eighty',
       90 => 'Ninety'
   };
   private static Map<Integer,String> smallNumbers = new Map<Integer,String> {
       0 => 'Zero',
       1 => 'One',
       2 => 'Two',
       3 => 'Three',
       4 => 'Four',
       5 => 'Five',
       6 => 'Six',
       7 => 'Seven',
       8 => 'Eight',
       9 => 'Nine',
       10 => 'Ten',
       11 => 'Eleven',
       12 => 'Twelve',
       13 => 'Thirteen',
       14 => 'Fourteen',
       15 => 'Fifteen',
       16 => 'Sixteen',
       17 => 'Seventeen',
       18 => 'Eighteen',
       19 => 'Nineteen'
   };
   private static Map<Integer,String> modifiers = new Map<Integer,String> {
       1 => 'Thousand ',
       2 => 'Million ',
       3 => 'Billion '
   };    

   public static String NumberToTextconvert(Integer value) 
   {
    // zero is a special case
    if (value == 0)
        return ZERO;

    // text representation of the number to convert. e.g. 'one hundred'
    String numberText = '';

    // If value is negative prepend the text with 'negative'
    // and then process as a positive value
    if (value < 0) {
        numberText = 'negative ';
        value *= -1;
    }

    // string representation of the number to convert. e.g. '100'
    String numberString = String.valueOf(value);

    // split the number into sets (hundreds, thousands, millions, billions)
    // and convert each as a three digit number.
    while(numberString.length() > 0){
        // Figure out how many digits are in this set
        Integer digits = Math.mod(numberString.length(), DIGITS_PER_SET) == 0 ?
                         DIGITS_PER_SET :
                         Math.mod(numberString.length(), DIGITS_PER_SET);

        // Create a string to represent this set.
        String thisSet = numberString.substring(0, digits);

        // Convert the set into an integer and generate the text for this set.
        Integer valueToConvert = Integer.valueOf(thisSet);

        // Remove the first set from numberString now that it has been converted.
        numberString = numberString.substring(digits, numberString.length());

        if (valueToConvert > 0) {                
            String setText = NumberToTextgenerateText(valueToConvert);

            // Calculate the modifierIndex to determine what set this is
            // e.g. thousands, millions, billions.
            Integer modifierKey = numberString.length() / DIGITS_PER_SET;

            // Create the modifier string
            String modifier = modifierKey > 0 ? ' ' + modifiers.get(modifierKey) : '';

            // Build the text
            numberText += setText + modifier;
        }
    }    
    return numberText.trim();
}

private static String NumberToTextgenerateText(Integer value) {
    if (value < 100)
        return generateTextForTwoDigits(value);

    String numberText = '';

    // Calculate the number of hundreds
    Integer hundreds = value / 100;
    if (hundreds > 0)
        numberText = generateTextForTwoDigits(hundreds) + ' Hundred';

    // Calculate the leftover value
    Integer leftOver = Math.mod(value, 100);
    if (leftOver > 0)
        numberText += ' ' + generateTextForTwoDigits(leftOver);
    return numberText;
}

private static String generateTextForTwoDigits(Integer value) {
    if (value < 20) {
        return smallNumbers.get(value);
    }

    // Round the value down to the nearest 10 and get the text representation
    Integer tensKey = (value/10) * 10;
    String numberText = tens.get(tensKey);

    // Calculate the leftover value
    Integer leftOver = value - tensKey;

    if (leftOver > 0) {
        // Add a hypen for values between 21 - 99.
        // https://www.grammarly.com/blog/hyphen-in-compound-numbers/
        if (tensKey >= 20 && tensKey <= 90 && leftOver > 0) {
            numberText += '-';
        }
        numberText += generateTextForTwoDigits(leftOver);
    }
    return numberText;
}
  //Added by Maaz till here for number conversion to text values  


    public static Map<String,String> constantsMap ;
    public static String objType = '';
    public static User userDetail ;
    
    
    
    
    
    //Get System Messages
    public static SystemMessages__mdt getSystemMessages(string messageName){
        try{
            SystemMessages__mdt messageDetails = [SELECT DeveloperName, Message__c, MergeFieldsToReplace__c, LongMessage__c
                                                  FROM SystemMessages__mdt
                                                  WHERE DEVELOPERNAME =: messageName];
            return messageDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    
    @auraEnabled(cacheable=true)
    public static map<string,string> getPicklistValues(String objName,String fieldName){
        Map<string,string> pickValMap = new  Map<string,string>();     
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objName) ;
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        System.debug('fields'+fieldResult);
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){           
            pickValMap.put(pickListVal.getLabel(),pickListVal.getValue());
        }
        return pickValMap;
        
    }
    
    //Get Timer Details
    public static Timer__mdt getTimer(string timerName){
        try{
            Timer__mdt timerDetails = [SELECT Timer__c, Time__c
                                       FROM Timer__mdt
                                       WHERE DEVELOPERNAME =: timerName];
            return timerDetails;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    
    
    
    
    public static String getOrgWideEmailAddressId(){
        try{
            
            OrgWideEmailAddress orgWideEmailAddress = [Select id,Address From OrgWideEmailAddress LIMIT 1];
            
            return orgWideEmailAddress.Id;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    
    public static SystemConfiguration__mdt getSystemInformation(string objectName){
        try{
            SystemConfiguration__mdt systemConfig = [SELECT DeveloperName,MasterLabel,
                                                     IsRunBeforeInsert__c,IsRunBeforeUpdate__c,IsRunAfterInsert__c,IsRunAfterUpdate__c,IsRunBeforeDelete__c,IsRunAfterDelete__c,IsRunTrigger__c
                                                     FROM SystemConfiguration__mdt 
                                                     WHERE MasterLabel =: objectName];
            return systemConfig ;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    
   
    
    /**
* SendEmailWithTemplateID 
*
* This method will return SingleEmailMessage instance with given parameters
* 
* @usage all apex based emails
*
* @param    targetObject     contact/user/lead ID
* @param    templateID       template ID to be used
* @param    whatId           What ID for additinal merge details
* @param    toRecipients     List of Send to address
* @param    bccRecipients    List of BCC address
* @param    ccRecipients     List of CC address
* @param    emailSubject     Email Subject
* @param    body             Plain text body
* @param    htmlBody         Html Body
* @param    fileAttachments  list of attachments
* @param    OrgWideEmailAddressID    org wide email Id 
*
* @return Messaging.SingleEmailMessage instance
*/
    public static Messaging.SingleEmailMessage getEmailInstance( string targetObject, string templateID,string whatId , List<String> toRecipients,List<String> bccRecipients,List<String> ccRecipients,String emailSubject,String body,string htmlBody,List<Messaging.EmailFileAttachment> fileAttachments,string orgWideEmailAddressID) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
        mail.setSaveAsActivity(false);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        if(targetObject!=null && targetObject!=''){
            mail.setTargetObjectId(targetObject);
        }
        if(whatId!=null && whatId!=''){
            mail.setWhatId(whatId);
        }
        if(templateID!=null && templateID!=''){
            mail.setTemplateID(templateID);
        }
        if(emailSubject!=null && emailSubject!=''){
            mail.setSubject(emailSubject);
        }
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
    
    /**
* SendEmailWithTemplateID 
*
* This method will trigger send email logic
* 
* @usage all apex based emails
*
* @param    mails     list<Messaging.SingleEmailMessage> to be sent
*
* @return none
*/
    public static list<Messaging.SendEmailResult> sendEmail(list<Messaging.SingleEmailMessage> mails) {
        return Messaging.sendEmail(mails); 
    }
   
    /*
    Get Current user profileName 
    */

    @AuraEnabled(cacheable=false)
    public static string getCurrentUserProfileName(){
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        system.debug('ProfileName' + PROFILE[0].Name);
        Return PROFILE[0].Name;

    }
    
    
    /*
* Get Record Type Id by Object
*/
    public static Id getRecordTypeId(String objectName, String recordTypeName){
        Map<String,Schema.SObjectType> schemaDescribe = Schema.getGlobalDescribe();  
        Schema.DescribeSObjectResult describeResult = schemaDescribe.get(objectName).getDescribe();
        return(describeResult.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId());
    }
    
    
    /*
* Get Constant value
*/
    @AuraEnabled(cacheable=false)
    public static Integer getConstantValue(String constantName){
        
        Integer constantValue ;
        
        if(constantsMap == null){
            constantsMap = new Map<String,String>();
            for(Constant__mdt constant : [SELECT DeveloperName, MasterLabel, ConstantValue__c FROM Constant__mdt]){
                constantsMap.put(constant.DeveloperName,constant.ConstantValue__c);
            }   
        }
        
        if(constantsMap.containsKey(constantName))
            constantValue = Integer.ValueOF(constantsMap.get(constantName)); 
        
        return constantValue ;
    }
    
    /*
* Get Constant value
*/
    @AuraEnabled(cacheable=false)
    public static Constant__mdt getConstant(string messageName){
        try{
            Constant__mdt constant = [SELECT DeveloperName, MasterLabel, ConstantValue__c, ConstantValueLong__c
                                      FROM Constant__mdt WHERE DEVELOPERNAME =: messageName];
            
            return constant;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }
    
    /*
* Get Record Count for the App
*/
    public static integer getRecordCount(String constantName,Integer maxRecordCount){
        
        try{
            Integer recordCountToFetch = getConstantValue(constantName) ;
            recordCountToFetch = (recordCountToFetch != null && recordCountToFetch > 0 ) ? recordCountToFetch : 3000;
            if(maxRecordCount > 0){
                return recordCountToFetch > maxRecordCount ? maxRecordCount : recordCountToFetch;
            }else{
                return recordCountToFetch;
            }
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return 3000;
        }
    }
    
   
    /*
* Get Logged In User Details
*/
    public static User getLoggedInUserDetail(){
        User userDetail = Utilities.userDetail ;
        if(userDetail==null){
            userDetail = [SELECT Id,Name,ProfileName__c,UserRole.Name,Profile.Name, UserRole.Id,AccountId, ContactId, Contact.AccountId,Contact.AgentID__c,Team__c,Email,UserRoleId,ProfileId,FullPhotoUrl,Title,Manager.Name,MobilePhone  FROM USER WHERE Id=:UserInfo.getUserId()];
            Utilities.userDetail = userDetail ;
        }   
        return userDetail ;     
    }
    
   
   
   
    /*
* Get Domain URL for VF page
*/
    @AuraEnabled(cacheable=false)
    public static String getVFDomainURL(){
        String currentDomainURL = '';
        string baseURL = URL.getOrgDomainUrl().toExternalForm();
//        currentDomainURL = baseURL.split('.my.')[0] + '--c.' + 'visualforce.com'; 
        currentDomainURL = baseURL.split('.sandbox.')[0] + '--c.' + 'sandbox.vf.force.com'; 
        return currentDomainURL ;     
    }
    
    public class MyPickListInfo {
        public String validFor;
    }
    
    @AuraEnabled
    
    public static void createLogAudit(Id recordId,String recordName){
        
        LogRecordAudit__c logAudit = new LogRecordAudit__c();
        logAudit.Name = (String.isNotBlank(recordName)? recordName :Constants.GENERIC_MOBILE_LOG_VIEW) ;
        if(recordId.getSObjectType() == Lead.SObjectType)
            logAudit.Lead__c = recordId;
        if(recordId.getSObjectType() == Account.SObjectType)
            logAudit.Account__c = recordId;       
        insert logAudit ;
    }
    
    
    //----- Get System Messages by set of strings
    public static Map<String,SystemMessages__mdt> getSystemMessages(Set<String> messageNames){
        Map<String,SystemMessages__mdt> systemMessagesMap = new Map<String,SystemMessages__mdt>();
        
        try{
            for(SystemMessages__mdt messageDetails : [SELECT DeveloperName, Message__c, MergeFieldsToReplace__c, LongMessage__c
                                                      FROM SystemMessages__mdt WHERE DeveloperName IN: messageNames]){
                                                          systemMessagesMap.put(messageDetails.DeveloperName,messageDetails);
                                                      }
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
        
        return systemMessagesMap ; 
    }
    
    /*
* Purpose : To fetch the records from ValidationFields__mdt metadata
* Created by : Smaartt
*/
    public static Map<String,List<ValidationFields__mdt>> getValidationFields()
    {
        List<ValidationFields__mdt> valFieldList = ValidationFields__mdt.getall().values();
        
        Map<String,List<ValidationFields__mdt>> validationFieldsMap = new Map<String,List<ValidationFields__mdt>>();
        
        for(ValidationFields__mdt vf : valFieldList)
        {
            if(!validationFieldsMap.containsKey(vf.ObjectName__c))
                validationFieldsMap.put(vf.ObjectName__c, new List<ValidationFields__mdt>{vf});
            else
            {
                List<ValidationFields__mdt> valfldList = validationFieldsMap.get(vf.ObjectName__c);
                valfldList.add(vf);
                validationFieldsMap.put(vf.ObjectName__c, valfldList);
            }
            
        }
        
        return validationFieldsMap;
    }
    
    /*
* Purpose : To fetch the records from OfferLinesService__mdt metadata
* Created by : smaartt
*/
    public static Map<String,OfferLinesService__mdt> getOfferLineService()
    {
        List<OfferLinesService__mdt> OfferLineService = OfferLinesService__mdt.getall().values();
        
        Map<String,OfferLinesService__mdt> OfferLineServiceMap = new Map<String,OfferLinesService__mdt>();
        
        for(OfferLinesService__mdt OfferService : OfferLineService)
        {
            if(!OfferLineServiceMap.containsKey(OfferService.FieldAPI__c))
                OfferLineServiceMap.put(OfferService.FieldAPI__c, OfferService);            
            
        }
        
        return OfferLineServiceMap;
    }
    
    /**
* amountInWords 
*
* This method is used to convert the amount into text
* 
* @usage opportunityUnitSearchHandler
*
* @param amount    amount to be converted
* @param currencyUnit   primary currency unit
* @param currencySubUnit    secondary unit/subunit
* @return   string amount in words
*/
    public static string amountInWords(decimal amount, string currencyUnit, String currencySubUnit){
        String amountInWords = '';
        if(amount !=null){
            Decimal totalAmount = amount.setScale(2) ;
            String totalAmountString = String.valueOf(totalAmount);
            String beforeDecimal='';
            String afterDecimal='';
            
            if(totalAmountString.contains('.')){
                beforeDecimal = totalAmountString.substringBefore('.');
                beforeDecimal = NumberToTextconvert(Integer.valueOf(beforeDecimal));
                
                afterDecimal = totalAmountString.substringAfter('.');
                afterDecimal = NumberToTextconvert(Integer.valueOf(afterDecimal));
                
            }else{
                beforeDecimal = NumberToTextconvert(Integer.valueOf(totalAmount));
            }
            
            if(String.isNotBlank(beforeDecimal)){
                amountInWords =  beforeDecimal + ' '+currencyUnit+' ';
            }
            if(String.isNotBlank(afterDecimal) && afterDecimal !='Zero'){
                amountInWords = amountInWords + 'and ' +afterDecimal + ' '+currencySubUnit+' ';
            }
            amountInWords = amountInWords +'Only.' ;
        }
        return amountInWords;
    }
    
    public static Messaging.EmailFileAttachment setEmailFileAtt(ContentVersion cvObj) {
        Messaging.EmailFileAttachment emlAtt = new Messaging.EmailFileAttachment();
        Blob fileData = cvObj.VersionData;
        emlAtt.setFilename(cvObj.Title);
        emlAtt.setBody(fileData);
        return emlAtt;
    }

 
    //Added by Maaz for Building related Calls
    @AuraEnabled(cacheable=true)
    public static List<BuildingSection__c> prepareBuildingsNames(String projectId){ 
    list<BuildingSection__c> lstLocationName = new list<BuildingSection__c>();
    for(BuildingSection__c objP : [Select Id,Name from BuildingSection__c where Project__c   =: projectId WITH SECURITY_ENFORCED order by Name]){
      lstLocationName.add(objP);
    }
    return lstLocationName;
    }
    
    @auraEnabled
    public static string genericValidationMsgGenerator(Id recordId){
        
        string validationMsg = '';
        String sObjectName = recordId.getSObjectType().getDescribe().getName();
        Sobject sobjectData = getDataWithAllFields(recordId);
        
        List<ValidationFields__mdt> validationList = [SELECT Id,MasterLabel,Label,IsActive__c,FieldAPI__c,ObjectName__c,Process__c,RecordType__c FROM ValidationFields__mdt WHERE ObjectName__c=:sObjectName AND IsActive__c=true ];
        
        System.debug('hasRecType--'+string.valueOf(sobjectData).contains('RecordTypeId'));
        
        if(validationList.size()>0 && sobjectData!= null){
            
            string rectypeId = string.valueOf(sobjectData).contains('RecordTypeId')?string.valueOf(sobjectData.get('RecordTypeId')):'';
            
            for(ValidationFields__mdt vl : validationList){
                
                if(String.isNotBlank(rectypeId)){                    
                    string recordTypeName = Schema.getGlobalDescribe().get(sObjectName).getDescribe().getRecordTypeInfosById().get(rectypeId).getName();
                    if(recordTypeName!=null && vl.RecordType__c == recordTypeName) {                     
                        validationMsg += (String.isNotBlank(String.valueOf( sobjectData.get(vl.FieldAPI__c))) ? '': (String.isNotBlank(validationMsg) ? +', ' : '') + vl.Label);
                    }
                }else{
                    validationMsg += (String.isNotBlank(String.valueOf( sobjectData.get(vl.FieldAPI__c))) ? '': (String.isNotBlank(validationMsg) ? +', ' : '') + vl.Label);
                }            
            }
            system.debug(validationMsg);
        }
        return validationMsg;
        
    }
    
     public static List<String> getUsersInPublicGroup(String GroupName) {
        List<User> groupUsers = new List<User>();
         List<String>getUserEmails = New List<String>();
        Group publicGroup = [SELECT Id,Name,DeveloperName FROM Group where DeveloperName=:GroupName];
         System.debug('publicGroup'+publicGroup);
        List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :publicGroup.Id];
        
        Set<Id> userIds = new Set<Id>();
        for (GroupMember member : groupMembers) {
            userIds.add(member.UserOrGroupId);
        }
        
        
        groupUsers = [SELECT Id, Name, Email FROM User WHERE Id IN :userIds];
         for(User u:groupUsers){
             getUserEmails.add(u.Email);
         }
        
        return getUserEmails;
    }

    
 @AuraEnabled
public static String OppBlackListEirateValidation(Id recordId) {
    String str='';// Default return value
   
        List<Opportunity> oppList = [SELECT Id, AccountId, Account.Emirate_Id_Copy__c FROM Opportunity WHERE Id = :recordId];
        Set<String> accountIds = new Set<String>();
        for (Opportunity opp : oppList) {
            accountIds.add(opp.AccountId);
        }

        Map<Id, String> accountIdToEmiratesMap = new Map<Id, String>();
        for (Account acc : [SELECT Id, Emirate_Id_Copy__c FROM Account WHERE Id IN :accountIds]) {
            accountIdToEmiratesMap.put(acc.Id, acc.Emirate_Id_Copy__c);
        }

        Set<String> blacklistedEmirates = new Set<String>();
        for (Black_List_Emirate_Validation__mdt blacklistEntry : [SELECT Emirate_Ids__c FROM Black_List_Emirate_Validation__mdt]) {
            blacklistedEmirates.addAll(blacklistEntry.Emirate_Ids__c.split(','));
        }

        for (Opportunity opp : oppList) {
            String emirateId = accountIdToEmiratesMap.get(opp.AccountId);
            if (emirateId != null && blacklistedEmirates.contains(emirateId)) {
                str = 'This opportunity cannot be processed as it belongs to a blacklisted emirate.';
                break; // Exit the loop once we find one blacklisted opportunity
            }
        }
     
    return str;
}




        
    
        
    
    public static Sobject getDataWithAllFields(Id recordId){

        String sObjectName = recordId.getSObjectType().getDescribe().getName();

        Set<String> FieldList = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().keySet();

        String fields = string.join(new list<string>(FieldList),',');      

        String query = 'SELECT ' + fields +' From '+sObjectName+' WHERE Id = :recordId';       

        return Database.Query(query);

        

    }
    
     private static final List<String> N2W_ONES = new List<String>{
        '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
        'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
        'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    };
    
    private static final List<String> N2W_TENS = new List<String>{
        '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    };
    
    private static final List<String> N2W_THOUSANDS = new List<String>{
        '', 'Thousand', 'Million', 'Billion'
    };
    
    /** Convert an integer (Long) to words using Western scale (up to Billions). */
    public static String n2wInteger(Long num) {
        if (num == null) return '';
        if (num == 0)     return 'Zero';
    
        String result = '';
        Integer idx = 0;
        Long n = Math.abs(num);
    
        while (n > 0) {
            Integer chunk = Integer.valueOf(Math.mod(n, 1000));
            if (chunk != 0) {
                String part = n2wChunk(chunk);
                String suffix = N2W_THOUSANDS[idx];
                result = (part + (String.isNotBlank(suffix) ? ' ' + suffix : '') + ' ' + result).trim();
            }
            n = n / 1000;
            idx++;
        }
    
        if (num < 0) result = 'Negative ' + result;
        // Normalize whitespace and hyphens are produced only within chunk words.
        return result.replaceAll('\\s+', ' ').trim();
    }
    
    /** Convert a 0..999 chunk. */
    private static String n2wChunk(Integer chunkValue) {
        Integer c = chunkValue;
        String out = '';
    
        if (c >= 100) {
            Integer hundreds = c / 100;
            out += N2W_ONES[hundreds] + ' Hundred';
            c = Math.mod(c, 100);
            if (c > 0) out += ' ';
        }
    
        if (c >= 20) {
            Integer tensDigit = c / 10;
            Integer unitsDigit = Math.mod(c, 10);
            out += N2W_TENS[tensDigit];
            if (unitsDigit != 0) out += '-' + N2W_ONES[unitsDigit];
        } else if (c > 0) {
            out += N2W_ONES[c];
        }
    
        return out;
    }
    
    /**
     * Convert a money amount into words like:
     * "One Hundred Twenty-Three Dirhams and Five Fils Only"
     *
     * @param amount    monetary amount (will be rounded to 2 decimals for subunit)
     * @param unit      major unit label (e.g., 'Dirhams', 'Rupees', 'Dollars')
     * @param subUnit   minor unit label (e.g., 'Fils', 'Paise', 'Cents')
     */
    public static String amountToWords(Decimal amount, String unit, String subUnit) {
        if (amount == null) return '';
    
        // Whole part
        Long intPart = amount.longValue();
    
        // Fractional part as 0..99 after rounding to 2 decimals
        Decimal rounded = amount.setScale(2);
        Decimal frac = (rounded - rounded.setScale(0)) * 100;
        Integer decPart = frac.abs().setScale(0).intValue(); // always positive 0..99
    
        String words = n2wInteger(intPart) + ' ' + unit;
        if (decPart > 0) {
            words += ' and ' + n2wInteger(Integer.valueOf(decPart)) + ' ' + subUnit;
        }
        return words + ' Only';
    }
    public String formatDayMonth(Date dt) {
        DateTime dtTime = DateTime.newInstance(dt, Time.newInstance(0, 0, 0, 0));
        return dtTime.format('dd MMMM');
    }
     public class WebServiceException extends Exception {
        public Integer statusCode {get;set;}
    }

    public class UnitsAlreadyBookedException extends Exception {
        public List<Unit__c> units {get;set;}
        public Set<Id> unitRemoved {get;set;}
    }

    public class UnitsTimerExpiredException extends Exception {
        public List<Unit__c> units {get;set;}
    }

    public class DataNotCompleteException extends Exception{
        public List<String> messages {get;set;}
    }
    

    public class PaymentPlanException extends Exception{}
    public class BudgetUnAvailableException extends Exception{}    
    public class UpdatingAccountsWithDifferentTypesException extends Exception{}
    public class IncorrectFilterException extends Exception{}
    public class MultipleEOIException extends Exception {}

    

}