@isTest
public class UnitLayoutUploadBatchTest {
    @isTest
    static void testExecuteMethod() {
    // Step 1: Query the AppSetting__mdt metadata to get the UnitLayoutLibraryFolderId
    Unit__c testUnit = new Unit__c(Name = 'Test File');
        insert testUnit;
    List<AppSetting__mdt> folderData = [
        SELECT TextValue__c 
        FROM AppSetting__mdt 
        WHERE DeveloperName = 'UnitLayoutLibraryFolderId'
    ];
    
    System.assert(!folderData.isEmpty(), 'No metadata record found for UnitLayoutLibraryFolderId.');
    String folderId = folderData[0].TextValue__c;
    System.debug('Folder Id from Metadata: ' + folderId);

    // Step 2: Create and insert a ContentVersion (File)
    ContentVersion contentVersion = new ContentVersion(
        Title = 'Test File',
        PathOnClient = 'TestFile.pdf',
        VersionData = Blob.valueOf('Sample file content'),
        IsMajorVersion = true
    );
    insert contentVersion;
    System.debug('Inserted ContentVersion: ' + contentVersion);

    // Step 3: Retrieve ContentDocumentId from the inserted ContentVersion
    Id contentDocumentId = [
        SELECT ContentDocumentId 
        FROM ContentVersion 
        WHERE Id = :contentVersion.Id
    ].ContentDocumentId;
    System.debug('ContentDocumentId: ' + contentDocumentId);

    // Step 4: Link the ContentDocument to the Library using ContentDocumentLink
    ContentDocumentLink link = new ContentDocumentLink(
        ContentDocumentId = contentDocumentId,
        LinkedEntityId = folderId, // Folder Id from Metadata
        ShareType = 'I', // Inferred permissions
        Visibility = 'AllUsers'
    );
    insert link;
    System.debug('Inserted ContentDocumentLink: ' + link);

    // Step 5: Verify inserted ContentDocument and ContentVersion details
    List<ContentVersion> contentVersions = [
        SELECT Title, ContentDocumentId, FileType, IsLatest, PathOnClient, FileExtension, VersionData 
        FROM ContentVersion
    ];
    System.debug('ContentVersion records: ' + contentVersions);

    List<ContentDocument> contentDocuments = [
        SELECT Id, ParentId 
        FROM ContentDocument 
        WHERE Id = :contentDocumentId
    ];
    System.debug('ContentDocument ParentId: ' + contentDocuments);

    // Step 6: Execute Batch class and assert results
    Test.startTest();
    Database.executeBatch(new UnitLayoutUploadBatch(), 1);
    Test.stopTest();
}

    
    
}