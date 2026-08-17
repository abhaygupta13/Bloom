/***
Class       : UpdateAccountInfoAfterRefreshBatch
Author      : Smaartt
Description : 
TestClass   : UpdateAccountInfoAfterRefreshBatchTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0              05/12/23           Initial Version 
****************************************************************************************************************/
global class UpdateAccountInfoAfterRefreshBatch implements Database.Batchable<SObject> {
    Exception[] errors = new Exception[0];
    global Database.QueryLocator start( Database.BatchableContext context ) {
        return Database.getQueryLocator( 'SELECT id,PersonEmail,PersonMobilePhone,MobileNumber__c,IsPersonAccount FROM Account' );
    }
    
    global void execute( Database.BatchableContext context, List<Account> Acc ) {        
        for ( Account a : Acc) {    
            if(a.IsPersonAccount){
                a.PersonEmail = RandomCharactersGenerator.generateRandomString(9)+'@test.com';
                a.PersonMobilePhone =  RandomCharactersGenerator.generateRandomNumber(9);
            }else{
                a.MobileNumber__c=RandomCharactersGenerator.generateRandomNumber(9);
            }
           
        }  
        try {
            update Acc; 
        }catch(Exception e) {
            errors.add(e);
        }
    }
    
    global void finish( Database.BatchableContext context ) {
        if(!errors.isEmpty()) {
            system.debug(errors);
        }
        
    }
    
}