/***
Class       : UpdateLeadInfoAfterRefreshBatch
Author      : Smaartt
Description : 
TestClass   : UpdateLeadInfoAfterRefreshBatchTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0              05/12/23           Initial Version 
****************************************************************************************************************/
global class UpdateLeadInfoAfterRefreshBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start( Database.BatchableContext context ) {
        return Database.getQueryLocator( 'SELECT id,Email,MobilePhone FROM Lead WHERE Status !=\'Retired\' ' );
    }
    
    global void execute( Database.BatchableContext context, List<Lead> lea ) {        
        for ( Lead l : lea) {            
            l.Email = RandomCharactersGenerator.generateRandomString(9)+'@test.com';
            l.MobilePhone =  RandomCharactersGenerator.generateRandomNumber(9);
        }        
        update lea;        
    }
    
    global void finish( Database.BatchableContext context ) {
        
    }
    
}