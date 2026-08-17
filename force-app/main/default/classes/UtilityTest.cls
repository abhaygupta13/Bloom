@isTest
public class UtilityTest {
    
    @isTest
    static void testGetRandomString() {
        Integer len = 10;
        String result = Utility.getRandomString(len);
        
        
          RecordType existingRecordType = [SELECT Id, Name,DeveloperName  FROM RecordType 
                                          WHERE SObjectType = 'Account' 
                                          AND Name = 'Person Account' 
                                          LIMIT 1];
        Account oldAccount = new Account(
            Name = 'Old Name',
            AnnualRevenue = 50000
        );
        insert oldAccount;

        // Clone the Account record with modified values
        Account newAccount = new Account(
            Id = oldAccount.Id, // Use the same Id to indicate it's the same record
            Name = 'New Name', // Change the Name field
            AnnualRevenue = 50000 // Keep AnnualRevenue the same
        );
        
        Group gp = [SELECT Id, Name, Type FROM Group where Name ='Sales Operation Team'];
        
            Utility.getRecordTypeIdByName(Account.SObjectType, existingRecordType.Name);
            Utility.getRecordTypeIdByDevName(Account.SObjectType, existingRecordType.DeveloperName);
            Utility.getPicklistValues(Account.SObjectType,'Industry');
            Utility.checkAnyFieldChange(newAccount, oldAccount);
            Utility.getUserEmailsFromPublicGroupId(gp.id);
            Utility.getUserEmailsFromPublicGroupIds(new set<id>{gp.id});
            Utility.formatEmiratesId('53535353');
             Utility.formatPhoneNumber('971','53535353');
             Utility.doStandardizePhoneNumber('53535353');
             Utility.doStandardizeText('test abc');
        	Utility.getCurrentQuarter(2);
        	Utility.getCurrentQuarter(5);
        	Utility.getCurrentQuarter(8);
        	Utility.getCurrentQuarter(10);
        	Utility.getRandomString(10);
        	Utility.getCurrentQuarter(5);
        	Utility.getCountingFromNumber(5);
        	//Utility.getRecordTypeIdByDevName('Case', 'DefaultUnit'); 
        	//Shruti
        	Utility.recordExists(oldAccount.Id);   
        	Utility.generateRandomPassword();
        	Utility.getMonthYearLabel(System.Today());
        	Utility.formatDayMonth(System.Today());
        	Utility.formatDateToYYYYMMDD(System.Today());	
        	Utility.getCountingFromNumber(1);
            Utility.getCountingFromNumber(2);
            Utility.getCountingFromNumber(3);
        	Utility.formatTimeHHmm(Time.newInstance(14, 30, 0, 0));
        	Utility.formatTime(Time.newInstance(14, 30, 0, 0));
        	Utility.doStandardizePhoneNumber('0888888888');
        	Utility.doStandardizePhoneNumber('08888888 8');
           }
    
    
  }