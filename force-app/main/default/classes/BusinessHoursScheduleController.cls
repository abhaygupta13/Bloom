/*****************************************************************************************
* @Author        : Prashant Sahu
* @CreatedDate   : 18 May 2026
* @Description   : This controller is used to upload and process Contact Center
*                  Schedule CSV files in Salesforce.
*
*                  Features:
*                  - Validates CSV file format and headers
*                  - Validates email addresses and active users
*                  - Parses StartDateTime and EndDateTime values
*                  - Inserts new BusinessHoursSchedule__c records
*                  - Updates existing schedule records for same user/date
*                  - Skips blank rows safely
*                  - Prevents invalid date and time entries
*
* @Methods       :
*                  1. uploadSchedule  : Main method to process CSV upload
*                  2. parseCSVRow     : Parses CSV row into column values
*                  3. isValidEmail    : Validates email using regex pattern
*                  4. parseDateTime   : Converts CSV datetime string into DateTime
*
* @Object Used   : BusinessHoursSchedule__c
*
* @Version       : 1.0
*****************************************************************************************/
public with sharing class BusinessHoursScheduleController {
    @AuraEnabled
    public static String uploadSchedule(String csvText,String fileName) { 
        try{
            UserService objUserService = UserService.getInstance();
            BusinessHoursService bhservice = BusinessHoursService.getInstance();
            BusinessHoursScheduleService objBusiHoursScheduleService =  BusinessHoursScheduleService.getInstance();
        
            Id defaultBHId = MetadataService.getInstance().getAppSettingTextValue('DefaultBusinessHoursId');
            
            if(String.isBlank(csvText)) throw new AuraHandledException('CSV file is empty. Please upload a valid CSV file.');
            
            if(String.isBlank(fileName) || !fileName.toLowerCase().endsWith('.csv'))
                throw new AuraHandledException('Invalid file format. Please upload CSV file only.');
            
            csvText = csvText.replace('\r\n','\n').replace('\r','\n');
            List<String> rows = csvText.split('\n');
            
            if(rows.size() <= 1){
                throw new AuraHandledException('Invalid CSV format. Please use the sample CSV template.');
            }
            List<String> headerCols = parseCSVRow(rows[0]);
            
            if(headerCols.size() < 6){
                throw new AuraHandledException('CSV header format is invalid. Please check the sample CSV file.');
            }
            
            if(headerCols[0].trim().toLowerCase() != 'agentname' ||
               headerCols[1].trim().toLowerCase() != 'email' ||
               headerCols[2].trim().toLowerCase() != 'startdate' ||
               headerCols[3].trim().toLowerCase() != 'starttime' ||
               headerCols[4].trim().toLowerCase() != 'enddate' ||
               headerCols[5].trim().toLowerCase() != 'endtime') {
                   
                   throw new AuraHandledException('CSV header names are incorrect. Please use the sample CSV format.');
               }
            
            Set<String> emailSet = new Set<String>();
            for(Integer i = 1; i < rows.size(); i++) {
                if(String.isBlank(rows[i])) continue;
                List<String> cols = parseCSVRow(rows[i]);
                if(cols.size() < 6) continue;
                String email = cols[1].trim();
                if(String.isBlank(email)){
                    throw new AuraHandledException('Email field is mandatory. Please fill all email fields in CSV file.');
                }
                if(!isValidEmail(email)){
                    throw new AuraHandledException('Invalid email format found in CSV file. Please check and upload again.');
                }
                emailSet.add(email.toLowerCase());
            }
            
            Map<String,User> userMap = new Map<String,User>();
            Set<Id> businessHourIdSet = new Set<Id>();  
            businessHourIdSet.add(defaultBHId);
            Set<Id> userIdSet = new Set<Id>();
                
            for(User usr : objUserService.getUsersByEmails(emailSet)) { 
                userMap.put(usr.Email.toLowerCase(),usr); 
                userIdSet.add(usr.Id);
                if(usr.BusinessHour__c != null){
                    businessHourIdSet.add(usr.BusinessHour__c);
                }
            } 
            
            Map<Id, BusinessHours> businessHoursMap = new Map<Id, BusinessHours>(bhservice.getBusinessHoursByIds(businessHourIdSet));
            
            DateTime todayAsStartDT = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
                
            Map<String,BusinessHoursSchedule__c> existingMap = new Map<String,BusinessHoursSchedule__c>();
            for(BusinessHoursSchedule__c oldRec : objBusiHoursScheduleService.getBusinessHoursScheduleByUserIdStartDTs( userIdSet, todayAsStartDT ) ) {
                if(oldRec.User__c != null && oldRec.StartDateTime__c != null) {
                    String key = oldRec.User__c + '_' + String.valueOf(oldRec.StartDateTime__c.date());
                    existingMap.put(key,oldRec);
                }
            }
            
            List<BusinessHoursSchedule__c> recordsToInsert = new List<BusinessHoursSchedule__c>();
            Map<Id,BusinessHoursSchedule__c> recordsToUpdateMap = new Map<Id,BusinessHoursSchedule__c>();
            
            for(Integer i = 1; i < rows.size(); i++) {
                
                if(String.isBlank(rows[i])) continue;
                
                List<String> cols = parseCSVRow(rows[i]);
                
                if(cols.size() < 6) continue;
                
                String agentName = cols[0].trim();
                String email = cols[1].trim().toLowerCase();
                String startDate = cols[2].trim();
                String startTime = cols[3].trim();
                String endDate = cols[4].trim();
                String endTime = cols[5].trim();
                
                if(String.isBlank(startDate)){
                    throw new AuraHandledException('Start Date is mandatory.');
                }
                if(String.isBlank(startTime)){
                    throw new AuraHandledException('Start Time is mandatory.');
                }
                if(String.isBlank(endDate)){
                    throw new AuraHandledException('End Date is mandatory.');
                }
                if(String.isBlank(endTime)){
                    throw new AuraHandledException('End Time is mandatory.');
                }
                if(String.isBlank(email)){
                    throw new AuraHandledException('Email field is mandatory. Please fill all email fields in CSV file.');
                }
                
                User usr = userMap.get(email);
                if(usr == null || (usr != null && usr.isActive == false)){
                    throw new AuraHandledException('No active user found for email: ' + email + '. Please check the CSV file and try again.');
                }
                
                DateTime startDT = null;
                DateTime endDT = null;
                
                String startDateTime = startDate + ' ' + startTime;
                String endDateTime = endDate + ' ' + endTime;   
                startDT = parseDateTime(startDateTime);
                
                if(startDT == null){
                    throw new AuraHandledException(  'Invalid Start Date/Time format found in CSV file.');
                }
                
                endDT = parseDateTime(endDateTime);
                if(endDT == null){
                    throw new AuraHandledException( 'Invalid End Date/Time format found in CSV file.');
                }
                
                if(startDT != null && endDT != null && endDT <= startDT){
                    throw new AuraHandledException('End Date Time should be greater than Start Date Time. Please check CSV file.');
                }
                if(startDT == null) continue;
                
                String recordKey = usr.Id + '_' + String.valueOf(startDT.date());
                BusinessHoursSchedule__c existingRec = existingMap.get(recordKey);
                BusinessHours bh = businessHoursMap.get(usr.BusinessHour__c);
                if (bh == null) {
                    bh = businessHoursMap.get(defaultBHId);
                }
                DateTime startDTInBH = startDT;
                DateTime endDTInBH   = endDT;
                if(existingRec != null) {
                    existingRec.Name = String.isBlank(agentName) ? email : agentName;
                    existingRec.StartDateTime__c = startDTInBH;
                    existingRec.EndDateTime__c = endDTInBH;
                    recordsToUpdateMap.put(existingRec.Id,existingRec);
                } 
                else {
                    BusinessHoursSchedule__c rec = new BusinessHoursSchedule__c();
                    rec.Name = String.isBlank(agentName) ? email : agentName;
                    rec.User__c = usr.Id;
                    rec.StartDateTime__c = startDTInBH;
                    rec.EndDateTime__c = endDTInBH;
                    recordsToInsert.add(rec);
                }
            }
            
            if(recordsToInsert.isEmpty() && recordsToUpdateMap.isEmpty()){
                return 'CSV validated and uploaded successfully. Blank rows were skipped.';
            }
            if(!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }
            if(!recordsToUpdateMap.isEmpty()) {
                update recordsToUpdateMap.values();
            }
            return recordsToInsert.size() + ' records inserted and ' + recordsToUpdateMap.size() + ' records updated successfully.';
        }catch (AuraHandledException ex) {
            throw ex;
        }
        catch (Exception ex) {
            throw new AuraHandledException(
                'Unexpected Error: ' + ex.getMessage()
            );
        }
        
    }
    
    @AuraEnabled(cacheable=true)
    public static String getSampleCSVContentVersionId() {
        return MetadataService.getInstance().getAppSettingTextValue('SampleCSVContentVersionId');
    }
    
    private static List<String> parseCSVRow(String row) {
        List<String> cols = new List<String>();
        if(String.isBlank(row)) return cols;
        cols = row.contains('\t') ? row.split('\t',-1) : row.split(',',-1);
        for(Integer i = 0; i < cols.size(); i++){
            cols[i] = cols[i].replace('"','').replace('\r','').trim();
        }
        return cols;
    }
    
    private static Boolean isValidEmail(String email) {
        Pattern pattern = Pattern.compile('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$');
        return pattern.matcher(email).matches();
    }
    
    private static DateTime parseDateTime(String input) {
    input = input.trim();

    List<String> parts = input.split(' ');
    if(parts.size() != 3) return null;

    List<String> dateParts = parts[0].replace('/', '-').split('-');
    if(dateParts.size() != 3) return null;

    Integer day = Integer.valueOf(dateParts[0]);
    Integer month = Integer.valueOf(dateParts[1]);
    Integer year = Integer.valueOf(dateParts[2]);

    List<String> timeParts = parts[1].split(':');
    if(timeParts.size() != 2) return null;

    Integer hour = Integer.valueOf(timeParts[0]);
    Integer minute = Integer.valueOf(timeParts[1]);
    String ampm = parts[2].toUpperCase();

    if(hour < 1 || hour > 12) return null;
    if(minute < 0 || minute > 59) return null;
    if(ampm != 'AM' && ampm != 'PM') return null;

    if(ampm == 'PM' && hour < 12) hour += 12;
    if(ampm == 'AM' && hour == 12) hour = 0;

    return DateTime.newInstance(
        Date.newInstance(year, month, day),
        Time.newInstance(hour, minute, 0, 0)
    );
}
}