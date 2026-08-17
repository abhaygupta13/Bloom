@IsTest
public class MarkretriedleadstatusTest {
@IsTest
    static void Testmethod1(){
        Lead l = new Lead();
        l.LastName = 'Testclass';
        l.MobileCountryCode__c = '971';
        l.Status = 'New';
        l.MobilePhone = '37829292020';
        l.Email = 'Testclass@gmail.com';
       // l.Lead_Channel__c = 'Online';
       l.RetiredReason__c = 'Duplicate';
        l.RetirementComments__c = 'retired'; 
        Test.startTest();
      
        
        try {
            insert l;
        } catch (exception e) {
           
        }
 try {
            Markretriedleadstatus.markretriedStatus(String.valueOf(l.Id));
        } catch (exception e) {
         
        }
        Test.stopTest();

      }

   
   
}