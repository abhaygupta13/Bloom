/***
Class       : SandboxPostRefreshActivities
Author      : Smaartt
Description : 
TestClass   : SandboxPostRefreshActivitiesTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0              05/12/23           Initial Version 
****************************************************************************************************************/
global class SandboxPostRefreshActivities implements SandboxPostCopy {
    global void runApexClass( SandboxContext context ) {        
        Database.executeBatch(new UpdateContactInfoAfterRefreshBatch(), 200);
        Database.executeBatch(new UpdateAccountInfoAfterRefreshBatch(), 200);
        Database.executeBatch(new UpdateLeadInfoAfterRefreshBatch(), 200);       
        
    }
}