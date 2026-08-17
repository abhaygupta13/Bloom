/*
* @Author: Biswajeet Samal
* @CreatedDate: 13th AUG 2024
* @Description: Utility
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   24NOV2024      	 Initial draft 
* 1.1           Shruti      04OCTOMBER2025   Check if a record exists in org based on Id
* 1.2			Dhanraj		20NOV2025		 Added 2 new methods for date and currency
*****************************************************************************************************/
public class Utility {
    
    private static Utility instance;
    
    public static Utility getInstance() {
        if(instance == null) {
            instance = new Utility();
        }
        return instance;
    }
    
    public static String getRandomString(Integer len) {
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    //Shruti
    public static String generateRandomPassword() {
        
        String charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        String randomPassword = '';
        String charToInsert = '@';
        for (Integer i = 0; i < 8; i++) {  
            Integer randomIndex = Integer.valueOf(Math.floor(Math.random() * charset.length()));
            randomPassword += charset.substring(randomIndex, randomIndex + 1);
        }
        String modifiedString = randomPassword.substring(0, 4) + charToInsert + randomPassword.substring(4);
        
        return modifiedString;
    }
    
    public static String getRecordTypeDevNameById(String objectName, Id strRecordTypeId){
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById().get(strRecordTypeId).getDeveloperName();
    }
    
    public static String getCurrentQuarter(Integer currentMonth){
        String currentQuarter;
        if (currentMonth >= 1 && currentMonth <= 3) {
            currentQuarter = 'Q1';
        } else if (currentMonth >= 4 && currentMonth <= 6) {
            currentQuarter = 'Q2';
        } else if (currentMonth >= 7 && currentMonth <= 9) {
            currentQuarter = 'Q3';
        } else {
            currentQuarter = 'Q4';
        }
        return currentQuarter;
    }
    
    public static Id getRecordTypeIdByDevName(Schema.SObjectType sObjType, string recTypeDevName){
        Id recTypeId;
        if(sObjType != NULL && String.isNotBlank(recTypeDevName)){
            recTypeId = sObjType.getDescribe().getRecordTypeInfosByDeveloperName().get(recTypeDevName).getRecordTypeId();
        }  
        return recTypeId;  
    }
    
    public static Id getRecordTypeIdByName(Schema.SObjectType sObjType, string recTypeName){
        Id recTypeId;
        if(sObjType != NULL && String.isNotBlank(recTypeName)){
            recTypeId = sObjType.getDescribe().getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        }  
        return recTypeId;  
    }
    
    public static Map<String, String> getPicklistValues(Schema.SObjectType sObjType, String fieldAPIName){
        Map<String, String> options = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = sObjType.getDescribe().fields.getMap().get(fieldAPIName).getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.put(p.getValue(), p.getLabel());
        }
        return options;
    }
    
    public static Boolean checkAnyFieldChange(Sobject newObj, Sobject oldObj) {
        for (String field : newObj.getSObjectType().getDescribe().fields.getMap().keySet()) {
            if (newObj.get(field) != oldObj.get(field)) {
                return true;
            }
        }
        return false;
    }
    
    public static List<String> getUserEmailsFromPublicGroupId(Id groupId) {
        List<User> groupUsers = new List<User>();
        List<String> userEmails = New List<String>();
        if(String.isNotBlank(groupId)){
            Set<Id> userIds = new Set<Id>();
            for (GroupMember member : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :groupId]) {
                userIds.add(member.UserOrGroupId);
            }
            
            UserService objUserService = UserService.getInstance();
            for(User u:objUserService.getUsersByIds(userIds)){
                userEmails.add(u.Email);
            }
        }
        return userEmails;
    }
    
    public static List<String> getUserEmailsFromPublicGroupIds(Set<Id> groupIds) {
        List<User> groupUsers = new List<User>();
        List<String> userEmails = New List<String>();
        if(groupIds != NULL && !groupIds.isEmpty()){
            Set<Id> userIds = new Set<Id>();
            for (GroupMember member : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :groupIds]) {
                userIds.add(member.UserOrGroupId);
            }
            
            UserService objUserService = UserService.getInstance();
            for(User u:objUserService.getUsersByIds(userIds)){
                userEmails.add(u.Email);
            }
        }
        return userEmails;
    }   
    
    public static string formatEmiratesId(String emiratesId){
        if(String.isNotBlank(emiratesId)){
            emiratesId = emiratesId.remove('-');
            Integer eidCharLength = emiratesId.length();
            if(eidCharLength > 3){
                emiratesId = emiratesId.substring(0, 3) + '-' + emiratesId.substring(3, emiratesId.length());
            }
            if(eidCharLength > 7){
                emiratesId = emiratesId.substring(0, 8) + '-' + emiratesId.substring(8, emiratesId.length());
            }
            if(eidCharLength > 14){
                emiratesId = emiratesId.substring(0, 16) + '-' + emiratesId.substring(16, emiratesId.length());
            }
        }
        return emiratesId;
    }
    public static string formatPhoneNumber(String countryCode, String phoneNumber){
        if(String.isNotBlank(countryCode) && String.isNotBlank(phoneNumber)){
            phoneNumber = countryCode + phoneNumber;
        }
        return phoneNumber;
    }
    
    public static string doStandardizePhoneNumber(String phoneNumber){
        if(String.isNotBlank(phoneNumber)){
            if(phoneNumber.startsWith('0')){
                phoneNumber = phoneNumber.replaceFirst('^0+', '');
            }
            if(phoneNumber.contains(' ')){
                phoneNumber = phoneNumber.replace(' ', '');
            }
        }
        return phoneNumber;
    }
    
    public static string doStandardizeText(String name){
        if(String.isNotBlank(name)){
            name = name.substring(0, 1).toUpperCase() + name.substring(1).toLowerCase();      
        }
        return name;
    }
    
    public static string getCountingFromNumber(Decimal NoOfReminderSent) {
        String counting = '';
        switch on Integer.valueOf(NoOfReminderSent) {
            when 1 {
                counting = 'st';
            }
            when 2 {
                counting = 'nd'; 
            }
            when 3 {
                counting = 'rd'; 
            }
            when else {
                counting = 'th';
            }
        }
        return counting;
    }
    
    public static String formatDateToYYYYMMDD(Date dt) {
        if (dt == null) return null;
        
        Integer year = dt.year();
        Integer month = dt.month();
        Integer day = dt.day();
        
        String monthStr = (month < 10 ? '0' : '') + String.valueOf(month);
        String dayStr = (day < 10 ? '0' : '') + String.valueOf(day);
        
        return String.valueOf(year) + monthStr + dayStr;
    }
    
    //community app related changes
    public static String formatDayMonth(Date dt) {
        DateTime dtTime = DateTime.newInstance(dt, Time.newInstance(0, 0, 0, 0));
        return dtTime.format('dd MMMM');
    }
    
    public static String formatTimeHHmm(Time t) {
        Date dummyDate = Date.today(); 
        DateTime dt = DateTime.newInstance(dummyDate, t);
        return dt.format('h:mm a');
    }
    
    public static String getMonthYearLabel(Date d) {
        List<String> months = new List<String>{
            'January', 'February', 'March', 'April', 'May', 'June', 
                'July', 'August', 'September', 'October', 'November', 'December'
                };
                    Integer monthIndex = d.month() - 1; // 0-based index
        return months[monthIndex] + ' ' + String.valueOf(d.year());
    }
    
      public static String getRecordTypeNameById(String objectName, Id strRecordTypeId) {
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById().get(strRecordTypeId).getName();
    }

    public static String formatTime(Time t) {
        String hh = (t.hour() < 10) ? '0' + String.valueOf(t.hour()) : String.valueOf(t.hour());
        String mm = (t.minute() < 10) ? '0' + String.valueOf(t.minute()) : String.valueOf(t.minute());
        String ss = (t.second() < 10) ? '0' + String.valueOf(t.second()) : String.valueOf(t.second());
        return hh + ':' + mm + ':' + ss;
    }
    
    /**
    * Check if a record exists in org based on Id
    * @param recordId Id of the record
    * @return true if exists, false if not
    */
    public static Boolean recordExists(Id recordId) {
        if (recordId == null) return false;
        
        String idStr = String.valueOf(recordId);
        if (idStr.length() != 15 && idStr.length() != 18) return false;
        
        try {
            Schema.SObjectType objType = recordId.getSObjectType(); 
            String objectName = objType.getDescribe().getName();
            String soql = 'SELECT Id FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
            List<SObject> records = Database.query(soql);
            return !records.isEmpty();
        } catch (Exception e) {
            return false; 
        }
    }
    
    public static String formatCurrency(Decimal amount) {
        if (amount == null) return '0.00';
        String amt = String.valueOf(amount.setScale(2, RoundingMode.HALF_UP));
        return amt.replaceAll('(?<=\\d)(?=(\\d{3})+(?!\\d))', ',');
    }

    public static String formatDate(Date inputDate) {
        if (inputDate != null)
            return DateTime.newInstance(inputDate.year(), inputDate.month(), inputDate.day()).format('dd-MMM-yy');
        return '';
    }
    
    public static Decimal getOrDefault(Decimal objDecimal) { 
        return objDecimal == null ? 0 : objDecimal; 
    }
    
    public static Boolean getOrDefault(Boolean objBoolean) { 
        return objBoolean == null ? false : objBoolean; 
    }
    
    public static String getGUID() {
        return String.valueOf(UUID.randomUUID());
    }

    public static String formatPhoneNumberWithCountryCode(String phoneNumber){

        if(String.isBlank(phoneNumber)){
            return phoneNumber;
        }
        phoneNumber = phoneNumber.trim();
        if(phoneNumber.startsWith('0')){
            phoneNumber = '971' + phoneNumber.substring(1);
        }

        return phoneNumber;
    }
    public static Datetime calculateSLAEndDate(Id businessHoursId, Datetime assignedDateTime, Decimal slaHours){        
        if(businessHoursId == null || assignedDateTime == null || slaHours == null){
            return null;
        }
        Long milliseconds = (Long)(slaHours * 60 * 60 * 1000);
        Datetime slaEndDate = BusinessHours.add(businessHoursId, assignedDateTime, milliseconds);
        return slaEndDate;
    }

    public String maskPhoneNumber(String phoneNumber) {
        if(String.isBlank(phoneNumber) || phoneNumber.length() < 6){
            return phoneNumber;
        }
        return phoneNumber.substring(0,3) + 'XXXX' + phoneNumber.substring(phoneNumber.length() - 3);
    }

    public String cleanPhoneNumber(String phoneNumber){

        if(phoneNumber == null){
            return '';
        }
        phoneNumber = phoneNumber.replaceAll('[^0-9]', '');
        return phoneNumber;
    }
}