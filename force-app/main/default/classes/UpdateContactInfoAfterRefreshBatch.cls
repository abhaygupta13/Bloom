/***
Class       : UpdateContactInfoAfterRefreshBatch
Author      : Smaartt
Description : 
TestClass   : UpdateContactInfoAfterRefreshBatchTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0              05/12/23           Initial Version 
****************************************************************************************************************/
global class UpdateContactInfoAfterRefreshBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start( Database.BatchableContext context ) {
        return Database.getQueryLocator( 'SELECT id, email,mobilephone FROM Contact' );
    }
    
    global void execute( Database.BatchableContext context, List<Contact> con ) {
        
        for ( Contact c : con) {            
            c.email = RandomCharactersGenerator.generateRandomString(9)+'@test.com';
            c.MobilePhone =  RandomCharactersGenerator.generateRandomNumber(9);
        }        
        update con;
        
    }
    
    global void finish( Database.BatchableContext context ) {
        
    }
}